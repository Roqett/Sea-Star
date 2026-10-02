import Foundation
import Observation

/// A local harness the person can switch between. Identity is its endpoint,
/// because two names can describe the same address (oMLX and vLLM both default
/// to port 8000).
struct InferenceOption: Identifiable, Equatable, Sendable {
    var id: String { baseURL }
    let name: String
    let baseURL: String
    let models: [String]

    /// Whether this endpoint is off this machine. The ontology draws a local
    /// runtime and a remote API as the same row but never as the same thing:
    /// one is "about the machine", the other is "what is coming in".
    var isRemote: Bool {
        guard let host = URL(string: baseURL)?.host()?.lowercased() else { return false }
        return !(host == "localhost" || host == "127.0.0.1" || host == "::1" || host == "0.0.0.0")
    }
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
/// How far a harness got, in the foundation's own ladder words. The graph draws
/// the rung rather than a yes/no "connected", because "installed", "up" and
/// "answering" are three different facts and collapsing them is what makes a
/// cockpit look like it knows more than it does.
enum HarnessRung: String, Sendable, Equatable, CaseIterable {
    /// A live `sea-star serve` process records it as the host that spawned it.
    case connected
    /// A port probe answers in its name.
    case listening
    /// A process owns the app right now, but nothing answers on a port.
    case running
    /// The app is installed; nothing is up.
    case present

    /// Whether Sea-Star can currently hand this harness a question.
    var isAttached: Bool { self == .connected }

    /// The rung as it should read to a person, not as a ladder number.
    var label: String {
        switch self {
        case .connected: return Strings.Detail.rungConnected
        case .listening: return Strings.Detail.rungListening
        case .running: return Strings.Detail.rungRunning
        case .present: return Strings.Detail.rungPresent
        }
    }
}

/// A harness app on this Mac that is not attached to the engine over stdio.
/// Identity is its bundle id — stable across installs and renames — with the
/// rung it reached carried alongside, so the graph can say "up, not answering"
/// instead of flattening every unattached app to the same absence.
struct LatentHarnessOption: Identifiable, Equatable, Sendable {
    var id: String { bundleID }
    let name: String
    let bundleID: String
    let path: String
    private let rawRung: String?

    init(name: String, bundleID: String, path: String, rung: String? = nil) {
        self.name = name
        self.bundleID = bundleID
        self.path = path
        self.rawRung = rung
    }

    /// How far this app climbed. An engine that could not say leaves it
    /// unknown rather than assumed, so the graph says nothing instead of lying.
    var rung: HarnessRung? {
        guard let rawRung else { return nil }
        switch rawRung.lowercased() {
        case "connected", "caller-attributed": return .connected
        case "listening": return .listening
        case "running": return .running
        case "present", "declared": return .present
        default: return nil
        }
    }
}

/// A harness app that is attached to the engine over stdio *right now*: it
/// spawned the `serve` process, so the engine knows which process is asking.
/// This is the one harness state that is proof rather than presence.
struct AttachedHarnessOption: Identifiable, Equatable, Sendable {
    var id: String { bundleID ?? name }
    let name: String
    let bundleID: String?
    let pid: Int
    let startedAt: String
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
    private(set) var inferenceOverride: InferenceOption?

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
        if let inferenceOverride {
            overrides[EngineCommand.baseURLOverrideKey] = inferenceOverride.baseURL
            overrides[EngineCommand.runtimeOverrideKey] = inferenceOverride.name
        }
        return overrides
    }

    /// Every harness app attached to the engine over stdio right now. This is
    /// the honest top rung: the engine recorded which process spawned its
    /// `serve`, so an entry here is a live connection and not a guess from a
    /// disk scan. It is also how a harness that *is* this machine's agent —
    /// the one the person is talking to — ends up on the graph.
    var attachedHarnesses: [AttachedHarnessOption] {
        report?.attachedMcpClients.map {
            AttachedHarnessOption(
                name: $0.name,
                bundleID: $0.bundleID,
                pid: $0.pid,
                startedAt: $0.startedAt
            )
        } ?? []
    }

    /// Every endpoint models can come from, with the one the report is
    /// describing kept in the list even when it came from env/TOML rather than
    /// detection (spec §8). This is the ontology's Inference row: an endpoint
    /// is where models live, whereas a harness is what drives Sea-Star, and
    /// filing the two as one thing is what made the cockpit unreadable.
    var inferenceOptions: [InferenceOption] {
        guard let report else { return [] }
        var options = report.detectedRuntimes.map {
            InferenceOption(name: $0.name, baseURL: $0.baseURL, models: $0.models)
        }
        if !options.contains(where: { $0.baseURL == report.baseURL }) {
            options.insert(
                InferenceOption(name: report.runtime, baseURL: report.baseURL, models: report.models),
                at: 0
            )
        }
        return options
    }

    /// The inference endpoint the report is currently describing, if it can be
    /// matched.
    var currentInference: InferenceOption? {
        guard let report else { return nil }
        return inferenceOptions.first { $0.baseURL == report.baseURL }
    }

