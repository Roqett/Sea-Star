import AppKit
import SwiftUI
import UniformTypeIdentifiers

private struct SeaStarCockpitOpenKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var seaStarCockpitOpen: Bool {
        get { self[SeaStarCockpitOpenKey.self] }
        set { self[SeaStarCockpitOpenKey.self] = newValue }
    }
}

/// Which way the cockpit is read (spec §8.7): the starfield graph, or the plain
/// "letterface" list of rows. The raw value is what persists as the person's
/// preference; an empty stored value means they have not chosen yet.
enum CockpitMode: String, CaseIterable, Identifiable {
    case graph
    case list

    var id: String { rawValue }

    /// The stored preference, or the opening default (the graph) when unset.
    static func resolved(from raw: String) -> CockpitMode {
        CockpitMode(rawValue: raw) ?? .graph
    }

    /// Standard Apple symbols stand in for the words: connected points for the
    /// graph, a bulleted list for the rows.
    var symbol: String {
        switch self {
        case .graph: return "point.3.connected.trianglepath.dotted"
        case .list: return "list.bullet"
        }
    }

    var label: String {
        switch self {
        case .graph: return Strings.Views.graph
        case .list: return Strings.Views.list
        }
    }

    var help: String {
        switch self {
        case .graph: return Strings.Views.graphHelp
        case .list: return Strings.Views.listHelp
        }
    }
}

/// The cockpit popover: what the engine found, at a glance, with one button to
/// start or stop the server (spec §8). Glass is applied to the control layer
/// only — the canvas stays flat so the accents read as glowing (spec §7).
struct CockpitPopoverView: View {
    let controller: ServerController
    /// Opens the Settings window. Supplied by the AppKit host, which owns that
    /// window; `nil` when the popover is used without one.
    var onOpenSettings: (() -> Void)?

    /// The header mark's side in points; also the caustic shimmer's scale, so the
    /// two can never drift apart.
    private static let markSize: CGFloat = 26

    @State private var isImportingVault = false
    @State private var isLogsExpanded = false
    @State private var isLogsHovering = false
    /// Whether the graph's harness drawer is slid out. Lives here rather than in
    /// the drawer because opening it changes how tall the pool may be.
    @State private var isTrayOpen = false

    /// Which reading of the cockpit the person prefers (spec §8.7). Empty until
    /// they choose on first launch, after which the header toggle swaps it.
    @AppStorage("SeaStar.cockpitMode") private var modeRaw = ""

    private var mode: CockpitMode { CockpitMode.resolved(from: modeRaw) }
    private var hasChosenMode: Bool { CockpitMode(rawValue: modeRaw) != nil }

    /// Which of the panel's readings the plain rows are drawn in
    /// (DECISIONS.md D-001). This lives here rather than inside the panel so the
    /// header toggle and the panel share one source of truth — two `@AppStorage`s
    /// on one key would agree by luck, not by design.
    @AppStorage("SeaStar.panelLayout") private var layoutRaw = PanelLayout.facts.rawValue

    private var layout: PanelLayout { PanelLayout.resolved(from: layoutRaw) }

    /// How deep the *graph* is read (spec §8.7): the flat pool, the 3D deep, or
    /// the two side by side.
    ///
    /// Deliberately its own key rather than another case of `panelLayout`. The
    /// two answer genuinely different questions — one is "how many dimensions
    /// is this drawing in", the other is "how are the rows arranged" — and
    /// folding them together would mean picking Stack/Chain/Both *means*
    /// abandoning the 3D pool, which is not a trade anybody asked to make.
    /// Separate keys also mean the depth you chose in the graph survives a trip
    /// to the rows and back.
    @AppStorage("SeaStar.graphDepth") private var depthRaw = Strings.Views.Depth.flat.rawValue

    private var depth: Strings.Views.Depth { Strings.Views.Depth.resolved(from: depthRaw) }

