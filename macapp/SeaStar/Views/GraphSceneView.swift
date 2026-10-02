import AppKit
import SceneKit
import SwiftUI

/// The 3D reading of the graph (spec §8.7): the same pool, in a camera you fly.
///
/// The founder's note is the brief this is built to: *"it just needs to look
/// good and people expect you to be able to do that, just to move around and
/// have that freedom with those sort of graph models now."* So the freedom lives
/// entirely in the **camera** — SceneKit's own control gives orbit, zoom and
/// pan with a mouse or a trackpad, and nothing else in here fights it for the
/// pointer. The nodes themselves hold still, because a layout that never
/// settles is a layout you can never learn.
///
/// Every fact is read from the shared `EntityGraphModel`, exactly as the 2D pool
/// reads it. Switching between them changes the camera and the drawing and
/// nothing else.
struct GraphSceneView: View {
    let controller: ServerController
    /// The pool's height in points. The deep wants more room than the flat pool
    /// does, because a thing seen in space needs somewhere to be seen from.
    var height: CGFloat = 400

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The entity under the cursor. Hover names it; it does not select it.
    @State private var hovered: String?
    /// The entity the person has clicked open.
    @State private var selected: String?
    /// The entity the person has zoomed into: its neighbourhood stays lit and
    /// everything else fades back.
    @State private var focused: String?
    /// Whether the camera has been moved off its opening view, which is what
    /// offers the way back.
    @State private var isCameraMoved = false
    /// Whether the last tap was a double tap. Two in quick succession on the
    /// same sphere zooms in; the first is undone rather than left to linger.
    @State private var lastTapID: String?
    @State private var lastTapTime = Date.distantPast
    /// Bumped to ask the canvas to fly home. A token rather than a binding on
    /// the camera itself: the camera belongs to SceneKit, and SwiftUI should be
    /// able to *request* a return without taking the wheel.
    @State private var resetToken = 0

    /// The shared model — the same one the 2D pool reads.
    private var model: EntityGraphModel { EntityGraphModel(controller: controller) }
    private var space: GraphSpace3D { GraphSpace3D(model: model) }

    /// The ids that belong to the focused neighbourhood, or empty for the whole
    /// pool. Asked of the shared model, so a focus here and a focus in the flat
    /// pool are the same company.
    private var focusSet: Set<String> {
        guard let focused else { return [] }
        return model.neighbours(of: focused).union([focused])
    }

    /// The entity the card describes: a click wins, then a hover, and failing
    /// both it falls back to the active harness — so the cockpit still opens
    /// already telling you what is running.
    private var subject: GraphNode? {
        if let id = selected ?? hovered { return model.node(id) }
        return model.activeInferenceID.flatMap { model.node($0) }
    }

    /// Where the focused entity sits, and how big it is drawn — the two facts
    /// the camera needs to frame it. Resolved in one place because both come
    /// from the same `space`, and asking it twice per frame to get one number
    /// twice is the kind of thing that quietly makes a view expensive.
    private var focusTarget: (point: Point3, radius: Float)? {
        guard let focused, let node = model.node(focused) else { return nil }
        guard let point = space.positions()[focused] else { return nil }
        return (point, space.radius(for: node))
    }

    var body: some View {
        SceneCanvas(
            plan: GraphScenePlan(
                model: model,
                space: space,
                focus: focusSet,
                selectedID: selected
            ),
            animated: !reduceMotion,
            onHover: { hovered = $0 },
            onSelect: { tap($0) },
            onCameraMoved: { isCameraMoved = $0 },
            focusPoint: focusTarget?.point,
            focusRadius: focusTarget?.radius,
            resetToken: resetToken
        )
        .frame(height: height)
        .background(Palette.pool)
        .overlay(alignment: .bottomLeading) { readout }
        .overlay(alignment: .topTrailing) { recentreControl }
        .overlay(alignment: .topLeading) { focusControl }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .help(Strings.Views.orbitHint)
        .onChange(of: model.activeInferenceID) { _, _ in
            // A new active harness is a new thing to look at, so the camera
            // comes back to where the pool opens, the way the 2D pool re-tides.
            reset()
        }
    }

