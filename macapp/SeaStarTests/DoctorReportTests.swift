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
