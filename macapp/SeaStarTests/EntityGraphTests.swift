import Foundation
import SwiftUI
import Testing

@testable import SeaStar

/// The graph's honesty contract, written as tests rather than as comments.
///
/// Everything here exists because the founder's rule was that the graph must
/// never imply activity the engine did not observe. A rule that only lives in a
/// doc comment will be broken by the next plausible-looking refactor, so the
/// liveness rules are pinned here against a real decoded report — the same one
/// the bridge actually produces — rather than against a hand-built graph.
@Suite("Graph liveness is what was observed, nothing else")
@MainActor
struct GraphLivenessTests {
    /// A controller holding a report, with no engine behind it. `command: nil`
    /// is what keeps this hermetic: nothing is spawned, nothing is probed, and
    /// `ready` is whatever the fixture says it is.
    private func controller(
        ready: Bool = true,
        model: String = "qwen3",
        agents: Bool = true,
        latent: Bool = true,
        attached: Bool = true
    ) -> ServerController {
        let controller = ServerController(command: nil)
        controller.adopt(try! Fixture.report(
            ready: ready,
            model: model,
            agents: agents,
            latent: latent,
            attached: attached
        ))
        return controller
    }

    private func nodes(_ controller: ServerController) -> [String: GraphNode] {
        Dictionary(
            uniqueKeysWithValues: EntityGraphModel(controller: controller).nodes.map { ($0.id, $0) }
        )
    }

    // MARK: - The rule itself

