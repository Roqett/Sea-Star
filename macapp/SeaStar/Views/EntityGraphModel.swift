import AppKit
import SwiftUI

/// One thing in the rockpool: the vault, a harness driving Sea-Star, an
/// inference endpoint, a model, or an agent.
///
/// There are five kinds because the ontology has four rows and one of them holds
/// two things that used to be filed together: a **harness** is the app that
/// drives Sea-Star, an **inference** endpoint is where models come from. Calling
/// both "harness" was the bug that made the pool unreadable.
///
/// Internal rather than file-private because the graph has two bodies. The 2D
/// pool and the 3D one are two *drawings* of one model, and the whole value of
/// having both is that they cannot disagree about what is in the pool.
struct GraphNode: Identifiable, Hashable {
    enum Kind: Sendable, Hashable {
        case vault, harness, inference, model, agent

        /// Relative size, as a fraction of a vault's. One number per kind, held
        /// here rather than in a renderer, because "how big is a model next to a
        /// vault" is a fact about the roster rather than about how you are
        /// looking at it — the 2D pool and the 3D one must not disagree about
        /// what is the heavyweight.
        var scale: Double {
            switch self {
            case .vault: return 1.0
            case .harness: return 0.86
            case .inference: return 0.82
            case .agent: return 0.78
            case .model: return 0.63
            }
        }
    }

    let id: String
    let kind: Kind
    let title: String
    let subtitle: String?
    let accent: Color
    /// Whether something actually answered on this entity during the last read.
    /// A harness with a live `serve` process, an endpoint that answered, and the
    /// model that endpoint is serving can be live; a vault is not on a port, and
    /// an endpoint that did not answer is not live however installed it is.
    let isLive: Bool
    /// How far a `.harness` climbed the foundation's ladder; `nil` for every
    /// other kind. On the node because the graph draws the rung: "installed",
    /// "up" and "answering" must not be flattened into one grey absence.
    var rung: HarnessRung? = nil
}

/// One binding between two entities — the thing a renderer actually draws a
/// wire for. Undirected: a harness serving a model is one edge however you
/// phrase it, and drawing it twice would make the graph look busier than the
/// report is.
struct GraphEdge: Identifiable, Hashable, Sendable {
    let from: String
    let to: String

    /// Order-independent, so an edge collected from either end is the same edge.
    var id: String {
        from < to ? "\(from)\u{1F}\(to)" : "\(to)\u{1F}\(from)"
    }
}

/// Deterministic variation seeded from an entity's own id.
///
/// The founder asked for multicoloured nodes, and the rule that keeps that
/// honest is that the colour is *seeded, never random*: the same vault, harness,
/// model or agent always gets the same blend and the same drift phase, on every
/// redraw, in both the 2D pool and the 3D one. A node that changes colour when
/// you move the mouse is decoration; one that doesn't is an identity.
enum GraphSeed {
    /// A stable 0…2π phase from an id. Drives the 2D pool's drift and seeds each
    /// node's arm colours and its own slight turn.
    static func phase(for id: String) -> Double {
        var hash: UInt64 = 1469598103934665603
        for byte in id.utf8 { hash = (hash ^ UInt64(byte)) &* 1099511628211 }
        return Double(hash % 6283) / 1000.0
    }

    /// A stable 0…1 fraction of a full hue turn, for the 3D scene's per-node
    /// colour variation. Derived from the same hash as `phase`, so an entity
    /// that drifts one way in the pool is also tinted one way in the deep.
    static func hue(for id: String) -> Double {
        phase(for: id) / (.pi * 2)
    }

    /// Rotate a colour's hue by `delta` (0…1 = a full turn), keeping its
    /// saturation and brightness. Gives the node-to-node shimmer its palette.
    static func shifted(_ color: Color, by delta: Double) -> Color {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? .white
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        ns.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        var turned = (hue + CGFloat(delta)).truncatingRemainder(dividingBy: 1)
        if turned < 0 { turned += 1 }
        return Color(
            hue: Double(turned),
            saturation: Double(saturation),
            brightness: Double(min(1, brightness * 1.06)),
            opacity: Double(alpha)
        )
    }
}

/// A point in the 3D pool, in points. Deliberately a plain struct rather than
/// `SCNVector3`: the layout is a *fact about the pool* that both the scene
/// builder and its tests read, and it should not require SceneKit to be asked
/// where anything is.
struct Point3: Equatable, Sendable {
    var x: Float
    var y: Float
    var z: Float

    static let origin = Point3(x: 0, y: 0, z: 0)

