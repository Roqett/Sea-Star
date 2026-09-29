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

/// A persona the person built in a harness (an Osaurus agent). Identity is its
/// name — the one thing that is unique on their roster — with the bound model
/// optional, since an agent may ride whatever model the harness is set to.
struct AgentOption: Identifiable, Equatable, Sendable {
    var id: String { name }
    let name: String
    let model: String?
    let description: String

    /// The harness a qualified model id names (``omlx/…`` -> ``omlx``), if any.
    var provider: String? {
        guard let model, let slash = model.firstIndex(of: "/") else { return nil }
        let head = String(model[model.startIndex..<slash])
        return head.isEmpty ? nil : head
    }
}

/// What the cockpit can honestly say about the agent roster.
///
/// These four are genuinely different facts, and collapsing them into one
/// "No agent" string would be a small lie in three of the four cases. The
/// split exists because the foundation's degradation contract asks the panel to
/// show the highest rung it proved *and* which rung that was.
enum AgentState: Equatable, Sendable {
    /// A roster was found, and the engine named whose it is.
    case roster([AgentOption])
    /// A source answered and reported no agents.
    case empty
    /// No roster was found anywhere.
    case notFound
    /// Agents arrived without a source — an engine too old to say. The app
    /// will not guess, because guessing means claiming a roster belongs to the
    /// machine when it demonstrably belongs to one app.
    case unconfirmed
}

/// A known harness app installed on this Mac but not answering on a port — an
/// IDE or runtime app that carries its own model loop. Identity is its bundle id,
/// the one thing stable across a rename or a move between Applications folders.
struct LatentHarnessOption: Identifiable, Equatable, Sendable {
    var id: String { bundleID }
    let name: String
    let bundleID: String
    let path: String
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

    /// Bundle ids of latent harnesses the person has switched *off*. Detected
    /// harnesses float by default, so the starfield shows at a glance where this
    /// machine could work rather than hiding every idle app until it is asked
    /// for; the person takes away the ones they do not want in view.
    private(set) var hiddenLatentHarnesses: Set<String>

    private static let hiddenLatentHarnessesKey = "SeaStar.latentHarnessesOff"
    private static let legacyEnabledLatentHarnessesKey = "SeaStar.latentHarnesses"

    private let command: EngineCommand?
    private var serveProcess: Process?
    /// The write end of the server's stdin. `serve` is a stdio MCP server: the
    /// moment its stdin hits EOF it shuts down. A `Process` whose standardInput
    /// is left unset inherits the app's own stdin — closed for a menu-bar app —
    /// so the child saw EOF and exited instantly while the pill still read
    /// "Running". Holding this pipe open keeps the server genuinely alive; it is
    /// released only when the server is stopped.
    private var serveInput: Pipe?

    /// The rolling log of engine output (spec §8.8). It lives here because the
    /// engine process does — everything the engine prints lands in one place,
    /// pruned on a retention window the person sets in Settings.
    let logs = LogStore()

