import Foundation
import Testing

@testable import SeaStar

@Suite("Doctor bridge decoding")
struct DoctorReportTests {
    private func decode(_ json: String) throws -> DoctorResponse {
        try JSONDecoder().decode(DoctorResponse.self, from: Data(json.utf8))
    }

    @Test("decodes the full §6 report")
    func decodesFullReport() throws {
        let response = try decode(
            """
            {
              "schema_version": 1,
              "ready": true,
              "version": "0.1.0",
              "vault": {
                "path": "/Users/lono/Vaults/main",
                "source": "obsidian",
                "note_count": 1234,
                "candidates": ["/Users/lono/Vaults/main", "/Users/lono/Vaults/demo"]
              },
              "runtime": "osaurus",
              "base_url": "http://127.0.0.1:1337/v1",
              "model": "foundation",
              "models": ["foundation"],
              "server": { "state": "running" },
              "servers": [
                { "name": "obsidian", "command": "npx", "include": ["search"], "exclude": ["delete"] }
              ]
            }
            """
        )

        guard case .report(let report) = response else {
            Issue.record("expected a report, got a failure")
            return
        }

        #expect(report.schemaVersion == 1)
        #expect(report.ready)
        #expect(report.vault.path == "/Users/lono/Vaults/main")
        #expect(report.vault.source == "obsidian")
        #expect(report.vault.noteCount == 1234)
        #expect(report.vault.candidates.count == 2)
        #expect(report.baseURL == "http://127.0.0.1:1337/v1")
        #expect(report.server.state == "running")
        #expect(report.servers.first?.include == ["search"])
        #expect(report.servers.first?.exclude == ["delete"])
        #expect(report.detectedRuntimes.isEmpty)
    }

    @Test("decodes every live harness")
    func decodesRuntimes() throws {
        let response = try decode(
            """
            {
              "schema_version": 1,
              "ready": true,
              "version": "0.1.0",
              "vault": { "path": "/v", "source": "obsidian", "note_count": 1, "candidates": [] },
              "runtime": "osaurus",
              "base_url": "http://127.0.0.1:1337/v1",
              "model": "foundation",
              "models": ["foundation"],
              "runtimes": [
                { "name": "osaurus", "base_url": "http://127.0.0.1:1337/v1", "model": "foundation", "models": ["foundation"] },
                { "name": "omlx", "base_url": "http://127.0.0.1:8000/v1", "model": "mlx-community/Qwen3", "models": ["mlx-community/Qwen3"] }
              ],
              "server": { "state": "running" },
              "servers": []
            }
            """
        )

        guard case .report(let report) = response else {
            Issue.record("expected a report, got a failure")
            return
        }

        #expect(report.detectedRuntimes.map(\.name) == ["osaurus", "omlx"])
        #expect(report.detectedRuntimes.last?.baseURL == "http://127.0.0.1:8000/v1")
        #expect(report.detectedRuntimes.last?.model == "mlx-community/Qwen3")
    }

