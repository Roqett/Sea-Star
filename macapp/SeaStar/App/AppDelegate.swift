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
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    let controller = ServerController()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        configurePopover()
        observeIcon()
        // The first-run window needs the launch sequence to finish before it can
        // order itself front: at this exact moment the app is not yet active,
        // and a window shown now can be swallowed by the remaining launch work.
        DispatchQueue.main.async { [weak self] in
            self?.showOnboardingOnFirstRun()
        }
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
    /// reroll lands in the menu bar too (spec §7). The face is drawn as a
    /// template by `AppIconMark`, band and all, so the system tints it — white
    /// on a dark bar, black on a light one — and it matches the popover header
    /// rather than drifting from it.
    private func applyStatusIcon() {
        guard let button = statusItem?.button else { return }
        button.image = AppIconMark.menuBarImage(for: controller.currentIcon)
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
        // The founder's rule: the cockpit is a panel, not a tooltip. It stays
        // open until the star is clicked again — clicking another app must not
        // dismiss it, or you can never watch the cockpit while you work.
        // Closing is purely the star's toggle in `togglePopover()`.
        popover.behavior = .applicationDefined
        popover.animates = true
        popover.delegate = self

        let hosting = NSHostingController(
            rootView: CockpitPopoverView(controller: controller, onOpenSettings: { [weak self] in
                self?.openSettings()
            })
        )
        hosting.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hosting
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

    // The SDK's NSPopoverDelegate takes a Notification (macOS 14+). The old
    // `popoverDidShow(_ popover: NSPopover)` signature is not a delegate method
    // any more, so it compiled and never fired — which silently kept
    // `SeaStar.cockpitOpen` false and the starfield still. Written as a
    // notification handler on purpose, and worth a comment because a wrong
    // signature here fails without a single warning.
    func popoverDidShow(_ notification: Notification) {
        UserDefaults.standard.set(true, forKey: "SeaStar.cockpitOpen")
    }

    func popoverDidClose(_ notification: Notification) {
        UserDefaults.standard.set(false, forKey: "SeaStar.cockpitOpen")
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
        menu.addItem(item(Strings.Menu.onboarding, #selector(openOnboarding), symbol: "sparkles"))
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

    /// The onboarding window: the machine's ledger, the register's questions,
    /// and which harnesses float on the graph. Opened once on first launch, and
    /// reachable afterwards from the menu and from Settings. It is its own
    /// window on purpose — it is a desk you clear once, not a reading you take.
    @objc func openOnboarding() {
        if let window = onboardingWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
            markOnboardingShown()
            return
        }

        let hosting = NSHostingController(
            rootView: OnboardingView(controller: controller) { [weak self] in
                self?.onboardingWindow?.close()
            }
        )
        let window = NSWindow(contentViewController: hosting)
        window.title = Strings.Onboarding.title
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 460, height: 640))
        window.center()
        onboardingWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        // The "seen" mark is written *after* the window is up, so a window that
        // fails to appear can never be counted as one the person saw.
        markOnboardingShown()
    }

    private func markOnboardingShown() {
        UserDefaults.standard.set(true, forKey: Self.onboardingShownKey)
    }

    /// The first launch opens onboarding so the machine gets named before the
    /// graph is asked to mean anything. Every launch after leaves it to the
    /// menu, so the window can never ambush a person twice.
    private func showOnboardingOnFirstRun() {
        guard !UserDefaults.standard.bool(forKey: Self.onboardingShownKey) else { return }
        openOnboarding()
    }

    private static let onboardingShownKey = "SeaStar.onboardingShown"

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
