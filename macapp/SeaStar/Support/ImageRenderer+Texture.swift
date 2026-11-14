import AppKit
import SwiftUI

/// Rasterises SwiftUI artwork for the 3D scene to wear.
enum Texture {
    /// Rasterise a SwiftUI view into an `NSImage` the deep can map onto a
    /// billboard.
    ///
    /// This is the whole trick behind the 3D pool looking like *this* product:
    /// the sea-star and the nudibranch bar are rasterised from the very same
    /// views the 2D pool draws, so the deep inherits the brand art instead of
    /// approximating it with hand-built geometry that would slowly drift away
    /// from the original.
    ///
    /// Drawn at 2×, because a texture that is soft on a Retina display is worse
    /// than no texture at all — and the camera can get close.
    ///
    /// The `size` is handed over as a *proposed* size rather than applied as a
    /// frame, which matters because the glyph is built around a
    /// `GeometryReader`: a frame would leave that reader with an unbounded
    /// proposal and the star would rasterise at nothing.
    ///
    /// A free-standing function rather than an extension on `ImageRenderer`,
    /// because `ImageRenderer` is generic over its content and an extension on
    /// it leaves that parameter dangling in a way the call site cannot satisfy.
    ///
    /// Main-actor bound, like `ImageRenderer` itself: it walks AppKit text and
    /// colour machinery, and it is only ever called while building a scene on
    /// the main thread.
    @MainActor
    static func make<V: View>(
        of size: CGSize,
        @ViewBuilder content: () -> V
    ) -> NSImage {
        let view: V = content()
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(size)
        renderer.scale = 2
        renderer.isOpaque = false
        return renderer.nsImage ?? NSImage(size: size)
    }
}
