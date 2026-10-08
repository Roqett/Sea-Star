import AppKit
import SceneKit
import SwiftUI

/// The renderer-independent description of what the 3D scene needs to draw.
///
/// The scene is a value rather than a closure over live controller state, so
/// the scene builder is a pure function of *this* and a test can build a pool
/// with no window, no view and no controller at all. Everything the scene can
/// be asked — where the things are, what touches what, which ones answered —
/// is either here or reachable from the model it was built from.
@MainActor
struct GraphScenePlan: Equatable {
    let nodes: [GraphNode]
    let edges: [GraphEdge]
    let positions: [String: Point3]
    let radii: [String: Float]
    /// The focused neighbourhood, or empty for the whole-pool reading.
    var focus: Set<String> = []
    var selectedID: String?

    init(
        model: EntityGraphModel,
        space: GraphSpace3D,
        focus: Set<String>,
        selectedID: String?
    ) {
        self.nodes = model.nodes
        self.edges = model.edges
        self.positions = space.positions()
        self.radii = Dictionary(
            uniqueKeysWithValues: model.nodes.map { ($0.id, space.radius(for: $0)) }
        )
        self.focus = focus
        self.selectedID = selectedID
    }

    /// Whether something answered on this entity during the read this plan came
    /// from. Asked of the plan rather than of the live controller so the scene
    /// builder stays a pure function of the plan — a pool can be built and
    /// tested with no window and no engine behind it.
    func isLive(_ id: String) -> Bool {
        nodes.first { $0.id == id }?.isLive == true
    }

    /// Whether this binding has Sea-Star at one end. Its wires are drawn a touch
    /// heavier, because they are the ones the hub exists to carry.
    func touchesCore(_ edge: GraphEdge) -> Bool {
        edge.from == EntityGraphModel.coreID || edge.to == EntityGraphModel.coreID
    }
}

/// Builds the `SCNScene` for a plan.
///
/// Every texture here is *rasterised from the 2D views themselves* — the
/// sea-star glyph and the nudibranch liveness bar are the same SwiftUI code the
/// pool draws, rendered once into an image and mapped onto a billboard. That is
/// the decision that keeps the deep honest: there is no second sea-star, and no
/// second idea of what "live" looks like. If the founder repaints the star or
/// the nudibranch, the 3D pool changes with it, for free, and cannot fall
/// behind the way a hand-built 3D model would.
///
/// The cost is honest too: rasterising on every rebuild would be wasteful, so
/// textures are cached by the things that actually change them (the node's own
/// identity and liveness), not by the frame.
///
/// Main-actor bound because the caches are mutable statics and rasterising walks
/// AppKit — which is also where every one of these is called from.
@MainActor
enum GraphSceneBuilder {
    /// Side length of a rasterised glyph, in points. Big enough to stay crisp
    /// with the camera close in, small enough that a pool of a dozen is cheap.
    private static let glyphPixels: CGFloat = 256
    private static let barWidth: CGFloat = 192
    private static let barHeight: CGFloat = 32

    private static var glyphCache: [String: NSImage] = [:]
    private static var barCache: [String: NSImage] = [:]

    /// Where the camera opens, and where "recentre" returns it. Held here —
    /// next to the camera that has to be built at this pose — so the two can
    /// never disagree about what "home" means.
    ///
    /// Non-isolated constants inside an otherwise main-actor enum: SceneKit's
    /// render thread compares the camera against these every frame, and a pose
    /// nobody can change is not something that needs an actor to protect it.
    /// Where the camera waits. Far enough back that the ring's *near* side is not
    /// dramatically bigger than its far side: at 240 with a radius of 120, the
    /// closest node stood 120 units from the eye and the furthest 360, so
    /// perspective made the front of the pool enormous and the founder's screenshot
    /// opened on a giant coloured blob that was not special — merely near. Doubling
    /// the distance roughly halves that disparity, which is what lets the height
    /// axis be read instead of being shouted over by scale.
    nonisolated(unsafe) static let homePosition = SCNVector3(0, 150, 430)
    nonisolated(unsafe) static let homePitch: CGFloat = -0.22
    /// The whole opening orientation, so "home" is one pose rather than a
    /// position and a pitch that could each be changed on their own.
    nonisolated(unsafe) static let homeAngles = SCNVector3(homePitch, 0, 0)

