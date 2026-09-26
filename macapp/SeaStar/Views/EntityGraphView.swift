import AppKit
import SwiftUI

/// One thing in the rockpool: a vault, a harness, or a model.
private struct GraphNode: Identifiable {
    enum Kind { case vault, harness, model }

    let id: String
    let kind: Kind
    let title: String
    let subtitle: String?
    let accent: Color
}

/// A plain star polygon — `arms` outer points on a circle with `arms` valleys
/// pulled in between them. The same shape draws both the faint outline behind
/// the pool and, five-armed, the mark each entity wears.
private struct StarShape: Shape {
    var arms: Int
    var innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        let total = max(arms, 3) * 2
        for index in 0..<total {
            let radius = index.isMultiple(of: 2) ? outer : inner
            let angle = -Double.pi / 2 + Double(index) / Double(total) * 2 * .pi
            let point = CGPoint(
                x: centre.x + radius * cos(angle),
                y: centre.y + radius * sin(angle)
            )
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

/// The multicoloured star a single entity wears. Its hues are *seeded* from the
/// entity id — never random — so a given vault, harness or model always spins the
/// same unique blend around its own entity colour. The structure stays a plain
/// five-armed sea-star; only the tint and its rotation differ, which is what makes
/// each node read as its own thing rather than a copy (spec §8.7).
private struct SeaStarGlyph: View {
    let accent: Color
    let seed: Double
    let isActive: Bool

    var body: some View {
        let shape = StarShape(arms: 5, innerRatio: 0.42)
        let stops: [Gradient.Stop] = (0..<6).map { index in
            let location = Double(index) / 6
            return Gradient.Stop(
                color: Self.shift(accent, by: seed / 6 + location * 0.4),
                location: location
            )
        }
        ZStack {
            shape.fill(
                AngularGradient(
                    gradient: Gradient(stops: stops),
                    center: .center,
                    angle: .radians(seed)
                )
            )
            shape.stroke(accent.opacity(0.9), lineWidth: 0.8)
            Circle()
                .fill(RadialGradient(
                    colors: [Palette.bone.opacity(0.95), accent.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: isActive ? 7 : 4.5
                ))
        }
        .rotationEffect(.radians(seed * 0.5))
    }

    /// Rotate a colour's hue by `delta` (0…1 = a full turn), keeping its
    /// saturation and brightness. Gives the arm-to-arm shimmer its palette.
    private static func shift(_ color: Color, by delta: Double) -> Color {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? .white
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        ns.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        var shifted = (hue + CGFloat(delta)).truncatingRemainder(dividingBy: 1)
        if shifted < 0 { shifted += 1 }
        return Color(
            hue: Double(shifted),
            saturation: Double(saturation),
            brightness: Double(min(1, brightness * 1.06)),
            opacity: Double(alpha)
        )
    }
}

/// Catches the scroll wheel for the pool. A mouse has no pinch or twist, so
/// without this the only way to zoom would be the trackpad. An app-local event
/// monitor watches scroll events while the popover is open and, when the cursor
/// is inside this view's own bounds, turns the wheel into zoom and swallows the
/// event so nothing behind the graph scrolls instead. `hitTest` returns `nil`,
/// so clicks and hovers still fall through to the sea-stars beneath it.
private struct GraphScrollCatcher: NSViewRepresentable {
    var onZoom: (CGFloat) -> Void

    func makeNSView(context: Context) -> CatcherView {
        let view = CatcherView()
        view.onZoom = onZoom
        return view
    }

    func updateNSView(_ nsView: CatcherView, context: Context) {
        nsView.onZoom = onZoom
        nsView.refreshFrame()
    }

    final class CatcherView: NSView {
        /// All three are `nonisolated(unsafe)` so the event-monitor closure can
        /// read them without hopping actors. They are only ever written on the
        /// main thread; the handler is also delivered on the main thread.
        nonisolated(unsafe) var onZoom: ((CGFloat) -> Void)?
        nonisolated(unsafe) private var monitor: Any?
        nonisolated(unsafe) private var cachedWindow: NSWindow?
        /// This view's rect in *screen* coordinates, refreshed on layout, so the
        /// handler can test the cursor against `NSEvent.mouseLocation` without
        /// touching any main-actor state.
        nonisolated(unsafe) private var screenBounds: CGRect = .zero

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
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
                guard let self,
                      event.window === self.cachedWindow,
                      self.screenBounds.contains(NSEvent.mouseLocation) else {
                    return event
                }
                let delta = (event.hasPreciseScrollingDeltas ? 0.01 : 0.05)
                    * event.scrollingDeltaY
                guard delta != 0 else { return event }
                self.onZoom?(delta)
                return nil
            }
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
    @State private var hovered: String?
    @State private var selected: String?
    /// How far the connection ribbon has grown out of the vault, 0…1. Reset and
    /// re-run whenever the active harness changes, so the strip visibly *shoots*
    /// from the vault at the thing it just connected to.
    @State private var connectProgress: CGFloat = 0
    /// Whether the tip note is open beside the active starfish. Tapping that
    /// starfish expands and contracts it (spec §8.7).
    @State private var tipExpanded = true

    /// The pool as an object you can hold: its pan, zoom and turn, with the
    /// committed resting values each gesture returns to.
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1
    @State private var rotation: Angle = .zero
    @State private var panBase: CGSize = .zero
    @State private var scaleBase: CGFloat = 1
    @State private var rotationBase: Angle = .zero

    /// How far the star's points stand off the pool's edge, and how deep its
    /// valleys cut between them.
    private let starInset: CGFloat = 16
    private let starInnerRatio: CGFloat = 0.42

    var body: some View {
        Group {
            if reduceMotion {
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
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .overlay { scrollCatcher }
        .gesture(
            panGesture
                .simultaneously(with: magnifyGesture)
                .simultaneously(with: rotateGesture)
        )
        .help(Strings.Views.panHint)
        .onAppear { growConnection() }
        .onChange(of: activeHarnessID) { _, _ in
            growConnection()
            tipExpanded = true
        }
    }

    /// The pool at one instant: the faint star outline, the connection ribbon,
    /// every node, and the tip note — all carried as one piece by the pan, zoom
    /// and turn, so the whole thing moves like an object.
    private func pool(at time: Double, animated: Bool) -> some View {
        GeometryReader { geo in
            let points = drifted(layout(in: geo.size), at: time, animated: animated)
            ZStack {
                starBackdrop(in: geo.size)
                connectionLayer(points, time: time, animated: animated)
                ForEach(nodes) { node in
                    if let point = points[node.id] {
                        nodeView(node, at: point, time: time, animated: animated)
                    }
                }
                tipCallout(points, in: geo.size)
            }
            .scaleEffect(scale)
            .rotationEffect(rotation)
            .offset(offset)
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
            let phase = Self.phase(for: id)
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
    private static func phase(for id: String) -> Double {
        var hash: UInt64 = 1469598103934665603
        for byte in id.utf8 { hash = (hash ^ UInt64(byte)) &* 1099511628211 }
        return Double(hash % 6283) / 1000.0
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

    private var nodes: [GraphNode] {
        var nodes: [GraphNode] = []
        if let vault = controller.report?.vault.path {
            nodes.append(GraphNode(
                id: "vault",
                kind: .vault,
                title: (vault as NSString).lastPathComponent,
                subtitle: vault,
                accent: Palette.vaultGlow
            ))
        }
        for harness in controller.harnessOptions {
            nodes.append(GraphNode(
                id: "harness:\(harness.baseURL)",
                kind: .harness,
                title: harness.name,
                subtitle: harness.baseURL,
                accent: Palette.harnessGlow
            ))
        }
        for model in controller.modelOptions {
            nodes.append(GraphNode(
                id: "model:\(model)",
                kind: .model,
                title: model,
                subtitle: nil,
                accent: Palette.modelGlow
            ))
        }
        return nodes
    }

    /// The majors: everything that is not a satellite model. These wear the star.
    private var majors: [GraphNode] {
        nodes.filter { $0.kind != .model }
    }

    private var activeHarnessID: String? {
        controller.report.map { "harness:\($0.baseURL)" }
    }

    private var subject: GraphNode? {
        guard let id = hovered ?? selected else { return nil }
        return nodes.first { $0.id == id }
    }

    // MARK: - Layout

    /// The major nodes stand on the tips of an N-pointed star, evenly around a
    /// circle — so the count of majors is the count of points. Models ring the
    /// active harness, pulled in toward the middle so they never clip the edge.
    private func layout(in size: CGSize) -> [String: CGPoint] {
        var points: [String: CGPoint] = [:]
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let outer = starOuterRadius(in: size)
        let majorNodes = majors

        for (index, node) in majorNodes.enumerated() {
            let angle = -Double.pi / 2
                + Double(index) / Double(max(majorNodes.count, 1)) * 2 * .pi
            points[node.id] = CGPoint(
                x: centre.x + outer * cos(angle),
                y: centre.y + outer * sin(angle)
            )
        }

        let models = nodes.filter { $0.kind == .model }
        let anchor = nodes.first(where: { $0.id == activeHarnessID }) ?? majorNodes.first
        if let anchor, let tip = points[anchor.id], !models.isEmpty {
            // Sit the model constellation between the active harness and the
            // middle, so it reads as "what this harness offers" without spilling
            // past the star's edge.
            let hub = CGPoint(
                x: tip.x + (centre.x - tip.x) * 0.42,
                y: tip.y + (centre.y - tip.y) * 0.42
            )
            let radius = outer * 0.26
            for (index, model) in models.enumerated() {
                let angle = -Double.pi / 2
                    + Double(index) / Double(models.count) * 2 * .pi
                points[model.id] = CGPoint(
                    x: hub.x + radius * cos(angle),
                    y: hub.y + radius * sin(angle)
                )
            }
        }

        return points
    }

    /// The radius of the star's outer points — pushed right out to the pool's
    /// edge so the graphic reaches it, unlike the text reading's margins.
    private func starOuterRadius(in size: CGSize) -> CGFloat {
        max(min(size.width, size.height) / 2 - starInset, 24)
    }

    // MARK: - Layers

    /// The faint star traced behind the pool. Its points line up exactly with the
    /// major nodes, and hair-thin rays run from the middle out to each point, so
    /// the arrangement reads as a star even before you read a single node.
    @ViewBuilder
    private func starBackdrop(in size: CGSize) -> some View {
        let count = majors.count
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let outer = starOuterRadius(in: size)
        let inner = outer * starInnerRatio
        Canvas { context, _ in
            guard count >= 3 else { return }
            var star = Path()
            let total = count * 2
            for index in 0..<total {
                let radius = index.isMultiple(of: 2) ? outer : inner
                let angle = -Double.pi / 2 + Double(index) / Double(total) * 2 * .pi
                let point = CGPoint(
                    x: centre.x + radius * cos(angle),
                    y: centre.y + radius * sin(angle)
                )
                if index == 0 { star.move(to: point) } else { star.addLine(to: point) }
            }
            star.closeSubpath()
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

    @ViewBuilder
    private func connectionLayer(
        _ points: [String: CGPoint],
        time: Double,
        animated: Bool
    ) -> some View {
        if let vault = points["vault"],
           let active = activeHarnessID,
           let target = points[active],
           vault != target {
            let dx = target.x - vault.x
            let dy = target.y - vault.y
            let length = max(sqrt(dx * dx + dy * dy), 1)
            NudiStrip(style: .blueWhite, height: 3, expands: false)
                .frame(width: length, height: 3)
                // Reveal from the vault end, so the ribbon grows *out of* the
                // vault toward the harness it just connected to.
                .mask(alignment: .leading) {
                    Rectangle().frame(width: length * connectProgress)
                }
                .rotationEffect(.radians(atan2(dy, dx)))
                .position(x: (vault.x + target.x) / 2, y: (vault.y + target.y) / 2)
                .opacity(animated ? 0.8 + 0.2 * (0.5 + 0.5 * sin(time * 0.9)) : 1)
                .shadow(color: Palette.harnessGlow.opacity(0.6), radius: 5)
        }
    }

    /// The note that grows out of the active starfish (spec §8.7): a setting-up
    /// hint for a harness the person has never been on, a wrong-vault nudge, or
    /// the quiet "connected" line. Tapping that starfish contracts it.
    @ViewBuilder
    private func tipCallout(_ points: [String: CGPoint], in size: CGSize) -> some View {
        if let tip = controller.currentTip,
           let active = activeHarnessID,
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
            // The note stays upright and legible even when the pool has been
            // turned on its side.
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
        let size: CGFloat = node.kind == .model ? 17 : (node.kind == .vault ? 27 : 23)
        // A slow breath in the glow, each orb on its own phase.
        let phase = Self.phase(for: node.id)
        let pulse = animated ? 0.5 + 0.5 * sin(time * 1.1 + phase) : 0.5
        let glyph = SeaStarGlyph(accent: node.accent, seed: phase, isActive: isActive)
            .frame(width: size, height: size)
            .shadow(
                color: node.accent.opacity(isActive ? 0.95 : 0.35 + 0.3 * pulse),
                radius: isActive ? 10 : 4 + 3 * pulse
            )

        return Group {
            if animated {
                glyph.caustics(size: size * 2)
            } else {
                glyph
            }
        }
        .scaleEffect(isActive ? 1.25 : 1)
        .overlay(alignment: .bottom) {
            if isActive {
                Text(node.title)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Palette.bone)
                    .lineLimit(1)
                    .fixedSize()
                    .offset(y: size / 2 + 12)
            }
        }
        .position(point)
        .onHover { hovering in
            if hovering { hovered = node.id }
            else if hovered == node.id { hovered = nil }
        }
        .onTapGesture {
            if node.id == activeHarnessID {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                    tipExpanded.toggle()
                }
            } else {
                select(node)
                tipExpanded = true
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isActive)
    }

    private var backdrop: some View {
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
    }

    /// The card that blooms when a starfish is hovered or clicked (spec §8.7):
    /// the plain facts the engine already handed us, laid out so a node is
    /// inspectable at a glance. Nothing here needs a second call to the engine —
    /// it is all in the report we already hold. Empty until something is chosen.
    @ViewBuilder
    private var readout: some View {
        if let subject {
            let rows = facts(for: subject)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(kindLabel(subject.kind).uppercased())
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(subject.accent)
                    Text(subject.title)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Palette.bone)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                if !rows.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(row.label)
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(Palette.mauve)
                                    .frame(width: 56, alignment: .leading)
                                Text(row.value)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(Palette.bone.opacity(0.92))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(width: 240, alignment: .leading)
            .background(Palette.pool.opacity(0.94), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(subject.accent.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 7, y: 2)
            .padding(9)
            .transition(.opacity)
        }
    }

    private func kindLabel(_ kind: GraphNode.Kind) -> String {
        switch kind {
        case .vault: return Strings.Detail.vault
        case .harness: return Strings.Detail.harness
        case .model: return Strings.Detail.model
        }
    }

    /// What a clicked sea-star can tell you, all of it already in the report: a
    /// vault says how much is in it and how Sea-Star found it; a harness says its
    /// endpoint and how many models it serves; a model says which harness offers
    /// it. Ordered most-useful first, and rows that would say nothing are left out.
    private func facts(for node: GraphNode) -> [(label: String, value: String)] {
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
            if let path = node.subtitle {
                rows.append((Strings.Detail.path, path))
            }
            return rows

        case .harness:
            var rows: [(label: String, value: String)] = [
                (Strings.Detail.endpoint, node.subtitle ?? Strings.States.unknown),
            ]
            if let harness = controller.harnessOptions
                .first(where: { "harness:\($0.baseURL)" == node.id }) {
                rows.append((
                    Strings.Detail.models,
                    Strings.Detail.modelCount(harness.models.count)
                ))
            }
            rows.append((
                Strings.Detail.status,
                node.id == activeHarnessID ? Strings.Detail.current : Strings.Detail.available
            ))
            return rows

        case .model:
            var rows: [(label: String, value: String)] = []
            let servers = controller.harnessOptions
                .filter { $0.models.contains(node.title) }
                .map(\.name)
            if !servers.isEmpty {
                rows.append((Strings.Detail.servedBy, servers.joined(separator: ", ")))
            }
            rows.append((
                Strings.Detail.status,
                node.title == report.model ? Strings.Detail.current : Strings.Detail.available
            ))
            return rows
        }
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

    private var isTransformed: Bool {
        offset != .zero || scale != 1 || rotation != .zero
    }

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

    /// Mouse zoom. Trackpads have pinch, but a mouse has only the wheel, so the
    /// wheel scales the pool the same way. Kept inert to clicks so it never
    /// stands between the cursor and a sea-star.
    private var scrollCatcher: some View {
        GraphScrollCatcher { delta in
            let next = min(max(scale * (1 + delta), 0.55), 2.6)
            scale = next
            scaleBase = next
        }
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

    private func select(_ node: GraphNode) {
        selected = node.id
        switch node.kind {
        case .vault:
            if let path = node.subtitle { controller.selectVault(path) }
        case .harness:
            if let baseURL = node.subtitle { controller.selectHarness(baseURL) }
        case .model:
            controller.selectModel(node.title)
        }
    }
}
