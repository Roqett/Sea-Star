import SwiftUI

/// The card that blooms when a sea-star is hovered or clicked (spec §8.7): the
/// plain facts the engine already handed us, laid out so a node is inspectable
/// at a glance. Nothing here needs a second call to the engine — it is all in
/// the report we already hold.
///
/// Extracted from the 2D pool rather than copied into the 3D scene, because the
/// whole point of the shared `EntityGraphModel` is that the two renderings cannot
/// disagree. If hovering a star in the pool and hovering a sphere in the deep
/// drew two different cards, the second one would be a place for the ontology to
/// quietly fork. So both ask the *same* model for the *same* rows and lay them
/// out with this one view.
///
/// It is a plain value view with no knowledge of the scene behind it: the
/// renderer decides what a "node" is, and this only draws what it was told.
struct GraphReadoutCard: View {
    /// The entity being described.
    let node: GraphNode
    /// The already-resolved fact rows, from `EntityGraphModel.facts(for:)`.
    let rows: [(label: String, value: String)]
    /// The kind's display name, from `EntityGraphModel.kindLabel(_:)`.
    let kindLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(kindLabel.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(node.accent)
                Text(node.title)
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
                .stroke(node.accent.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 7, y: 2)
    }
}