    /// Live means something was *observed* during the latest read. Four things
    /// qualify with a ready endpoint and one attached host: the app driving
    /// Sea-Star (its process is recorded), the endpoint being read, the model
    /// that endpoint is serving, and an agent riding that model. Nothing else —
    /// and in particular no app that is merely installed.
    @Test("a ready endpoint and an attached host make exactly four things live")
    func readyMakesFourLive() {
        let byID = nodes(controller())
        let live = byID.values.filter(\.isLive).map(\.id).sorted()

        #expect(live == [
            "agent:Mariner",
            "harness:chat.atomic.app",
            "inference:http://127.0.0.1:1337/v1",
            "model:qwen3",
        ])
    }

    /// An app driving the engine is the top rung and the only harness drawn
    /// live, because the engine recorded the process rather than inferring one.
    @Test("an attached host is live and wears the connected rung")
    func attachedHostIsLiveAndConnected() {
        let byID = nodes(controller())
        let host = byID["harness:chat.atomic.app"]

        #expect(host?.kind == .harness)
        #expect(host?.isLive == true)
        #expect(host?.rung == .connected)
    }

    /// The single most important test in this file. A vault is not on a port at
    /// all, and an app that is merely *installed* answers on none. If either
    /// could be drawn live, the graph would be claiming the engine talked to
    /// something it never touched.
    @Test("a vault is never live, however ready the endpoint is")
    func vaultIsNeverLive() {
        let byID = nodes(controller(ready: true))
        #expect(byID["vault"]?.isLive == false)
        #expect(byID["vault"]?.kind == .vault)

        // And when nothing answered at all, it is still false — so the rule is
        // not "true unless ready", which would have been the easy way to write it.
        let cold = nodes(controller(ready: false))
        #expect(cold["vault"]?.isLive == false)
    }

    /// A harness app that is not attached is an app on the disk carrying its own
    /// model loop. There is nothing for a probe to have answered, so it cannot be
    /// live under any circumstances — but it is still drawn, and it still says
    /// which rung it reached.
    @Test("an unattached harness app is never live, and never flattened to one grey state")
    func unattachedHarnessIsNeverLive() {
        let byID = nodes(controller())
        let installed = byID["harness:app:com.apple.dt.Xcode"]
        let up = byID["harness:app:ai.unsloth.studio"]

        #expect(installed?.kind == .harness)
        #expect(installed?.isLive == false)
        // "Installed" and "up but not answering" are different facts, and the
        // graph has to be able to say both.
        #expect(installed?.rung == .present)
        #expect(up?.rung == .running)

        // D-020: the rung has to carry a *drawing* consequence too, or the pool
        // flattens the two back into one grey. An app that never launched is
        // not up; a running one is. `isUp` is the honest test, and it is what
        // the glow reads.
        #expect(installed?.rung?.isUp == false)
        #expect(up?.rung?.isUp == true)
        // Neither may be `isAttached`: up is not the same as driving Sea-Star.
        #expect(installed?.rung?.isAttached == false)
        #expect(up?.rung?.isAttached == false)
    }

    /// "Installed" is not "answering". Both endpoints are detected and both are
    /// on the graph, and only the one the report is actually describing is live.
    @Test("only the endpoint being described is live; the other is merely available")
    func onlyTheCurrentEndpointIsLive() {
        let byID = nodes(controller())
        #expect(byID["inference:http://127.0.0.1:1337/v1"]?.isLive == true)
        #expect(byID["inference:http://127.0.0.1:8000/v1"]?.isLive == false)
    }

    /// Every model the endpoint offers is drawn. Only the one it is serving
    /// *now* answered, so only that one is live — "on offer" and "in use" are
    /// different facts and the graph has to keep them apart.
    @Test("only the current model is live; the others are on offer")
    func onlyTheCurrentModelIsLive() {
        let byID = nodes(controller())
        #expect(byID["model:qwen3"]?.isLive == true)
        #expect(byID["model:qwen3-tiny"]?.isLive == false)
    }

    /// The load-bearing distinction in the whole ontology. An agent is live when
    /// the *endpoint behind it* answered — not when someone spoke to it. Sea-Star
    /// observes the port, never the conversation, so it must not draw the
    /// stronger claim it has no evidence for.
    @Test("an agent is endpoint-live only on the current model, and never implies conversation")
    func agentLivenessFollowsTheModel() {
        let byID = nodes(controller())

        // Rides the current model, so the endpoint answered under it.
        #expect(byID["agent:Mariner"]?.isLive == true)
        // Rides a model the endpoint is not serving right now.
        #expect(byID["agent:Cartographer"]?.isLive == false)
        // Bound to no model at all — there is no endpoint behind it to have
        // answered, and drawing it live would be inventing one.
        #expect(byID["agent:Drifter"]?.isLive == false)
    }

    /// The whole graph goes cold together, and stays cold. A failed probe must
    /// not leave yesterday's live nodes glowing.
    ///
    /// One exception, and it is the point of the whole pass: an attached harness
    /// is live on *different evidence* — a process the engine can see — and it
    /// stays live when inference is down. The app really is connected; it just
    /// has nothing to think with.
    @Test("an endpoint that did not answer leaves nothing live but the attached host")
    func notReadyMeansOnlyTheAttachedHostIsLive() {
        let model = EntityGraphModel(controller: controller(ready: false))

        #expect(!model.nodes.isEmpty)
        // Spelled as a closure rather than a key path: the same roster is
        // present, so this has to be about liveness rather than about emptiness.
        let live = model.nodes.filter(\.isLive).map(\.id).sorted()
        #expect(live == ["harness:chat.atomic.app"])

        // And with nothing attached, a cold endpoint really does leave the whole
        // pool dark — nothing is glowing on the strength of a name alone.
        let dark = EntityGraphModel(controller: controller(ready: false, attached: false))
        #expect(!dark.nodes.contains { $0.isLive })
    }

    /// With no roster from the engine there are simply no agents to draw. The
    /// graph must not invent personas to fill the space — an empty node list is
    /// the honest reading of an engine too old to have the field.
    @Test("an engine without agents draws no agents")
    func missingRosterDrawsNoAgents() {
        let model = EntityGraphModel(controller: controller(agents: false))
        #expect(!model.nodes.contains { $0.kind == .agent })
    }

    // MARK: - Edges are honest too

    /// A harness app that is not attached is driving nothing, so it knows about
    /// nothing. Drawing it wired to the vault would imply a connection that was
    /// never observed — the exact lie the ladder exists to prevent.
    ///
    /// There is one observed connection a non-attached app *can* have, and it is
    /// not an exception to that rule: the engine reads which process holds each
    /// model-server port, so an app whose own server is answering is genuinely
    /// connected to it. Unsloth Studio here owns port 8009 and answers on it, so
    /// the wire is drawn; Xcode owns nothing and is wired to nothing.
    @Test("an unattached harness is wired to nothing it was not observed doing")
    func unattachedHarnessHasNoEdges() {
        let model = EntityGraphModel(controller: controller())
        #expect(model.neighbours(of: "harness:app:com.apple.dt.Xcode").isEmpty)
        #expect(
            model.neighbours(of: "harness:app:ai.unsloth.studio")
                == ["inference:http://127.0.0.1:8009/v1"]
        )
    }

    /// The opposite case, and the one the founder asked for by name: an app that
    /// *is* attached is wired to the vault it is driving, to Sea-Star itself, and
    /// to the server its own process owns.
    ///
    /// The endpoint is the load-bearing part. It calls itself `osaurus`, which is
    /// nobody's name — on the real machine the identical case is Atomic Chat's
    /// inbuilt server calling itself `remote`. Only the port-ownership fact can
    /// find it, which is why this test would have failed for two sessions.
    @Test("an attached harness is wired to the vault, to Sea-Star, and to its own server")
    func attachedHarnessIsWiredUp() {
        let model = EntityGraphModel(controller: controller())
        #expect(model.neighbours(of: "harness:chat.atomic.app") == [
            "inference:http://127.0.0.1:1337/v1",
            "seastar",
            "vault",
        ])
    }

    /// The founder's rule for the readout, pinned so it cannot quietly come
    /// back: never "five models". An endpoint names the models it serves.
    @Test("an endpoint readout names its models instead of counting them")
    func endpointFactsNameModels() {
        let model = EntityGraphModel(controller: controller())
        let node = try! #require(model.node("inference:http://127.0.0.1:1337/v1"))
        let rows = model.facts(for: node)

        let serves = rows.first { $0.label == Strings.Detail.serves }?.value
        #expect(serves == "qwen3, qwen3-tiny")
        #expect(!rows.contains { $0.value.lowercased().contains("2 models") })
    }

    /// Local and API inference are the same row and deliberately not the same
    /// colour. The seat of that rule is the model, so it is pinned there.
    @Test("a remote endpoint is drawn apart from one on this Mac")
    func remoteEndpointWearsItsOwnColour() {
        let local = InferenceOption(
            name: "omlx",
            baseURL: "http://127.0.0.1:8009/v1",
            models: []
        )
        let api = InferenceOption(
            name: "deepseek",
            baseURL: "https://api.example.com/v1",
            models: []
        )

        #expect(local.isRemote == false)
        #expect(api.isRemote == true)
    }

    /// A relationship drawn twice looks busier than the report is. Every edge
    /// is walked from both ends, so mutual bindings have to collapse to one.
    @Test("a mutual relationship is drawn once, not twice")
    func edgesAreUndirected() {
        let model = EntityGraphModel(controller: controller())
        let ids = model.edges.map(\.id)

        #expect(Set(ids).count == ids.count)

        // The vault/endpoint binding is mutual, and appears exactly once.
        let forward = GraphEdge(from: "vault", to: "inference:http://127.0.0.1:1337/v1")
        #expect(ids.contains(forward.id))
        #expect(ids.filter { $0 == forward.id }.count == 1)
    }

    /// Every edge must join two things that are actually drawn. A wire to an id
    /// that is not in the pool would have nothing at the end of it.
    @Test("every edge connects two nodes that exist")
    func edgesOnlyJoinKnownNodes() {
        let model = EntityGraphModel(controller: controller())
        let known = Set(model.nodes.map(\.id))

        for edge in model.edges {
            #expect(known.contains(edge.from), "unknown tail \(edge.from)")
            #expect(known.contains(edge.to), "unknown head \(edge.to)")
            #expect(edge.from != edge.to, "an edge to itself")
        }
    }
}

