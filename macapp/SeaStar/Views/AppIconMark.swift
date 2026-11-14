import AppKit
import SwiftUI

/// Draws one of the app's faces. Prefers the exported artwork when it exists and
/// falls back to the placeholder SF Symbol, so swapping in the real PNGs is a
/// data change, not a view change.
///
/// The art is monochrome — black ink whose detail lives in the alpha channel —
/// so it renders as a template on every surface. The menu bar takes the system's
/// tint for light/dark, and the header takes whichever accent `.foregroundStyle`
/// supplies. That is also what keeps the fine line art readable on the near-black
/// canvas: a template shows its shape, whereas the original black-on-clear art
/// would vanish. Raster art ignores `.font`, so `size` frames it explicitly.
///
/// The bare art is eight bare spokes around a rosette, which reads as a
/// snowflake. A solid band drawn partway out gives the mark a *body* — a fuzzy
/// centre inside a sea-star's disc, with the ray tips still free outside it — so
/// it stops reading as a snowflake's spokes without hardening into a cog.
struct AppIconMark: View {
    let icon: AppIcon
    var size: CGFloat = 18

    /// The band's geometry, both as fractions of the mark's side, so the header
    /// and the menu bar draw the same anatomy at any size. Chosen by eye against
    /// the alternatives: thinner and the ring thins away at menu-bar sizes,
    /// wider or further out and the mark starts to read as a cog, so 0.55 / 0.12
    /// keeps a definite body while leaving the ray tips free.
    static let bandDiameter: CGFloat = 0.55
    static let bandWidth: CGFloat = 0.12

    var body: some View {
        if let name = icon.asset {
            ZStack {
                Image(name)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                Circle()
                    .strokeBorder(lineWidth: size * Self.bandWidth)
                    .frame(width: size * Self.bandDiameter, height: size * Self.bandDiameter)
            }
            .frame(width: size, height: size)
        } else {
            Image(systemName: icon.symbol)
                .font(.system(size: size))
        }
    }

    /// The same mark as a template `NSImage`, for the menu bar, which AppKit draws
    /// itself rather than through SwiftUI (spec §7). The art is drawn in its own
    /// alpha and the band is stroked on top, then the whole thing is templated so
    /// the system tints it white on a dark bar and black on a light one.
    static func menuBarImage(for icon: AppIcon, side: CGFloat = 18) -> NSImage? {
        guard let name = icon.asset, let art = NSImage(named: name) else {
            let fallback = NSImage(systemSymbolName: icon.symbol, accessibilityDescription: Strings.MenuBar.label)
            fallback?.isTemplate = true
            return fallback
        }
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            art.draw(in: rect)
            let band = side * bandDiameter
            let inset = (side - band) / 2
            let ring = NSBezierPath(ovalIn: NSRect(x: inset, y: inset, width: band, height: band))
            ring.lineWidth = side * bandWidth
            NSColor.black.setStroke()
            ring.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }
}
