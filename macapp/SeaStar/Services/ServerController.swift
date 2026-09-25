import Foundation
import Observation

/// A local harness the person can switch between. Identity is its endpoint,
/// because two names can describe the same address (oMLX and vLLM both default
/// to port 8000).
struct HarnessOption: Identifiable, Equatable, Sendable {
    var id: String { baseURL }
    let name: String
    let baseURL: String
    let models: [String]
}

/// Owns the app's view of the engine: the last decoded report, any fail-loud
/// message, and the running/stopped state of the MCP server.
///
/// The engine process belongs to the app (spec §6 — `server.state` may be local
/// app state), so this type is the single place that starts and stops it.
@MainActor
@Observable
final class ServerController {
    private(set) var report: DoctorReport?
    private(set) var message: String?
    private(set) var isRefreshing = false
    private(set) var isServerRunning = false

    /// Which face the app is wearing right now. It changes each time the server
    /// opens or shuts (spec §7 — the Easter egg), never repeating the face that
    /// just went away.
    private(set) var currentIcon: AppIcon = IconRoster.first

    /// The person's explicit choices from the popover. `nil` means "let the
    /// engine autodetect" (env > TOML > Obsidian, config.py).
    private(set) var vaultOverride: String?
    private(set) var modelOverride: String?
    private(set) var harnessOverride: HarnessOption?

    /// Harness identities the person has already been on. A brand-new one gets a
    /// setting-up hint beside its starfish (spec §8.7), then drops out of the
    /// "new" set once acknowledged.
    private(set) var seenHarnesses: Set<String>

    private static let seenHarnessesKey = "SeaStar.seenHarnesses"

    private let command: EngineCommand?
    private var serveProcess: Process?

    /// The rolling log of engine output (spec §8.8). It lives here because the
    /// engine process does — everything the engine prints lands in one place,
    /// pruned on a retention window the person sets in Settings.
    let logs = LogStore()

    init(command: EngineCommand? = EngineCommand.resolve()) {
        self.command = command
        self.seenHarnesses = Set(
            UserDefaults.standard.stringArray(forKey: Self.seenHarnessesKey) ?? []
        )
    }

    var isReady: Bool { report?.ready ?? false }

    /// Whether an engine command resolved, and where it points — surfaced in the
    /// Settings window so a broken install is diagnosable at a glance.
    var isEngineResolved: Bool { command != nil }

    var enginePath: String? { command?.executableURL.path }

    /// The extra environment every engine call carries — the person's choices,
    /// mapped onto the same knobs the CLI reads.
    private var environment: [String: String] {
        var overrides: [String: String] = [:]
        if let vaultOverride { overrides[EngineCommand.vaultOverrideKey] = vaultOverride }
        if let modelOverride { overrides[EngineCommand.modelOverrideKey] = modelOverride }
        if let harnessOverride {
            overrides[EngineCommand.baseURLOverrideKey] = harnessOverride.baseURL
            overrides[EngineCommand.runtimeOverrideKey] = harnessOverride.name
        }
        return overrides
    }

    /// Every harness the engine found, with the current one kept in the list even
    /// when it came from env/TOML rather than detection (spec §8).
    var harnessOptions: [HarnessOption] {
        guard let report else { return [] }
        var options = report.detectedRuntimes.map {
            HarnessOption(name: $0.name, baseURL: $0.baseURL, models: $0.models)
        }
        if !options.contains(where: { $0.baseURL == report.baseURL }) {
            options.insert(
                HarnessOption(name: report.runtime, baseURL: report.baseURL, models: report.models),
                at: 0
            )
        }
        return options
    }

    /// The harness the report is currently describing, if it can be matched.
    var currentHarness: HarnessOption? {
        guard let report else { return nil }
        return harnessOptions.first { $0.baseURL == report.baseURL }
    }

    /// The note to grow beside the active starfish, or `nil` when there is
    /// nothing worth saying (spec §8.7).
    var currentTip: HarnessTip? {
        guard let report else { return nil }
        return HarnessTips.tip(
            harnessName: currentHarness?.name ?? report.runtime,
            isNew: isCurrentHarnessNew,
            isReady: report.ready,
            modelCount: modelOptions.count,
            vaultName: (report.vault.path as NSString).lastPathComponent,
            otherVaults: max(vaultOptions.count - 1, 0)
        )
    }

    /// Whether the harness the report is describing has never been seen before.
    var isCurrentHarnessNew: Bool {
        guard let report else { return false }
        return !seenHarnesses.contains(HarnessTips.identity(baseURL: report.baseURL))
    }

    /// Remember the current harness, so its setting-up hint doesn't nag again.
    func rememberCurrentHarness() {
        guard let report else { return }
        let updated = HarnessTips.remembered(
            seenHarnesses,
            adding: HarnessTips.identity(baseURL: report.baseURL)
        )
        guard updated != seenHarnesses else { return }
        seenHarnesses = updated
        UserDefaults.standard.set(Array(updated), forKey: Self.seenHarnessesKey)
    }

