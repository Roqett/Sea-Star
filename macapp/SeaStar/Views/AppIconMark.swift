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
struct AppIconMark: View {
    let icon: AppIcon
    var size: CGFloat = 18

    var body: some View {
        if let name = icon.asset {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: icon.symbol)
                .font(.system(size: size))
        }
    }
}