/// The founder asked for "an actual big one hanging in the middle there with
/// live connections for whenever it's live as well", and the reason it needed
/// building is that **a picture cannot carry an edge**: the middle of the pool
/// held a decorative outline, so "everything connects to Sea-Star" was a claim
/// the graph had no way to draw.
///
/// These pin the three things that make the hub honest: there is exactly one and
/// it is *not* on the ring, it is at the middle of both readings, and — the one
/// that keeps the rest from being decoration — it is never itself live, because
/// nothing on this machine can probe the thing doing the probing.
@Suite("Sea-Star is a body in the pool, not the frame around it")
@MainActor
struct GraphCoreTests {
    private var coreID: String { EntityGraphModel.coreID }

    private func model(ready: Bool = true) -> EntityGraphModel {
        EntityGraphModel(controller: Fixture.controller(ready: ready))
    }

    @Test("the pool holds one Sea-Star, and it is not a point on the ring")
    func thereIsExactlyOneCore() {
        let model = model()
        #expect(model.nodes.filter { $0.kind == .core }.count == 1)
        #expect(model.node(coreID)?.title == Strings.Detail.seaStar)
        #expect(model.majors.filter { $0.kind == .core }.isEmpty)
    }

    @Test("Sea-Star is drawn at the middle of both readings")
    func seaStarHoldsTheMiddle() {
        // The flat pool: 400×300 puts the middle at (200, 150).
        let pool = EntityGraphView(controller: Fixture.controller())
            .layout(in: CGSize(width: 400, height: 300))
        #expect(pool[coreID] == CGPoint(x: 200, y: 150))

        // The deep, from the same id. Two drawings of one arrangement, which is
        // the only reason there are two bodies at all.
        let space = GraphSpace3D(model: model())
        #expect(space.positions()[coreID] == space.centre)
        #expect(space.centre == .origin)
    }

    @Test("Sea-Star is never live, however ready the machine is")
    func seaStarIsNeverLive() {
        #expect(model().node(coreID)?.isLive == false)
        #expect(model(ready: false).node(coreID)?.isLive == false)
        // The four live things are the same four — a fifth name here would be
        // the hub claiming a heartbeat it cannot have.
        #expect(model().nodes.filter(\.isLive).count == 4)
    }

    @Test("Sea-Star is wired to the vault, the host driving it, and the endpoint it reads")
    func seaStarIsWiredUp() {
        #expect(model().neighbours(of: coreID) == [
            "harness:chat.atomic.app",
            "inference:http://127.0.0.1:1337/v1",
            "vault",
        ])
        // An app that is installed and idle is not driving Sea-Star, so there is
        // nothing to draw between them. "Connected" has to mean something the
        // other end is doing.
        #expect(!model().neighbours(of: coreID).contains("harness:app:com.apple.dt.Xcode"))
    }

    @Test("the whole-pool reading draws Sea-Star's wires and holds the spokes back")
    func thePoolDrawsTheHubsWires() {
        let ids = Set(model().standingEdges.map(\.id))

        #expect(ids.contains(GraphEdge(from: coreID, to: "vault").id))
        #expect(ids.contains(GraphEdge(from: coreID, to: "harness:chat.atomic.app").id))
        #expect(
            ids.contains(GraphEdge(from: coreID, to: "inference:http://127.0.0.1:1337/v1").id)
        )

        // A model's spoke to the endpoint offering it is a real binding, but
        // drawn alongside every other one it turns the flat pool into a bag of
        // string — the founder's own complaint about the 2D reading. It is a
        // focus-reading edge, and the deep still draws it always.
        #expect(
            !ids.contains(GraphEdge(from: "model:qwen3", to: "inference:http://127.0.0.1:1337/v1").id)
        )
    }

    @Test("Sea-Star's card names what it is driving through, and claims no heartbeat")
    func seaStarCardIsHonest() {
        let graph = model()
        let core = try! #require(graph.node(coreID))
        let rows = graph.facts(for: core)

        #expect(rows.contains { $0.label == Strings.Detail.status && $0.value == Strings.Detail.observing })
        #expect(rows.contains { $0.label == Strings.Detail.drivenBy && $0.value == "Atomic Chat" })
        #expect(rows.contains { $0.label == Strings.Detail.readingThrough && $0.value == "osaurus" })
        // With nothing answering, the card says so rather than going blank.
        let cold = model(ready: false)
        let coldRows = cold.facts(for: try! #require(cold.node(coreID)))
        #expect(coldRows.contains { $0.label == Strings.Detail.status && $0.value == Strings.Detail.notObserving })
    }
}

/// The founder asked for multicoloured nodes. The rule that keeps that honest is
/// that colour is *seeded, never random* — so these tests are what stops a
/// future "let's just make it feel more alive" from turning identity into
/// decoration.
@Suite("Graph identity is seeded, not random")
struct GraphSeedTests {
    @Test("an entity's phase is stable across every call")
    func phaseIsStable() {
        for id in ["vault", "inference:http://127.0.0.1:1337/v1", "model:qwen3", "agent:Mariner"] {
            #expect(GraphSeed.phase(for: id) == GraphSeed.phase(for: id))
        }
    }

    @Test("a phase is always a real angle")
    func phaseIsInRange() {
        for id in ["vault", "model:qwen3", "agent:Cartographer", "harness:app:com.apple.dt.Xcode"] {
            let phase = GraphSeed.phase(for: id)
            #expect(phase >= 0)
            #expect(phase < .pi * 2)
        }
    }

    /// The 2D pool's drift and the 3D pool's tint come from the same hash, so an
    /// entity that drifts one way in the flat pool is tinted one way in the deep.
    /// That agreement is the reason the two readings feel like one pool.
    @Test("hue is the same seed read as a fraction of a turn")
    func hueDerivesFromPhase() {
        for id in ["vault", "inference:http://127.0.0.1:8000/v1", "model:qwen3"] {
            #expect(GraphSeed.hue(for: id) == GraphSeed.phase(for: id) / (.pi * 2))
            #expect(GraphSeed.hue(for: id) >= 0)
            #expect(GraphSeed.hue(for: id) < 1)
        }
    }

    @Test("different entities land on different phases")
    func phasesVary() {
        let ids = (0..<40).map { "entity-\($0)" }
        #expect(Set(ids.map { GraphSeed.phase(for: $0) }).count > ids.count - 4)
    }
}