    /// The card, shared with the 2D pool: hovering a sphere and hovering a star
    /// bring up the very same facts, from the very same model.
    @ViewBuilder
    private var readout: some View {
        if let subject {
            GraphReadoutCard(
                node: subject,
                rows: model.facts(for: subject),
                kindLabel: model.kindLabel(subject.kind)
            )
            .padding(9)
            .transition(.opacity)
        }
    }

    /// The way back to the opening view, offered only once the camera has
    /// actually been moved — a control that is always there is a control that is
    /// always lying.
    @ViewBuilder
    private var recentreControl: some View {
        if isCameraMoved {
            Button(action: reset) {
                Text(Strings.Views.recentre)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Palette.bone.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Palette.pool.opacity(0.9), in: Capsule())
                    .overlay(Capsule().stroke(Palette.mauve.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(Strings.Views.recentreHelp)
            .padding(9)
            .transition(.opacity)
        }
    }

    /// The chip that appears while something is focused: it names what you are
    /// zoomed into and offers the way back out to the whole pool.
    @ViewBuilder
    private var focusControl: some View {
        if let focused, let node = model.node(focused) {
            Button(action: unfocus) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 8, weight: .bold))
                    Text(node.title)
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .lineLimit(1)
                    Text(Strings.Views.exitFocus)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Palette.mauve)
                }
                .foregroundStyle(Palette.bone.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Palette.pool.opacity(0.9), in: Capsule())
                .overlay(Capsule().stroke(node.accent.opacity(0.45), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(Strings.Views.exitFocusHelp)
            .padding(9)
            .transition(.opacity)
        }
    }

    /// One tap inspects; two on the same sphere in quick succession zoom in.
    /// Detected here rather than left to SwiftUI's paired tap gestures, because
    /// a SceneKit tap is not a SwiftUI tap — this keeps the first of the two
    /// from leaving a stray selection behind waiting on a second that never
    /// comes.
    private func tap(_ id: String) {
        let now = Date()
        if lastTapID == id, now.timeIntervalSince(lastTapTime) < 0.4 {
            focus(id)
            lastTapID = nil
            return
        }
        lastTapID = id
        lastTapTime = now
        withAnimation(.easeInOut(duration: 0.18)) {
            selected = selected == id ? nil : id
        }
    }

    private func focus(_ id: String) {
        withAnimation(.easeInOut(duration: 0.24)) {
            focused = focused == id ? nil : id
        }
    }

    private func unfocus() {
        withAnimation(.easeInOut(duration: 0.24)) {
            focused = nil
        }
    }

    private func reset() {
        focused = nil
        selected = nil
        hovered = nil
        resetToken += 1
    }
}