    /// Vaults the popover offers: the Obsidian-known candidates, with the current
    /// vault kept in the list even when it came from env/TOML (spec §8.1).
    var vaultOptions: [String] {
        guard let report else { return [] }
        var options = report.vault.candidates
        if !options.contains(report.vault.path) {
            options.insert(report.vault.path, at: 0)
        }
        return options
    }

    /// Models the endpoint reports, with the current model kept in the list
    /// (spec §8.3). The selected harness's own models come first, so switching
    /// harness swaps the model list even before the engine re-reports (e.g. a
    /// Qwen model served only by oMLX).
    var modelOptions: [String] {
        guard let report else { return [] }
        var options = currentHarness.map(\.models).flatMap { $0.isEmpty ? nil : $0 } ?? report.models
        if !report.model.isEmpty, !options.contains(report.model) {
            options.insert(report.model, at: 0)
        }
        return options
    }

    /// Ask the engine what it found. Either a report lands or a plain-language
    /// message does — never both, never a crash.
    func refresh() async {
        guard let command else {
            apply(failure: Strings.Errors.engineNotResolved)
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let response = try await EngineClient(command: command).doctor(environment: environment)
            switch response {
            case .report(let report):
                self.report = report
                self.message = nil
                logs.append("refresh · \(report.runtime) · \(report.model.isEmpty ? "no model" : report.model)")
            case .failure(let failure):
                apply(failure: failure)
            }
        } catch {
            apply(failure: error.localizedDescription)
        }
    }

    /// Switch vault and re-read. A running server is restarted so the new choice
    /// takes effect — it was spawned with the previous environment.
    func selectVault(_ path: String) {
        vaultOverride = path
        applySelection()
    }

    /// Drop any explicit vault so the engine autodetects again (env > TOML >
    /// Obsidian, config.py).
    func clearVaultOverride() {
        vaultOverride = nil
        applySelection()
    }

    /// Switch model and re-read, restarting a running server if needed.
    func selectModel(_ model: String) {
        modelOverride = model
        applySelection()
    }

    /// Switch the harness the engine talks to and re-read. Any model chosen on
    /// the previous endpoint is cleared — it may not exist on the new one, so the
    /// engine picks that harness's first model instead.
    func selectHarness(_ baseURL: String) {
        guard let option = harnessOptions.first(where: { $0.baseURL == baseURL }) else { return }
        harnessOverride = option
        modelOverride = nil
        applySelection()
    }

    private func applySelection() {
        if isServerRunning, let command {
            stopServer()
            startServer(command)
            rollIcon()
        }
        Task { await refresh() }
    }

    func toggleServer() {
        guard let command else {
            apply(failure: Strings.Errors.engineNotResolved)
            return
        }
        if isServerRunning {
            stopServer()
            rollIcon()
        } else if startServer(command) {
            rollIcon()
        }
    }

    /// Move to a face that isn't the current one — the "open and shut" reroll.
    private func rollIcon() {
        currentIcon = IconRoster.next(after: currentIcon)
    }

    @discardableResult
    private func startServer(_ command: EngineCommand) -> Bool {
        let invocation = command.serve(environment: environment)
        let process = Process()
        process.executableURL = invocation.executableURL
        process.arguments = invocation.arguments
        if let directory = invocation.workingDirectoryURL,
           FileManager.default.fileExists(atPath: directory.path) {
            process.currentDirectoryURL = directory
        }
        if !invocation.environment.isEmpty {
            process.environment = ProcessInfo.processInfo.environment
                .merging(invocation.environment) { _, override in override }
        }
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            serveProcess = process
            isServerRunning = true
            message = nil
            logs.append("engine started · \(invocation.executableURL.lastPathComponent)")
            drain(process.standardOutput as? Pipe)
            drain(process.standardError as? Pipe)
            return true
        } catch {
            apply(failure: Strings.Errors.launchFailed(error.localizedDescription))
            return false
        }
    }

    /// Feed whatever the engine prints into the rolling log. The handler runs on
    /// a background queue, so it hops to the main actor before touching state.
    private func drain(_ pipe: Pipe?) {
        guard let pipe else { return }
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in self?.logs.append(text) }
        }
    }

    private func stopServer() {
        (serveProcess?.standardOutput as? Pipe)?.fileHandleForReading.readabilityHandler = nil
        (serveProcess?.standardError as? Pipe)?.fileHandleForReading.readabilityHandler = nil
        serveProcess?.terminate()
        serveProcess = nil
        isServerRunning = false
        logs.append("engine stopped")
    }

    private func apply(failure: String) {
        report = nil
        message = failure
    }
}
