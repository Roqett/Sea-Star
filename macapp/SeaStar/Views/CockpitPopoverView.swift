import AppKit
import SwiftUI
import UniformTypeIdentifiers

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

    /// Which reading of the cockpit the person prefers (spec §8.7). Empty until
    /// they choose on first launch, after which the header toggle swaps it.
    @AppStorage("SeaStar.cockpitMode") private var modeRaw = ""

    private var mode: CockpitMode { CockpitMode.resolved(from: modeRaw) }
    private var hasChosenMode: Bool { CockpitMode(rawValue: modeRaw) != nil }

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
    private var panelWidth: CGFloat { mode == .graph ? 600 : 360 }

    /// The pool's height for the visual reading. The starfield wants room, so it
    /// takes a fixed, generous one — but it is clamped so the whole panel (header,
    /// pool, logs and controls) still fits on the display. The rows reading has no
    /// pool: it hugs its own content, so the popover is exactly as tall as it
    /// needs to be and never shows a half-empty void.
    private var graphHeight: CGFloat {
        let chrome: CGFloat = 250 + (isLogsExpanded ? 190 : 0)
        let desired: CGFloat = 560
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
                EntityGraphView(controller: controller, height: graphHeight)
            case .list:
                details
            }
            if let message = controller.message {
                guidance(message)
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
                Text(Strings.Header.subtitle)
                    .font(.caption)
                    .foregroundStyle(Palette.inkMuted)
            }

            Spacer()

            statePill

            modeToggle

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

    private var details: some View {
        VStack(alignment: .leading, spacing: 10) {
            PickerRow(
                label: Strings.Rows.vault,
                value: vaultValue,
                accent: Palette.teal,
                options: controller.vaultOptions,
                selection: Binding(
                    get: { controller.report?.vault.path ?? "" },
                    set: { controller.selectVault($0) }
                ),
                display: Self.vaultName,
                onChooseFolder: { isImportingVault = true }
            )
            .help(Strings.Actions.chooseVault)

            if controller.harnessOptions.count > 1 {
                PickerRow(
                    label: Strings.Rows.harness,
                    value: harnessValue,
                    accent: Palette.electricBlue,
                    options: controller.harnessOptions.map(\.baseURL),
                    selection: Binding(
                        get: { controller.report?.baseURL ?? "" },
                        set: { controller.selectHarness($0) }
                    ),
                    display: harnessLabel
                )
                .help(Strings.Actions.chooseHarness)
            } else {
                StatusRow(label: Strings.Rows.harness, value: harnessValue, accent: Palette.electricBlue)
            }

            PickerRow(
                label: Strings.Rows.model,
                value: modelValue,
                accent: Palette.neonGreen,
                options: controller.modelOptions,
                selection: Binding(
                    get: { controller.report?.model ?? "" },
                    set: { controller.selectModel($0) }
                ),
                display: { $0 }
            )
            .help(Strings.Actions.chooseModel)

            if !controller.latentHarnessOptions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.Rows.latent)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Palette.inkMuted)

                    ForEach(controller.latentHarnessOptions) { latent in
                        LatentRow(
                            name: latent.name,
                            path: latent.path,
                            isFloating: controller.isLatentHarnessEnabled(latent.bundleID),
                            toggle: { controller.toggleLatentHarness(latent.bundleID) }
                        )
                    }
                }
                .help(Strings.Rows.latentHelp)
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

    private var vaultValue: String {
        controller.report?.vault.path ?? Strings.States.unknown
    }

    private var harnessValue: String {
        guard let report = controller.report else { return Strings.States.unknown }
        return "\(report.runtime) · \(report.baseURL)"
    }

    /// A harness is its name plus where it lives — the URL alone can't say which
    /// app is answering on a shared port.
    private func harnessLabel(_ baseURL: String) -> String {
        guard let option = controller.harnessOptions.first(where: { $0.baseURL == baseURL }) else {
            return baseURL
        }
        return "\(option.name) · \(baseURL)"
    }

    private var modelValue: String {
        controller.report?.model ?? Strings.States.unknown
    }
}

/// The palette accent bar: same idea, same colour, every time (spec §7).
private struct AccentBar: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color)
            .frame(width: 3, height: 14)
            .shadow(color: color.opacity(0.6), radius: 4)
    }
}

/// One labelled fact. The accent bar carries the palette colour so the same
/// idea always glows the same (spec §7).
private struct StatusRow: View {
    let label: String
    let value: String
    let accent: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            AccentBar(color: accent)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.inkMuted)
                .frame(width: 60, alignment: .leading)

            Text(value)
                .font(.caption)
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .truncationMode(.middle)

            Spacer(minLength: 0)
        }
    }
}

/// A labelled fact whose value is a picker (spec §8.1, §8.3). The row shows the
/// full current choice; the menu lists the alternatives. Disabled when there is
/// nothing to switch to, so a single-vault or single-model machine stays quiet.
private struct PickerRow: View {
    let label: String
    let value: String
    let accent: Color
    let options: [String]
    let selection: Binding<String>
    let display: (String) -> String
    /// Optional extra menu entry — the vault row uses it to adopt any folder.
    var onChooseFolder: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            AccentBar(color: accent)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.inkMuted)
                .frame(width: 60, alignment: .leading)

            Menu {
                Picker(label, selection: selection) {
                    ForEach(options, id: \.self) { option in
                        Text(display(option)).tag(option)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()

                if let onChooseFolder {
                    Divider()
                    Button(Strings.Actions.openFolder, action: onChooseFolder)
                }
            } label: {
                HStack(spacing: 4) {
                    Text(value)
                        .font(.caption)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(2)
                        .truncationMode(.middle)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Palette.inkMuted)
                }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .disabled(options.count <= 1 && onChooseFolder == nil)

            Spacer(minLength: 0)
        }
    }
}

/// One installed-but-idle harness (spec §8.3): its name, and a word that floats
/// it onto the graph or takes it back off. The path is only ever a tooltip —
/// the row stays as quiet as the rest of the panel.
private struct LatentRow: View {
    let name: String
    let path: String
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
