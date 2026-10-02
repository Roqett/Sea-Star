import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// The configuration surface the right-click menu's "Settings…" opens (spec
/// §8.4). It is the searchable, roomy counterpart to the popover: every known
/// vault can be filtered and picked, and any folder can be adopted.
///
/// It is also drawn in the house style now (D-012): the same canvas, ink and
/// mono accents as the cockpit and the onboarding window, so the three surfaces
/// read as one app instead of one app and a generic Apple form.
struct SettingsView: View {
    let controller: ServerController

    @State private var vaultQuery = ""
    @State private var isImportingVault = false
    @State private var updateStatus: String?
    @State private var isChecking = false

    private static let markSize: CGFloat = 26

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                engineSection
                vaultSection
                inferenceSection
                logsSection
                updatesSection
                linksSection
            }
            .padding(20)
        }
        .frame(width: 460, height: 560)
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
                Text(Strings.Settings.title)
                    .font(.caption)
                    .foregroundStyle(Palette.inkMuted)
            }

            Spacer()

            Button(Strings.Menu.onboarding) {
                openOnboarding()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(Palette.electricBlue)
        }
    }

    private func openOnboarding() {
        (NSApp.delegate as? AppDelegate)?.openOnboarding()
    }

    // MARK: - Sections

    private var engineSection: some View {
        section(Strings.Settings.engine) {
            SettingsRow(label: Strings.Settings.status, accent: controller.isEngineResolved ? Palette.neonGreen : Palette.vermilion) {
                HStack(spacing: 6) {
                    Text(controller.isEngineResolved ? Strings.Settings.engineResolved : Strings.Settings.engineMissing)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                    if let path = controller.enginePath {
                        Text(path)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Palette.inkMuted)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            if !controller.isEngineResolved {
                Text(Strings.Settings.engineHint)
                    .font(.caption)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var vaultSection: some View {
        section(Strings.Settings.vault) {
            SettingsRow(label: Strings.Rows.vault, accent: Palette.vaultGlow) {
                Text(controller.report?.vault.path ?? Strings.States.unknown)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            TextField(Strings.Settings.vaultSearch, text: $vaultQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .padding(8)
                .background(Palette.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(filteredVaults, id: \.self) { path in
                        vaultRow(path)
                    }
                }
            }
            .frame(maxHeight: 150)

            HStack(spacing: 14) {
                wordButton(Strings.Actions.openFolder) { isImportingVault = true }
                wordButton(Strings.Settings.vaultDetected, enabled: controller.vaultOverride != nil) {
                    controller.clearVaultOverride()
                }
            }
        }
    }

    private func vaultRow(_ path: String) -> some View {
        let isCurrent = path == controller.report?.vault.path
        return Button {
            controller.selectVault(path)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isCurrent ? "checkmark" : "folder")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isCurrent ? Palette.teal : Palette.inkMuted)
                    .frame(width: 14)
                VStack(alignment: .leading, spacing: 1) {
                    Text((path as NSString).lastPathComponent)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                    Text(path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Palette.inkMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var inferenceSection: some View {
        section(Strings.Rows.inference) {
            if controller.inferenceOptions.count > 1 {
                SettingsRow(label: Strings.Rows.inference, accent: Palette.inferenceGlow) {
                    Picker("", selection: Binding(
                        get: { controller.report?.baseURL ?? "" },
                        set: { controller.selectInference($0) }
                    )) {
                        ForEach(controller.inferenceOptions) { option in
                            Text("\(option.name) · \(option.baseURL)").tag(option.baseURL)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
            } else {
                SettingsRow(label: Strings.Rows.inference, accent: Palette.inferenceGlow) {
                    Text(harnessValue)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            if controller.modelOptions.count > 1 {
                SettingsRow(label: Strings.Rows.model, accent: Palette.modelGlow) {
                    Picker("", selection: Binding(
                        get: { controller.report?.model ?? "" },
                        set: { controller.selectModel($0) }
                    )) {
                        ForEach(controller.modelOptions, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
            } else {
                SettingsRow(label: Strings.Rows.model, accent: Palette.modelGlow) {
                    Text(modelValue)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }

    private var logsSection: some View {
        section(Strings.Logs.title) {
            SettingsRow(label: Strings.Logs.retention, accent: Palette.working) {
                Picker("", selection: Binding(
                    get: { controller.logs.retentionDays },
                    set: { controller.logs.retentionDays = $0 }
                )) {
                    ForEach(LogStore.retentionOptions, id: \.self) { days in
                        Text(Strings.Logs.retentionLabel(days)).tag(days)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            SettingsRow(label: Strings.Logs.entries, accent: Palette.working) {
                HStack(spacing: 14) {
                    Text("\(controller.logs.entries.count)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Palette.inkMuted)
                        .monospacedDigit()
                    wordButton(Strings.Logs.clearNow, enabled: !controller.logs.entries.isEmpty) {
                        controller.logs.clear()
                    }
                    wordButton(Strings.Logs.reveal, enabled: controller.logs.logFileURL != nil) {
                        revealLogs()
                    }
                }
            }
        }
    }

    private func revealLogs() {
        guard let url = controller.logs.logFileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private var updatesSection: some View {
        section(Strings.Settings.updates) {
            SettingsRow(label: Strings.Menu.checkForUpdates, accent: Palette.ready) {
                HStack(spacing: 14) {
                    if let updateStatus {
                        Text(updateStatus)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Palette.inkMuted)
                            .lineLimit(1)
                    }
                    wordButton(Strings.Actions.checkNow, enabled: !isChecking) {
                        checkForUpdates()
                    }
                }
            }
            SettingsRow(label: Strings.Settings.version, accent: Palette.mauve) {
                Text(AppInfo.versionLine)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Palette.inkMuted)
            }
        }
    }

    private var linksSection: some View {
        section(Strings.Settings.links) {
            HStack(spacing: 16) {
                linkWord(Links.issues, Strings.Menu.help, "questionmark.circle")
                linkWord(Links.patchdog, Strings.Menu.patchdog, "ladybug")
                linkWord(Links.repository, Strings.Header.title, "star")
            }
        }
    }

    // MARK: - The house pieces

    /// A section in the house style: one mono heading, quiet, and the rows
    /// beneath it. The same shape the cockpit and onboarding use, so nothing in
    /// Settings looks like it belongs to a different app.
    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.inkMuted)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// One labelled setting: an accent bar, a fixed label column, and the
    /// control or value. Mirrors the cockpit's rows so the two surfaces agree.
    private struct SettingsRow<Content: View>: View {
        let label: String
        let accent: Color
        @ViewBuilder let content: Content

        var body: some View {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                AccentBar(color: accent)

                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.inkMuted)
                    .frame(width: 96, alignment: .leading)

                content

                Spacer(minLength: 0)
            }
        }
    }

    /// A plain word button, exactly as the cockpit draws them: mono, small, and
    /// answerable to the cursor with a faint ground rather than shouting.
    private func wordButton(
        _ title: String,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(enabled ? Palette.electricBlue : Palette.inkMuted.opacity(0.45))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func linkWord(_ url: URL, _ title: String, _ symbol: String) -> some View {
        Link(destination: url) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(Palette.inkMuted)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Derived

    private var filteredVaults: [String] {
        let all = controller.vaultOptions
        guard !vaultQuery.isEmpty else { return all }
        return all.filter { $0.localizedCaseInsensitiveContains(vaultQuery) }
    }

    private var harnessValue: String {
        guard let report = controller.report else { return Strings.States.unknown }
        return "\(report.runtime) · \(report.baseURL)"
    }

    private var modelValue: String {
        controller.report?.model ?? Strings.States.unknown
    }

    private func checkForUpdates() {
        isChecking = true
        updateStatus = Strings.Updates.checking
        Task { @MainActor in
            let outcome = await UpdateChecker().check(currentVersion: AppInfo.version)
            switch outcome {
            case .upToDate(let current):
                updateStatus = Strings.Updates.upToDate(current)
            case .available(_, let latest, _):
                updateStatus = "Sea-Star \(latest) is available."
            case .failed(let reason):
                updateStatus = reason
            }
            isChecking = false
        }
    }
}