/// The founder's note on the deep: *"it's never gonna be that crowded, so I'm
/// fine with that… it's not gonna unbearably double the size of the beast."*
/// A handful of things in a pool. So the layout is fixed and deterministic, and
/// these tests are what keep it from quietly becoming a force simulation.
@Suite("The deep is a fixed pool, not a simulation")
@MainActor
struct GraphSpace3DTests {
    /// The model and the space built from it, held together because almost
    /// every claim here is about the *relationship* between the two — where
    /// the pool put a thing, relative to what the roster says that thing is.
    private func pool(radius: Float = 120) -> (EntityGraphModel, GraphSpace3D) {
        let model = EntityGraphModel(controller: Fixture.controller())
        return (model, GraphSpace3D(model: model, radius: radius))
    }

    @Test("the same roster always builds the same pool")
    func layoutIsDeterministic() {
        let (_, first) = pool()
        let (_, second) = pool()
        #expect(first.positions() == second.positions())
    }

    @Test("every node has a place, so none can hide behind another")
    func everyNodeIsPlaced() {
        let (model, space) = pool()
        let ids = Set(model.nodes.map(\.id))

        #expect(ids == Set(space.positions().keys))

        // Absent rather than defaulted to the centre — which is the whole
        // reason the layout returns a dictionary and not a defaulted lookup.
        // A body parked on the centre is a body you cannot click.
        //
        // The core is the one deliberate exception, and the opposite of that
        // failure: it is at the centre *on purpose*, because being the thing
        // everything else is wired to is its whole job in the pool. It is
        // tested for in its own suite rather than waved through here.
        for node in model.nodes where node.kind != .core {
            #expect(space.positions()[node.id] != space.centre)
        }
        #expect(space.positions()[EntityGraphModel.coreID] == space.centre)
    }

    /// The majors ring the pool, so their horizontal distance from the centre is
    /// the radius. That is what makes the shape learnable: the same roster always
    /// opens the same way round, and you learn where things are.
    @Test("the majors ring the pool at exactly its radius")
    func majorsRingThePool() {
        let (model, space) = pool()
        let positions = space.positions()

        for node in model.majors {
            guard let point = positions[node.id] else { continue }
            let horizontal = (point.x * point.x + point.z * point.z).squareRoot()
            #expect(abs(horizontal - space.radius) < 0.01)
        }
    }

    /// Two bodies sharing a spot is the failure mode that makes a small graph
    /// unreadable — you cannot click what you cannot separate.
    @Test("no two bodies occupy the same place")
    func nothingOverlaps() {
        let (_, space) = pool()
        let points = Array(space.positions().values)

        for (index, first) in points.enumerated() {
            for second in points[(index + 1)...] {
                #expect(first.distance(to: second) > 1)
            }
        }
    }

    @Test("a wider pool moves the ring without changing the shape")
    func radiusScalesTheRing() {
        let (model, narrow) = pool(radius: 120)
        let (_, wide) = pool(radius: 240)
        let majorIDs = Set(model.majors.map(\.id))
        let narrowPoints = narrow.positions()
        let widePoints = wide.positions()

        for id in majorIDs {
            guard let from = narrowPoints[id], let to = widePoints[id] else { continue }
            #expect(abs(to.x - from.x * 2) < 0.01)
            #expect(abs(to.z - from.z * 2) < 0.01)
        }
    }

    /// Size is a fact about the roster, not about how you are looking at it —
    /// which is why it lives on the kind rather than in either renderer.
    @Test("a vault outweighs the ring, and Sea-Star outweighs the vault")
    func vaultIsTheHeavyweight() {
        // The ring of majors first — vault, then the harnesses and the
        // endpoints they read from — and the satellites a model and an agent
        // ride on below them.
        #expect(GraphNode.Kind.vault.scale > GraphNode.Kind.harness.scale)
        #expect(GraphNode.Kind.harness.scale > GraphNode.Kind.inference.scale)
        #expect(GraphNode.Kind.inference.scale > GraphNode.Kind.agent.scale)
        #expect(GraphNode.Kind.agent.scale > GraphNode.Kind.model.scale)

        // And then the hub, which is not on that ring and is not measured
        // against it. Sea-Star is the biggest thing in the pool deliberately:
        // the founder asked for "an actual big one hanging in the middle", and a
        // hub drawn smaller than the things wired into it reads as one more node
        // with an odd address rather than as the middle of the picture.
        #expect(GraphNode.Kind.core.scale > GraphNode.Kind.vault.scale)
    }

