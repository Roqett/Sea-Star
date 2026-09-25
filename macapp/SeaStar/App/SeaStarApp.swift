import SwiftUI

@main
struct SeaStarApp: App {
    /// One controller for the whole app, hoisted above the popover so the
    /// menu-bar glyph can wear the same face the header does (and reroll when the
    /// server opens or shuts — the Easter egg).
    @State private var controller = ServerController()

    var body: some Scene {
        MenuBarExtra {
            CockpitPopoverView(controller: controller)
        } label: {
            AppIconMark(icon: controller.currentIcon, template: true)
                .accessibilityLabel(Strings.MenuBar.label)
        }
        .menuBarExtraStyle(.window)
    }
}
