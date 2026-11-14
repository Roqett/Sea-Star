import Foundation

/// What a finished engine process left behind.
struct ProcessOutcome: Sendable, Equatable {
    var standardOutput: Data
    var standardError: Data
    var terminationStatus: Int32
}

enum EngineClientError: Error, LocalizedError, Equatable {
    case engineNotResolved
    case launchFailed(String)
    case emptyOutput(String)

    var errorDescription: String? {
        switch self {
        case .engineNotResolved:
            Strings.Errors.engineNotResolved
        case .launchFailed(let reason):
            Strings.Errors.launchFailed(reason)
        case .emptyOutput(let detail):
            Strings.Errors.emptyOutput(detail)
        }
    }
}

/// The Swift side of the §6 bridge: run the engine and decode its machine
/// output. It never scrapes human-formatted text — only `doctor --json`.
struct EngineClient: Sendable {
    var command: EngineCommand

    func doctor(environment: [String: String] = [:], workspace: URL? = nil) async throws -> DoctorResponse {
        let outcome = try await run(command.doctor(environment: environment, workspace: workspace))
        let output = outcome.standardOutput
        guard !output.isEmpty else {
            let detail = String(data: outcome.standardError, encoding: .utf8) ?? ""
            throw EngineClientError.emptyOutput(detail.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return try JSONDecoder().decode(DoctorResponse.self, from: output)
    }

    /// Record a verdict and report whether the engine accepted it.
    ///
    /// The engine is the only writer of the register, so the answer a person
    /// gives is stored in one place. A non-zero exit is surfaced rather than
    /// swallowed: a decision that did not save must not look like one that did.
    func record(_ invocation: EngineCommand.Invocation) async throws {
        let outcome = try await run(invocation)
        guard outcome.terminationStatus == 0 else {
            let detail = String(data: outcome.standardError, encoding: .utf8) ?? ""
            let message = detail.trimmingCharacters(in: .whitespacesAndNewlines)
            throw EngineClientError.emptyOutput(
                message.isEmpty ? Strings.Errors.verdictNotSaved : message
            )
        }
    }

    func run(_ invocation: EngineCommand.Invocation) async throws -> ProcessOutcome {
        try await ProcessRunner.run(invocation)
    }
}

/// Runs a child process off the main actor and hands back its streams.
///
/// `doctor --json` prints its object even when it exits non-zero (fail loud),
/// so the caller always decodes stdout regardless of the exit status; the
/// status is surfaced on ``ProcessOutcome`` for callers that care.
enum ProcessRunner {
    static func run(_ invocation: EngineCommand.Invocation) async throws -> ProcessOutcome {
        try await Task.detached(priority: .userInitiated) {
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

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            do {
                try process.run()
            } catch {
                throw EngineClientError.launchFailed(error.localizedDescription)
            }

            let outData = stdout.fileHandleForReading.readDataToEndOfFile()
            let errData = stderr.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            return ProcessOutcome(
                standardOutput: outData,
                standardError: errData,
                terminationStatus: process.terminationStatus
            )
        }.value
    }
}