    /// The note to grow beside the active starfish, or `nil` when there is
    /// nothing worth saying (spec §8.7).
    var currentTip: HarnessTip? {
        guard let report else { return nil }
        return HarnessTips.tip(
            inferenceName: currentInference?.name ?? report.runtime,
            isNew: isCurrentHarnessNew,
            isReady: report.ready,
            model: report.model,
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
        var options = currentInference.map(\.models).flatMap { $0.isEmpty ? nil : $0 } ?? report.models
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

    /// The persona the panel is currently reading, resolved from its name.
    ///
    /// The whole cascade hangs off this one lookup: an agent lives in a harness,
    /// rides a model, and the model comes from an endpoint. Pick the agent and
    /// the other two rows can now say where it is.
    var selectedAgent: AgentOption? {
        guard let name = selectedAgentName else { return nil }
        return agentOptions.first { $0.name == name }
    }

    /// Where the selected agent is, in one honest sentence (D-013).
    ///
    /// Three cases, and they must be told apart rather than flattened:
    ///
    /// 1. A running endpoint lists the agent's model — it is *there*.
    /// 2. The agent's model names a provider whose endpoint is up, but the
    ///    endpoint is not serving that model — "built for X, X is not
    ///    serving it". On this machine this is Patchdog's real state.
    /// 3. Nothing answers to the model at all.
    ///
    /// A sentence is returned rather than a structure because the panel draws
    /// it as one line, and the MCP answer renders the same three cases from
    /// the same rule in Python — one cascade, one wording.
    func placement(of agent: AgentOption) -> String {
        guard let model = agent.model, !model.isEmpty else {
            return Strings.Rows.agentRidesWhatever
        }
        let serving = inferenceOptions.first { $0.models.contains(model) }
        if let endpoint = serving {
            return Strings.Rows.agentRunsOn(model, endpoint.name)
        }
        if let provider = agent.provider,
           let named = inferenceOptions.first(where: { $0.name.caseInsensitiveCompare(provider) == .orderedSame }) {
            return Strings.Rows.agentBuiltFor(model, named.name)
        }
        return Strings.Rows.agentModelNowhere(model)
    }

    /// Every harness app the engine found that is not attached over stdio, in
    /// the engine's stable order, each carrying the rung it reached. These are
    /// togglable rather than autodetected: an app on the disk is not a
    /// connection, so the person decides which ones float on the graph — but a
    /// running one is drawn as running, not smeared into the same grey as a
    /// dormant install.
    var latentHarnessOptions: [LatentHarnessOption] {
        report?.detectedLatentHarnesses.map {
            LatentHarnessOption(
                name: $0.name,
                bundleID: $0.bundleID,
                path: $0.path,
                rung: $0.rung
            )
        } ?? []
    }

    /// The harness apps the person has kept in view — every detected one that
    /// has not been switched off.
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

    /// The app whose inbuilt server is answering on this endpoint, if any.
    ///
    /// Read from the port rather than assumed from a name: the reconnaissance
    /// says which process owns the socket, and the parent chain says which app
    /// owns the process. On this machine every endpoint is inbuilt, which means
    /// the model Sea-Star thinks with can die because somebody quit a chat app —
    /// a fact the cockpit has to be able to state plainly.
    func bundledOwner(of baseURL: String) -> String? {
        guard let url = URL(string: baseURL), let port = url.port else { return nil }
        return report?.modelServers.first { $0.port == port }?.appName
    }

    /// Whether the endpoint Sea-Star is currently using belongs to another app.
    var currentEndpointIsBundled: Bool {
        guard let report else { return false }
        return bundledOwner(of: report.baseURL) != nil
    }

    /// What each app is doing with models, as the engine observed it.
    ///
    /// The point of the whole cockpit, stated once: every harness on this machine
    /// has a commercial interest in which endpoint a person uses, and none of
    /// them volunteers which one they are using right now. This is the one place
    /// that says it without a stake in the answer.
    var appBehaviour: [DoctorReport.HarnessBehaviourInfo] {
        report?.appBehaviour ?? []
    }

    // MARK: - The register

    /// What is on this machine and has not been decided about. The engine does
    /// the finding; the app only asks, so there is one place a thing can enter
    /// the graph and one place a person can answer for it.
    var candidates: [DoctorReport.CandidateInfo] {
        report?.undecided ?? []
    }

    /// Whether a verdict is being written, so the buttons can go quiet rather
    /// than accepting a second click on a question already answered.
    private(set) var isDeciding = false

    /// Record that something is a harness, under the name the person chose.
    ///
    /// The name matters: the register is what recognises this thing from now on,
    /// and the label a person gives it is the one they will look for on the
    /// graph. Re-reading afterwards is not a refresh for its own sake — it is
    /// how the newly recognised harness stops being a question.
    func adoptCandidate(_ identity: String, name: String) async {
        await decide { command in command.adopt(identity, name: name) }
    }

    /// Record that something is *not* a harness, so it stops being proposed.
    func dismissCandidate(_ identity: String) async {
        await decide { command in command.dismiss(identity) }
    }

    private func decide(_ make: (EngineCommand) -> EngineCommand.Invocation) async {
        guard let command else {
            apply(failure: Strings.Errors.engineNotResolved)
            return
        }
        isDeciding = true
        defer { isDeciding = false }
        do {
            try await EngineClient(command: command).record(make(command))
            await refresh()
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
    func selectInference(_ baseURL: String) {
        guard let option = inferenceOptions.first(where: { $0.baseURL == baseURL }) else { return }
        inferenceOverride = option
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