    @Test("decodes the fail-loud error object")
    func decodesFailure() throws {
        let response = try decode(#"{ "ready": false, "error": "No vault found." }"#)
        guard case .failure(let message) = response else {
            Issue.record("expected a failure, got a report")
            return
        }
        #expect(message == "No vault found.")
    }

    /// The stdio connection list proves attachment without any port probe —
    /// a stdio host never answers a port. The engine only ever adds keys, so
    /// this decodes additively alongside everything else in §6.
    @Test("decodes hosts attached over stdio")
    func decodesMcpClients() throws {
        let response = try decode(
            """
            {
              "schema_version": 1,
              "ready": true,
              "version": "0.1.0",
              "vault": { "path": "/v", "source": "obsidian", "note_count": 1, "candidates": [] },
              "runtime": "osaurus",
              "base_url": "http://127.0.0.1:1337/v1",
              "model": "qwen3",
              "models": ["qwen3"],
              "mcp_clients": [
                { "name": "TraeWork", "bundle_id": "com.trae.solo.app", "pid": 31147, "started_at": "2026-09-30T10:00:00Z" }
              ],
              "server": { "state": "stopped" },
              "servers": []
            }
            """
        )

        guard case .report(let report) = response else {
            Issue.record("expected a report, got a failure")
            return
        }

        #expect(report.attachedMcpClients.map(\.name) == ["TraeWork"])
        #expect(report.attachedMcpClients.first?.bundleID == "com.trae.solo.app")
        #expect(report.attachedMcpClients.first?.pid == 31147)
    }

    /// An engine that predates connection records omits the key entirely, and
    /// the app must show *no* attached host rather than an invented one — the
    /// same absent-vs-empty rule the roster follows above.
    @Test("an older engine decodes to no attached host")
    func decodesWithoutMcpClients() throws {
        let response = try decode(
            """
            {
              "schema_version": 1,
              "ready": true,
              "version": "0.1.0",
              "vault": { "path": "/v", "source": "obsidian", "note_count": 1, "candidates": [] },
              "runtime": "osaurus",
              "base_url": "http://127.0.0.1:1337/v1",
              "model": "qwen3",
              "models": ["qwen3"],
              "server": { "state": "stopped" },
              "servers": []
            }
            """
        )

        guard case .report(let report) = response else {
            Issue.record("expected a report, got a failure")
            return
        }

        #expect(report.attachedMcpClients.isEmpty)
    }

    /// The roster and the fact that *someone* vouched for it are two separate
    /// fields, and the panel's four Agent states are read straight off them. So
    /// the pair has to survive the bridge intact, in both directions.
    @Test("decodes an agent roster and names its source")
    func decodesAgentRoster() throws {
        let response = try decode(
            """
            {
              "schema_version": 1,
              "ready": true,
              "version": "0.1.0",
              "vault": { "path": "/v", "source": "obsidian", "note_count": 1, "candidates": [] },
              "runtime": "osaurus",
              "base_url": "http://127.0.0.1:1337/v1",
              "model": "qwen3",
              "models": ["qwen3"],
              "agents": [
                { "name": "Mariner", "model": "qwen3", "description": "reads and answers" }
              ],
              "agent_source": "osaurus",
              "server": { "state": "stopped" },
              "servers": []
            }
            """
        )

        guard case .report(let report) = response else {
            Issue.record("expected a report, got a failure")
            return
        }

        #expect(report.detectedAgents.map(\.name) == ["Mariner"])
        #expect(report.detectedAgents.first?.model == "qwen3")
        #expect(report.agentSource == "osaurus")
        #expect(report.hasKnownAgentSource)
    }

    /// An engine that has never heard of agents omits the field entirely. It
    /// must decode to "no source" rather than to an empty roster — the app shows
    /// those two states differently, and guessing here would be the lie the
    /// foundation exists to prevent.
    @Test("an older engine decodes to an unknown scope, not an empty one")
    func decodesWithoutAgentSource() throws {
        let response = try decode(
            """
            {
              "schema_version": 1,
              "ready": true,
              "version": "0.1.0",
              "vault": { "path": "/v", "source": "obsidian", "note_count": 1, "candidates": [] },
              "runtime": "osaurus",
              "base_url": "http://127.0.0.1:1337/v1",
              "model": "qwen3",
              "models": ["qwen3"],
              "server": { "state": "stopped" },
              "servers": []
            }
            """
        )

        guard case .report(let report) = response else {
            Issue.record("expected a report, got a failure")
            return
        }

        #expect(report.detectedAgents.isEmpty)
        #expect(report.agentSource == nil)
        #expect(!report.hasKnownAgentSource)
    }

    /// A source that looked and found nothing is a *different fact* from a
    /// source that was never consulted, and the panel says so in words.
    @Test("an empty roster still names its source")
    func decodesEmptyRosterWithSource() throws {
        let response = try decode(
            """
            {
              "schema_version": 1,
              "ready": true,
              "version": "0.1.0",
              "vault": { "path": "/v", "source": "obsidian", "note_count": 1, "candidates": [] },
              "runtime": "osaurus",
              "base_url": "http://127.0.0.1:1337/v1",
              "model": "qwen3",
              "models": ["qwen3"],
              "agents": [],
              "agent_source": "osaurus",
              "server": { "state": "stopped" },
              "servers": []
            }
            """
        )

        guard case .report(let report) = response else {
            Issue.record("expected a report, got a failure")
            return
        }

        #expect(report.detectedAgents.isEmpty)
        #expect(report.hasKnownAgentSource)
    }
}

@Suite("Engine invocation")
struct EngineCommandTests {
    @Test("doctor asks for JSON")
    func doctorAsksForJSON() {
        let command = EngineCommand(
            executableURL: URL(fileURLWithPath: "/usr/local/bin/sea-star"),
            baseArguments: [],
            workingDirectoryURL: nil
        )
        #expect(command.doctor().arguments == ["doctor", "--json"])
    }

    @Test("uv prefix is kept ahead of the subcommand")
    func keepsPrefix() {
        let command = EngineCommand(
            executableURL: URL(fileURLWithPath: "/opt/homebrew/bin/uv"),
            baseArguments: ["run", "--project", "/repo", "sea-star"],
            workingDirectoryURL: nil
        )
        #expect(command.serve().arguments == ["run", "--project", "/repo", "sea-star", "serve"])
    }