    /// The layout's actual job is to make the ontology *legible in space*: a
    /// model should read as belonging to the harness that serves it, and an
    /// agent as riding the model it is bound to. If the satellites were simply
    /// scattered, the graph would be a bag of coloured balls — the colours would
    /// say who is who, but the positions would say nothing.
    ///
    /// "Serves it" is read from the shared model's own `neighbours`, not from a
    /// second copy of the rule written here. That is the whole reason the graph
    /// has one model: if the wiring and the placement could disagree, the deep
    /// would be drawing a different claim from the flat pool than the edges in it.
    @Test("a model sits closest to the endpoint that serves it")
    func modelSitsWithItsEndpoint() {
        let (model, space) = pool()
        let positions = space.positions()

        for node in model.nodes where node.kind == .model {
            guard let here = positions[node.id] else { continue }
            let servers = model.neighbours(of: node.id)
                .filter { $0.hasPrefix("inference:") }
            #expect(!servers.isEmpty, "\(node.title) has no endpoint in the pool to sit with")

            let nearest = servers
                .compactMap { positions[$0] }
                .map { here.distance(to: $0) }
                .min() ?? .greatestFiniteMagnitude
            for other in model.nodes where other.kind == .inference {
                guard let there = positions[other.id] else { continue }
                #expect(
                    nearest <= here.distance(to: there),
                    "\(node.title) sits nearer \(other.title) than an endpoint that serves it"
                )
            }
        }
    }

    /// An agent is bound to a model, not to a machine-wide endpoint. So the
    /// space it occupies should read that way too: nearest the model it rides,
    /// and no nearer to some harness it merely happens to be discoverable from.
    ///
    /// An agent with *no* bound model is a different case and is deliberately
    /// skipped rather than forced to pass: it has nothing to orbit, so the layout
    /// parks it on the ring around the active harness. That is the honest
    /// placement for a persona whose model is not currently offered — the graph
    /// is not supposed to invent a binding to give it a tidier home.
    @Test("a bound agent sits closest to the model it rides")
    func agentSitsWithItsModel() {
        let (model, space) = pool()
        let positions = space.positions()

        for node in model.nodes where node.kind == .agent {
            let bound = model.neighbours(of: node.id)
                .filter { $0.hasPrefix("model:") }
            guard !bound.isEmpty else { continue }
            guard let here = positions[node.id] else { continue }

            let nearest = bound
                .compactMap { positions[$0] }
                .map { here.distance(to: $0) }
                .min() ?? .greatestFiniteMagnitude
            for other in model.nodes where other.kind == .inference {
                guard let there = positions[other.id] else { continue }
                #expect(
                    nearest <= here.distance(to: there),
                    "\(node.title) sits nearer \(other.title) than the model it rides"
                )
            }
        }
    }

    /// The other half of that rule, and the reason it is worth stating: an agent
    /// with no model in the pool is still drawn, still placed, and still parked
    /// on the ring around the active harness. It is not dropped, and it is not
    /// given a model it does not have.
    @Test("an agent with no bound model is parked, not dropped and not given one")
    func unboundAgentIsParked() {
        let (model, space) = pool()
        let positions = space.positions()
        let unbound = model.nodes.filter {
            $0.kind == .agent && !model.neighbours(of: $0.id).contains { $0.hasPrefix("model:") }
        }

        #expect(!unbound.isEmpty, "the fixture should exercise an unbound agent")
        for node in unbound {
            #expect(positions[node.id] != nil, "\(node.title) was dropped from the pool")
            #expect(!model.neighbours(of: node.id).contains { $0.hasPrefix("model:") })
        }
    }

    /// The camera opens at a fixed pose, so the pool has to actually fit inside
    /// what that pose can see. If the layout ever grew past the opening view,
    /// bodies would sit off-screen with no indication they existed — a silent
    /// bug that no screenshot of the default view would ever catch.
    @Test("the pool fits inside the camera's opening view")
    func poolFitsTheOpeningView() {
        let (_, space) = pool()
        let points = Array(space.positions().values)
        let furthest = points.map { CGFloat($0.distance(to: space.centre)) }.max() ?? 0
        let home = GraphSceneBuilder.homePosition
        let cameraDistance = (home.x * home.x + home.y * home.y + home.z * home.z).squareRoot()

        // Outside the pool's bounding sphere: standing inside it would mean
        // orbiting around bodies rather than looking at a pool.
        #expect(cameraDistance > furthest)
    }
}

/// The scene plan is the hand-off between the shared model and SceneKit, and
/// `updateNSView` rebuilds only when it changes. If two genuinely different
/// pools ever compared equal, the deep would silently keep drawing the old one.
@Suite("The scene plan describes one pool exactly")
@MainActor
struct GraphScenePlanTests {
    private func plan(
        focus: Set<String> = [],
        selected: String? = nil,
        controller: ServerController = Fixture.controller()
    ) -> GraphScenePlan {
        let model = EntityGraphModel(controller: controller)
        return GraphScenePlan(
            model: model,
            space: GraphSpace3D(model: model),
            focus: focus,
            selectedID: selected
        )
    }

    @Test("one roster always plans the same scene")
    func planIsDeterministic() {
        #expect(plan() == plan())
    }

    @Test("the plan carries every node, edge and placement from the shared model")
    func planAgreesWithTheModel() {
        let controller = Fixture.controller()
        let model = EntityGraphModel(controller: controller)
        let scene = plan(controller: controller)

        #expect(scene.nodes == model.nodes)
        #expect(scene.edges == model.edges)
        #expect(Set(scene.positions.keys) == Set(model.nodes.map(\.id)))
        #expect(Set(scene.radii.keys) == Set(model.nodes.map(\.id)))
    }

    /// Selection is what the person is inspecting. If it did not reach the plan,
    /// clicking a sphere would repaint the scene without marking the choice.
    @Test("selecting something changes the plan")
    func selectionChangesThePlan() {
        #expect(plan() != plan(selected: "model:qwen3"))
    }

    /// Focus and selection are independent readings: one asks "what is this?"
    /// and the other asks "show me this one's company". Conflating them would
    /// make a hover repaint the neighbourhood, or a focus forget the click.
    @Test("focus and selection are independent")
    func focusAndSelectionAreIndependent() {
        let focused = plan(focus: ["vault", "inference:http://127.0.0.1:1337/v1"])
        let selected = plan(selected: "vault")

        #expect(focused != selected)
        #expect(focused.selectedID == nil)
        #expect(selected.focus.isEmpty)
    }

    /// Liveness is drawn, so a probe answering has to reach the scene. If the
    /// plan ignored it, the nudibranch bars would lie until something else
    /// happened to force a rebuild.
    @Test("a probe answering changes the plan")
    func livenessChangesThePlan() {
        let cold = plan(controller: Fixture.controller(ready: false))
        let warm = plan(controller: Fixture.controller(ready: true))
        #expect(cold != warm)
    }

    /// The deep decides two things about a wire before it draws it — whether
    /// anything live is on it (so it can wear the liveness ribbon rather than
    /// plain blue) and whether Sea-Star is at one end (so it can be drawn
    /// heavier). Both are read off the plan, so they are pinned here rather than
    /// left to the scene builder's own judgement about which facts matter.
    @Test("the plan knows which wires are live, and which carry Sea-Star")
    func thePlanKnowsItsWires() {
        let scene = plan()

        // Something answered on the attached host, so a wire touching it has a
        // live end; the idle app has not, and its wire stays infrastructure blue.
        #expect(scene.isLive("harness:chat.atomic.app"))
        #expect(!scene.isLive("harness:app:com.apple.dt.Xcode"))

        #expect(scene.touchesCore(GraphEdge(from: EntityGraphModel.coreID, to: "vault")))
        #expect(!scene.touchesCore(GraphEdge(from: "vault", to: "harness:chat.atomic.app")))
    }

