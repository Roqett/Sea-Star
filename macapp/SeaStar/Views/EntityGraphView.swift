import AppKit
import SwiftUI

/// A sea-star drawn as anatomy, not as a spiky polygon. Eight slender arms
/// taper from a soft central disc out to rounded tips, with webbing dipping
/// between them — the leggy silhouette of a *Meridiastra* carpet sea-star
/// (the reference art) rather than a squat five-point graphic. Every proportion
/// is a fraction of the circumscribed radius, so the same cut scales from a
/// 17pt satellite up to the faint outline traced behind the whole pool. A tiny
/// seeded wobble in each arm's length and angle keeps the creature from reading
/// as clockwork (spec §8.7).
struct SeaStarShape: Shape {
    var arms: Int = 8
    /// Radius of the central body, as a fraction of the outer radius. Kept small
    /// so the legs stay long and leggy rather than the icon reading squat.
    var discRatio: CGFloat = 0.30
    /// Where the webbing valley sits between arms, as a fraction of the outer
    /// radius. Kept near the disc so the legs read as separate, fanning fingers.
    var webbingRatio: CGFloat = 0.34
    /// How much of each angular step an arm's root fills — lower is leggier.
    var armFullness: CGFloat = 0.44
    /// How much of each angular step the arm's rounded tip cap spans.
    var tipFullness: CGFloat = 0.30
    /// Seeded variation in arm length and angle, so no two arms are identical.
    var wobble: CGFloat = 0.03

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let count = max(arms, 3)
        let step = 2 * CGFloat.pi / CGFloat(count)
        let start = -CGFloat.pi / 2
        let disc = outer * discRatio
        let webbing = outer * webbingRatio
        let halfBase = step * armFullness / 2
        let halfTip = step * tipFullness / 2
        var firstBase: CGPoint?

        for index in 0..<count {
            let wobbleIndex = CGFloat(index)
            let angle = start
                + wobbleIndex * step
                + step * wobble * 0.3 * sin(wobbleIndex * 1.7)
            let tipR = outer * (1 + wobble * sin(wobbleIndex * 2.399))
            let reach = tipR - disc

            let baseRight = polar(centre, disc, angle - halfBase)
            let baseLeft = polar(centre, disc, angle + halfBase)
            let shoulderRight = polar(centre, tipR, angle - halfTip)
            let shoulderLeft = polar(centre, tipR, angle + halfTip)

            if index == 0 {
                path.move(to: baseRight)
                firstBase = baseRight
            } else {
                // Climb out of the webbing valley into this leg's root.
                path.addQuadCurve(
                    to: baseRight,
                    control: polar(centre, disc * 1.06, angle - step / 2)
                )
            }
            // Outer edge of the leg: root → shoulder, gently convex.
            path.addCurve(
                to: shoulderRight,
                control1: polar(centre, disc + reach * 0.28, angle - halfBase * 1.02),
                control2: polar(centre, disc + reach * 0.74, angle - halfTip * 1.40)
            )
            // The rounded tip — a broad cap, not a needle.
            path.addQuadCurve(
                to: shoulderLeft,
                control: polar(centre, tipR * 1.07, angle)
            )
            // Inner edge of the leg: shoulder → root, mirroring the outer edge.
            path.addCurve(
                to: baseLeft,
                control1: polar(centre, disc + reach * 0.74, angle + halfTip * 1.40),
                control2: polar(centre, disc + reach * 0.28, angle + halfBase * 1.02)
            )
            // Webbing dipping to the valley between this leg and the next.
            path.addQuadCurve(
                to: polar(centre, webbing, angle + step / 2),
                control: polar(centre, webbing * 0.98, angle + step / 2)
            )
        }
        // Close the webbing between the last leg and the first, then tie off.
        if let firstBase {
            path.addQuadCurve(
                to: firstBase,
                control: polar(centre, webbing * 0.98, start - step / 2)
            )
        }
        path.closeSubpath()
        return path
    }

    private func polar(_ centre: CGPoint, _ radius: CGFloat, _ angle: CGFloat) -> CGPoint {
        CGPoint(x: centre.x + radius * cos(angle), y: centre.y + radius * sin(angle))
    }
}