    /// Drop every rasterised texture. Called when the roster changes shape, so
    /// ids that will never be drawn again do not sit in memory for the session.
    static func flushCaches() {
        glyphCache.removeAll()
        barCache.removeAll()
    }

    // MARK: - The pool

    /// The pool the camera flies around: the fixed dark ground, a key and a
    /// fill so the bodies read as volumes, and the far motes that give the
    /// emptiness a scale.
    static func makeScene(animated: Bool) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = NSColor(Palette.pool)

        let camera = SCNNode()
        camera.name = "camera"
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 50
        camera.camera?.zNear = 1
        camera.camera?.zFar = 4000
        // HDR, bloom, pushed contrast and raised saturation together are the 1985
        // recipe: they are what made the founder call this room "wacky blob pop
        // art". Depth now comes from *height carrying the rung* and from the fog
        // below, so nothing here needs to fake it with glow.
        camera.camera?.wantsHDR = false
        camera.camera?.bloomIntensity = 0
        camera.camera?.contrast = 0
        camera.camera?.saturation = 1.0
        // Fog is the other half of making the room a room: without it every body
        // sits at the same apparent distance and a tilted pool reads as a flat blob
        // from every angle. It also does the honest work of pushing an
        // installed-but-off harness visibly to the back, which is what the height
        // axis says and what additive glow was faking.
        scene.fogStartDistance = 90
        scene.fogEndDistance = 620
        scene.fogDensityExponent = 0.6
        scene.fogColor = NSColor(Palette.pool)
        camera.position = homePosition
        camera.eulerAngles = homeAngles
        scene.rootNode.addChildNode(camera)

        // A soft key from above and in front, and a cool fill from behind, so
        // the pool has a direction to its light and the bodies are not flat.
        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .omni
        key.light?.intensity = 620
        key.light?.color = NSColor(Palette.bone)
        key.position = SCNVector3(160, 220, 260)
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .omni
        fill.light?.intensity = 240
        fill.light?.color = NSColor(Palette.electricBlue)
        fill.position = SCNVector3(-220, -60, -160)
        scene.rootNode.addChildNode(fill)

        // The far motes: a seeded drift of dim points, so the pool is water with
        // depth rather than an object floating in a void. Seeded, so it is the
        // same water every time the cockpit opens.
        let motes = SCNNode()
        motes.name = "motes"
        for index in 0..<90 {
            let mote = SCNNode()
            mote.geometry = SCNSphere(radius: 1.1)
            let material = SCNMaterial()
            let tint = index % 3 == 0 ? Palette.mauve : Palette.electricBlue
            material.diffuse.contents = NSColor(tint)
            material.emission.contents = NSColor(tint)
            material.lightingModel = .constant
            material.transparency = 0.20
            material.transparencyMode = .aOne
            material.blendMode = .add
            mote.geometry?.firstMaterial = material

            let angle = GraphSeed.phase(for: "mote-\(index)")
            let distance = CGFloat(index) / 90 * 900 + 420
            let x: CGFloat = cos(angle) * distance
            let y: CGFloat = sin(angle * 1.7) * distance * 0.4
            let z: CGFloat = -distance * 0.6
            mote.position = SCNVector3(x, y, z)
            if animated {
                // Drifting opacity, seeded in period so the field never pulses
                // as one block. Idle water, not a disco floor.
                let period = 2.4 + Double(index % 5) * 0.4
                mote.runAction(
                    .repeatForever(.sequence([
                        .fadeOpacity(to: 0.55, duration: period),
                        .fadeOpacity(to: 0.12, duration: period),
                    ])),
                    forKey: "drift"
                )
            }
            motes.addChildNode(mote)
        }
        scene.rootNode.addChildNode(motes)

