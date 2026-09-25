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
/// First pass: the geometry is deterministic (vault left, harnesses right,
/// models ringing the active harness) and the drift is still. Motion and
/// harness tips are the next slice; this proves the shape.
struct EntityGraphView: View {
    let controller: ServerController

    @State private var hovered: String?
    @State private var selected: String?

    private let margin: CGFloat = 30

    var body: some View {
        GeometryReader { geo in
            let points = layout(in: geo.size)
            ZStack {
                connectionLayer(points)
                ForEach(nodes) { node in
                    if let point = points[node.id] {
                        nodeView(node, at: point)
                    }
                }
            }
        }
        .frame(height: 190)
        .background(backdrop)
        .overlay(alignment: .bottomLeading) { readout }
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
    private func connectionLayer(_ points: [String: CGPoint]) -> some View {
        if let vault = points["vault"],
           let active = activeHarnessID,
           let target = points[active],
           vault != target {
            let dx = target.x - vault.x
            let dy = target.y - vault.y
            let length = max(sqrt(dx * dx + dy * dy), 1)
            NudiStrip(style: .blueWhite, height: 3, expands: false)
                .frame(width: length, height: 3)
                .rotationEffect(.radians(atan2(dy, dx)))
                .position(x: (vault.x + target.x) / 2, y: (vault.y + target.y) / 2)
                .shadow(color: Palette.harnessGlow.opacity(0.6), radius: 5)
        }
    }

    private func nodeView(_ node: GraphNode, at point: CGPoint) -> some View {
        let isActive = hovered == node.id || selected == node.id
        let size: CGFloat = node.kind == .model ? 11 : (node.kind == .vault ? 22 : 18)
        return Circle()
            .fill(RadialGradient(
                colors: [node.accent, node.accent.opacity(0.12)],
                center: .center,
                startRadius: 0,
                endRadius: size
            ))
            .overlay(Circle().stroke(node.accent.opacity(0.85), lineWidth: 1))
            .frame(width: size, height: size)
            .shadow(color: node.accent.opacity(isActive ? 0.95 : 0.5), radius: isActive ? 10 : 5)
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
            .onTapGesture { select(node) }
            .animation(.easeInOut(duration: 0.18), value: isActive)
    }

    private var backdrop: some View {
        ZStack {
            Palette.canvas
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
