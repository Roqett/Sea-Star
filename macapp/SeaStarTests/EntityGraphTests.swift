import Foundation
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
        latent: Bool = true
    ) -> ServerController {
        let controller = ServerController(command: nil)
        controller.adopt(try! Fixture.report(
            ready: ready,
            model: model,
            agents: agents,
            latent: latent
        ))
        return controller
    }

    private func nodes(_ controller: ServerController) -> [String: GraphNode] {
        Dictionary(
            uniqueKeysWithValues: EntityGraphModel(controller: controller).nodes.map { ($0.id, $0) }
        )
    }

    // MARK: - The rule itself

    /// Live means a probe answered during the latest read. So with a ready
    /// endpoint, exactly three things can be live: the harness the report is
    /// describing, the model it is serving, and an agent riding that model.
    @Test("a ready endpoint makes exactly the current harness, model and their agents live")
    func readyMakesThreeLive() {
        let byID = nodes(controller())
        let live = byID.values.filter(\.isLive).map(\.id).sorted()

        #expect(live == [
            "agent:Mariner",
            "harness:http://127.0.0.1:1337/v1",
            "model:qwen3",
        ])
    }

    /// The single most important test in this file. A harness that is merely
    /// *installed* answers on no port; a vault is not on one at all. If either
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

    /// A latent harness is an app on the disk that carries its own model loop
    /// and is not answering a port. There is nothing for a probe to have
    /// answered, so it cannot be live under any circumstances.
    @Test("a latent harness is never live, even while a harness beside it is")
    func latentIsNeverLive() {
        let byID = nodes(controller())
        let latent = byID["latent:com.apple.dt.Xcode"]

        #expect(latent?.kind == .latent)
        #expect(latent?.isLive == false)
        // The contrast is the point: its neighbour on the ring is live.
        #expect(byID["harness:http://127.0.0.1:1337/v1"]?.isLive == true)
    }

    /// "Installed" is not "answering". Both harnesses are detected and both are
    /// on the graph, and only the one the report is actually describing is live.
    @Test("only the harness being described is live; the other is merely available")
    func onlyTheCurrentHarnessIsLive() {
        let byID = nodes(controller())
        #expect(byID["harness:http://127.0.0.1:1337/v1"]?.isLive == true)
        #expect(byID["harness:http://127.0.0.1:8000/v1"]?.isLive == false)
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
    @Test("an endpoint that did not answer leaves nothing live")
    func notReadyMeansNothingIsLive() {
        let model = EntityGraphModel(controller: controller(ready: false))

        #expect(!model.nodes.isEmpty)
        // Spelled as a closure rather than a key path: the same roster is
        // present, so this has to be about liveness rather than about emptiness.
        #expect(!model.nodes.contains { $0.isLive })
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

    /// A latent harness answers on no port, so it knows about nothing. Drawing
    /// it wired to the harness would imply a connection that was never probed.
    @Test("a latent harness is wired to nothing")
    func latentHasNoEdges() {
        let model = EntityGraphModel(controller: controller())
        #expect(model.neighbours(of: "latent:com.apple.dt.Xcode").isEmpty)
    }

    /// A relationship drawn twice looks busier than the report is. Every edge
    /// is walked from both ends, so mutual bindings have to collapse to one.
    @Test("a mutual relationship is drawn once, not twice")
    func edgesAreUndirected() {
        let model = EntityGraphModel(controller: controller())
        let ids = model.edges.map(\.id)

        #expect(Set(ids).count == ids.count)

        // The vault/harness binding is mutual, and appears exactly once.
        let forward = GraphEdge(from: "vault", to: "harness:http://127.0.0.1:1337/v1")
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

/// The founder asked for multicoloured nodes. The rule that keeps that honest is
/// that colour is *seeded, never random* — so these tests are what stops a
/// future "let's just make it feel more alive" from turning identity into
/// decoration.
@Suite("Graph identity is seeded, not random")
struct GraphSeedTests {
    @Test("an entity's phase is stable across every call")
    func phaseIsStable() {
        for id in ["vault", "harness:http://127.0.0.1:1337/v1", "model:qwen3", "agent:Mariner"] {
            #expect(GraphSeed.phase(for: id) == GraphSeed.phase(for: id))
        }
    }

    @Test("a phase is always a real angle")
    func phaseIsInRange() {
        for id in ["vault", "model:qwen3", "agent:Cartographer", "latent:com.apple.dt.Xcode"] {
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
        for id in ["vault", "harness:http://127.0.0.1:8000/v1", "model:qwen3"] {
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
        for node in model.nodes {
            #expect(space.positions()[node.id] != space.centre)
        }
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
    @Test("a vault outweighs everything else in the pool")
    func vaultIsTheHeavyweight() {
        #expect(GraphNode.Kind.vault.scale > GraphNode.Kind.harness.scale)
        #expect(GraphNode.Kind.harness.scale > GraphNode.Kind.agent.scale)
        #expect(GraphNode.Kind.agent.scale > GraphNode.Kind.latent.scale)
        #expect(GraphNode.Kind.latent.scale > GraphNode.Kind.model.scale)
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
    @Test("a model sits closest to the harness that serves it")
    func modelSitsWithItsHarness() {
        let (model, space) = pool()
        let positions = space.positions()

        for node in model.nodes where node.kind == .model {
            guard let here = positions[node.id] else { continue }
            let servers = model.neighbours(of: node.id)
                .filter { $0.hasPrefix("harness:") }
            #expect(!servers.isEmpty, "\(node.title) has no harness in the pool to sit with")

            let nearest = servers
                .compactMap { positions[$0] }
                .map { here.distance(to: $0) }
                .min() ?? .greatestFiniteMagnitude
            for other in model.nodes where other.kind == .harness {
                guard let there = positions[other.id] else { continue }
                #expect(
                    nearest <= here.distance(to: there),
                    "\(node.title) sits nearer \(other.title) than a harness that serves it"
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
            for other in model.nodes where other.kind == .harness {
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
        let focused = plan(focus: ["vault", "harness:http://127.0.0.1:1337/v1"])
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
        latent: Bool = true
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
            }
          ],
          \(agents ? """
          "agents": [
            { "name": "Mariner", "model": "\(model)", "description": "reads and answers" },
            { "name": "Cartographer", "model": "qwen3-large", "description": "draws the map" },
            { "name": "Drifter", "model": null, "description": "rides whatever is set" }
          ],
          "agent_source": "osaurus",
          """ : "")
          \(latent ? """
          "latent_harnesses": [
            { "name": "Xcode", "bundle_id": "com.apple.dt.Xcode", "path": "/Applications/Xcode.app" }
          ],
          """ : "")
          "server": { "state": "running" },
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
        latent: Bool = true
    ) -> ServerController {
        let controller = ServerController(command: nil)
        controller.adopt(
            try! report(ready: ready, model: model, agents: agents, latent: latent)
        )
        return controller
    }

    enum FixtureError: Error {
        case notAReport
    }
}
