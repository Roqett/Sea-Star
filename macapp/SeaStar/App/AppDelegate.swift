import AppKit
import Observation
import SwiftUI

/// Owns the menu-bar glyph, the cockpit popover, the right-click menu and the
/// Settings window.
///
/// SwiftUI's `MenuBarExtra` renders a popover on left-click but exposes no
/// right-click hook, so the standard app menu (Settings, updates, help, quit)
/// has nowhere to live. This delegate takes over the status item directly —
/// the smallest AppKit bridge that closes that gap — and hosts the existing
/// SwiftUI cockpit and settings views unchanged.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = ServerController()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var settingsWindow: NSWindow?

    private static let popoverWidth: CGFloat = 320

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        configurePopover()
        observeIcon()
    }

    // MARK: - Status item

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = Strings.MenuBar.label
        }
        statusItem = item
        applyStatusIcon()
    }

    /// The glyph wears whichever face the app is showing, so the Easter-egg
    /// reroll lands in the menu bar too (spec §7). Marking the image as a
    /// template lets the system tint it — white on a dark bar, black on a light
    /// one — so the detailed starfish stays legible in both appearances.
    private func applyStatusIcon() {
        guard let button = statusItem?.button else { return }
        let icon = controller.currentIcon
        let image = icon.asset.flatMap { NSImage(named: $0) }
            ?? NSImage(systemSymbolName: icon.symbol, accessibilityDescription: Strings.MenuBar.label)
        image?.isTemplate = true
        image?.size = NSSize(width: 18, height: 18)
        button.image = image
    }

    /// Re-arm observation after every change — `withObservationTracking` fires
    /// once, so the handler re-registers itself.
    private func observeIcon() {
        withObservationTracking {
            _ = controller.currentIcon
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.applyStatusIcon()
                self?.observeIcon()
            }
        }
    }

    // MARK: - Popover

    private func configurePopover() {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true

        let hosting = NSHostingController(
            rootView: CockpitPopoverView(controller: controller, onOpenSettings: { [weak self] in
                self?.openSettings()
            })
        )
        hosting.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hosting
        popover.contentSize = NSSize(width: Self.popoverWidth, height: 360)
        self.popover = popover
    }

    private func togglePopover() {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            NSApp.activate()
        }
    }

    // MARK: - Click routing

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isSecondary = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true
        if isSecondary {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    // MARK: - Right-click menu

    private func showContextMenu() {
        guard let statusItem else { return }
        popover?.performClose(nil)

        let menu = NSMenu()
        menu.addItem(item(Strings.Menu.checkForUpdates, #selector(checkForUpdates), symbol: "arrow.triangle.2.circlepath"))
        menu.addItem(.separator())
        menu.addItem(item(Strings.Menu.settings, #selector(openSettings), symbol: "gearshape", key: ","))
        menu.addItem(item(Strings.Menu.help, #selector(openHelp), symbol: "questionmark.circle"))
        menu.addItem(item(Strings.Menu.patchdog, #selector(openPatchdog), symbol: "ladybug"))
        menu.addItem(.separator())

        let version = NSMenuItem(
            title: Strings.Menu.version(AppInfo.versionLine),
            action: nil,
            keyEquivalent: ""
        )
        version.isEnabled = false
        menu.addItem(version)

        menu.addItem(.separator())
        menu.addItem(item(Strings.Menu.quit, #selector(quit), symbol: "power", key: "q"))

        // Assigning a menu makes the next click present it rather than fire the
        // action; the transient assignment shows it once, then clears.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func item(
        _ title: String,
        _ action: Selector,
        symbol: String,
        key: String = ""
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        return item
    }

    // MARK: - Menu actions

    @objc private func openHelp() {
        NSWorkspace.shared.open(Links.issues)
    }

    @objc private func openPatchdog() {
        NSWorkspace.shared.open(Links.patchdog)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let hosting = NSHostingController(rootView: SettingsView(controller: controller))
        let window = NSWindow(contentViewController: hosting)
        window.title = Strings.Settings.title
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    @objc private func checkForUpdates() {
        let current = AppInfo.version
        Task { @MainActor in
            let outcome = await UpdateChecker().check(currentVersion: current)
            present(outcome)
        }
    }

    private func present(_ outcome: UpdateChecker.Outcome) {
        let alert = NSAlert()
        switch outcome {
        case .upToDate(let current):
            alert.messageText = Strings.Updates.upToDateTitle
            alert.informativeText = Strings.Updates.upToDate(current)
            alert.addButton(withTitle: Strings.Updates.dismiss)
        case .available(let current, let latest, let url):
            alert.messageText = Strings.Updates.availableTitle
            alert.informativeText = Strings.Updates.available(current: current, latest: latest)
            alert.addButton(withTitle: Strings.Updates.openRelease)
            alert.addButton(withTitle: Strings.Updates.later)
            NSApp.activate()
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(url)
            }
            return
        case .failed(let reason):
            alert.messageText = Strings.Updates.failedTitle
            alert.informativeText = reason
            alert.addButton(withTitle: Strings.Updates.dismiss)
        }
        NSApp.activate()
        alert.runModal()
    }
}