    init(command: EngineCommand? = EngineCommand.resolve()) {
        self.command = command
        self.seenHarnesses = Set(
            UserDefaults.standard.stringArray(forKey: Self.seenHarnessesKey) ?? []
        )
        self.hiddenLatentHarnesses = Set(
            UserDefaults.standard.stringArray(forKey: Self.hiddenLatentHarnessesKey) ?? []
        )
        // The old key stored the *enabled* ones, so it is now meaningless and
        // would otherwise linger as a stale preference forever.
        UserDefaults.standard.removeObject(forKey: Self.legacyEnabledLatentHarnessesKey)
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

    /// The personas the person built in their harness (spec §8.7). They are not
    /// scoped to the active harness — a roster the person made is theirs to see
    /// whichever harness the engine is talking to.
    var agentOptions: [AgentOption] {
        report?.detectedAgents.map {
            AgentOption(name: $0.name, model: $0.model, description: $0.description)
        } ?? []
    }

    /// Whose roster the agents belong to, as the engine reported it. `nil`
    /// means the engine could not say, and the panel must not fill the gap with
    /// a guess.
    var agentSource: String? {
        report?.agentSource
    }

    /// A display label for the roster's owner, capitalised for reading in a row.
    /// An unnameable roster gets a word that admits it rather than a name the
    /// app invented.
    var agentScopeLabel: String {
        guard let source = report?.agentSource, !source.isEmpty else {
            return Strings.Rows.agentScopeUnknown
        }
        return source.prefix(1).uppercased() + source.dropFirst()
    }

    /// The Agent row's state, derived rather than stored, so it can never drift
    /// out of step with the report it describes.
    var agentState: AgentState {
        let options = agentOptions
        guard !options.isEmpty else {
            // No agents at all. Whether that is "empty" or "not found" depends
            // on whether the engine told us it looked — a roster source that
            // exists and is empty is a different fact from no source at all.
            return report?.hasKnownAgentSource == true ? .empty : .notFound
        }
        return report?.hasKnownAgentSource == true ? .roster(options) : .unconfirmed
    }

    /// The persona the person has chosen, if any. Kept in memory only: an
    /// agent is a reading of the cockpit, not a server setting, so it is not
    /// persisted and not sent to the engine as an override.
    private(set) var selectedAgentName: String?

    /// Choose which persona the panel reads. This deliberately does *not*
    /// restart the server or set an environment override — the engine has no
    /// knob for "talk to this agent", and pretending otherwise would make the
    /// control look load-bearing when it is not. What it genuinely changes is
    /// what the panel shows.
    func selectAgent(_ name: String) {
        guard agentOptions.contains(where: { $0.name == name }) else { return }
        selectedAgentName = name
    }

    /// Every installed-but-idle harness the engine found, in the engine's stable
    /// order. These are togglable rather than autodetected: an app on the disk is
    /// not a connection, so the person decides which ones float on the graph.
    var latentHarnessOptions: [LatentHarnessOption] {
        report?.detectedLatentHarnesses.map {
            LatentHarnessOption(name: $0.name, bundleID: $0.bundleID, path: $0.path)
        } ?? []
    }

    /// The latent harnesses the person has kept in view — every detected one
    /// that has not been switched off.
    var visibleLatentHarnesses: [LatentHarnessOption] {
        latentHarnessOptions.filter { isLatentHarnessEnabled($0.bundleID) }
    }

    /// Whether an installed-but-idle harness is currently floating on the graph.
    /// Everything detected is in view until the person takes it off.
    func isLatentHarnessEnabled(_ bundleID: String) -> Bool {
        !hiddenLatentHarnesses.contains(bundleID)
    }

    /// Float a latent harness on the graph, or take it back off. The choice is a
    /// durable preference — an idle harness the person wanted to keep out of view
    /// should stay out the next time the cockpit opens.
    func toggleLatentHarness(_ bundleID: String) {
        if hiddenLatentHarnesses.contains(bundleID) {
            hiddenLatentHarnesses.remove(bundleID)
        } else {
            hiddenLatentHarnesses.insert(bundleID)
        }
        UserDefaults.standard.set(
            Array(hiddenLatentHarnesses), forKey: Self.hiddenLatentHarnessesKey
        )
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
                adopt(report)
                logs.append("refresh · \(report.runtime) · \(report.model.isEmpty ? "no model" : report.model)")
            case .failure(let failure):
                apply(failure: failure)
            }
        } catch {
            apply(failure: error.localizedDescription)
        }
    }

    /// Take a report as the current reading, clearing any stale guidance.
    ///
    /// Pulled out of `refresh` so the one place that *accepts* a report is named
    /// rather than inlined, and so the graph's liveness rules can be tested
    /// against a real report without a live engine behind it. Everything the
    /// graph draws is a function of this value, so being able to set it is the
    /// difference between testing the honesty contract and only testing that the
    /// plumbing compiles.
    func adopt(_ report: DoctorReport) {
        self.report = report
        self.message = nil
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
        let inputPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        process.terminationHandler = { [weak self] proc in
            let status = proc.terminationStatus
            let reason = proc.terminationReason == .uncaughtSignal ? "signal" : "exit"
            Task { @MainActor in
                guard let self, self.serveProcess === process else { return }
                self.isServerRunning = false
                self.serveProcess = nil
                self.serveInput = nil
                self.logs.append("engine exited on its own · \(reason) \(status)")
            }
        }

        do {
            try process.run()
            serveProcess = process
            serveInput = inputPipe
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
        serveInput = nil
        isServerRunning = false
        logs.append("engine stopped by request")
    }

    private func apply(failure: String) {
        report = nil
        message = failure
    }
}