    /// Whether the popover is on screen. Written by the AppKit host through the
    /// popover delegate; every animated surface inside the cockpit gates on it
    /// so the reading runs live while open and holds still once it shuts. The
    /// engine's own connections are untouched — only the drawing stops.
    @AppStorage("SeaStar.cockpitOpen") private var isOpen = false

    /// The most the whole cockpit may occupy before it would run off the screen.
    /// The reading is only open for a moment, so it can be large — we give it as
    /// much room as the display allows and clamp only to keep the bottom on-screen
    /// (spec §8).
    private var maxPopoverHeight: CGFloat {
        let usable = NSScreen.main?.visibleFrame.height ?? 800
        return max(320, usable - 72)
    }

    /// The two readings want different rooms (spec §8.7). The rows are happy in a
    /// column, but the starfield is a *canvas*, not a utility dropdown: it opens
    /// wide so the vault, the harnesses on the right edge and the tip note beside
    /// the active starfish all have room and nothing crowds or clips — the visual
    /// reading opens a big panel, the text one a comfortable column.
    private var panelWidth: CGFloat {
        if mode == .graph {
            return 600
        }
        return 360
    }

    /// The pool's height for the visual reading. The starfield wants room, so it
    /// takes a fixed, generous one — but it is clamped so the whole panel (header,
    /// pool, logs and controls) still fits on the display. The rows reading has no
    /// pool: it hugs its own content, so the popover is exactly as tall as it
    /// needs to be and never shows a half-empty void.
    private var graphHeight: CGFloat {
        let chrome: CGFloat = 250 + (isLogsExpanded ? 190 : 0)
        // The deep pool is a room you fly a camera around in, so it asks for
        // more height than the flat drawing, which is read at a glance and is
        // happy in a shallower box.
        //
        // An open drawer is paid for out of the pool: the panel's height is
        // capped, so a tray that simply grew would open below the fold. The
        // graph gives way instead, which is the same "the panel extends" idea
        // read against a screen that will not get any taller.
        let drawer: CGFloat = isTrayOpen ? 214 : 0
        let desired: CGFloat = (depth == .flat ? 560 : 600) - drawer
        return max(240, min(desired, maxPopoverHeight - chrome))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            ScrollView {
                content
            }
            logs
            controls
        }
        .padding(18)
        .frame(width: panelWidth, alignment: .topLeading)
        // The whole panel may never exceed what the display allows. The header
        // and the controls sit *outside* the scroll region, so when the middle
        // outgrows its room it scrolls rather than pushing the mode switch off
        // the top of the screen — the failure this cap exists to make impossible.
        .frame(maxHeight: maxPopoverHeight)
        .background(Palette.canvas)
        .environment(\.seaStarCockpitOpen, isOpen)
        .task { await watchTheMachine() }
        .fileImporter(
            isPresented: $isImportingVault,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
                controller.selectVault(url.path)
            }
        }
    }

    /// The middle of the cockpit: the first-run choice, the chosen reading, and
    /// any guidance line. It is the *only* part that scrolls, and it only scrolls
    /// when it must: the reading hugs its content until the display cannot take
    /// any more, and then gives way without ever moving the header above it.
    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !hasChosenMode {
                firstRunChoice
            }
            switch mode {
            case .graph:
                graph
            case .list:
                details
            }
            if let message = controller.message {
                guidance(message)
            }
        }
    }

    /// The graph, at whichever depth was chosen (spec §8.7), with the controls
    /// that decide what appears on it directly beneath — a switch that floats
    /// harnesses onto the pool belongs next to the pool it changes, not in the
    /// text reading where it can have no visible effect.
    ///
    /// Both branches read the *same* `EntityGraphModel`, so changing depth can
    /// only ever change what you are looking at — never what is true.
    @ViewBuilder
    private var graph: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch depth {
            case .flat:
                EntityGraphView(controller: controller, height: graphHeight)
            case .deep:
                GraphSceneView(controller: controller, height: graphHeight)
            }
            // What belongs to the graph lives in a drawer at its foot rather than
            // beside it: the roster only. The depth choice used to be here too, and
            // that made the deep reading a dead end — the founder could not find his
            // way back to the flat pool, and said so twice. It is now in the graph's
            // own header, where it is visible, labelled, and only present where it
            // means something.
            CockpitTray(isOpen: $isTrayOpen, title: Strings.Views.trayTitle) {
                HarnessVisibilityList(controller: controller)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            AppIconMark(icon: controller.currentIcon, size: Self.markSize)
                .foregroundStyle(controller.currentIcon.accent)
                .caustics(size: Self.markSize)
                .shadow(color: controller.currentIcon.accent.opacity(0.55), radius: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Header.title)
                    .font(.headline)
                    .foregroundStyle(Palette.ink)
                    // The name is one word and must stay one line: in the narrow
                    // text reading the header used to squeeze it into "Sea-" /
                    // "Star", which reads as a broken title rather than a title.
                    .lineLimit(1)
                    .fixedSize()
                Text(Strings.Header.subtitle)
                    .font(.caption)
                    .foregroundStyle(Palette.inkMuted)
                    .lineLimit(1)
            }

            Spacer()

            statePill

            modeToggle

            if mode == .list {
                layoutToggle
            } else {
                depthToggle
            }

            if let onOpenSettings {
                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.inkMuted)
                }
                .buttonStyle(.plain)
                .help(Strings.Menu.settings)
            }
        }
    }

    /// The "ready" pill stays — the founder likes it as a status. Everything
    /// else that used to be a capsule is now a plain word.
    private var statePill: some View {
        Text(stateText)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(stateColour)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(stateColour.opacity(0.16), in: Capsule())
    }

    /// The mode switch, now up with the "ready" pill and the gear (spec §8.7):
    /// two SF Symbols, the active one lit, rather than a text capsule.
    private var modeToggle: some View {
        HStack(spacing: 2) {
            ForEach(CockpitMode.allCases) { option in
                Button {
                    choose(option)
                } label: {
                    Image(systemName: option.symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isActive(option) ? Palette.ink : Palette.inkMuted)
                        .frame(width: 24, height: 20)
                        .background(
                            isActive(option) ? Palette.ink.opacity(0.12) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 5)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .help(option.help)
            }
        }
    }

    /// The Facts / Path switch, shown only in the list reading — it is that
    /// reading's layout, so it moved out of the drawer up to the header, where
    /// the founder wanted it (2026-10-07). Icon *and* word: as bare symbols the
    /// control was unreadable in use — the founder could not tell which reading
    /// was which without hovering each one, which means the switch failed at the
    /// only job it has. The hover text still carries the longer explanation.
    private var layoutToggle: some View {
        HStack(spacing: 2) {
            ForEach(PanelLayout.allCases) { option in
                Button {
                    chooseLayout(option)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: option.symbol)
                            .font(.system(size: 11, weight: .semibold))
                        Text(option.label)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    }
                    .foregroundStyle(layout == option ? Palette.ink : Palette.inkMuted)
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(
                        layout == option ? Palette.ink.opacity(0.12) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 5)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .help(option.help)
            }
        }
    }

    /// The chosen reading is only lit once a preference exists, so first launch
    /// shows neither side pressed.
    private func isActive(_ option: CockpitMode) -> Bool {
        hasChosenMode && option == mode
    }

    private func choose(_ option: CockpitMode) {
        withAnimation(.easeInOut(duration: 0.18)) { modeRaw = option.rawValue }
    }

    /// Shown once, before a preference exists: the person picks how the cockpit
    /// should open, and can change it from the header at any time (spec §8.7).
    private var firstRunChoice: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.Mode.firstRunTitle)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.ink)

            Text(Strings.Mode.firstRunBody)
                .font(.caption)
                .foregroundStyle(Palette.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                ForEach(CockpitMode.allCases) { option in
                    Button {
                        choose(option)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: option.symbol)
                                .font(.system(size: 18))
                            Text(option.label)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(Palette.ink)
                        .background(Palette.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Palette.ink.opacity(0.12), lineWidth: 1)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .help(option.help)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.electricBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
    }

    /// The plain reading: the four rows (Vault / Harness / Agent / Inference) in
    /// whichever layout the person prefers, and the `Working now` band beneath
    /// them (DECISIONS.md D-001). Nothing else — the ledger and the register are
    /// onboarding, and live in their own window, not in the everyday reading.
    private var details: some View {
        VStack(alignment: .leading, spacing: 14) {
            CockpitPanel(controller: controller, layout: layoutBinding) {
                isImportingVault = true
            }
        }
    }

    /// The one binding both the header toggle and the panel read and write, so
    /// tapping either side redraws both.
    private var layoutBinding: Binding<PanelLayout> {
        Binding(
            get: { PanelLayout.resolved(from: layoutRaw) },
            set: { chooseLayout($0) }
        )
    }

    /// How often the cockpit re-reads the machine while it is on screen.
    ///
    /// The cockpit's whole claim is that it tells the truth about this machine
    /// *now*. A single read at open time made that claim false the moment
    /// anything changed: launching a harness, quitting one, or a model server
    /// coming up all left the panel describing a machine that had stopped
    /// existing. Two seconds is short enough that a harness firing up is
    /// noticed while you are still looking at it, and the read is one process
    /// listing plus a loopback port scan.
    ///
    /// Cancellation is the whole off-switch: `.task` tears this down when the
    /// cockpit closes, so a closed cockpit costs nothing and a background
    /// process is not kept alive to poll on its behalf.
    private static let watchInterval: Duration = .milliseconds(2000)

    /// Poll until the cockpit closes. Each `refresh` is awaited before the next
    /// one starts, so a slow read delays the next tick rather than stacking
    /// probes on top of each other.
    private func watchTheMachine() async {
        while !Task.isCancelled {
            await controller.refresh()
            do {
                try await Task.sleep(for: Self.watchInterval)
            } catch {
                return  // cancelled — the cockpit closed mid-wait
            }
        }
    }

    /// Flat or deep, shown only in the graph reading — it is meaningless anywhere
    /// else, so it lives in *this* header rather than a tray at the graph's foot.
    ///
    /// It was in the tray, and that was a trap the founder walked into twice in one
    /// session: once for Facts/Path, once for this. *"I still can't alternate between
    /// this 3D test and the original"* — because getting back out of the deep reading
    /// meant finding a hidden drawer. A control you cannot find is not a control, and
    /// a reading you cannot leave is a dead end. Icon **and** word, for the same
    /// reason the layout toggle carries both.
    private var depthToggle: some View {
        HStack(spacing: 2) {
            ForEach(Strings.Views.Depth.allCases) { option in
                Button {
                    chooseDepth(option)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: option.symbol)
                            .font(.system(size: 11, weight: .semibold))
                        Text(option.label)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    }
                    .foregroundStyle(depth == option ? Palette.ink : Palette.inkMuted)
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(
                        depth == option ? Palette.ink.opacity(0.12) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 5)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .help(Strings.Views.depthTitle)
            }
        }
    }

    private func chooseLayout(_ option: PanelLayout) {
        withAnimation(.easeInOut(duration: 0.18)) { layoutRaw = option.rawValue }
    }

    private func chooseDepth(_ option: Strings.Views.Depth) {
        withAnimation(.easeInOut(duration: 0.18)) { depthRaw = option.rawValue }
    }

    /// Vaults read better as their folder name in the menu; the row itself shows
    /// the full path so two vaults with the same name stay distinguishable.
    private static func vaultName(_ path: String) -> String {
        (path as NSString).lastPathComponent
    }

    /// The control layer, stripped of its pill capsules (spec §8). Start sits
    /// in the left corner and Refresh in the right, plain words and nothing
    /// else. The pair used to be framed by two nudibranch strips — pure
    /// decoration inherited from the early visual spec — and the founder asked
    /// for them off, so they are gone. The strip survives only where it says
    /// something: the live-connection ribbon in the starfield, the liveness
    /// bar, and the frame around an expanded log box.
    private var controls: some View {
        HStack(alignment: .firstTextBaseline) {
            actionButton(
                title: controller.isServerRunning ? Strings.Actions.stop : Strings.Actions.start,
                enabled: controller.isServerRunning || controller.isReady
            ) {
                controller.toggleServer()
            }

            Spacer(minLength: 12)

            actionButton(
                title: Strings.Actions.refresh,
                enabled: !controller.isRefreshing
            ) {
                Task { await controller.refresh() }
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
    }

    /// A plain word where a pill used to be: mono, small, toned down, exactly as
    /// Apple would draw a text button. Weight and ink stay light so the pair
    /// reads as part of the panel's prose rather than shouting over it.
    private func actionButton(
        title: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        ControlWord(title: title, enabled: enabled, action: action)
    }

    // MARK: - Logs

    private var logs: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { isLogsExpanded.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Palette.inkMuted)
                        .rotationEffect(.degrees(isLogsExpanded ? 90 : 0))
                        .frame(width: 9)

                    Image(systemName: "terminal")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Palette.electricBlue)

                    Text(Strings.Logs.title)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Palette.ink)

                    Spacer(minLength: 0)

                    Text("\(controller.logs.entries.count)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Palette.inkMuted)
                        .monospacedDigit()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(
                    Palette.ink.opacity(isLogsHovering ? 0.10 : 0.05),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .contentShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .onHover { isLogsHovering = $0 }
            .help(isLogsExpanded ? Strings.Logs.hide : Strings.Logs.show)

            if isLogsExpanded { logPanel }
        }
    }

    /// The log body, framed top and bottom by the blue-white nudibranch strip
    /// and inked in the matching blue (spec §8.8). The strips are inset from the
    /// edges and floated on the log ground, so they read as wiring inside the
    /// panel rather than as its border. Ground and ink adapt with the panel.
    private var logPanel: some View {
        VStack(spacing: 0) {
            NudiStrip(style: .blueWhite)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    if controller.logs.entries.isEmpty {
                        Text(Strings.Logs.empty)
                            .foregroundStyle(Palette.inkMuted)
                    } else {
                        ForEach(controller.logs.entries.suffix(300)) { entry in
                            Text(entry.text)
                                .foregroundStyle(Palette.logInk)
                                .textSelection(.enabled)
                        }
                    }
                }
                .font(.system(size: 10, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 150)

            NudiStrip(style: .blueWhite)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
        .background(Palette.logSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Guidance & derived state

    private func guidance(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(Palette.ink.opacity(0.85))
            .fixedSize(horizontal: false, vertical: true)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.vermilion.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
    }

    // The status dot reports the machine's state, never the app's own housekeeping.
        // `isRefreshing` used to drive it, which was invisible when the cockpit
        // read once and became a colour flip every two seconds once it watched —
        // a background poll is not a "checking" state and must not look like one.
        private var stateText: String {
        if controller.isServerRunning { return Strings.States.running }
        return controller.isReady ? Strings.States.ready : Strings.States.notReady
    }

    private var stateColour: Color {
        if controller.isServerRunning { return Palette.neonGreen }
        return controller.isReady ? Palette.neonGreen : Palette.offline
    }
}

/// The palette accent bar: same idea, same colour, every time (spec §7).
/// Not file-private — the chain layout draws the same bar, and one definition
/// keeps the two layouts from drifting.
struct AccentBar: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color)
            .frame(width: 3, height: 14)
            .shadow(color: color.opacity(0.6), radius: 4)
    }
}

/// The Start/Refresh control, wearing a soft ground under the pointer the way
/// the logs row already does. It is the same plain word, unmoved; only a faint
/// capsule appears, so the panel answers the cursor without the button ever
/// shouting over its own prose. The ground hides when the control is disabled,
/// so an inert word never looks pressable.
private struct ControlWord: View {
    let title: String
    let enabled: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(enabled ? Palette.ink.opacity(0.85) : Palette.inkMuted.opacity(0.4))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Palette.ink.opacity(enabled && hovering ? 0.10 : 0),
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .onHover { hovering = $0 }
    }
}
