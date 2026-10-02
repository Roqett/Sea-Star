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
    /// Whether the whole register backlog is unfolded. Folded by default: the
    /// panel is a cockpit, not a to-do list.
    @State private var showingAllCandidates = false
    @State private var isLogsHovering = false

    /// Which reading of the cockpit the person prefers (spec §8.7). Empty until
    /// they choose on first launch, after which the header toggle swaps it.
    @AppStorage("SeaStar.cockpitMode") private var modeRaw = ""

    private var mode: CockpitMode { CockpitMode.resolved(from: modeRaw) }
    private var hasChosenMode: Bool { CockpitMode(rawValue: modeRaw) != nil }

    /// Which of the panel's readings the plain rows are drawn in
    /// (DECISIONS.md D-001). This lives here rather than inside the panel so the
    /// header toggle and the panel share one source of truth — two `@AppStorage`s
    /// on one key would agree by luck, not by design.
    @AppStorage("SeaStar.panelLayout") private var layoutRaw = PanelLayout.stack.rawValue

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
        let desired: CGFloat = depth == .flat ? 560 : 600
        return max(240, min(desired, maxPopoverHeight - chrome))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            content
            logs
            controls
        }
        .padding(18)
        .frame(width: panelWidth, alignment: .topLeading)
        .background(Palette.canvas)
        .environment(\.seaStarCockpitOpen, isOpen)
        .task { await controller.refresh() }
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
    /// any guidance line. It is deliberately *not* wrapped in a scroll view — a
    /// scroll view has no natural height, so the popover could never size itself
    /// to its content and the panel showed a half-empty void, nested frames and
    /// clipped edges. Without it the pool carries its own definite height and the
    /// rows simply hug theirs, so the panel is exactly as tall as it needs to be.
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

    /// The graph, at whichever depth was chosen (spec §8.7).
    ///
    /// Both branches read the *same* `EntityGraphModel`, so changing depth can
    /// only ever change what you are looking at — never what is true.
    @ViewBuilder
    private var graph: some View {
        switch depth {
        case .flat:
            EntityGraphView(controller: controller, height: graphHeight)
        case .deep:
            GraphSceneView(controller: controller, height: graphHeight)
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
                Text(Strings.Header.subtitle)
                    .font(.caption)
                    .foregroundStyle(Palette.inkMuted)
            }

            Spacer()

            statePill

            modeToggle

            if mode == .graph {
                depthToggle
            }

            if mode == .list {
                layoutToggle
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
    /// whichever layout the person prefers, the `Working now` band beneath
    /// them, and the idle-harness toggles after that (DECISIONS.md D-001).
    private var details: some View {
        VStack(alignment: .leading, spacing: 14) {
            CockpitPanel(controller: controller, layout: layoutBinding) {
                isImportingVault = true
            }

            whatEachAppIsDoing
            latentHarnesses
            newOnThisMachine
        }
    }

    /// The ledger (D-008): what each harness is doing with models, read from
    /// sockets and the process table rather than from anything an app says about
    /// itself. It reads as a sentence list because it is one — a claim, and the
    /// observations it stands on are the same line.
    @ViewBuilder
    private var whatEachAppIsDoing: some View {
        if !controller.appBehaviour.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Rows.behaviour)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.inkMuted)

                ForEach(controller.appBehaviour) { row in
                    BehaviourRow(row: row)
                }
            }
            .help(Strings.Rows.behaviourHelp)
        }
    }

    /// What the engine found and has not been told about (D-005). The question
    /// is asked here rather than in a wizard because the answer is a fact about
    /// the machine the person is looking at, and it is asked **once**: an answer
    /// goes into the register and the row never returns.
    ///
    /// The evidence sits above the buttons on purpose. A candidate that arrived
    /// without it would be a demand for trust, and this app does not make those.
    @ViewBuilder
    private var newOnThisMachine: some View {
        if !controller.candidates.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(Strings.Rows.newHere)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Palette.inkMuted)

                    Spacer(minLength: 8)

                    // Tidy by default: the register is a backlog, not the panel.
                    // A first run can have a dozen things to decide about, and
                    // showing all of them buries the cockpit underneath its own
                    // housekeeping. Three are shown; the rest wait behind one
                    // quiet word, and nothing is hidden.
                    if controller.candidates.count > Self.candidatesShown {
                        Button(showingAllCandidates ? Strings.Actions.showFewer : Strings.Actions.showAll) {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                showingAllCandidates.toggle()
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Palette.inkMuted)
                    }
                }

                Text(Strings.Rows.newHereCount(controller.candidates.count))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Palette.inkMuted)

                ForEach(visibleCandidates) { candidate in
                    NewCandidateRow(
                        candidate: candidate,
                        isBusy: controller.isDeciding,
                        adopt: { name in
                            Task { await controller.adoptCandidate(candidate.identity, name: name) }
                        },
                        dismiss: {
                            Task { await controller.dismissCandidate(candidate.identity) }
                        }
                    )
                }
            }
            .help(Strings.Rows.newHereHelp)
        }
    }

    /// How many undecided things are shown before the rest are folded away.
    private static let candidatesShown = 3

    private var visibleCandidates: [DoctorReport.CandidateInfo] {
        guard !showingAllCandidates else { return controller.candidates }
        return Array(controller.candidates.prefix(Self.candidatesShown))
    }

    /// The one binding both the header toggle and the panel read and write, so
    /// tapping either side redraws both.
    private var layoutBinding: Binding<PanelLayout> {
        Binding(
            get: { PanelLayout.resolved(from: layoutRaw) },
            set: { chooseLayout($0) }
        )
    }

    private func chooseLayout(_ option: PanelLayout) {
        withAnimation(.easeInOut(duration: 0.18)) { layoutRaw = option.rawValue }
    }

    /// Harness apps the engine found that are not attached over stdio. These sit
    /// below the four rows rather than inside them, because they are not part of
    /// the request chain — nothing is driving Sea-Star through them. Each one
    /// still says how far it got: an app that is up but not answering is a
    /// different fact from one that is merely installed.
    @ViewBuilder
    private var latentHarnesses: some View {
        if !controller.latentHarnessOptions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Rows.latent)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.inkMuted)

                ForEach(controller.latentHarnessOptions) { latent in
                    LatentRow(
                        name: latent.name,
                        path: latent.path,
                        rung: latent.rung,
                        isFloating: controller.isLatentHarnessEnabled(latent.bundleID),
                        toggle: { controller.toggleLatentHarness(latent.bundleID) }
                    )
                }
            }
            .help(Strings.Rows.latentHelp)
        }
    }

    /// How deep the graph is drawn: the flat pool, the 3D deep, or the two
    /// together (spec §8.7).
    ///
    /// Built exactly like `layoutToggle` and for the same reason: the depth is
    /// only meaningful once you are in the graph, so like the layout toggle it
    /// only appears in that mode. Two toggles in the header, never three — the
    /// one for the mode you are not in is a control for something invisible.
    private var depthToggle: some View {
        HStack(spacing: 2) {
            ForEach(Strings.Views.Depth.allCases) { option in
                Button {
                    chooseDepth(option)
                } label: {
                    Image(systemName: option.symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(depth == option ? Palette.ink : Palette.inkMuted)
                        .frame(width: 24, height: 20)
                        .background(
                            depth == option ? Palette.ink.opacity(0.12) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 5)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .help("\(option.label) — \(option.help)")
            }
        }
    }

    private func chooseDepth(_ option: Strings.Views.Depth) {
        withAnimation(.easeInOut(duration: 0.18)) { depthRaw = option.rawValue }
    }

    /// The A/B toggle for the two readings, plus the side-by-side that exists
    /// only to help choose between them (DECISIONS.md D-001). It sits in the
    /// header beside the mode toggle and looks like it: the same pair of symbols,
    /// the active one lit, no text menu.
    private var layoutToggle: some View {
        HStack(spacing: 2) {
            ForEach(PanelLayout.allCases) { option in
                Button {
                    chooseLayout(option)
                } label: {
                    Image(systemName: option.symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(layout == option ? Palette.ink : Palette.inkMuted)
                        .frame(width: 24, height: 20)
                        .background(
                            layout == option ? Palette.ink.opacity(0.12) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 5)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .help("\(option.label) — \(option.help)")
            }
        }
    }

    /// Vaults read better as their folder name in the menu; the row itself shows
    /// the full path so two vaults with the same name stay distinguishable.
    private static func vaultName(_ path: String) -> String {
        (path as NSString).lastPathComponent
    }

    /// The control layer, stripped of its pill capsules (spec §8). Start sits in
    /// the left corner and Refresh in the right, with a nudibranch strip above
    /// and below the pair as the column reference — the 3px bar grown up.
    private var controls: some View {
        VStack(spacing: 12) {
            NudiStrip(style: .blueWhite)
                .padding(.horizontal, 10)

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

            NudiStrip(style: .blueWhite)
                .padding(.horizontal, 10)
        }
        .padding(.vertical, 2)
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

    private var stateText: String {
        if controller.isServerRunning { return Strings.States.running }
        if controller.isRefreshing { return Strings.States.checking }
        return controller.isReady ? Strings.States.ready : Strings.States.notReady
    }

    private var stateColour: Color {
        if controller.isServerRunning { return Palette.neonGreen }
        if controller.isRefreshing { return Palette.working }
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

/// One installed-but-idle harness (spec §8.3): its name, and a word that floats
/// it onto the graph or takes it back off. The path is only ever a tooltip —
/// the row stays as quiet as the rest of the panel.
/// One harness and what it is observed to be doing with models.
///
/// The distinction that earns this row its place: an app that ships a model
/// server *and* is reaching outside the machine while not using it is doing
/// something a person would want to know about, and would otherwise never see.
/// The wording states the two observations and stops there — no motive is
/// attributed, because the engine did not observe one.
private struct BehaviourRow: View {
    let row: DoctorReport.HarnessBehaviourInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                AccentBar(color: row.ownsIdleServer ? Palette.agentGlow : Palette.inferenceGlow)

                Text(row.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 8)

                Text(summary)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(row.ownsIdleServer ? Palette.agentGlow : Palette.inkMuted)
                    .lineLimit(1)
            }

            if row.ownsIdleServer {
                Text(Strings.Rows.idleServer(row.serves))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Palette.inkMuted)
                    .padding(.leading, 18)
            }
        }
    }

    /// The line, built from the observations in the order they matter.
    ///
    /// A port that never answered is reported as a port, never as a server:
    /// "listening on 8888, not answering" is honest, where "serves models on
    /// 8888" was a guess that a real machine proved wrong.
    private var summary: String {
        var parts: [String] = []
        if !row.serves.isEmpty {
            let ports = row.serves.map(String.init).joined(separator: ", ")
            parts.append("serves \(ports)")
            if row.usingOwnServer { parts.append("using it") }
        } else if !row.unconfirmed.isEmpty {
            let ports = row.unconfirmed.map(String.init).joined(separator: ", ")
            parts.append("listening \(ports), not answering")
        }
        if row.reachesOut > 0 {
            parts.append("reaching \(row.reachesOut) outside")
        }
        return parts.isEmpty ? Strings.States.unknown : parts.joined(separator: " · ")
    }
}

/// One undecided thing, with the evidence for it and the two answers available.
///
/// The name is pre-filled from the scan when the scan had one, so answering is a
/// click rather than a typing exercise; it stays editable because the label a
/// person gives a thing is the label they will look for on the graph afterwards.
private struct NewCandidateRow: View {
    let candidate: DoctorReport.CandidateInfo
    let isBusy: Bool
    let adopt: (String) -> Void
    let dismiss: () -> Void

    @State private var name: String = ""
    @State private var hasEditedName = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                AccentBar(color: Palette.harnessGlow)

                TextField(candidate.suggestedName ?? candidate.name, text: $name)
                    .textFieldStyle(.plain)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .onAppear {
                        if !hasEditedName {
                            name = candidate.suggestedName ?? candidate.name
                        }
                    }
                    .onChange(of: name) { _, _ in hasEditedName = true }

                Spacer(minLength: 8)

                Button(Strings.Actions.itIsAHarness) {
                    adopt(name.isEmpty ? candidate.name : name)
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.harnessGlow)
                .disabled(isBusy)

                Button(Strings.Actions.notAHarness, action: dismiss)
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Palette.inkMuted)
                    .disabled(isBusy)
            }

            // Every line here is something the engine observed, not a guess.
            ForEach(candidate.evidence, id: \.self) { line in
                Text(line)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 18)
            }
        }
    }
}

private struct LatentRow: View {
    let name: String
    let path: String
    /// How far this app got. Shown beside the name rather than hidden in a
    /// tooltip, because "up, not answering yet" is the single most useful thing
    /// to know about a harness that is not driving Sea-Star.
    let rung: HarnessRung?
    let isFloating: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            AccentBar(color: Palette.harnessGlow)

            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .truncationMode(.middle)

            if let rung, rung != .present {
                Text(rung.label)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(rung == .running ? Palette.ready : Palette.inkMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button(action: toggle) {
                Text(isFloating ? Strings.Actions.sinkHarness : Strings.Actions.floatHarness)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isFloating ? Palette.harnessGlow : Palette.inkMuted)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(path)
        }
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
