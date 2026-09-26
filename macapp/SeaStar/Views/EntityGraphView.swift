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

/// The starfield (spec §8.7): vaults, harnesses and models as glowing orbs
/// drifting in water, with the active harness joined to the vault by a
/// nudibranch strip — the ribbon literally shoots out at the thing it connects
/// to. Clicking a node selects it, which is what "making the connection" means.
///
/// The geometry is deterministic (vault left, harnesses right, models ringing the
/// active harness) and the orbs drift on their own slow current; `reduceMotion`
/// stills the whole pool. Harness tips are the next slice.
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

    private let margin: CGFloat = 30

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
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear { growConnection() }
        .onChange(of: activeHarnessID) { _, _ in
            growConnection()
            tipExpanded = true
        }
    }

    /// The pool at one instant: static geometry plus a slow, per-node drift so the
    /// orbs float rather than sit. `time` is seconds since the reference date.
    private func pool(at time: Double, animated: Bool) -> some View {
        GeometryReader { geo in
            let points = drifted(layout(in: geo.size), at: time, animated: animated)
            ZStack {
                connectionLayer(points, time: time, animated: animated)
                ForEach(nodes) { node in
                    if let point = points[node.id] {
                        nodeView(node, at: point, time: time, animated: animated)
                    }
                }
                tipCallout(points)
            }
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
    /// same way and nothing jitters between redraws.
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

    private var activeHarnessID: String? {
        controller.report.map { "harness:\($0.baseURL)" }
    }

    private var subject: GraphNode? {
        guard let id = hovered ?? selected else { return nil }
        return nodes.first { $0.id == id }
    }

    // MARK: - Layout

    private func layout(in size: CGSize) -> [String: CGPoint] {
        var points: [String: CGPoint] = [:]

        if nodes.contains(where: { $0.kind == .vault }) {
            points["vault"] = CGPoint(x: margin + 12, y: size.height / 2)
        }

        let harnesses = nodes.filter { $0.kind == .harness }
        for (index, harness) in harnesses.enumerated() {
            let t = harnesses.count == 1
                ? 0.5
                : CGFloat(index) / CGFloat(harnesses.count - 1)
            let y = margin + t * (size.height - 2 * margin)
            points[harness.id] = CGPoint(x: size.width - margin - 12, y: y)
        }

        let models = nodes.filter { $0.kind == .model }
        let anchor = nodes.first(where: { $0.id == activeHarnessID })
            ?? harnesses.first
        if let anchor, let centre = points[anchor.id] {
            let radius: CGFloat = 26
            for (index, model) in models.enumerated() {
                let angle = (Double(index) / Double(max(models.count, 1))) * 2 * .pi - .pi / 2
                points[model.id] = CGPoint(
                    x: centre.x - 34 + radius * cos(angle),
                    y: centre.y + radius * sin(angle)
                )
            }
        }

        return points
    }

    // MARK: - Layers

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
    private func tipCallout(_ points: [String: CGPoint]) -> some View {
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
            // starfish, but is clamped so a harness near the top edge (or the
            // left edge) can never push the note outside the clipped frame.
            .position(x: max(point.x - 98, 88), y: max(point.y - 26, 52))
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
        let size: CGFloat = node.kind == .model ? 11 : (node.kind == .vault ? 22 : 18)
        // A slow breath in the glow, each orb on its own phase.
        let pulse = animated ? 0.5 + 0.5 * sin(time * 1.1 + Self.phase(for: node.id)) : 0.5
        let orb = Circle()
            .fill(RadialGradient(
                colors: [node.accent, node.accent.opacity(0.12)],
                center: .center,
                startRadius: 0,
                endRadius: size
            ))
            .overlay(Circle().stroke(node.accent.opacity(0.85), lineWidth: 1))
            .frame(width: size, height: size)
            .shadow(
                color: node.accent.opacity(isActive ? 0.95 : 0.35 + 0.3 * pulse),
                radius: isActive ? 10 : 4 + 3 * pulse
            )

        return Group {
            if animated {
                orb.caustics(size: size * 2)
            } else {
                orb
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

    /// The name at the bottom of the pool — what a click in a codebase graph
    /// would surface. Empty until something is hovered or chosen.
    @ViewBuilder
    private var readout: some View {
        if let subject {
            Text(subject.subtitle ?? subject.title)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Palette.mauve)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
        }
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
