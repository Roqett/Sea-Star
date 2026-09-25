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

    private let command: EngineCommand?
    private var serveProcess: Process?

    init(command: EngineCommand? = EngineCommand.resolve()) {
        self.command = command
    }

    var isReady: Bool { report?.ready ?? false }

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
    /// (spec §8.3).
    var modelOptions: [String] {
        guard let report else { return [] }
        var options = report.models
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
            return true
        } catch {
            apply(failure: Strings.Errors.launchFailed(error.localizedDescription))
            return false
        }
    }

    private func stopServer() {
        serveProcess?.terminate()
        serveProcess = nil
        isServerRunning = false
    }

    private func apply(failure: String) {
        report = nil
        message = failure
    }
}
