import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// The configuration surface the right-click menu's "Settings…" opens (spec
/// §8.4). It is the searchable, roomy counterpart to the popover: every known
/// vault can be filtered and picked, and any folder can be adopted.
struct SettingsView: View {
    let controller: ServerController

    @State private var vaultQuery = ""
    @State private var isImportingVault = false
    @State private var updateStatus: String?
    @State private var isChecking = false

    var body: some View {
        Form {
            engineSection
            vaultSection
            harnessSection
            logsSection
            updatesSection
            linksSection
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 560)
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

    // MARK: - Sections

    private var engineSection: some View {
        Section {
            LabeledContent(Strings.Settings.engine) {
                HStack(spacing: 8) {
                    Image(systemName: controller.isEngineResolved ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(controller.isEngineResolved ? Palette.neonGreen : Palette.vermilion)
                    Text(controller.isEngineResolved ? Strings.Settings.engineResolved : Strings.Settings.engineMissing)
                    if let path = controller.enginePath {
                        Text(path)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            if !controller.isEngineResolved {
                Text(Strings.Settings.engineHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var vaultSection: some View {
        Section(Strings.Settings.vault) {
            LabeledContent(Strings.Rows.vault) {
                Text(controller.report?.vault.path ?? Strings.States.unknown)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            TextField(Strings.Settings.vaultSearch, text: $vaultQuery)
                .textFieldStyle(.roundedBorder)

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(filteredVaults, id: \.self) { path in
                        vaultRow(path)
                    }
                }
            }
            .frame(maxHeight: 150)

            HStack {
                Button(Strings.Actions.openFolder) { isImportingVault = true }
                Button(Strings.Settings.vaultDetected) { controller.clearVaultOverride() }
                    .disabled(controller.vaultOverride == nil)
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
                    .foregroundStyle(isCurrent ? Palette.teal : .secondary)
                    .frame(width: 14)
                VStack(alignment: .leading, spacing: 1) {
                    Text((path as NSString).lastPathComponent)
                        .foregroundStyle(.primary)
                    Text(path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }

    private var harnessSection: some View {
        Section {
            if controller.inferenceOptions.count > 1 {
                Picker(Strings.Rows.inference, selection: Binding(
                    get: { controller.report?.baseURL ?? "" },
                    set: { controller.selectInference($0) }
                )) {
                    ForEach(controller.inferenceOptions) { option in
                        Text("\(option.name) · \(option.baseURL)").tag(option.baseURL)
                    }
                }
            } else {
                LabeledContent(Strings.Rows.inference) {
                    Text(harnessValue)
                }
            }

            if controller.modelOptions.count > 1 {
                Picker(Strings.Rows.model, selection: Binding(
                    get: { controller.report?.model ?? "" },
                    set: { controller.selectModel($0) }
                )) {
                    ForEach(controller.modelOptions, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
            } else {
                LabeledContent(Strings.Rows.model) {
                    Text(modelValue)
                }
            }
        }
    }

    private var logsSection: some View {
        Section(Strings.Logs.title) {
            Picker(Strings.Logs.retention, selection: Binding(
                get: { controller.logs.retentionDays },
                set: { controller.logs.retentionDays = $0 }
            )) {
                ForEach(LogStore.retentionOptions, id: \.self) { days in
                    Text(Strings.Logs.retentionLabel(days)).tag(days)
                }
            }
            LabeledContent(Strings.Logs.entries) {
                HStack(spacing: 10) {
                    Text("\(controller.logs.entries.count)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Button(Strings.Logs.clearNow) { controller.logs.clear() }
                        .disabled(controller.logs.entries.isEmpty)
                    Button(Strings.Logs.reveal) { revealLogs() }
                        .disabled(controller.logs.logFileURL == nil)
                }
            }
        }
    }

    private func revealLogs() {
        guard let url = controller.logs.logFileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private var updatesSection: some View {
        Section(Strings.Settings.updates) {
            LabeledContent(Strings.Menu.checkForUpdates) {
                HStack(spacing: 10) {
                    if let updateStatus {
                        Text(updateStatus)
                            .foregroundStyle(.secondary)
                    }
                    Button(Strings.Actions.checkNow) { checkForUpdates() }
                        .disabled(isChecking)
                }
            }
            LabeledContent("Version") { Text(AppInfo.versionLine) }
        }
    }

    private var linksSection: some View {
        Section(Strings.Settings.links) {
            Link(destination: Links.issues) { Label(Strings.Menu.help, systemImage: "questionmark.circle") }
            Link(destination: Links.patchdog) { Label(Strings.Menu.patchdog, systemImage: "ladybug") }
            Link(destination: Links.repository) { Label(Strings.Header.title, systemImage: "star") }
        }
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