    static func + (lhs: Point3, rhs: Point3) -> Point3 {
        Point3(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    func distance(to other: Point3) -> Float {
        let dx = x - other.x, dy = y - other.y, dz = z - other.z
        return (dx * dx + dy * dy + dz * dz).squareRoot()
    }
}

/// Where everything sits in the deep, and how big it is drawn.
///
/// The founder's note on this was the important part: the graph is *never* going
/// to be the crowded thousands-of-nodes problem that makes a force layout
/// unreadable. It is a handful of things in a pool. So this is not a physics
/// simulation to be tuned — it is a fixed, deterministic arrangement, and the
/// freedom the person gets comes from the **camera** (orbit, zoom, pan), not
/// from the nodes wandering. That is a deliberate trade: an always-moving layout
/// would never settle into a shape you could learn, whereas a fixed one you can
/// fly around is something you can actually hold in your head.
///
/// It is seeded from ids, so the same roster always builds the same pool.
///
/// Main-actor bound like the model it reads, so the layout can never be built
/// from a report that has already moved on.
@MainActor
struct GraphSpace3D {
    /// The radius the majors sit on — the pool's overall width.
    var radius: Float = 120
    /// The distance a satellite orbits from whatever it orbits.
    var satelliteRadius: Float = 46

    private let model: EntityGraphModel

    init(model: EntityGraphModel, radius: Float = 120) {
        self.model = model
        self.radius = radius
    }

    /// The centre of the pool, where a focused node is drawn.
    var centre: Point3 { .origin }

    /// The position of every node, by id. Nodes with no place in the arrangement
    /// (there should be none) are simply absent rather than stacked at the
    /// origin, so a stray node can never hide behind another.
    func positions() -> [String: Point3] {
        var points: [String: Point3] = [:]
        let majors = model.majors
        let count = max(majors.count, 1)

        // The majors ring the pool on the horizontal plane, evenly and
        // deterministically — the same "the count of majors is the count of
        // points" rule the 2D star uses, so the two readings agree on shape.
        // A seeded lift in y and z gives the ring depth, so the pool is
        // legibly three-dimensional from any angle rather than a flat disc.
        for (index, node) in majors.enumerated() {
            let angle = -Double.pi / 2 + Double(index) / Double(count) * 2 * .pi
            let wobble = GraphSeed.phase(for: node.id)
            points[node.id] = Point3(
                x: Float(cos(angle)) * radius,
                y: Float(sin(angle * 2 + wobble)) * radius * 0.30,
                z: Float(sin(angle)) * radius
            )
        }

        // The satellites orbit whatever they belong to, so a model sits near the
        // harness serving it and a persona near the model it rides. Anything
        // with nothing to orbit (an agent whose model is not in the pool) is
        // parked on a slow ring of its own rather than dropped.
        let hub = model.activeInferenceID.flatMap { points[$0] } ?? centre
        var parked: Int = 0
        var parkedCount = 0
        for node in model.nodes where points[node.id] == nil {
            parkedCount += 1
        }
        for node in model.nodes where points[node.id] == nil {
            let angle = -Double.pi / 2 + Double(parked) / Double(max(parkedCount, 1)) * 2 * .pi
            let lift = Float(GraphSeed.phase(for: node.id)) * 0.5
            points[node.id] = Point3(
                x: hub.x + Float(cos(angle)) * satelliteRadius,
                y: hub.y + lift * satelliteRadius * 0.5,
                z: hub.z + Float(sin(angle)) * satelliteRadius
            )
            parked += 1
        }

        // Pull each satellite toward its own anchor, so the orbit is legible
        // rather than a uniform ring: a model hugs its harness, an agent hugs
        // its model, and the depth between them is what you read when you turn.
        for (kind, reach) in [(GraphNode.Kind.model, 0.55), (.agent, 0.72)] {
            for node in model.nodes where node.kind == kind {
                guard let anchor = anchorID(for: node), let target = points[anchor] else { continue }
                guard let here = points[node.id] else { continue }
                points[node.id] = Point3(
                    x: here.x + (target.x - here.x) * Float(reach),
                    y: here.y + (target.y - here.y) * Float(reach),
                    z: here.z + (target.z - here.z) * Float(reach)
                )
            }
        }

        return points
    }

    /// What a satellite should be pulled toward: a model orbits an endpoint
    /// that serves it, an agent orbits the model it rides. A major is placed on
    /// the ring and has nothing to orbit.
    private func anchorID(for node: GraphNode) -> String? {
        switch node.kind {
        case .model:
            for endpoint in model.controller.inferenceOptions
            where endpoint.models.contains(node.title) {
                return "inference:\(endpoint.baseURL)"
            }
            return model.activeInferenceID
        case .agent:
            if let model = node.subtitle { return "model:\(model)" }
            return model.activeInferenceID
        default:
            return nil
        }
    }

    /// The drawn radius of a node, from the kind's share of a vault.
    func radius(for node: GraphNode) -> Float {
        Float(17 + 12 * node.kind.scale)
    }
}

/// The graph's *content*, with no drawing in it.
///
/// Every question the graph can be asked — what is in it, what touches what,
/// what a clicked node can tell you — is answered here, once, from the report.
/// Both the 2D pool and the 3D one read this same struct, which is what makes
/// the 2D/3D switch a change of camera rather than a change of facts.
///
/// It is a value read on demand rather than something stored: the report can
/// change under the person at any moment, and a cache here would only ever be a
/// second thing to go stale.
///
/// Main-actor bound, because every fact it can answer comes from the live
/// controller. That is deliberate: the graph is a reading of the report as it
/// stands right now, and a snapshot taken off the main actor would be exactly
/// the kind of second copy that goes stale behind the first.
@MainActor
struct EntityGraphModel {
    let controller: ServerController

    // MARK: - Contents

    var nodes: [GraphNode] {
        var nodes: [GraphNode] = []
        if let vault = controller.report?.vault.path {
            nodes.append(GraphNode(
                id: "vault",
                kind: .vault,
                title: (vault as NSString).lastPathComponent,
                subtitle: vault,
                accent: Palette.vaultGlow,
                isLive: false
            ))
        }

        // Harnesses: the apps that drive Sea-Star. An attached one is proof —
        // the engine recorded the process that spawned `serve` — so it is the
        // only thing here drawing as live. Every other known app still belongs
        // on the graph, wearing the rung it actually reached.
        for attached in controller.attachedHarnesses {
            nodes.append(GraphNode(
                id: "harness:\(attached.id)",
                kind: .harness,
                title: attached.name,
                subtitle: attached.bundleID,
                accent: Palette.harnessGlow,
                isLive: true,
                rung: .connected
            ))
        }
        for app in controller.visibleLatentHarnesses where !isAttached(app) {
            nodes.append(GraphNode(
                id: "harness:app:\(app.bundleID)",
                kind: .harness,
                title: app.name,
                subtitle: app.path,
                accent: Palette.harnessGlow,
                // Nothing here has answered a port; the rung says how far it got.
                isLive: false,
                rung: app.rung
            ))
        }

        // Inference: where models come from. A local endpoint and an API are the
        // same row and deliberately not the same colour — one is about this
        // machine, the other is what is coming in.
        let activeInferenceID = self.activeInferenceID
        for endpoint in controller.inferenceOptions {
            let id = "inference:\(endpoint.baseURL)"
            nodes.append(GraphNode(
                id: id,
                kind: .inference,
                title: endpoint.name,
                subtitle: endpoint.baseURL,
                accent: endpoint.isRemote ? Palette.apiInferenceGlow : Palette.inferenceGlow,
                isLive: id == activeInferenceID && controller.isReady
            ))
        }

        // A model is live when it is the one the active endpoint is actually
        // serving right now. Every other model is merely on offer.
        let currentModel = controller.report?.model
        for model in controller.modelOptions {
            nodes.append(GraphNode(
                id: "model:\(model)",
                kind: .model,
                title: model,
                subtitle: nil,
                accent: Palette.modelGlow,
                isLive: model == currentModel && controller.isReady
            ))
        }

        for agent in controller.agentOptions {
            nodes.append(GraphNode(
                id: "agent:\(agent.name)",
                kind: .agent,
                title: agent.name,
                subtitle: agent.model,
                accent: Palette.agentGlow,
                // A persona is live when the endpoint behind it answered, not
                // when someone spoke to it. Sea-Star observes the port, not the
                // conversation, and the graph has to be that honest too.
                isLive: agent.model == currentModel && controller.isReady
            ))
        }

        return nodes
    }

    /// Whether a known harness app is the same thing as one already attached.
    /// The engine already filters attached names out of the latent list; this is
    /// the belt to that braces, so a connected app can never be drawn twice.
    private func isAttached(_ app: LatentHarnessOption) -> Bool {
        controller.attachedHarnesses.contains { attached in
            guard let bundle = attached.bundleID else {
                return attached.name.caseInsensitiveCompare(app.name) == .orderedSame
            }
            return bundle == app.bundleID
        }
    }

    /// The majors: everything that is not a satellite. These wear the star. A
    /// satellite is a model or an agent — a thing that orbits an endpoint —
    /// rather than a peer of the vault, its harnesses and its endpoints.
    var majors: [GraphNode] {
        nodes.filter { $0.kind != .model && $0.kind != .agent }
    }

    /// The endpoint the report is currently reading models from.
    var activeInferenceID: String? {
        controller.report.map { "inference:\($0.baseURL)" }
    }

    func node(_ id: String) -> GraphNode? {
        nodes.first { $0.id == id }
    }

    // MARK: - Relationship

    /// Every binding in the pool, each one drawn once. Built from `neighbours`
    /// by walking both ends and throwing away the duplicates, so a relationship
    /// that is mutual (a harness and the vault it is on) becomes a single edge.
    /// The 2D pool draws only the one edge it has always drawn; the 3D scene
    /// draws all of them, and both are reading this list.
    var edges: [GraphEdge] {
        var seen: Set<String> = []
        var result: [GraphEdge] = []
        for node in nodes {
            for other in neighbours(of: node.id).sorted() {
                let edge = GraphEdge(from: node.id, to: other)
                if seen.insert(edge.id).inserted {
                    result.append(edge)
                }
            }
        }
        return result
    }

    /// Everything directly related to one entity, by id — the company a focus
    /// reading keeps lit. Each kind wires to what the report already knows: the
    /// vault to the harnesses driving it and the endpoint it reads through, a
    /// harness to the vault it drives, an endpoint to the models it serves and
    /// the personas riding them, a model to the endpoints offering it and the
    /// personas bound to it, a persona to its model and where that model lives.
    /// Only ids that are actually drawn survive, so no edge ever points at a
    /// node the person cannot see.
    func neighbours(of id: String) -> Set<String> {
        guard let node = node(id) else { return [] }
        var related: Set<String> = []
        switch node.kind {
        case .vault:
            for attached in controller.attachedHarnesses {
                related.insert("harness:\(attached.id)")
            }
            if let active = activeInferenceID { related.insert(active) }

        case .harness:
            // A connected harness is by definition driving this vault. An app
            // that is merely up drives nothing yet, so it is wired to nothing —
            // an edge would be an invention.
            if node.isLive {
                related.insert("vault")
                // An app that names an endpoint (oMLX, Osaurus) owns that
                // endpoint: a real match on the name, never a guess from a port.
                for endpoint in controller.inferenceOptions
                where endpoint.name.caseInsensitiveCompare(node.title) == .orderedSame {
                    related.insert("inference:\(endpoint.baseURL)")
                }
            }

        case .inference:
            if let endpoint = controller.inferenceOptions
                .first(where: { "inference:\($0.baseURL)" == id }) {
                if id == activeInferenceID { related.insert("vault") }
                for model in endpoint.models { related.insert("model:\(model)") }
                for agent in controller.agentOptions
                where agent.model.map(endpoint.models.contains) == true {
                    related.insert("agent:\(agent.name)")
                }
            }

        case .model:
            let name = node.title
            for endpoint in controller.inferenceOptions where endpoint.models.contains(name) {
                related.insert("inference:\(endpoint.baseURL)")
            }
            if controller.report?.model == name, let active = activeInferenceID {
                related.insert(active)
            }
            for agent in controller.agentOptions where agent.model == name {
                related.insert("agent:\(agent.name)")
            }

        case .agent:
            if let model = node.subtitle {
                related.insert("model:\(model)")
                for endpoint in controller.inferenceOptions where endpoint.models.contains(model) {
                    related.insert("inference:\(endpoint.baseURL)")
                }
            }
        }
        let known = Set(nodes.map(\.id))
        return related.intersection(known).subtracting([id])
    }

    // MARK: - Inspection

    func kindLabel(_ kind: GraphNode.Kind) -> String {
        switch kind {
        case .vault: return Strings.Detail.vault
        case .harness: return Strings.Detail.harness
        case .inference: return Strings.Detail.inference
        case .model: return Strings.Detail.model
        case .agent: return Strings.Detail.agent
        }
    }

    /// The names of things, shown rather than counted. A readout that says
    /// "five models" makes the person open something else to find out what they
    /// are; four names and "and 3 more" is a fact they can act on.
    private func nameList(_ names: [String], limit: Int = 4) -> String {
        guard names.count > limit else { return names.joined(separator: ", ") }
        let shown = names.prefix(limit).joined(separator: ", ")
        return "\(shown) + \(names.count - limit) more"
    }

    /// What a clicked sea-star can tell you, all of it already in the report.
    /// Every row names something: an attached harness names its process and the
    /// tool it calls Sea-Star with, an endpoint names the models it serves, a
    /// model names where it lives and who rides it. Rows that would only restate
    /// the title, or would say nothing at all, are left out rather than padded.
    func facts(for node: GraphNode) -> [(label: String, value: String)] {
        guard let report = controller.report else { return [] }
        switch node.kind {
        case .vault:
            var rows: [(label: String, value: String)] = [
                (Strings.Detail.notes, report.vault.noteCount.formatted()),
                (Strings.Detail.found, Strings.Detail.source(report.vault.source)),
            ]
            let others = max(controller.vaultOptions.count - 1, 0)
            if others > 0 {
                rows.append((Strings.Detail.nearby, Strings.Detail.nearbyVaults(others)))
            }
            if !report.model.isEmpty {
                rows.append((Strings.Detail.model, report.model))
            }
            if let path = node.subtitle {
                rows.append((Strings.Detail.path, path))
            }
            return rows

        case .harness:
            var rows: [(label: String, value: String)] = [
                (Strings.Detail.status, node.rung?.label ?? Strings.Detail.notConnected),
            ]
            if let attached = controller.attachedHarnesses
                .first(where: { "harness:\($0.id)" == node.id }) {
                rows.append((Strings.Detail.process, "pid \(attached.pid)"))
                rows.append((Strings.Detail.since, attached.startedAt))
                rows.append((Strings.Detail.canCall, Strings.Detail.askTool))
            } else if let path = node.subtitle {
                rows.append((Strings.Detail.path, path))
            }
            if let bundle = node.subtitle, node.isLive {
                rows.append((Strings.Detail.bundle, bundle))
            }
            return rows

        case .inference:
            let endpoint = controller.inferenceOptions
                .first(where: { "inference:\($0.baseURL)" == node.id })
            var rows: [(label: String, value: String)] = [
                (
                    Strings.Detail.location,
                    (endpoint?.isRemote ?? false)
                        ? Strings.Detail.remoteAPI
                        : Strings.Detail.onThisMac
                ),
                (Strings.Detail.endpoint, node.subtitle ?? Strings.States.unknown),
                (
                    Strings.Detail.status,
                    node.id == activeInferenceID ? Strings.Detail.current : Strings.Detail.available
                ),
            ]
            if let models = endpoint?.models, !models.isEmpty {
                rows.append((Strings.Detail.serves, nameList(models)))
            }
            // Who the server actually belongs to. On this machine every endpoint
            // is inbuilt, so this is not trivia: it is the reason the model list
            // changes when a chat app is quit, and the reason to know which app
            // has to be running for the current one to work.
            if let owner = controller.bundledOwner(of: endpoint?.baseURL ?? node.subtitle ?? "") {
                rows.append((Strings.Detail.insideApp, owner))
                if node.id == activeInferenceID {
                    rows.append((Strings.Detail.warning, Strings.Detail.stopsWith(owner)))
                }
            }
            let riders = controller.agentOptions
                .filter { agent in
                    guard let model = agent.model else { return false }
                    return endpoint?.models.contains(model) == true
                }
                .map(\.name)
            if !riders.isEmpty {
                rows.append((Strings.Detail.usedBy, riders.joined(separator: ", ")))
            }
            return rows

        case .model:
            var rows: [(label: String, value: String)] = []
            let servers = controller.inferenceOptions
                .filter { $0.models.contains(node.title) }
                .map(\.name)
            if !servers.isEmpty {
                rows.append((Strings.Detail.servedBy, servers.joined(separator: ", ")))
            }
            rows.append((
                Strings.Detail.status,
                node.title == report.model ? Strings.Detail.current : Strings.Detail.available
            ))
            let riders = controller.agentOptions
                .filter { $0.model == node.title }
                .map(\.name)
            if !riders.isEmpty {
                rows.append((Strings.Detail.usedBy, riders.joined(separator: ", ")))
            }
            return rows

        case .agent:
            var rows: [(label: String, value: String)] = [
                (Strings.Detail.uses, node.subtitle ?? Strings.States.unknown),
            ]
            if let provider = controller.agentOptions
                .first(where: { "agent:\($0.name)" == node.id })?.provider {
                rows.append((Strings.Detail.provider, provider))
            }
            if let model = node.subtitle {
                let homes = controller.inferenceOptions
                    .filter { $0.models.contains(model) }
                    .map(\.name)
                if !homes.isEmpty {
                    rows.append((Strings.Detail.servedBy, homes.joined(separator: ", ")))
                }
            }
            rows.append((Strings.Detail.roster, controller.agentScopeLabel))
            return rows
        }
    }
}