        return scene
    }

    // MARK: - The graph

    /// The graph itself: one lit body per entity, a wire for every binding, and
    /// — on the things that actually answered — a nudibranch liveness bar.
    static func makeGraph(plan: GraphScenePlan, animated: Bool) -> SCNNode {
        let root = SCNNode()
        root.name = "graph"

        for edge in plan.edges {
            guard plan.positions[edge.from] != nil, plan.positions[edge.to] != nil else { continue }
            root.addChildNode(makeWire(edge, plan: plan))
        }

        for node in plan.nodes {
            guard let point = plan.positions[node.id] else { continue }
            let body = makeNode(
                node,
                radius: plan.radii[node.id] ?? 20,
                isDimmed: isDimmed(node, plan: plan),
                isSelected: plan.selectedID == node.id,
                animated: animated
            )
            body.position = SCNVector3(point.x, point.y, point.z)
            root.addChildNode(body)
        }

        return root
    }

    /// One binding, drawn as a thin lit cylinder from body to body.
    ///
    /// A wire with something live on it wears the founder's green-and-orange
    /// liveness ribbon; one that is only a binding the report states stays the
    /// cool blue of infrastructure. That is the same rule the flat pool's wires
    /// follow, read from the same `isLive` facts, so flying between the two
    /// readings cannot change which connections look live.
    private static func makeWire(_ edge: GraphEdge, plan: GraphScenePlan) -> SCNNode {
        let from = plan.positions[edge.from]!
        let to = plan.positions[edge.to]!

        let wire = SCNNode()
        wire.name = "wire-\(edge.id)"
        let length = from.distance(to: to)
        let isLive = plan.isLive(edge.from) || plan.isLive(edge.to)
        let tint = isLive ? Palette.neonGreen : Palette.electricBlue
        let cylinder = SCNCylinder(
            radius: plan.touchesCore(edge) ? 1.6 : 0.9,
            height: CGFloat(max(length, 0.1))
        )
        let material = SCNMaterial()
        material.diffuse.contents = NSColor(tint)
        material.emission.contents = NSColor(tint)
        material.lightingModel = .constant
        material.transparencyMode = .aOne
        material.blendMode = .add
        cylinder.firstMaterial = material
        wire.geometry = cylinder
        wire.position = SCNVector3(
            (from.x + to.x) / 2,
            (from.y + to.y) / 2,
            (from.z + to.z) / 2
        )
        // Stand the cylinder on its end between the two bodies.
        wire.look(at: SCNVector3(to.x, to.y, to.z))
        wire.eulerAngles.x += .pi / 2

        // While something is focused, a wire that joins two faded nodes fades
        // with them — so a focus reading is a single readable company rather
        // than the whole pool behind a scrim.
        let lit = plan.focus.isEmpty
            || (plan.focus.contains(edge.from) && plan.focus.contains(edge.to))
        material.transparency = lit ? 0.75 : 0.14

        return wire
    }

    /// One entity: the body, the sea-star worn on it, the name beneath, and the
    /// liveness bar if — and only if — something actually answered.
    private static func makeNode(
        _ node: GraphNode,
        radius: Float,
        isDimmed: Bool,
        isSelected: Bool,
        animated: Bool
    ) -> SCNNode {
        let holder = SCNNode()
        holder.name = "node-\(node.id)"

        let tinted = GraphSeed.shifted(node.accent, by: GraphSeed.hue(for: node.id) * 0.25)

        // The body was a solid emissive SCNSphere with the sea-star art on a quad
        // floating in front of it, so the thing you actually saw was the back of a
        // coloured ball through a star-shaped window. That is what made the room
        // "wacky blob pop art", and it is the whole difference between this reading
        // and the 2D pool — the flat pool draws the creature and has no sphere at
        // all, which is precisely why it looks right.
        //
        // So the sphere is gone. The node *is* the glyph now, the same art at the
        // same weight the 2D uses. What is left in the room that the 2D does not
        // have is the thing the 2D cannot offer: a third axis that carries the
        // rung, and a camera you can turn. The roster does not stop being the same
        // roster because the room is real.

        // The selected body's halo: a thin ring in the entity's own accent, and
        // the only selection cue in the pool. It is drawn in 3D rather than
        // borrowed from the 2D pool's scale-and-glow treatment because a sphere
        // cannot scale the way a flat star does without changing its meaning —
        // bigger would read as "bigger kind", which is a different claim.
        if isSelected {
            let halo = SCNNode(geometry: SCNPlane(
                width: CGFloat(radius) * 3.4,
                height: CGFloat(radius) * 3.4
            ))
            let haloMaterial = SCNMaterial()
            haloMaterial.diffuse.contents = NSColor(tinted)
            haloMaterial.emission.contents = NSColor(tinted)
            haloMaterial.lightingModel = .constant
            haloMaterial.isDoubleSided = true
            haloMaterial.transparencyMode = .aOne
            haloMaterial.transparency = 0.30
            haloMaterial.blendMode = .add
            halo.geometry?.firstMaterial = haloMaterial
            halo.position = SCNVector3(0, 0, CGFloat(radius) * 0.4)
            halo.constraints = [SCNBillboardConstraint()]
            halo.name = "halo-\(node.id)"
            holder.addChildNode(halo)
        }

        // The sea-star, as a billboard: the same 2D creature the flat pool draws, so the
        // roster stays recognisably the same roster rather than becoming a different
        // product. With the sphere gone this is no longer "art worn on a body" — it
        // is the node.
        let art = glyph(for: node)
        let plane = SCNPlane(width: CGFloat(radius) * 2.6, height: CGFloat(radius) * 2.6)
        let starMaterial = SCNMaterial()
        starMaterial.diffuse.contents = art
        starMaterial.emission.contents = art
        starMaterial.lightingModel = .constant
        starMaterial.isDoubleSided = true
        starMaterial.transparencyMode = .aOne
        starMaterial.transparency = isDimmed ? 0.3 : 1.0
        plane.firstMaterial = starMaterial
        let star = SCNNode(geometry: plane)
        star.name = "star-\(node.id)"
        star.position = SCNVector3(0, 0, CGFloat(radius) * 0.85)
        star.constraints = [SCNBillboardConstraint()]
        holder.addChildNode(star)

        // Liveness. The founder asked twice for the floating bars to come off the
        // starfield, and this room still had them: the 2D pool lost them and the
        // deep reading kept them, which is the two readings disagreeing about the
        // same fact — the exact failure the whole arrangement is meant to prevent.
        //
        // What replaces them is not nothing. "Up but not attached" is now a *steady*
        // glow rather than a breathing one — lit, but never pulsing, because the
        // breath is reserved for work and being up is not the same as carrying it
        // (D-020, which the 2D pool already did and this room did not).
        if node.isLive {
            let bar = makeLivenessBar(
                node,
                width: CGFloat(radius) * 2.4,
                animated: animated
            )
            bar.position = SCNVector3(0, CGFloat(radius) * 1.5, 0)
            holder.addChildNode(bar)
        } else if node.rung?.isUp == true {
            // Steady, and dimmer than the breath: present without pretending to be
            // busy. Drawn as a still, unlit-ribbon ring at the node's own radius so
            // it reads as "this is up" from across the room and does not animate.
            let ring = makeUpRing(radius: radius)
            holder.addChildNode(ring)
        }

        // The name, small and mono, hung beneath. Readable when you fly close;
        // quiet enough not to shout across the pool.
        if let label = makeLabel(for: node, isDimmed: isDimmed, radius: radius) {
            label.position = SCNVector3(0, -CGFloat(radius) * 1.6, 0)
            holder.addChildNode(label)
        }

        return holder
    }

    /// A still ring for a harness that is *up* but has answered nothing (D-020).
    ///
    /// Deliberately not the breathing ribbon: the breath means "carrying a request"
    /// and spending it on a merely-running process is exactly the false signal the
    /// founder objected to. A thin torus with constant lighting and no animation
    /// reads as lit-but-idle at any distance, and costs one geometry node.
    private static func makeUpRing(radius: Float) -> SCNNode {
        let ring = SCNTorus(ringRadius: CGFloat(radius) * 1.25, pipeRadius: CGFloat(radius) * 0.06)
        let material = SCNMaterial()
        material.diffuse.contents = NSColor(Palette.harnessGlow).withAlphaComponent(0.55)
        material.emission.contents = NSColor(Palette.harnessGlow).withAlphaComponent(0.34)
        material.lightingModel = .constant
        material.isDoubleSided = true
        material.transparencyMode = .aOne
        ring.firstMaterial = material

        let node = SCNNode(geometry: ring)
        node.name = "up-ring"
        node.constraints = [SCNBillboardConstraint()]
        return node
    }

    /// The nudibranch liveness bar: the founder's own green-and-orange strip,
    /// breathing.
    private static func makeLivenessBar(
        _ node: GraphNode,
        width: CGFloat,
        animated: Bool
    ) -> SCNNode {
        let art = livenessBar()
        let plane = SCNPlane(width: width, height: width / 6)
        let material = SCNMaterial()
        material.diffuse.contents = art
        material.emission.contents = art
        material.lightingModel = .constant
        material.isDoubleSided = true
        material.transparencyMode = .aOne
        material.blendMode = .add
        plane.firstMaterial = material

        let bar = SCNNode(geometry: plane)
        bar.name = "liveness-\(node.id)"
        bar.constraints = [SCNBillboardConstraint()]

        if animated {
            // The bar breathes — the same drift the SwiftUI bar has, on the
            // scene's own clock. Seeded in phase, so several live nodes
            // shimmer out of step with each other instead of strobing as one.
            let phase = Float(GraphSeed.phase(for: node.id))
            let sway = CGFloat(sin(phase) * 1.2)
            let breathe = SCNAction.sequence([
                .fadeOpacity(to: 0.65, duration: 1.1),
                .fadeOpacity(to: 1.0, duration: 1.1),
            ])
            breathe.timingMode = .easeInEaseOut
            let drift = SCNAction.sequence([
                .moveBy(x: sway, y: 0, z: 0, duration: 1.1),
                .moveBy(x: -sway, y: 0, z: 0, duration: 1.1),
            ])
            bar.runAction(.repeatForever(.group([breathe, drift])), forKey: "liveness")
        }

        return bar
    }

    /// The entity's own name as a flat, always-facing label. A billboard, so it
    /// turns to you as you orbit instead of turning edge-on and vanishing.
    private static func makeLabel(for node: GraphNode, isDimmed: Bool, radius: Float) -> SCNNode? {
        let text = SCNText(string: node.title, extrusionDepth: 0.2)
        text.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .semibold)
        text.flatness = 0.1
        let material = SCNMaterial()
        material.diffuse.contents = NSColor(Palette.bone)
        material.emission.contents = NSColor(Palette.bone)
        material.lightingModel = .constant
        material.transparencyMode = .aOne
        material.transparency = isDimmed ? 0.25 : 1.0
        text.materials = [material]

        let label = SCNNode(geometry: text)
        label.name = "label-\(node.id)"
        // `SCNText` is sized in *world units*, not points: at 11pt against a node
        // whose glyph is ~16 units across, the name was nearly as large as the thing
        // it named — the oversized type all over the founder's screenshot. Scaled to
        // the node's own radius so a caption reads as a caption at any pool size,
        // which is also what keeps it quiet rather than shouting across the room.
        // `SCNText` grows from its own baseline origin, so shift the pivot by
        // half its width to centre the words under the body rather than
        // trailing off to one side. `boundingBox` is a `(min:max:)` pair, so
        // the width is the gap between the two corners.
        let bounds = text.boundingBox
        label.pivot = SCNMatrix4MakeTranslation(
            (bounds.max.x - bounds.min.x) / 2,
            0,
            0
        )
        // Half the node's radius, expressed in the text's own world units.
        let captionScale = max(radius * 0.5 / 11, 0.05)
        label.scale = SCNVector3(captionScale, captionScale, captionScale)
        label.constraints = [SCNBillboardConstraint()]
        return label
    }

    /// Whether this node has faded back behind a focus reading.
    private static func isDimmed(_ node: GraphNode, plan: GraphScenePlan) -> Bool {
        !plan.focus.isEmpty && !plan.focus.contains(node.id)
    }

    // MARK: - Textures

    /// The sea-star, rasterised from the 2D glyph. Cached on the node's own
    /// identity and liveness, so a redraw that changed neither costs nothing.
    private static func glyph(for node: GraphNode) -> NSImage {
        let key = "\(node.id)|\(node.isLive)"
        if let cached = glyphCache[key] { return cached }
        let image = Texture.make(
            of: CGSize(width: glyphPixels, height: glyphPixels)
        ) {
            SeaStarGlyph(
                accent: node.accent,
                seed: GraphSeed.phase(for: node.id),
                isActive: node.isLive
            )
        }
        glyphCache[key] = image
        return image
    }

    /// The nudibranch liveness bar, rasterised from the same `LivenessBar` the
    /// 2D pool and the panel use — orange and green, on the founder's own art.
    private static func livenessBar() -> NSImage {
        let key = "live"
        if let cached = barCache[key] { return cached }
        let image = Texture.make(
            of: CGSize(width: barWidth, height: barHeight)
        ) {
            LivenessBar(isLive: true, height: 3)
        }
        barCache[key] = image
        return image
    }
}