    @Test("the whole-pool reading is the empty one")
    func emptyFocusIsTheWholePool() {
        let scene = plan()
        #expect(scene.focus.isEmpty)
        #expect(scene.selectedID == nil)
    }
}

/// One decoded report, shaped like the ones the bridge actually emits. Building
/// fixtures from JSON rather than from initialisers is the point: it means these
/// tests fail if the *contract* drifts, not only if the graph drifts.
enum Fixture {
    @MainActor
    static func report(
        ready: Bool = true,
        model: String = "qwen3",
        agents: Bool = true,
        latent: Bool = true,
        attached: Bool = true,
        extraJSON: String = ""
    ) throws -> DoctorReport {
        let json = """
        {
          "schema_version": 1,
          "ready": \(ready),
          "version": "0.1.0",
          "vault": {
            "path": "/Users/lono/Vaults/main",
            "source": "obsidian",
            "note_count": 12,
            "candidates": ["/Users/lono/Vaults/main", "/Users/lono/Vaults/demo"]
          },
          "runtime": "osaurus",
          "base_url": "http://127.0.0.1:1337/v1",
          "model": "\(model)",
          "models": ["qwen3", "qwen3-tiny"],
          "runtimes": [
            {
              "name": "osaurus",
              "base_url": "http://127.0.0.1:1337/v1",
              "model": "\(model)",
              "models": ["qwen3", "qwen3-tiny"]
            },
            {
              "name": "omlx",
              "base_url": "http://127.0.0.1:8000/v1",
              "model": "qwen3-large",
              "models": ["qwen3-large"]
            },
            {
              "name": "unsloth",
              "base_url": "http://127.0.0.1:8009/v1",
              "model": "",
              "models": []
            }
          ],
          \(agents ? """
          "agents": [
            { "name": "Mariner", "model": "\(model)", "description": "reads and answers" },
            { "name": "Cartographer", "model": "omlx/qwen3-large", "description": "draws the map" },
            { "name": "Drifter", "model": null, "description": "rides whatever is set" },
            { "name": "Bosun", "model": "omlx/KAT-Coder-V2.5-Dev-OptiQ-4bit", "description": "nowhere to be served" }
          ],
          "agent_source": "osaurus",
          """ : "")
          \(attached ? """
          "mcp_clients": [
            {
              "name": "Atomic Chat",
              "bundle_id": "chat.atomic.app",
              "pid": 4242,
              "started_at": "2026-10-02T08:41:58+00:00"
            }
          ],
          """ : "")
          \(latent ? """
          "latent_harnesses": [
            {
              "name": "Unsloth Studio",
              "bundle_id": "ai.unsloth.studio",
              "path": "/Applications/Unsloth Studio.app",
              "rung": "running"
            },
            {
              "name": "OpenCode",
              "bundle_id": "cli:opencode",
              "path": "OpenCode",
              "rung": "running"
            },
            {
              "name": "TraeCode",
              "bundle_id": "com.trae.app",
              "path": "/Applications/Trae.app",
              "rung": "present"
            },
            {
              "name": "Xcode",
              "bundle_id": "com.apple.dt.Xcode",
              "path": "/Applications/Xcode.app",
              "rung": "present"
            }
          ],
          """ : "")
          \(extraJSON.isEmpty ? "" : "\(extraJSON),")
          "server": { "state": "running" },
          "model_like": [
            {
              "port": 1337,
              "app_name": "Atomic Chat",
              "app_path": "/Applications/Atomic Chat.app",
              "base_url": "http://127.0.0.1:1337/v1",
              "answering": true
            },
            {
              "port": 8009,
              "app_name": "Unsloth Studio",
              "app_path": "/Applications/Unsloth Studio.app",
              "base_url": "http://127.0.0.1:8009/v1",
              "answering": true
            }
          ],
          "servers": []
        }
        """
        let response = try JSONDecoder().decode(
            DoctorResponse.self,
            from: Data(json.utf8)
        )
        guard case .report(let report) = response else {
            throw FixtureError.notAReport
        }
        return report
    }

    @MainActor
    static func controller(
        ready: Bool = true,
        model: String = "qwen3",
        agents: Bool = true,
        latent: Bool = true,
        attached: Bool = true,
        extraJSON: String = ""
    ) -> ServerController {
        let controller = ServerController(command: nil)
        controller.adopt(
            try! report(
                ready: ready,
                model: model,
                agents: agents,
                latent: latent,
                attached: attached,
                extraJSON: extraJSON
            )
        )
        return controller
    }

    enum FixtureError: Error {
        case notAReport
    }
}

/// The panel is a cockpit of dials, and a dial's job is to answer "what else is
/// on this machine, and why can't I use it?" (D-018). The founder's words: *"it
/// should be able to select whatever is live, or if it exists, it should be
/// greyed out on the dropdown … all selections in that panel should then just
/// reflect anything connected to it."*
///
/// Two rules are pinned here: an entry that cannot be honoured is **shown,
/// switched off, with its reason** rather than hidden; and a choice that *can* be
/// honoured is a real action that the rows underneath follow.
@Suite("The panel's dials show what exists and refuse what cannot be")
@MainActor
struct PanelDialTests {
    @Test("the Harness dial shows the app driving Sea-Star, and the rest with their rung")
    func harnessDialShowsTheRoster() {
        let dial = Fixture.controller().harnessDial

        let attached = dial.first { $0.label == "Atomic Chat" }
        #expect(attached?.isEnabled == true)
        #expect(attached?.reason == nil)

        // Every other app is *there* — hidden entries would answer "can I use
        // this?" with silence — and each carries the rung that explains it.
        let xcode = dial.first { $0.label == "Xcode" }
        #expect(xcode?.isEnabled == false)
        #expect(xcode?.reason == HarnessRung.present.label)

        let unsloth = dial.first { $0.label == "Unsloth Studio" }
        #expect(unsloth?.isEnabled == false)
        #expect(unsloth?.reason == HarnessRung.running.label)

        #expect(Set(dial.map(\.id)).count == dial.count, "an app is listed twice")
    }