/// Wraps the `SCNView` and reports what the person is pointing at.
///
/// The hover and click work is done by SceneKit's own hit-testing against the
/// scene graph, not by SwiftUI gestures layered on top: a SwiftUI gesture has no
/// idea where a sphere is in space, and guessing would make "click a star to
/// inspect" lie the moment the pool is rotated. Reading the real hit result is
/// the only way the pointer can mean what it says.
private struct SceneCanvas: NSViewRepresentable {
    let plan: GraphScenePlan
    let animated: Bool
    @Environment(\.seaStarCockpitOpen) private var isOpen
    let onHover: (String?) -> Void
    let onSelect: (String) -> Void
    let onCameraMoved: (Bool) -> Void
    /// Where the focused entity sits in the deep, or nil for the whole-pool
    /// reading. Carried as a plain value rather than a lookup into the scene so
    /// the camera can be moved from the same place the graph is rebuilt, without
    /// having to go hunting through the node tree for a body by name.
    var focusPoint: Point3?
    /// The focused body's own radius, so the camera can stand off far enough to
    /// frame a large body and not so far that a small one vanishes.
    var focusRadius: Float?
    /// Bumped to send the camera home; watched by the coordinator.
    var resetToken: Int = 0

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onHover: onHover,
            onSelect: onSelect,
            onCameraMoved: onCameraMoved
        )
    }

    func makeNSView(context: Context) -> PoolView {
        let view = PoolView()
        view.scene = GraphSceneBuilder.makeScene(animated: animated)
        view.pointOfView = view.scene?.rootNode.childNode(withName: "camera", recursively: false)
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = NSColor(Palette.pool)
        // The gesture that opens the card must not be swallowed by the camera's
        // own control, so the view is left to handle its own clicks and drags.
        view.delegate = context.coordinator
        view.isPlaying = animated && isOpen
        context.coordinator.attach(to: view)
        return view
    }

    func updateNSView(_ nsView: PoolView, context: Context) {
        context.coordinator.onHover = onHover
        context.coordinator.onSelect = onSelect
        context.coordinator.onCameraMoved = onCameraMoved

        // The pool is fixed and deterministic, so the scene is only rebuilt
        // when the reading actually changes — which on a still cockpit is
        // almost never, rather than sixty times a second.
        if context.coordinator.plan != plan {
            context.coordinator.plan = plan
            rebuild(nsView, context: context)
            // Rebuilding replaces the node holding the camera, so the flag the
            // "recentre" button depends on is re-derived from where the camera
            // now is rather than left to disagree with the pool it is drawn over.
            if let camera = nsView.pointOfView {
                context.coordinator.reportCamera(!PoolView.isAtHome(camera))
            }
        }
        nsView.isPlaying = animated && isOpen

        // Focus moves the camera, but only when the *subject* changes — not on
        // every re-render, and not when a hover repaints the same focus. The
        // distance is a multiple of the body's own radius so a small node and a
        // large one are both framed rather than one filling the screen.
        //
        // Leaving focus is the mirror of entering it, and has to move the camera
        // too. Sitting still on exit would strand the person nose-first against
        // whatever they had just been reading, with the rest of the pool off
        // screen behind it and no indication which way was out — the one case
        // where a stationary camera is not neutral but actively misleading.
        // Going home rather than backing off by the same distance is the
        // deliberate choice: it is the pose the pool opens in, so "exit focus"
        // and "recentre" mean the same thing and there is one pose to learn.
        if context.coordinator.focusPoint != focusPoint {
            context.coordinator.focusPoint = focusPoint
            if let point = focusPoint {
                let radius = CGFloat(focusRadius ?? 20)
                nsView.look(
                    at: SCNVector3(point.x, point.y, point.z),
                    distance: max(120, radius * 5),
                    animated: animated
                )
            } else {
                nsView.flyHome(animated: animated)
            }
        }

        if context.coordinator.resetToken != resetToken {
            context.coordinator.resetToken = resetToken
            nsView.flyHome(animated: animated)
        }
    }

    /// Swap in a freshly built graph, keeping the pool, the lights and — the
    /// point of the exercise — the camera exactly where the person left it.
    private func rebuild(_ view: PoolView, context: Context) {
        guard let scene = view.scene else { return }

        // Rasterised textures are cached by entity identity, so a harness or
        // model that leaves the roster leaves a texture behind that nothing will
        // ever draw again. Draining the cache on a *membership* change — not on
        // every rebuild, which a liveness change also triggers — keeps that
        // from accumulating over a long session of switching engines, and costs
        // one re-rasterise of the bodies that remain.
        let ids = Set(plan.nodes.map(\.id))
        if context.coordinator.rosterIDs != ids {
            context.coordinator.rosterIDs = ids
            GraphSceneBuilder.flushCaches()
        }

        let graph = GraphSceneBuilder.makeGraph(plan: plan, animated: animated)
        scene.rootNode.childNode(withName: "graph", recursively: true)?.removeFromParentNode()
        scene.rootNode.addChildNode(graph)
    }

    @MainActor
    final class Coordinator: NSObject, SCNSceneRendererDelegate {
        var onHover: (String?) -> Void
        var onSelect: (String) -> Void
        var onCameraMoved: (Bool) -> Void
        var plan: GraphScenePlan?
        var resetToken: Int = 0
        /// The last focus the camera was moved to, so the move happens once per
        /// focus change rather than on every update.
        var focusPoint: Point3?
        /// Which entities were in the last build, so the rasterised-texture
        /// caches can be drained when that set changes rather than on every
        /// rebuild.
        var rosterIDs: Set<String> = []

        /// The last "has the camera moved" answer, so the SwiftUI state is only
        /// written when the answer actually changes rather than every frame.
        private(set) var isCameraMoved = false
        /// Read from SceneKit's render thread as well as the main actor, so it
        /// is held without isolation. It is a weak reference written once during
        /// `makeNSView` and never mutated afterwards, so the race the compiler
        /// is warning about cannot actually occur — but "cannot occur" is not
        /// something to leave to a comment, hence the explicit opt-out.
        nonisolated(unsafe) private weak var view: PoolView?
        init(
            onHover: @escaping (String?) -> Void,
            onSelect: @escaping (String) -> Void,
            onCameraMoved: @escaping (Bool) -> Void
        ) {
            self.onHover = onHover
            self.onSelect = onSelect
            self.onCameraMoved = onCameraMoved
        }

        /// Hands the view its three voices, and remembers the view so the
        /// per-frame camera check has somewhere to look.
        ///
        /// The closures route *through the coordinator* rather than capturing
        /// SwiftUI's callbacks directly, so that when SwiftUI re-renders and
        /// hands down new closures, the next hover uses the new one. Capturing
        /// the original would leave the pool reporting hover state from a view
        /// that no longer exists.
        func attach(to view: PoolView) {
            self.view = view
            view.onHover = { [weak self] id in self?.onHover(id) }
            view.onSelect = { [weak self] id in self?.onSelect(id) }
        }

        /// Record a new camera verdict, and pass it on only if it actually
        /// changed. The single place that answers "is the camera home?", whether
        /// that came from a frame tick or from a rebuild.
        func reportCamera(_ moved: Bool) {
            guard moved != isCameraMoved else { return }
            isCameraMoved = moved
            onCameraMoved(moved)
        }

        /// SceneKit calls this every frame. It is used for one thing only:
        /// noticing that the person has flown the camera away from where the
        /// pool opened, so the way back can be offered.
        nonisolated func renderer(
            _ renderer: any SCNSceneRenderer,
            updateAtTime time: TimeInterval
        ) {
            let moved = Self.hasMovedCamera(view)
            Task { @MainActor [weak self] in
                self?.reportCamera(moved)
            }
        }

        /// Whether the view's camera is anywhere but home. Read without touching
        /// main-actor state, so it is safe to call from the render thread; a
        /// view that is gone is reported as "not moved", which simply stops the
        /// update rather than inventing one.
        private nonisolated static func hasMovedCamera(_ view: PoolView?) -> Bool {
            guard let camera = view?.pointOfView else { return false }
            return !PoolView.isAtHome(camera)
        }
    }
}

