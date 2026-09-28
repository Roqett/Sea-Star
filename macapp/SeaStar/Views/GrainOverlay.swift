import SwiftUI

/// Lays the rockpool's grain into whatever it is applied to: the faint visual
/// snow of a dark-adapted eye, so the void behind the starfield reads as living
/// water rather than a flat fill (spec §7). The field is sparse and cool on
/// purpose — it must never lift the pool's black or compete with a node for
/// attention.
///
/// Motion is the point, but not at the cost of accessibility: `reduceMotion`
/// holds the grain still, keeping the texture while dropping the drift.
private struct GrainOverlay: ViewModifier {
    let size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content.colorEffect(grain(at: 0))
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
                content.colorEffect(grain(at: timeline.date.timeIntervalSinceReferenceDate))
            }
        }
    }

    private func grain(at time: Double) -> Shader {
        Shader(
            function: ShaderFunction(library: .default, name: "grain"),
            arguments: [.float(Float(time)), .float(Float(size))]
        )
    }
}

extension View {
    /// Lays the pool's drifting grain into this view. `size` is the pool's
    /// shorter side in points, which sets the speckle's scale.
    func poolGrain(size: CGFloat) -> some View {
        modifier(GrainOverlay(size: size))
    }
}