    @Test("the Agent dial switches off a persona nothing is serving, and says why")
    func agentDialGreysTheUnserved() {
        let dial = Fixture.controller().agentDial

        // Mariner (the current model) and Cartographer (`omlx/qwen3-large` — the
        // endpoint lists it bare, so the id needs no more than unwrapping) are
        // both usable. Drifter has no bound model, which is a real state.
        for usable in ["Mariner", "Cartographer", "Drifter"] {
            #expect(dial.first { $0.label == usable }?.isEnabled == true, "\(usable)")
            #expect(dial.first { $0.label == usable }?.reason == nil, "\(usable)")
        }

        // Bosun's model is a real Osaurus-shaped entry that no endpoint offers —
        // the founder's Patchdog, in the fixture. Shown, switched off, with the
        // reason rather than moving something when it is chosen.
        let bosun = dial.first { $0.label == "Bosun" }
        #expect(bosun?.isEnabled == false)
        #expect(bosun?.reason == Strings.Rows.nothingServingItsModel)
    }

    @Test("choosing a persona something serves takes the endpoint and the model with it")
    func choosingAServedAgentCascades() {
        let controller = Fixture.controller()
        controller.selectAgent("Cartographer")

        // The rows underneath agree with the one just chosen, which is what
        // makes this a control rather than a label that moves nothing.
        #expect(controller.selectedAgentName == "Cartographer")
        #expect(controller.inferenceOverride?.baseURL == "http://127.0.0.1:8000/v1")
        #expect(controller.inferenceOverride?.name == "omlx")
        // And the model is the id *the endpoint* uses, not the roster's
        // qualified spelling of it.
        #expect(controller.modelOverride == "qwen3-large")
    }

    @Test("choosing a persona nothing serves moves nothing")
    func choosingAnUnservedAgentStaysPut() {
        let controller = Fixture.controller()
        controller.selectAgent("Bosun")

        #expect(controller.selectedAgentName == "Bosun")
        #expect(controller.inferenceOverride == nil)
        #expect(controller.modelOverride == nil)
    }

    @Test("the sentence about a persona and its dial entry are decided by one rule")
    func placementAgreesWithTheDial() {
        let controller = Fixture.controller()

        for agent in controller.agentOptions {
            let servable = controller.servingPlacement(of: agent) != nil
            let bound = !(agent.model ?? "").isEmpty
            let enabled = controller.agentDial.first { $0.label == agent.name }?.isEnabled
            #expect(enabled == (servable || !bound), "\(agent.name)")

            // A persona that is served must never be described as unserved, and
            // vice versa: the row and its sentence read from the same resolution.
            let sentence = controller.placement(of: agent)
            #expect(sentence.contains("not serving it") == (bound && !servable), "\(agent.name)")
        }
    }
}

/// The cascade (D-013): pick an agent and the panel must be able to say where
/// that agent actually is — model first, then the endpoint serving it, with
/// the three honest cases told apart.
@Suite("An agent's placement follows the cascade")
@MainActor
struct AgentPlacementTests {
    /// The fixture's cast: Mariner rides the current model (qwen3, on osaurus),
    /// Cartographer rides qwen3-large (on omlx), Drifter rides nothing.
    private func controller() -> ServerController {
        let controller = ServerController(command: nil)
        controller.adopt(try! Fixture.report())
        return controller
    }

    @Test("a model on offer names its serving endpoint")
    func servedAgentNamesItsEndpoint() {
        let controller = controller()
        controller.selectAgent("Mariner")
        guard let agent = controller.selectedAgent else {
            Issue.record("Mariner should be selected")
            return
        }
        #expect(controller.placement(of: agent) == "Runs on qwen3 — served by osaurus.")
    }

    @Test("an agent on another endpoint's model names that endpoint")
    func agentOnAnotherEndpoint() {
        let controller = controller()
        controller.selectAgent("Cartographer")
        guard let agent = controller.selectedAgent else {
            Issue.record("Cartographer should be selected")
            return
        }
        #expect(controller.placement(of: agent) == "Runs on qwen3-large — served by omlx.")
    }

    @Test("an agent with no model says it rides whatever is set")
    func unboundAgent() {
        let controller = controller()
        controller.selectAgent("Drifter")
        guard let agent = controller.selectedAgent else {
            Issue.record("Drifter should be selected")
            return
        }
        #expect(controller.placement(of: agent) == "Rides whatever the endpoint is serving.")
    }
}

/// The pool's hover follows the cursor, not the last node drawn. The founder hit
/// this when hovering the graph always lit up Patchdog — the topmost node — no
/// matter where the pointer actually was. The rule is now a pure hit-test over
/// the laid-out positions, so it is pinned here against hand-built nodes rather
/// than a live window.
@Suite("The pool hover follows the cursor, not the last node drawn")
struct GraphHoverTests {
    private func node(_ id: String, _ kind: GraphNode.Kind) -> GraphNode {
        GraphNode(id: id, kind: kind, title: id, subtitle: nil, accent: .white, isLive: false)
    }