    @Test("environment overrides ride along with the invocation")
    func carriesEnvironmentOverrides() {
        let command = EngineCommand(
            executableURL: URL(fileURLWithPath: "/usr/local/bin/sea-star"),
            baseArguments: [],
            workingDirectoryURL: nil
        )
        let invocation = command.doctor(
            environment: ["SEASTAR_VAULT": "/v", "SEASTAR_MODEL": "m"]
        )
        #expect(invocation.arguments == ["doctor", "--json"])
        #expect(invocation.environment == ["SEASTAR_VAULT": "/v", "SEASTAR_MODEL": "m"])
    }

    @Test("invocations default to a clean environment")
    func defaultsToCleanEnvironment() {
        let command = EngineCommand(
            executableURL: URL(fileURLWithPath: "/usr/local/bin/sea-star"),
            baseArguments: [],
            workingDirectoryURL: nil
        )
        #expect(command.serve().environment.isEmpty)
    }
}

@Suite("Cockpit options")
@MainActor
struct ServerControllerTests {
    @Test("an unresolved engine offers no choices and is not ready")
    func unresolvedEngineIsEmpty() {
        let controller = ServerController(command: nil)
        #expect(controller.vaultOptions.isEmpty)
        #expect(controller.modelOptions.isEmpty)
        #expect(controller.harnessOptions.isEmpty)
        #expect(controller.currentHarness == nil)
        #expect(!controller.isReady)
    }

    @Test("the cockpit opens on the roster's first face")
    func opensOnFirstFace() {
        let controller = ServerController(command: nil)
        #expect(controller.currentIcon == IconRoster.first)
    }

    @Test("an idle harness floats by default, and stays off once taken off")
    func latentHarnessesDefaultToVisible() {
        let controller = ServerController(command: nil)
        // An app on the disk is not a connection, but it is still somewhere this
        // machine can work, so it is in view until the person says otherwise.
        #expect(controller.isLatentHarnessEnabled("com.example.OpenCode"))

        controller.toggleLatentHarness("com.example.OpenCode")
        #expect(!controller.isLatentHarnessEnabled("com.example.OpenCode"))

        controller.toggleLatentHarness("com.example.OpenCode")
        #expect(controller.isLatentHarnessEnabled("com.example.OpenCode"))
    }
}

@Suite("Version comparison")
struct VersionTests {
    @Test("a higher patch, minor or major wins")
    func detectsNewer() {
        #expect(Version.isNewer("0.1.1", than: "0.1.0"))
        #expect(Version.isNewer("0.2.0", than: "0.1.9"))
        #expect(Version.isNewer("1.0.0", than: "0.9.9"))
    }

    @Test("equal or older versions are never newer")
    func rejectsSameOrOlder() {
        #expect(!Version.isNewer("0.1.0", than: "0.1.0"))
        #expect(!Version.isNewer("0.1.0", than: "0.1.1"))
        #expect(!Version.isNewer("0.1", than: "0.1.0"))
    }

    @Test("a leading v and ragged segment counts compare by number")
    func toleratesPrefixAndRaggedSegments() {
        #expect(Version.isNewer("v1.2", than: "1.1.9"))
        #expect(!Version.isNewer("v1.2.0", than: "1.2"))
        #expect(Version.components("v0.1.0") == [0, 1, 0])
    }

    @Test("a release tag normalises to a bare version")
    func normalisesTag() {
        #expect(UpdateChecker.normalize("v0.2.0") == "0.2.0")
        #expect(UpdateChecker.normalize("0.2.0") == "0.2.0")
    }
}

@Suite("Log retention")
struct LogStoreTests {
    private func entry(daysAgo: Int, text: String = "line") -> LogStore.Entry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return LogStore.Entry(date: date, text: text)
    }

    @Test("entries older than the window are dropped")
    func prunesOldLines() {
        let kept = LogStore.retained([entry(daysAgo: 1), entry(daysAgo: 20)], within: 14)
        #expect(kept.count == 1)
        #expect(kept.first?.text == "line")
    }

    @Test("a window of zero keeps everything")
    func keepsAllForever() {
        let all = [entry(daysAgo: 1), entry(daysAgo: 4000)]
        #expect(LogStore.retained(all, within: 0).count == 2)
    }

    @Test("the offered windows include the fortnight default")
    func offersFortnight() {
        #expect(LogStore.retentionOptions.contains(14))
        #expect(LogStore.retentionOptions.contains(0))
    }

    @Test("every window carries a plain-language label")
    func labelsRead() {
        #expect(Strings.Logs.retentionLabel(0) == "Forever")
        #expect(Strings.Logs.retentionLabel(14) == "14 days")
    }
}

@Suite("Harness tips")
struct HarnessTipsTests {
    @Test("a fresh harness gets the setting-up hint, and it names the harness")
    func freshHarnessHint() {
        let tip = HarnessTips.tip(
            harnessName: "oMLX", isNew: true, isReady: true,
            modelCount: 3, vaultName: "Vault", otherVaults: 2
        )
        #expect(tip?.kind == .fresh)
        #expect(tip?.body.contains("oMLX") == true)
    }