/// The `SCNView` that knows how to find an entity under the cursor.
///
/// Subclassed rather than configured, because the two things the founder asked
/// for — hover text and working clicks — both need a real hit test against the
/// scene, and both need to know whether the pointer was over a *body* rather
/// than a wire, a label or empty water.
final class PoolView: SCNView {
    /// How far the pointer may travel between pressing and releasing and still
    /// count as a click. Small enough that an intentional drag never selects
    /// whatever it happened to let go over, large enough that a slightly shaky
    /// hand still inspects what it aimed at.
    private static let clickSlop: CGFloat = 4

    nonisolated(unsafe) var onHover: ((String?) -> Void)?
    nonisolated(unsafe) var onSelect: ((String) -> Void)?
    private nonisolated(unsafe) var tracking: NSTrackingArea?
    /// Where the pointer went down, so the release can be compared against it.
    private nonisolated(unsafe) var pressOrigin: CGPoint?
    /// The entity under the pointer at press time. Captured *then* rather than
    /// re-hit-tested on release, so a selection is always about the thing you
    /// aimed at — not whatever a moving camera left under you instead.
    private nonisolated(unsafe) var pressedEntity: String?

    /// Whether a camera pose is the opening pose, within a point of slop. The
    /// pool is polled every frame to notice the person has flown away; this is
    /// that notice.
    ///
    /// Non-isolated, and taking the node rather than reaching for the view's own
    /// camera, because SceneKit's render thread asks the question every frame
    /// and that thread is not the main actor. It reads a transform and compares
    /// it — pure pose arithmetic, with nothing here belonging to SwiftUI.
    nonisolated static func isAtHome(_ camera: SCNNode) -> Bool {
        let position = camera.position
        let home = GraphSceneBuilder.homePosition
        return abs(position.x - home.x) < 1
            && abs(position.y - home.y) < 1
            && abs(position.z - home.z) < 1
            && abs(camera.eulerAngles.x - GraphSceneBuilder.homePitch) < 0.02
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        tracking = area
    }

