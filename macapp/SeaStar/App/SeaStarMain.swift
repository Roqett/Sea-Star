import AppKit

/// The app's entry point.
///
/// Sea-Star runs as an accessory app (`LSUIElement`) whose entire life is the
/// menu-bar glyph, so it starts AppKit directly and hands control to
/// ``AppDelegate``. SwiftUI's `App`/`MenuBarExtra` was the previous shell, but it
/// cannot present a right-click menu — see ``AppDelegate`` for the bridge.
@main
enum SeaStarMain {
    /// `NSApplication.delegate` is an unsafe-unowned reference, so the delegate
    /// is pinned here for the process's lifetime.
    @MainActor private static var delegate: AppDelegate?

    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        Self.delegate = delegate
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