    @Test("a known harness with no other vaults just reports it is connected")
    func connectedLine() {
        let tip = HarnessTips.tip(
            harnessName: "Osaurus", isNew: false, isReady: true,
            modelCount: 1, vaultName: "Brain", otherVaults: 0
        )
        #expect(tip?.kind == .reconnected)
        #expect(tip?.body.contains("1 model") == true)
    }

    @Test("other vaults nearby raise the wrong-vault nudge")
    func wrongVaultNudge() {
        let tip = HarnessTips.tip(
            harnessName: "oMLX", isNew: false, isReady: true,
            modelCount: 3, vaultName: "Second", otherVaults: 1
        )
        #expect(tip?.kind == .wrongVault)
        #expect(tip?.body.contains("Second") == true)
    }

    @Test("a known harness that is not ready says nothing")
    func silentWhenNotReady() {
        let tip = HarnessTips.tip(
            harnessName: "oMLX", isNew: false, isReady: false,
            modelCount: 0, vaultName: "Vault", otherVaults: 0
        )
        #expect(tip == nil)
    }

    @Test("remembering a harness is idempotent and keys on its endpoint")
    func rememberingIsIdempotent() {
        let id = HarnessTips.identity(baseURL: "http://127.0.0.1:8000")
        let once = HarnessTips.remembered([], adding: id)
        let twice = HarnessTips.remembered(once, adding: id)
        #expect(once == twice)
        #expect(once.contains("harness:http://127.0.0.1:8000"))
    }
}

@Suite("Icon roster")
struct IconRosterTests {
    @Test("there are four distinct faces")
    func fourDistinctFaces() {
        #expect(IconRoster.all.count == 4)
        #expect(Set(IconRoster.all.map(\.id)).count == IconRoster.all.count)
    }

    @Test("a reroll never lands on the face that just went away")
    func neverRepeats() {
        for icon in IconRoster.all {
            for _ in 0..<50 {
                #expect(IconRoster.next(after: icon).id != icon.id)
            }
        }
    }

    @Test("a reroll with nothing showing still returns a face")
    func rerollFromEmpty() {
        for _ in 0..<50 {
            #expect(IconRoster.all.contains(IconRoster.next(after: nil)))
        }
    }
}

@Suite("Panel layout")
struct PanelLayoutTests {
    /// An unset or corrupt stored value must land on the reading this panel has
    /// always been, never on a blank screen.
    @Test("an unset preference opens the stack")
    func unsetDefaultsToStack() {
        #expect(PanelLayout.resolved(from: "") == .stack)
        #expect(PanelLayout.resolved(from: "nonsense") == .stack)
    }

    @Test("a stored preference is honoured every way")
    func storedPreferenceRoundTrips() {
        for option in PanelLayout.allCases {
            #expect(PanelLayout.resolved(from: option.rawValue) == option)
        }
    }

    @Test("every reading carries a symbol, a label and a help line")
    func everyReadingIsLabelled() {
        for option in PanelLayout.allCases {
            #expect(!option.symbol.isEmpty)
            #expect(!option.label.isEmpty)
            #expect(!option.help.isEmpty)
        }
    }

    /// Only the side-by-side needs the room; widening it unconditionally would
    /// make the ordinary column a stranded strip of ink in a wide panel.
    @Test("only the side-by-side asks for a wide panel")
    func onlyCompareIsWide() {
        #expect(PanelLayout.both.isWide)
        #expect(!PanelLayout.stack.isWide)
        #expect(!PanelLayout.chain.isWide)
    }

    /// The two designs plus the way to compare them. If this ever drops a case,
    /// the header toggle silently loses a button.
    @Test("there are three readings")
    func threeReadings() {
        #expect(PanelLayout.allCases.count == 3)
    }
}

@Suite("Cockpit mode")
struct CockpitModeTests {
    @Test("an unset preference opens the graph")
    func unsetDefaultsToGraph() {
        #expect(CockpitMode.resolved(from: "") == .graph)
    }

    @Test("a stored preference is honoured both ways")
    func storedPreferenceRoundTrips() {
        for option in CockpitMode.allCases {
            #expect(CockpitMode.resolved(from: option.rawValue) == option)
        }
    }

    @Test("both readings carry a symbol, a label and a help line")
    func bothReadingsAreLabelled() {
        #expect(CockpitMode.allCases.count == 2)
        for option in CockpitMode.allCases {
            #expect(!option.symbol.isEmpty)
            #expect(!option.label.isEmpty)
            #expect(!option.help.isEmpty)
        }
    }
}