    @Test("a cursor on a node returns that node")
    func hitsTheNodeUnderTheCursor() {
        let a = node("vault", .vault)
        let positions = ["vault": CGPoint(x: 100, y: 100)]
        #expect(
            EntityGraphView.hitNode(at: CGPoint(x: 100, y: 100), nodes: [a], positions: positions)?.id == "vault"
        )
    }

    @Test("a cursor on empty water returns nothing")
    func missesEmptySpace() {
        let a = node("vault", .vault)
        let positions = ["vault": CGPoint(x: 100, y: 100)]
        #expect(
            EntityGraphView.hitNode(at: CGPoint(x: 400, y: 400), nodes: [a], positions: positions) == nil
        )
    }

    @Test("overlapping nodes resolve to the one drawn on top")
    func overlapResolvesToTopmost() {
        // Agents are appended after the majors, so the agent is drawn last and
        // sits on top. A cursor over the shared point must name the agent, not
        // the vault underneath it.
        let vault = node("vault", .vault)
        let agent = node("agent:Patchdog", .agent)
        let positions = [
            "vault": CGPoint(x: 100, y: 100),
            "agent:Patchdog": CGPoint(x: 100, y: 100),
        ]
        #expect(
            EntityGraphView.hitNode(
                at: CGPoint(x: 100, y: 100),
                nodes: [vault, agent],
                positions: positions
            )?.id == "agent:Patchdog"
        )
    }

    @Test("a node's padding is still part of the hit, and beyond it is not")
    func paddingBoundsTheHit() {
        // A vault is 27pt across, so the hit radius is 27/2 + 2 = 15.5.
        let vault = node("vault", .vault)
        let positions = ["vault": CGPoint(x: 100, y: 100)]

        #expect(
            EntityGraphView.hitNode(at: CGPoint(x: 114, y: 100), nodes: [vault], positions: positions)?.id == "vault"
        )
        #expect(
            EntityGraphView.hitNode(at: CGPoint(x: 130, y: 100), nodes: [vault], positions: positions) == nil
        )
    }
}

/// A harness that *declares* where it gets models from is saying something the
/// machine's sockets cannot: a configured provider holds no connection at all,
/// so no probe could ever have drawn this wire. It is the link the founder named
/// — *"the IDEs need to be shown to be hooked up to whatever they may be hooked
/// up to"* — and the whole point of the reader is that it stays honest about
/// being a declaration rather than a connection.
@Suite("A declared provider is a rung-0 claim, never liveness")
@MainActor
struct ConfiguredProviderTests {
    /// A harness whose settings name a provider, matched by the display-name /
    /// short-key gap that is the real-world case: the engine files the claim
    /// under `opencode`, the graph knows the app as `OpenCode`.
    private func subject(providerJSON: String, withEndpoint: Bool = true) -> ServerController {
        Fixture.controller(extraJSON: providerJSON)
    }

    private func localClaim(
        provider: String = "atomic",
        model: String = "atomic/Dirk",
        baseURL: String? = "http://127.0.0.1:1337/v1"
    ) -> String {
        """
        "providers": [
          {
            "harness": "opencode",
            "provider": "\(provider)",
            \(baseURL.map { "\"base_url\": \"\($0)\"," } ?? "")
            "model": "\(model)",
            "evidence": "configured",
            "local": true
          }
        ]
        """
    }

    private func model(_ controller: ServerController) -> EntityGraphModel {
        EntityGraphModel(controller: controller)
    }

    @Test("a harness's node says what it is configured for")
    func nodeSubtitleNamesTheDeclaration() {
        let subject = self.subject(providerJSON: localClaim())
        let node = model(subject).node("harness:app:cli:opencode")
        #expect(node?.subtitle?.contains("Configured for atomic") == true)
        #expect(node?.subtitle?.contains("atomic/Dirk") == true)
    }

    /// The load-bearing honesty test: a declaration is a statement in a settings
    /// file. It must not make a node live, and it must not change its rung.
    @Test("a declaration never makes the harness live")
    func declarationIsNotLiveness() {
        let subject = self.subject(providerJSON: localClaim())
        let node = model(subject).node("harness:app:cli:opencode")
        #expect(node?.isLive == false)
        #expect(node?.rung == .running)
    }

    /// A declaration resolves to an endpoint only when Sea-Star can already see
    /// that endpoint answering — otherwise the wire would point at nothing.
    @Test("a local declaration onto a visible endpoint is wired")
    func localDeclarationOntoAVisibleEndpointIsWired() {
        let subject = self.subject(providerJSON: localClaim())
        #expect(
            model(subject).neighbours(of: "harness:app:cli:opencode")
                .contains("inference:http://127.0.0.1:1337/v1")
        )
    }

    @Test("a declaration naming a port no endpoint answers is not wired")
    func declarationOntoAnInvisiblePortDrawsNoWire() {
        // The harness is configured for 9999, but nothing answering there is a
        // node Sea-Star draws. The claim is still shown; the wire is not invented.
        let subject = self.subject(
            providerJSON: localClaim(baseURL: "http://127.0.0.1:9999/v1")
        )
        #expect(
            model(subject).node("harness:app:cli:opencode")?.subtitle?.contains("atomic/Dirk") == true
        )
        #expect(
            !model(subject).neighbours(of: "harness:app:cli:opencode")
                .contains { $0.hasPrefix("inference:") }
        )
    }

    /// A cloud route is a real fact about where someone works, and there is no
    /// node on this machine to wire it to. Kept as a label, never as liveness.
    @Test("a cloud declaration is a label and never a local wire")
    func cloudDeclarationDrawsNoLocalWire() {
        let subject = self.subject(
            providerJSON: """
            "providers": [
              {
                "harness": "opencode",
                "provider": "openrouter",
                "base_url": "https://openrouter.ai/api/v1",
                "model": "some/model",
                "evidence": "configured",
                "local": false
              }
            ]
            """
        )
        let model = model(subject)
        #expect(model.node("harness:app:cli:opencode")?.subtitle?.contains("openrouter") == true)
        #expect(
            !model.neighbours(of: "harness:app:cli:opencode").contains { $0.hasPrefix("inference:") }
        )
    }

    @Test("a harness nobody declared for has no claim, and no neighbour's either")
    func identityMatchingDoesNotBorrow() {
        let subject = self.subject(providerJSON: localClaim())
        #expect(subject.declaredProvider(forHarnessNamed: "OpenCode") != nil)
        #expect(subject.declaredProvider(forHarnessNamed: "TraeCode") == nil)
        // And an app the person hid keeps whatever it had; hiding is not forgetting.
        #expect(model(subject).node("harness:app:com.trae.app") != nil)
    }

    /// An engine without the key must read as "this build did not look", never
    /// as "no harness uses any model" — which would be a claim about the machine.
    @Test("an engine predating the reader yields nothing and invents nothing")
    func olderEngineYieldsNothing() {
        let subject = Fixture.controller()
        #expect(subject.declaredProvider(forHarnessNamed: "OpenCode") == nil)
        #expect(subject.report?.declaredProviders.isEmpty == true)
    }
}
