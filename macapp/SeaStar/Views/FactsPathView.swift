import SwiftUI

/// The facts & path window's content (founder, 2026-11-10): both readings of
/// the four rows in one scrollable panel. The popover keeps its toggle because
/// a compact panel reads better one way at a time; a resizable window has the
/// room to carry both, and seeing the column and the chain together — same
/// facts, two shapes — is the comparison the window exists for.
struct FactsPathView: View {
    let controller: ServerController

    var body: some View {
        ScrollView {
            CockpitPanel(
                controller: controller,
                layout: .constant(.facts),
                combined: true
            )
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Palette.canvas)
    }
}
