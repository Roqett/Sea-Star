import SwiftUI

/// A slow caustic shimmer for the header mark, so the face reads as living water
/// rather than a sticker (spec §7). The effect is header-only: the menu-bar glyph
/// stays a flat, template-tinted glyph, where any motion would just be noise.
///
/// Motion is the point, but not at the cost of accessibility — `reduceMotion`
/// turns it off and leaves the plain tinted mark.
private struct CausticsEffect: ViewModifier {
    let size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.seaStarCockpitOpen) private var isOpen

    func body(content: Content) -> some View {
        if reduceMotion || !isOpen {
            content
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                content.colorEffect(
                    Shader(
                        function: ShaderFunction(library: .default, name: "caustics"),
                        arguments: [
                            .float(timeline.date.timeIntervalSinceReferenceDate),
                            .float(Float(size)),
                        ]
                    )
                )
            }
        }
    }
}

extension View {
    /// Applies the header's caustic shimmer. `size` is the mark's side length in
    /// points, which sets the scale of the shimmer.
    func caustics(size: CGFloat) -> some View {
        modifier(CausticsEffect(size: size))
    }
}
