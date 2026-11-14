import SwiftUI

/// A liveness bar: the nudibranch ribbon, lit and moving when something was
/// actually reached, still when it was not.
///
/// The art is the founder's own `NudiGreenOrange` strips, so the bar inherits
/// the orange-to-green gradient of the animal rather than inventing a new one.
/// Two states, and the difference between them is the whole point of the bar:
///
/// - **live** — a probe answered this endpoint during the last read, so the
///   gradient drifts along its length. "Live" here means *answering*, and
///   nothing more. It never means a person used it.
/// - **idle** — nothing answered. The bar is drawn desaturated and still, so a
///   still bar is a fact rather than a style choice.
///
/// Motion is the point, so it animates — but never at the cost of
/// accessibility. Under **Reduce Motion** the gradient holds its position and
/// the bar keeps its colour: the state is still readable, only the drift stops.
/// The drift also runs only while the cockpit reading is on screen; closed,
/// the bar holds still (spec §8).
struct LivenessBar: View {
    /// Whether the thing this bar describes was proven reachable.
    let isLive: Bool
    /// How many bars to draw in the row. One for a single endpoint, more where
    /// several are being shown together.
    var count: Int = 1
    var height: CGFloat = 3
    /// Staggers the drift so a row of bars does not move as one solid block.
    var seed: Int = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.seaStarCockpitOpen) private var isOpen
    @State private var drift: CGFloat = -1

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<max(1, count), id: \.self) { index in
                strip(index)
            }
        }
        .onAppear { startDrift() }
        .onChange(of: isLive) { _, _ in startDrift() }
        .onChange(of: isOpen) { _, _ in startDrift() }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func strip(_ index: Int) -> some View {
        // A live bar is the vivid strip, slid along a track so the gradient
        // appears to crawl. An idle one is the same art greyed and dimmed, so
        // the two read as one family rather than two unrelated marks.
        NudiStrip(style: .greenOrange, height: height)
            .saturation(isLive ? 1 : 0.15)
            .opacity(isLive ? 0.95 : 0.4)
            .scaleEffect(x: 2.0, anchor: .leading)
            .offset(x: offset(for: index))
            .frame(maxWidth: .infinity)
            .clipped()
            .animation(
                reduceMotion || !isOpen
                    ? nil : .easeInOut(duration: 0.55).repeatForever(autoreverses: true),
                value: drift
            )
    }

    /// Each bar sits at a different point in its travel, and that point is
    /// derived from the index so a row of them reads as a school rather than a
    /// ruler.
    private func offset(for index: Int) -> CGFloat {
        guard isLive else { return 0 }
        let phase = (drift + CGFloat(index) * 0.18 + CGFloat(seed) * 0.11)
            .truncatingRemainder(dividingBy: 1)
        return (phase < 0 ? phase + 1 : phase) * 8 - 8
    }

    private func startDrift() {
        guard isLive, isOpen, !reduceMotion else {
            drift = 0
            return
        }
        drift = 0
        // A tick's delay on first change, so the repeat-forever animation is
        // kicked off from SwiftUI rather than relying on the first appear.
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
            drift = 1
        }
    }
}