    /// Hover. The name of whatever body is under the cursor, or nil for open
    /// water — so the card closes when the pointer leaves a star rather than
    /// stranding the last thing you looked at.
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        onHover?(entity(at: convert(event.locationInWindow, from: nil)))
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        onHover?(nil)
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        onHover?(entity(at: convert(event.locationInWindow, from: nil)))
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        pressOrigin = convert(event.locationInWindow, from: nil)
        pressedEntity = entity(at: pressOrigin ?? .zero)
    }

    /// Selection happens on the *release*, and only if the pointer stayed put.
    ///
    /// This is the whole reason the click works at all: the camera's own control
    /// owns the drag, so a press that travels is the person flying the pool and
    /// must not also select whatever they happened to let go over. Both ends are
    /// compared in the view's own coordinates, which is the only frame in which
    /// "the pointer did not move" still means something while the camera is
    /// rotating underneath it.
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        defer {
            pressOrigin = nil
            pressedEntity = nil
        }
        guard let origin = pressOrigin, let id = pressedEntity else { return }
        let release = convert(event.locationInWindow, from: nil)
        guard hypot(release.x - origin.x, release.y - origin.y) < Self.clickSlop else { return }
        onSelect?(id)
    }

    /// The entity id under a point in this view's coordinates, or nil.
    ///
    /// Hit-testing asks the scene, then the hit node is walked *up* to the
    /// holder that names an entity. That walk is what makes the click land on
    /// the body even when the pointer is over the sea-star worn on it or the
    /// name hung beneath — all three are one thing to the person.
    private func entity(at point: CGPoint) -> String? {
        let results = hitTest(
            point,
            options: [
                .searchMode: SCNHitTestSearchMode.all.rawValue,
                .boundingBoxOnly: false,
            ]
        )
        for result in results {
            var node: SCNNode? = result.node
            while let current = node {
                if let name = current.name, name.hasPrefix("node-") {
                    return String(name.dropFirst("node-".count))
                }
                node = current.parent
            }
        }
        return nil
    }

    /// Send the camera back to the opening view, gliding rather than jumping
    /// when motion is allowed and cutting straight there when it is not.
    ///
    /// The start pose is captured *before* the action runs, rather than read
    /// from the camera on every frame. That distinction is the whole ballgame:
    /// reading it inside the action would sample a value the action had already
    /// moved, so the glide would chase its own tail and ease to a stop
    /// somewhere short of home — which is precisely the bug that makes a
    /// "recentre" button look like it does nothing.
    func flyHome(animated: Bool) {
        guard let camera = pointOfView else { return }
        let home = GraphSceneBuilder.homePosition
        // Cancel whatever the person's own dragging left running, or the two
        // would fight over the same transform.
        camera.removeAllActions()

        guard animated else {
            camera.position = home
            camera.eulerAngles = GraphSceneBuilder.homeAngles
            return
        }

        glide(
            camera,
            from: camera.position,
            to: home,
            fromAngles: camera.eulerAngles,
            toAngles: GraphSceneBuilder.homeAngles
        )
    }

    /// Bring a point to the middle of the frame without changing the angle the
    /// person is looking from.
    ///
    /// This is the difference between "focus follows you" and "the app threw
    /// away my viewpoint". Snapping the camera to a canned pose on every focus
    /// would be the 2D behaviour carried over literally, and in a pool you are
    /// freely flying it would be obnoxious: you would spend every focus losing
    /// the angle you had just found. So this only ever *translates* along the
    /// current line of sight — the pitch and yaw you chose are yours, and the
    /// graph moves to meet them.
    func look(at point: SCNVector3, distance: CGFloat, animated: Bool) {
        guard let camera = pointOfView else { return }
        // The camera looks down its own −Z, so the point it should end up
        // framing sits that far back along the current forward axis. Read from
        // the world transform rather than the euler angles, because the pool
        // has been orbited and the angles alone would no longer describe where
        // the camera is actually looking.
        let world = camera.worldTransform
        let dx = -world.m31
        let dy = -world.m32
        let dz = -world.m33
        let length = sqrt(dx * dx + dy * dy + dz * dz)
        // A degenerate basis cannot be normalised; leaving the camera where it
        // is beats dividing by zero and flinging it somewhere random.
        guard length > 0.0001 else { return }

        let stepX: CGFloat = dx / length * distance
        let stepY: CGFloat = dy / length * distance
        let stepZ: CGFloat = dz / length * distance
        let target = SCNVector3(point.x + stepX, point.y + stepY, point.z + stepZ)

        camera.removeAllActions()
        guard animated else {
            camera.position = target
            return
        }
        // From and to are the *same* orientation on purpose: this is a
        // translation along the line of sight, so the angle the person chose
        // survives the move untouched.
        let from = camera.position
        let angles = camera.eulerAngles
        glide(camera, from: from, to: target, fromAngles: angles, toAngles: angles)
    }

    /// The one place a camera move is animated.
    ///
    /// The start pose is captured *before* the action runs, rather than read
    /// from the camera on every frame. That distinction is the whole ballgame:
    /// reading it inside the action would sample a value the action had already
    /// moved, so the glide would chase its own tail and ease to a stop
    /// somewhere short of the target — which is precisely the bug that makes a
    /// "recentre" button look like it does nothing.
    ///
    /// Orientation is carried the whole way round rather than only its pitch.
    /// Writing yaw and roll back to zero here would be a small thing that
    /// undoes a lot: the person spends their time in this pool *finding* an
    /// angle that reads, and a focus move or a glide that quietly snapped the
    /// camera back to front-on would throw away the one thing they had found.
    /// Taking the full orientation as a parameter also means a focus move and a
    /// return-home are the same code, differing only in the pose they aim at.
    private func glide(
        _ camera: SCNNode,
        from: SCNVector3,
        to: SCNVector3,
        fromAngles: SCNVector3,
        toAngles: SCNVector3
    ) {
        // Spelled out rather than written as a leading-dot call: `SCNNode` is an
        // `NSObject` subclass, so the compiler has no static member to find the
        // action type through and the shorthand cannot infer it.
        let action = SCNAction.customAction(duration: Self.glideSeconds) { _, elapsed in
            let t = Self.smoothStep(min(max(CGFloat(elapsed / Self.glideSeconds), 0), 1))
            camera.position = SCNVector3(
                Self.lerp(from.x, to.x, t),
                Self.lerp(from.y, to.y, t),
                Self.lerp(from.z, to.z, t)
            )
            camera.eulerAngles = SCNVector3(
                Self.lerp(fromAngles.x, toAngles.x, t),
                Self.lerp(fromAngles.y, toAngles.y, t),
                Self.lerp(fromAngles.z, toAngles.z, t)
            )
        }
        camera.runAction(action)
    }

    /// How long the return home takes. Long enough to read as a glide, short
    /// enough that it never feels like the app is thinking about it.
    private static let glideSeconds: TimeInterval = 0.45

    /// Smoothstep, so the glide eases in *and* out and settles rather than
    /// arriving at a dead stop.
    private static func smoothStep(_ t: CGFloat) -> CGFloat {
        t * t * (3 - 2 * t)
    }

    /// Interpolated in `CGFloat`, because that is what `SCNVector3` holds —
    /// it is an Objective-C struct, so its components are `CGFloat` and not the
    /// `Float` the Swift-shaped API invites you to assume. Narrowing to `Float`
    /// first would round the pose twice and leave the camera a fraction off
    /// home, which is exactly the state `isAtHome` exists to detect.
    private static func lerp(_ from: CGFloat, _ to: CGFloat, _ t: CGFloat) -> CGFloat {
        from + (to - from) * t
    }
}
