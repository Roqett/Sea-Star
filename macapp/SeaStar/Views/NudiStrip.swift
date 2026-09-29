import SwiftUI

/// A nudibranch strip: the long, gradational colour ribbon lifted from sea-slug
/// photography. It is used as a hairline "wiring" rule — above and below the
/// controls as a column reference, as the edge of the log panel, and (in the
/// entity graph) as the stroke that links two entities.
///
/// The art is authored 3px tall. On screen at the popover's scale 2px reads
/// cleaner and less like a border, so `height` defaults to 2.
struct NudiStrip: View {
    /// The strips the founder has supplied so far. Named for their colours, not
    /// their file names — the files carry a `:` that plays badly with tooling.
    ///
    /// The two carry different meanings, and keeping them apart is what makes
    /// the second one readable at a glance:
    ///
    /// - `blueWhite` is **wiring** — rules, panel edges, chain links, and graph
    ///   edges. Cool, structural, says nothing about whether anything answered.
    /// - `greenOrange` is **liveness** — an endpoint that answered during the
    ///   latest read, or the ribbon toward one that did. Used in the graph and
    ///   in the liveness bar, nowhere else. A still, desaturated copy of it is
    ///   the idle state, so the colour is never the only thing carrying the
    ///   claim.
    enum Style: String, CaseIterable {
        case blueWhite = "NudiBlueWhite"
        case greenOrange = "NudiGreenOrange1"
        case greenOrangeAlt = "NudiGreenOrange2"
    }

    let style: Style
    var height: CGFloat = 2
    /// Whether the strip stretches to its container's width (rules, panel edges)
    /// or holds a fixed width the caller sets (the graph's connection stroke).
    var expands: Bool = true

    var body: some View {
        Image(style.rawValue)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fill)
            .frame(height: height)
            .frame(maxWidth: expands ? .infinity : nil)
            .clipped()
            .accessibilityHidden(true)
    }
}