/// The sea-star a single entity wears, cut from the brand sheet in
/// `assets/ss-icons/` — the S_S_1 "C star": a boldly outlined body, a
/// pentagon-and-dot device planted in every arm and a segmented rosette at
/// the hub. Its hues are *seeded* from the entity id — never random — so a
/// given vault, harness or model always spins the same unique blend around
/// its own entity colour. Only the tint and the rotation differ between
/// nodes, which is what makes each read as its own thing (spec §8.7).
///
/// Internal rather than file-private, because the 3D scene rasterises *this*
/// view into a texture and maps it onto a billboard. Rendering the actual
/// glyph rather than a second, hand-built 3D creature is the reason the deep
/// cannot drift away from the pool: there is only one sea-star, drawn twice.
struct SeaStarGlyph: View {
    let accent: Color
    let seed: Double
    let isActive: Bool

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let outer = side / 2
            let shape = SeaStarShape()
            let stops: [Gradient.Stop] = (0..<6).map { index in
                let location = Double(index) / 6
                return Gradient.Stop(
                    color: Self.shift(accent, by: seed / 6 + location * 0.4),
                    location: location
                )
            }
            ZStack {
                // The bloom sits behind the body: a bright core with a short,
                // feathered tail. The light burns hot and then falls away
                // quickly — the hazy, over-bright quality of a glow seen
                // through rubbed eyes, not a slow grey smear.
                Circle()
                    .fill(RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: Palette.bone.opacity(0.90), location: 0.0),
                            .init(color: accent.opacity(0.45), location: 0.28),
                            .init(color: accent.opacity(0.10), location: 0.58),
                            .init(color: accent.opacity(0.0), location: 1.0),
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: isActive ? outer * 1.15 : outer * 0.85
                    ))
                // Body: the seeded multicolour spun across the arms.
                shape.fill(
                    AngularGradient(
                        gradient: Gradient(stops: stops),
                        center: .center,
                        angle: .radians(seed)
                    )
                )
                // Iridescence: a low, additive nacre sheen so the arms catch
                // teal and mauve the way a living sea-star's skin does.
                shape.fill(
                    LinearGradient(
                        colors: [
                            Palette.teal.opacity(0.55),
                            Palette.mauve.opacity(0.30),
                            Palette.neonGreen.opacity(0.40),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.plusLighter)
                .opacity(0.45)
                // The brand's bold ink outline, then a fine parallel line just
                // inside it, so the rim reads as an inlaid double stroke rather
                // than a single hairline.
                shape.stroke(Palette.pool, lineWidth: max(1.3, side * 0.10))
                shape.stroke(Palette.bone.opacity(0.85), lineWidth: max(0.6, side * 0.03))
                shape.stroke(accent.opacity(0.9), lineWidth: max(0.4, side * 0.018))

                // The S_S_1 devices: pentagon-and-dot in every arm, and the
                // segmented rosette at the hub.
                armPentagons(outer: outer)
                    .stroke(Palette.bone.opacity(0.9), lineWidth: max(0.5, side * 0.026))
                armDots(outer: outer)
                    .fill(Palette.bone.opacity(0.95))
                hubRosette(outer: outer)
                    .fill(Palette.bone.opacity(0.92))
            }
            .rotationEffect(.radians(seed * 0.5))
        }
    }

    /// A regular pentagon planted mid-way along every arm, pointing outward —
    /// the device that gives the icon star its "shell in the leg" reading.
    private func armPentagons(outer: CGFloat) -> Path {
        var path = Path()
        let centre = CGPoint(x: outer, y: outer)
        let count = 8
        let step = 2 * CGFloat.pi / CGFloat(count)
        let start = -CGFloat.pi / 2
        let ring = outer * 0.46
        let size = outer * 0.17
        for index in 0..<count {
            let angle = start + CGFloat(index) * step
            let hub = CGPoint(x: centre.x + ring * cos(angle), y: centre.y + ring * sin(angle))
            path.addPath(pentagon(at: hub, radius: size, pointing: angle))
        }
        return path
    }

    /// A single dot near each arm's tip — the companion mark to the pentagon.
    private func armDots(outer: CGFloat) -> Path {
        var path = Path()
        let centre = CGPoint(x: outer, y: outer)
        let count = 8
        let step = 2 * CGFloat.pi / CGFloat(count)
        let start = -CGFloat.pi / 2
        let ring = outer * 0.72
        let dotR = outer * 0.055
        for index in 0..<count {
            let angle = start + CGFloat(index) * step
            let c = CGPoint(x: centre.x + ring * cos(angle), y: centre.y + ring * sin(angle))
            path.addEllipse(in: CGRect(x: c.x - dotR, y: c.y - dotR, width: dotR * 2, height: dotR * 2))
        }
        return path
    }

    /// The segmented rosette: a ring of small nubs around the hub, so the
    /// centre reads as a body rather than an intersection of spokes.
    private func hubRosette(outer: CGFloat) -> Path {
        var path = Path()
        let centre = CGPoint(x: outer, y: outer)
        let disc = outer * SeaStarShape().discRatio
        let ring = disc * 0.66
        let nubR = disc * 0.20
        let count = 8
        for index in 0..<count {
            let angle = -CGFloat.pi / 2 + CGFloat(index) * 2 * .pi / CGFloat(count)
            let c = CGPoint(x: centre.x + ring * cos(angle), y: centre.y + ring * sin(angle))
            path.addEllipse(in: CGRect(x: c.x - nubR, y: c.y - nubR, width: nubR * 2, height: nubR * 2))
        }
        return path
    }

    private func pentagon(at centre: CGPoint, radius: CGFloat, pointing angle: CGFloat) -> Path {
        var path = Path()
        for index in 0..<5 {
            let a = angle + CGFloat(index) * 2 * .pi / 5
            let point = CGPoint(x: centre.x + radius * cos(a), y: centre.y + radius * sin(a))
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    /// Rotate a colour's hue by `delta` (0…1 = a full turn), keeping its
    /// saturation and brightness. Gives the arm-to-arm shimmer its palette, and
    /// defers to the shared seed so the 3D spheres spin their hues the same way.
    private static func shift(_ color: Color, by delta: Double) -> Color {
        GraphSeed.shifted(color, by: delta)
    }
}

/// Catches the mouse for the pool — the wheel and the orbit buttons. A mouse has
/// no pinch, twist or trackpad, so without this the only way to zoom or turn
/// would be the trackpad. An app-local event monitor watches events while the
/// popover is open and, when the cursor is inside this view's own bounds:
///
/// * the wheel zooms *toward the cursor* (the point under the pointer stays put),
/// * a right- or middle-button drag spins the pool like an object in your hand,
/// * and the event is swallowed so nothing behind the graph reacts instead.
///
/// `hitTest` returns `nil`, so ordinary left-clicks and hovers still fall through
/// to the sea-stars beneath it. The monitor handler runs on the main thread but
/// must not touch main-actor AppKit state, so it reads only the cached
/// `screenBounds` and the static `NSEvent.mouseLocation`.
private struct GraphInputCatcher: NSViewRepresentable {
    var onZoom: (CGFloat, CGPoint) -> Void
    var onOrbit: (CGFloat) -> Void
    var onOrbitEnded: () -> Void

    func makeNSView(context: Context) -> CatcherView {
        let view = CatcherView()
        view.onZoom = onZoom
        view.onOrbit = onOrbit
        view.onOrbitEnded = onOrbitEnded
        return view
    }

    func updateNSView(_ nsView: CatcherView, context: Context) {
        nsView.onZoom = onZoom
        nsView.onOrbit = onOrbit
        nsView.onOrbitEnded = onOrbitEnded
        nsView.refreshFrame()
    }

    final class CatcherView: NSView {
        /// All `nonisolated(unsafe)` so the event-monitor closure can read them
        /// without hopping actors. They are only ever written on the main thread;
        /// the handler is also delivered on the main thread.
        nonisolated(unsafe) var onZoom: ((CGFloat, CGPoint) -> Void)?
        nonisolated(unsafe) var onOrbit: ((CGFloat) -> Void)?
        nonisolated(unsafe) var onOrbitEnded: (() -> Void)?
        nonisolated(unsafe) private var monitor: Any?
        nonisolated(unsafe) private var cachedWindow: NSWindow?
        /// This view's rect in *screen* coordinates, refreshed on layout, so the
        /// handler can locate the cursor without touching any main-actor state.
        nonisolated(unsafe) private var screenBounds: CGRect = .zero
        nonisolated(unsafe) private var lastOrbitX: CGFloat?

        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func layout() {
            super.layout()
            refreshFrame()
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            refreshFrame()
            guard window != nil else {
                if let monitor { NSEvent.removeMonitor(monitor) }
                monitor = nil
                return
            }
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(
                matching: [
                    .scrollWheel,
                    .rightMouseDown, .rightMouseDragged, .rightMouseUp,
                    .otherMouseDown, .otherMouseDragged, .otherMouseUp,
                ]
            ) { [weak self] event in
                guard let self,
                      let window = event.window,
                      window === self.cachedWindow,
                      self.screenBounds.contains(window.convertPoint(toScreen: event.locationInWindow)) else {
                    return event
                }
                let anchor = self.anchor(at: window.convertPoint(toScreen: event.locationInWindow))
                switch event.type {
                case .scrollWheel:
                    let delta = (event.hasPreciseScrollingDeltas ? 0.01 : 0.05)
                        * event.scrollingDeltaY
                    guard delta != 0 else { return event }
                    self.onZoom?(delta, anchor)
                    return nil
                case .rightMouseDown, .otherMouseDown:
                    self.lastOrbitX = anchor.x
                    return nil
                case .rightMouseDragged, .otherMouseDragged:
                    if let last = self.lastOrbitX { self.onOrbit?(anchor.x - last) }
                    self.lastOrbitX = anchor.x
                    return nil
                case .rightMouseUp, .otherMouseUp:
                    self.lastOrbitX = nil
                    self.onOrbitEnded?()
                    return nil
                default:
                    return event
                }
            }
        }

        /// The cursor position relative to this view's centre, in SwiftUI's
        /// top-left orientation — computed from cached geometry and the static
        /// mouse location so no main-actor AppKit call is needed.
        private func anchor(at mouse: NSPoint) -> CGPoint {
            CGPoint(
                x: (mouse.x - screenBounds.minX) - screenBounds.width / 2,
                y: screenBounds.height / 2 - (mouse.y - screenBounds.minY)
            )
        }

        func refreshFrame() {
            cachedWindow = window
            screenBounds = window.map { $0.convertToScreen(convert(bounds, to: nil)) } ?? .zero
        }

        deinit {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
    }
}

/// The starfield (spec §8.7): vaults, harnesses and models as glowing sea-stars
/// drifting in water. The majors — the vault and its harnesses — sit on the tips
/// of an N-pointed star, so four majors read as a four-pointed star, seven as
/// seven, and a faint star outline is traced behind them. Models ring the active
/// harness, and the active harness is joined to the vault by a nudibranch strip.
///
/// The whole pool is tactile: drag to drift it, pinch to zoom, twist to turn it
/// as if it were an object in your hand, and the recentre control tides it back.
/// The geometry is deterministic (seeded per node) and the orbs drift on their
/// own slow current; `reduceMotion` stills the pool.
struct EntityGraphView: View {
    let controller: ServerController
    /// The pool's height in points. The cockpit opens it taller for the visual
    /// reading than the text one would need, so the orbs and the tip note have room.
    var height: CGFloat = 190

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.seaStarCockpitOpen) private var isOpen
    @State private var hovered: String?
    @State private var selected: String?
    /// How far the connection ribbon has grown out of the vault, 0…1. Reset and
    /// re-run whenever the active harness changes, so the strip visibly *shoots*
    /// from the vault at the thing it just connected to.
    @State private var connectProgress: CGFloat = 0
    /// Whether the tip note is open beside the active starfish. Tapping that
    /// starfish expands and contracts it (spec §8.7).
    @State private var tipExpanded = true
    /// The entity the person has zoomed into with a double click (spec §8.7).
    /// While focused, its neighbourhood rings it and every unrelated star fades
    /// back, so the pool reads as *one* thing and what it touches rather than the
    /// whole field. `nil` is the normal, whole-pool reading.
    @State private var focused: String?
    /// Tap bookkeeping: a single click inspects, two in quick succession zoom in.
    /// Detected by hand so the first tap of a double never leaves a stray
    /// selection behind waiting on SwiftUI's paired tap gestures.
    @State private var lastTapID: String?
    @State private var lastTapTime = Date.distantPast

    /// The pool as an object you can hold: its pan, zoom and turn, with the
    /// committed resting values each gesture returns to.
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1
    @State private var rotation: Angle = .zero
    @State private var panBase: CGSize = .zero
    @State private var scaleBase: CGFloat = 1
    @State private var rotationBase: Angle = .zero

    /// How far the sea-star's arm tips stand off the pool's edge.
    private let starInset: CGFloat = 16

    var body: some View {
        Group {
            if reduceMotion || !isOpen {
                pool(at: 0, animated: false)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    pool(at: timeline.date.timeIntervalSinceReferenceDate, animated: true)
                }
            }
        }
        .frame(height: height)
        .background(backdrop)
        .overlay(alignment: .bottomLeading) { readout }
        .overlay(alignment: .topTrailing) { recentreControl }
        .overlay(alignment: .topLeading) { focusControl }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .overlay { inputCatcher }
        .gesture(
            panGesture
                .simultaneously(with: magnifyGesture)
                .simultaneously(with: rotateGesture)
        )
        .help(Strings.Views.panHint)
        .onAppear { growConnection() }
        .onChange(of: activeInferenceID) { _, _ in
            growConnection()
            tipExpanded = true
        }
    }

    /// The pool at one instant: the faint star outline, the connection ribbon,
    /// every node, and the tip note — all carried as one piece by the pan, zoom
    /// and turn, so the whole thing moves like an object.
    private func pool(at time: Double, animated: Bool) -> some View {
        GeometryReader { geo in
            let points = drifted(focusAwareLayout(in: geo.size), at: time, animated: animated)
            // Read once per frame and handed down, rather than asked of the model
            // inside each node and each wire: the model rebuilds its whole roster
            // on every question, and this view runs on a 30Hz clock. The pool's
            // geometry is already computed once above for the same reason.
            let liveNodes = Set(nodes.filter(\.isLive).map(\.id))
            let wires = model.standingEdges
            ZStack {
                starBackdrop(in: geo.size)
                    .opacity(focused == nil ? 1 : 0)
                if focused == nil {
                    wireLayer(wires, points, liveNodes: liveNodes, time: time, animated: animated)
                } else {
                    focusEdgeLayer(points, liveNodes: liveNodes)
                }
                ForEach(drawOrder) { node in
                    if let point = points[node.id] {
                        nodeView(node, at: point, time: time, animated: animated)
                    }
                }
                if focused == nil {
                    tipCallout(points, in: geo.size)
                }
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hovered = Self.hitNode(at: location, nodes: drawOrder, positions: points)?.id
                case .ended:
                    hovered = nil
                }
            }
            .scaleEffect(scale)
            .rotationEffect(rotation)
            .offset(offset)
            .animation(.spring(response: 0.42, dampingFraction: 0.82), value: focused)
        }
    }

    /// Each orb rides its own phase of the same current, so the pool never reads
    /// as a rigid grid sliding around.
    private func drifted(
        _ points: [String: CGPoint],
        at time: Double,
        animated: Bool
    ) -> [String: CGPoint] {
        guard animated else { return points }
        var result: [String: CGPoint] = [:]
        for (id, point) in points {
            let phase = GraphSeed.phase(for: id)
            result[id] = CGPoint(
                x: point.x + sin(time * 0.22 + phase) * 2.4,
                y: point.y + cos(time * 0.17 + phase * 1.3) * 2.0
            )
        }
        return result
    }

    /// A stable 0…2π phase from a node id, so the same entity always drifts the
    /// same way and nothing jitters between redraws. Also seeds each node's star
    /// colours and its own slight turn.
    ///
    /// Held in `GraphSeed` rather than here, because the 3D deep tints and
    /// jitters from the same seed. One entity must be the same creature in both
    /// bodies, not two things that happen to agree.
    private static func phase(for id: String) -> Double {
        GraphSeed.phase(for: id)
    }

    /// The side length of a node's glyph, by kind. One number, held here so the
    /// hover hit-test below and the drawing above cannot drift apart on how big a
    /// node is to land on.
    static func nodeSize(_ kind: GraphNode.Kind) -> CGFloat {
        switch kind {
        case .core: return 34
        case .model: return 17
        case .agent: return 21
        case .vault: return 27
        case .harness: return 23
        case .inference: return 23
        }
    }

    /// The node under a cursor point, if any. Walks the draw order top-down (last
    /// drawn is topmost) so overlapping satellites resolve to the one actually on
    /// top, and hits within a circle a touch wider than the glyph so a star is
    /// easy to land on. Pure and static so the rule can be tested without a
    /// window.
    static func hitNode(
        at point: CGPoint,
        nodes: [GraphNode],
        positions: [String: CGPoint]
    ) -> GraphNode? {
        for node in nodes.reversed() {
            guard let position = positions[node.id] else { continue }
            let radius = nodeSize(node.kind) / 2 + 2
            let dx = point.x - position.x
            let dy = point.y - position.y
            if dx * dx + dy * dy <= radius * radius {
                return node
            }
        }
        return nil
    }

    private func growConnection() {
        if reduceMotion {
            connectProgress = 1
        } else {
            connectProgress = 0
            withAnimation(.easeOut(duration: 0.5)) { connectProgress = 1 }
        }
    }

    // MARK: - Model

    /// The shared model. The 2D pool and the 3D deep read the *same* struct, so
    /// switching between them changes the drawing and the camera and nothing
    /// else. That is the whole point of pulling this out: there is no longer a
    /// second place where the roster can be described, and so no way for the two
    /// readings to drift apart and tell you different things.
    private var model: EntityGraphModel { EntityGraphModel(controller: controller) }

    private var nodes: [GraphNode] { model.nodes }

    /// The majors: everything that is not a satellite. These wear the star. A
    /// satellite is a model or an agent — a thing that orbits the active harness
    /// rather than a peer of the vault and its harnesses.
    private var majors: [GraphNode] { model.majors }

    private var activeInferenceID: String? { model.activeInferenceID }

    /// The node the card describes. A click or a hover wins, so inspecting
    /// something else still works; but with neither, this falls back to the
    /// active harness rather than nothing. The cockpit's whole point is knowing
    /// what is running without hunting for it, so the state is on screen the
    /// moment the popover opens.
    private var subject: GraphNode? {
        if let id = selected ?? hovered { return model.node(id) }
        return activeInferenceID.flatMap { model.node($0) }
    }

    /// The ids that belong to the focused neighbourhood — the focused node and
    /// everything directly bound to it. Empty when nothing is focused, so the
    /// whole-pool reading is untouched.
    private var focusSet: Set<String> {
        guard let focused else { return [] }
        return model.neighbours(of: focused).union([focused])
    }

    /// Nodes in draw order: the focused star last, so its glow and label sit over
    /// its neighbours rather than under them. Unchanged when nothing is focused.
    private var drawOrder: [GraphNode] {
        guard let focused else { return nodes }
        return nodes.filter { $0.id != focused } + nodes.filter { $0.id == focused }
    }

    /// Everything directly related to one entity, by id. Thinly forwarded to
    /// the shared model rather than re-derived here — the pool and the deep
    /// describe relationships from one place, so a focus reading in one and a
    /// focus reading in the other are the same company.
    private func neighbours(of id: String) -> Set<String> {
        model.neighbours(of: id)
    }

    // MARK: - Layout

    /// The major nodes stand on the tips of an N-pointed star, evenly around a
    /// circle — so the count of majors is the count of points. Models ring the
    /// active harness, pulled in toward the middle so they never clip the edge.
    ///
    /// Sea-Star holds the middle itself. It is the one place in the pool that is
    /// not a point on a ring, and it is placed before the ring so that adding it
    /// could not have shifted a single other body — the arrangement everything
    /// else has is untouched by the hub appearing in it.
    ///
    /// Internal rather than private, like `nodeSize` and `hitNode` above: where
    /// the pool puts each thing is a claim about the pool that both readings and
    /// the tests have to be able to check without opening a window.
    func layout(in size: CGSize) -> [String: CGPoint] {
        var points: [String: CGPoint] = [:]
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let outer = starOuterRadius(in: size)
        let majorNodes = majors

        points[EntityGraphModel.coreID] = centre

        for (index, node) in majorNodes.enumerated() {
            let angle = -Double.pi / 2
                + Double(index) / Double(max(majorNodes.count, 1)) * 2 * .pi
            points[node.id] = CGPoint(
                x: centre.x + outer * cos(angle),
                y: centre.y + outer * sin(angle)
            )
        }

        let anchor = nodes.first(where: { $0.id == activeInferenceID }) ?? majorNodes.first
        if let anchor, let tip = points[anchor.id] {
            // Sit the satellites between the active harness and the middle, so
            // they read as "what this harness offers" without spilling past the
            // star's edge. Models ride an inner ring; agents — the personas the
            // person built — ride a wider one around them.
            let hub = CGPoint(
                x: tip.x + (centre.x - tip.x) * 0.42,
                y: tip.y + (centre.y - tip.y) * 0.42
            )
            ring(nodes.filter { $0.kind == .model }, from: hub, radius: outer * 0.26, into: &points)
            ring(nodes.filter { $0.kind == .agent }, from: hub, radius: outer * 0.44, into: &points)
        }

        return points
    }

    /// Arrange one kind of satellite evenly on a ring around a hub; an empty set
    /// leaves the points untouched.
    private func ring(
        _ satellites: [GraphNode],
        from hub: CGPoint,
        radius: CGFloat,
        into points: inout [String: CGPoint]
    ) {
        guard !satellites.isEmpty else { return }
        for (index, node) in satellites.enumerated() {
            let angle = -Double.pi / 2
                + Double(index) / Double(satellites.count) * 2 * .pi
            points[node.id] = CGPoint(
                x: hub.x + radius * cos(angle),
                y: hub.y + radius * sin(angle)
            )
        }
    }

    /// The radius of the star's outer points — pushed right out to the pool's
    /// edge so the graphic reaches it, unlike the text reading's margins.
    private func starOuterRadius(in size: CGSize) -> CGFloat {
        max(min(size.width, size.height) / 2 - starInset, 24)
    }

    /// The whole-pool layout, reworked around a focus when there is one. When
    /// nothing is focused this is exactly the star.
    private func focusAwareLayout(in size: CGSize) -> [String: CGPoint] {
        var points = layout(in: size)
        if let focused, nodes.contains(where: { $0.id == focused }) {
            applyFocus(focused, in: size, into: &points)
        }
        return points
    }

    /// The focused reading's geometry: the focused star pulled to the middle with
    /// its neighbours rung around it, while every unrelated star keeps its place
    /// and simply fades — so the eye never loses where things were, and the pool
    /// still reads as the same object, only nearer. The drift and the pool's own
    /// zoom, turn and pan carry this layout like any other.
    private func applyFocus(
        _ focusID: String,
        in size: CGSize,
        into points: inout [String: CGPoint]
    ) {
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        points[focusID] = centre

        let near = nodes.map(\.id).filter { neighbours(of: focusID).contains($0) }
        let radius = starOuterRadius(in: size) * 0.52
        for (index, id) in near.enumerated() {
            let angle = -Double.pi / 2
                + Double(index) / Double(max(near.count, 1)) * 2 * .pi
            points[id] = CGPoint(
                x: centre.x + radius * cos(angle),
                y: centre.y + radius * sin(angle)
            )
        }
    }

    // MARK: - Layers

    /// The faint sea-star traced behind the pool. Its arms line up exactly with
    /// the major nodes — the same eight-armed silhouette the nodes wear, one huge
    /// — and hair-thin rays run from the middle out to each tip, so the
    /// arrangement reads as a sea-star even before you read a single node.
    @ViewBuilder
    private func starBackdrop(in size: CGSize) -> some View {
        let count = majors.count
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let outer = starOuterRadius(in: size)
        Canvas { context, _ in
            guard count >= 3 else { return }
            let rect = CGRect(
                x: centre.x - outer,
                y: centre.y - outer,
                width: outer * 2,
                height: outer * 2
            )
            // No wobble here: the outline's arms must land exactly on the nodes.
            let star = SeaStarShape(arms: count, wobble: 0).path(in: rect)
            context.stroke(star, with: .color(Palette.bone.opacity(0.07)), lineWidth: 1)

            var rays = Path()
            for index in 0..<count {
                let angle = -Double.pi / 2 + Double(index) / Double(count) * 2 * .pi
                rays.move(to: centre)
                rays.addLine(to: CGPoint(
                    x: centre.x + outer * cos(angle),
                    y: centre.y + outer * sin(angle)
                ))
            }
            context.stroke(rays, with: .color(Palette.mauve.opacity(0.05)), lineWidth: 1)
        }
    }

    /// Every wire the whole-pool reading draws: the ring's own bindings, and
    /// Sea-Star's.
    ///
    /// This is the layer the founder kept asking for. It used to draw exactly
    /// one ribbon — from the vault toward the endpoint currently being read —
    /// which meant that connecting an app to Sea-Star changed a *node* and never
    /// a *wire*: a new star appeared in the pool with nothing joining it to
    /// anything, and the picture sat still while the machine changed underneath
    /// it. A hub in the middle with wires into it is the whole point of the
    /// exercise.
    @ViewBuilder
    private func wireLayer(
        _ wires: [GraphEdge],
        _ points: [String: CGPoint],
        liveNodes: Set<String>,
        time: Double,
        animated: Bool
    ) -> some View {
        ForEach(wires) { edge in
            if let from = points[edge.from], let to = points[edge.to], from != to {
                wire(edge, from: from, to: to, liveNodes: liveNodes, time: time, animated: animated)
            }
        }
    }

    /// One wire, from one body to another.
    ///
    /// The orange-to-green art means one thing only, and it is the same claim the
    /// single ribbon always made: **something live is on this wire** — an app the
    /// engine recorded driving Sea-Star, or the endpoint it is reading right now.
    /// Being drawn at all earns nothing; a binding the report merely states stays
    /// cool blue-white wiring. The crawl is D-002's sweep, and it rides the frame
    /// clock the pool already runs on rather than any new timer.
    ///
    /// Sea-Star's own wires are drawn a touch heavier than the rest, because they
    /// are the reading the founder asked for rather than one of the ring's facts.
    @ViewBuilder
    private func wire(
        _ edge: GraphEdge,
        from: CGPoint,
        to: CGPoint,
        liveNodes: Set<String>,
        time: Double,
        animated: Bool
    ) -> some View {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let length = max(sqrt(dx * dx + dy * dy), 1)
        let touchesCore = edge.from == EntityGraphModel.coreID
            || edge.to == EntityGraphModel.coreID
        let isLive = liveNodes.contains(edge.from) || liveNodes.contains(edge.to)
        // The one ribbon that grows out of its end when the reading changes: the
        // link from the vault to the endpoint Sea-Star is reading through. The
        // rest are facts about the machine and are simply there.
        let isConnectionRibbon = activeInferenceID.map {
            (edge.from == "vault" && edge.to == $0) || (edge.to == "vault" && edge.from == $0)
        } ?? false
        let height: CGFloat = touchesCore ? 3 : 2
        let crawl = isLive && animated
            ? CGFloat((time * 0.35).truncatingRemainder(dividingBy: 1)) * length
            : 0
        let breath = animated ? 0.75 + 0.25 * (0.5 + 0.5 * sin(time * 0.9)) : 1
        NudiStrip(
            style: isLive ? .greenOrange : .blueWhite,
            height: height,
            expands: false
        )
            .frame(width: length * 2, height: height)
            .offset(x: -crawl)
            .frame(width: length, height: height, alignment: .leading)
            .clipped()
            .mask(alignment: .leading) {
                Rectangle().frame(width: length * (isConnectionRibbon ? connectProgress : 1))
            }
            .rotationEffect(.radians(atan2(dy, dx)))
            .position(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)
            .opacity(isLive ? breath : 0.7)
            .shadow(
                color: (isLive ? Palette.harnessGlow : Palette.electricBlue).opacity(0.5),
                radius: isLive ? 5 : 3
            )
    }

    /// The links out of a focused star: a nudibranch strip runs from it to each
    /// neighbour, so the reading shows not just *what* is near but *how* it is
    /// bound. A strip is an edge between two entities, drawn once per
    /// relationship the report knows.
    ///
    /// These read from the same `isLive` facts as the whole-pool layer, so a
    /// focus reading never flattens liveness: a wire to something that answered
    /// is the green-orange lit strip, a wire to something merely bound is the
    /// blue-white resting one. This layer used to draw every wire blue-white,
    /// which made a live connection and a dormant one indistinguishable the
    /// moment you clicked a star — the exact confusion the whole-pool reading
    /// had already solved.
    @ViewBuilder
    private func focusEdgeLayer(_ points: [String: CGPoint], liveNodes: Set<String>) -> some View {
        if let focused, let origin = points[focused] {
            ForEach(Array(neighbours(of: focused).sorted()), id: \.self) { id in
                if let target = points[id] {
                    let isLive = liveNodes.contains(id) || liveNodes.contains(focused)
                    let dx = target.x - origin.x
                    let dy = target.y - origin.y
                    let length = max(sqrt(dx * dx + dy * dy), 1)
                    NudiStrip(
                        style: isLive ? .greenOrange : .blueWhite,
                        height: isLive ? 3 : 2,
                        expands: false
                    )
                        .frame(width: length, height: isLive ? 3 : 2)
                        .rotationEffect(.radians(atan2(dy, dx)))
                        .position(x: (origin.x + target.x) / 2, y: (origin.y + target.y) / 2)
                        .opacity(isLive ? 0.95 : 0.7)
                        .shadow(
                            color: (isLive ? Palette.neonGreen : Palette.electricBlue).opacity(0.5),
                            radius: isLive ? 4 : 3
                        )
                }
            }
        }
    }

    /// The note that grows out of the active starfish (spec §8.7): a setting-up
    /// hint for a harness the person has never been on, a wrong-vault nudge, or
    /// the quiet "connected" line. Tapping that starfish contracts it.
    @ViewBuilder
    private func tipCallout(_ points: [String: CGPoint], in size: CGSize) -> some View {
        if let tip = controller.currentTip,
           let active = activeInferenceID,
           let point = points[active] {
            Group {
                if tipExpanded {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(tip.body)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Palette.bone)
                            .fixedSize(horizontal: false, vertical: true)
                        if tip.kind == .fresh {
                            Button(Strings.Tips.dismiss) { controller.rememberCurrentHarness() }
                                .buttonStyle(.plain)
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Palette.harnessGlow)
                        }
                    }
                    .padding(9)
                    .frame(width: 152, alignment: .leading)
                    .background(Palette.pool.opacity(0.94), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Palette.harnessGlow.opacity(0.45), lineWidth: 1)
                    )
                    .transition(.scale(scale: 0.65, anchor: .trailing).combined(with: .opacity))
                }
            }
            // Keep the note inside the pool: it rides just above the active
            // starfish, but is clamped so a harness out at any point of the star
            // can never push the note outside the clipped frame.
            .position(
                x: min(max(point.x - 98, 88), max(88, size.width - 168)),
                y: min(max(point.y - 26, 52), max(52, size.height - 12))
            )
            // The note stays upright and sharp even when the pool has been
            // turned or zoomed: it counters both, so its text is never resampled
            // by the pool's own transform.
            .scaleEffect(1 / max(scale, 0.01))
            .rotationEffect(.radians(-rotation.radians))
            .animation(.spring(response: 0.34, dampingFraction: 0.78), value: tipExpanded)
        }
    }

    private func nodeView(
        _ node: GraphNode,
        at point: CGPoint,
        time: Double,
        animated: Bool
    ) -> some View {
        let isActive = hovered == node.id || selected == node.id
        // In a focus reading, the focused star and its neighbours stay lit while
        // everything else recedes — so the pool reads as one thing and what it
        // touches, not a whole field.
        let isFocused = focused == node.id
        let inFocus = focused != nil && focusSet.contains(node.id)
        let faded = focused != nil && !inFocus
        let size = Self.nodeSize(node.kind)
        // A harness that is up but not answering stays dimmer than a connected
        // one: it exists, but it is driving nothing, and the eye should read that
        // at once. Unrelated stars, when something is focused, fade almost away.
        let unproven = node.rung.map { !$0.isAttached } ?? false
        // A harness that is up but not driving anything gets its own voice:
        // a real, steady glow a notch below the connected breath. Before this,
        // every non-live node took `glow = 0`, which drew a running IDE
        // pixel-identical to an app that never launched — the two rungs the
        // engine carefully told apart were flattened back into one grey by the
        // drawing. Steady, never pulsing: the breath is reserved for work, and
        // being up is not the same as carrying it.
        let isUpNotLive = !node.isLive && node.rung?.isUp == true
        let presence: Double = (unproven ? (isUpNotLive ? 0.72 : 0.5) : 1) * (faded ? 0.12 : 1)
        // A slow breath in the glow, each orb on its own phase. Only a node that
        // actually answered breathes — a still one is telling you nothing is on
        // its port, which is a fact, not a lack of decoration.
        let phase = Self.phase(for: node.id)
        let pulse = (animated && node.isLive) ? 0.5 + 0.5 * sin(time * 1.1 + phase) : 0.5
        // The tint is a *narrow* band either side of the kind's colour. It used
        // to be a quarter-turn, which was enough to turn a plum API endpoint red
        // and a teal local runtime blue — decoration eating the one distinction
        // the palette is carrying.
        let accent = GraphSeed.shifted(node.accent, by: GraphSeed.hue(for: node.id) * 0.06)
        let glow: Double = if isActive {
            0.95
        } else if node.isLive {
            0.35 + 0.3 * pulse
        } else if isUpNotLive {
            0.34
        } else {
            0
        }
        let glyph = SeaStarGlyph(accent: accent, seed: phase, isActive: isActive || node.isLive || isUpNotLive)
            .frame(width: size, height: size)
            .shadow(
                color: accent.opacity(glow * presence),
                radius: isActive ? 10 : (node.isLive ? 4 + 3 * pulse : (isUpNotLive ? 5 : 1))
            )

        return Group {
            if animated {
                glyph.caustics(size: size * 2)
            } else {
                glyph
            }
        }
        .opacity(presence)
        .scaleEffect(isFocused ? 1.7 : (isActive ? 1.25 : 1))
        .overlay(alignment: .bottom) {
            if isActive || inFocus {
                Text(node.title)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Palette.bone)
                    .lineLimit(1)
                    .fixedSize()
                    // Text drawn inside the pool would be resampled by the
                    // pool's zoom and turn, which is what made these labels look
                    // soft next to the card and the list. Countering both keeps
                    // the glyphs rendered at their own scale, so they stay sharp
                    // however the pool is held — and upright, always readable.
                    .scaleEffect(1 / max(scale, 0.01))
                    .rotationEffect(.radians(-rotation.radians))
                    .offset(y: size / 2 + 12)
            }
        }
        // Liveness is carried by the node's own glow — a live star breathes and
        // an idle one sits dim. The little green bar that used to float above
        // each live node is gone: the founder asked for those two floating
        // strips off more than once, and every session defended them instead of
        // removing them. They said nothing the glow did not already say.
        .position(point)
        .onTapGesture { handleTap(node) }
        .animation(.easeInOut(duration: 0.18), value: isActive)
    }

    private var backdrop: some View {
        GeometryReader { geo in
            ZStack {
                Palette.pool
                RadialGradient(
                    colors: [Palette.electricBlue.opacity(0.16), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 200
                )
                RadialGradient(
                    colors: [Palette.teal.opacity(0.14), .clear],
                    center: .leading,
                    startRadius: 0,
                    endRadius: 180
                )
            }
            // The void is water, not a fill: a fine grain drifts through it
            // behind the starfield, so the pool reads as alive at rest.
            .poolGrain(size: min(geo.size.width, geo.size.height))
        }
    }

    /// The card that blooms when a starfish is hovered or clicked (spec §8.7):
    /// the plain facts the engine already handed us, laid out so a node is
    /// inspectable at a glance. Nothing here needs a second call to the engine —
    /// it is all in the report we already hold. Empty until something is chosen.
    ///
    /// The card body itself is `GraphReadoutCard`, shared with the 3D scene, so
    /// the two renderings can never drift into showing different facts for the
    /// same entity. Only *where* the card sits is this view's business.
    @ViewBuilder
    private var readout: some View {
        if let subject {
            GraphReadoutCard(
                node: subject,
                rows: facts(for: subject),
                kindLabel: kindLabel(subject.kind)
            )
            .padding(9)
            .transition(.opacity)
        }
    }

    private func kindLabel(_ kind: GraphNode.Kind) -> String {
        model.kindLabel(kind)
    }

    /// What a clicked sea-star can tell you, all of it already in the report: a
    /// vault says how much is in it and how Sea-Star found it; a harness says its
    /// endpoint and how many models it serves; a model says which harness offers
    /// it. Ordered most-useful first, and rows that would say nothing are left out.
    ///
    /// Asked of the shared model, so hovering a star in the pool and hovering a
    /// sphere in the deep bring up the *same* card. Two renderings, one truth.
    private func facts(for node: GraphNode) -> [(label: String, value: String)] {
        model.facts(for: node)
    }

    // MARK: - Handling the object

    /// The control that appears once the pool has been moved, offering to tide it
    /// back to how it opened.
    @ViewBuilder
    private var recentreControl: some View {
        if isTransformed {
            Button(action: recentre) {
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
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
        }
    }

    /// The control that appears while a star is focused: it names what you are
    /// zoomed into and offers the way back out to the whole pool. Double-clicking
    /// the focused star does the same.
    @ViewBuilder
    private var focusControl: some View {
        if let focused, let node = nodes.first(where: { $0.id == focused }) {
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
                .background(Palette.pool.opacity(0.92), in: Capsule())
                .overlay(Capsule().stroke(node.accent.opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(Strings.Views.exitFocusHelp)
            .padding(9)
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
        }
    }

    private var isTransformed: Bool {
        offset != .zero || scale != 1 || rotation != .zero
    }

    /// Left-drag drifts the pool; ⌥-drag turns it, as a trackpad-free way to spin
    /// it by hand. (A right- or middle-drag also spins it — see `inputCatcher`.)
    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                if NSEvent.modifierFlags.contains(.option) {
                    rotation = rotationBase + .radians(Double(value.translation.width) * 0.006)
                } else {
                    offset = CGSize(
                        width: panBase.width + value.translation.width,
                        height: panBase.height + value.translation.height
                    )
                }
            }
            .onEnded { _ in
                if NSEvent.modifierFlags.contains(.option) {
                    rotationBase = rotation
                } else {
                    panBase = offset
                }
            }
    }

    /// The mouse input a trackpad gets for free. The wheel zooms *toward the
    /// cursor*, so the point under the pointer stays put, and a right- or
    /// middle-drag spins the whole pool like an object in your hand. Kept inert
    /// to clicks so it never stands between the cursor and a sea-star.
    private var inputCatcher: some View {
        GraphInputCatcher(
            onZoom: { delta, anchor in
                let next = min(max(scale * (1 + delta), 0.55), 2.6)
                let k = next / scale
                // Hold the cursor's point still: newOffset = anchor − k·(anchor − offset).
                offset = CGSize(
                    width: anchor.x - k * (anchor.x - offset.width),
                    height: anchor.y - k * (anchor.y - offset.height)
                )
                scale = next
                scaleBase = next
                panBase = offset
            },
            onOrbit: { dx in
                rotation += .radians(Double(dx) * 0.006)
            },
            onOrbitEnded: { rotationBase = rotation }
        )
        .allowsHitTesting(false)
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(scaleBase * value.magnification, 0.55), 2.6)
            }
            .onEnded { _ in scaleBase = scale }
    }

    private var rotateGesture: some Gesture {
        RotateGesture()
            .onChanged { value in
                rotation = rotationBase + value.rotation
            }
            .onEnded { _ in rotationBase = rotation }
    }

    private func recentre() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            offset = .zero
            scale = 1
            rotation = .zero
        }
        panBase = .zero
        scaleBase = 1
        rotationBase = .zero
    }

    // MARK: - Selection

    /// One click inspects a star; two in quick succession zoom into it. The
    /// second tap of a double is caught here by hand — SwiftUI's paired
    /// `onTapGesture(count:)` makes the first click wait on a second that may
    /// never come, which reads as lag on a field you are meant to feel.
    private func handleTap(_ node: GraphNode) {
        let now = Date()
        let isDouble = node.id == lastTapID
            && now.timeIntervalSince(lastTapTime) < 0.32
        lastTapID = node.id
        lastTapTime = now

        if isDouble {
            if focused == node.id {
                unfocus()
            } else {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                    focused = node.id
                    selected = node.id
                    tipExpanded = false
                }
            }
            return
        }

        // The active starfish keeps its own tap: it opens and closes the tip
        // note that grows beside it.
        if node.id == activeInferenceID {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                tipExpanded.toggle()
            }
        }
        select(node)
    }

    /// Tide back out to the whole pool. Double-clicking the focused star does
    /// the same, so the exit is never more than a click away.
    private func unfocus() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            focused = nil
        }
        lastTapID = nil
    }

    private func select(_ node: GraphNode) {
        selected = node.id
        switch node.kind {
        case .core:
            // Sea-Star is the one thing in the pool that is not a knob. There is
            // nothing to switch to: it is already the reader, and clicking it
            // opens its card like any other node.
            break
        case .vault:
            if let path = node.subtitle { controller.selectVault(path) }
        case .inference:
            if let baseURL = node.subtitle { controller.selectInference(baseURL) }
        case .model:
            controller.selectModel(node.title)
        case .harness:
            // A harness is inspectable, not drivable from here: the app cannot
            // make an app attach itself, so clicking one just opens its readout
            // and says which rung it reached.
            break
        case .agent:
            // An agent is a persona to inspect, not yet a knob to turn: the
            // engine reports the roster but the app does not drive a harness's
            // agents, so clicking one just opens its readout.
            break
        }
    }
}
