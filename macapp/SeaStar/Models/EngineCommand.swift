import Foundation

/// How to invoke the engine CLI.
///
/// The app owns the process; this type is the seam between the Swift shell and
/// the Python engine. It captures the *prefix* needed to reach `sea-star`
/// (direct binary, `uv run`, or `env` on `PATH`) so any subcommand can be built
/// from it without repeating the resolution logic.
struct EngineCommand: Sendable, Equatable {
    var executableURL: URL
    var baseArguments: [String]
    var workingDirectoryURL: URL?

    struct Invocation: Sendable, Equatable {
        var executableURL: URL
        var arguments: [String]
        var workingDirectoryURL: URL?
        /// Extra keys merged over the inherited environment. Used to pin choices
        /// the person made in the app (`SEASTAR_VAULT`, `SEASTAR_MODEL`) onto the
        /// engine — the same knobs `resolve_vault`/`load_config` already read.
        var environment: [String: String] = [:]
    }

    func invocation(
        _ subcommand: String,
        _ extra: [String] = [],
        environment: [String: String] = [:]
    ) -> Invocation {
        Invocation(
            executableURL: executableURL,
            arguments: baseArguments + [subcommand] + extra,
            workingDirectoryURL: workingDirectoryURL,
            environment: environment
        )
    }

    func doctor(environment: [String: String] = [:]) -> Invocation {
        invocation("doctor", ["--json"], environment: environment)
    }

    func serve(environment: [String: String] = [:]) -> Invocation {
        invocation("serve", environment: environment)
    }
}

extension EngineCommand {
    static let environmentOverrideKey = "SEASTAR_CLI"
    /// Pins the vault the engine resolves (`resolve_vault`, config.py).
    static let vaultOverrideKey = "SEASTAR_VAULT"
    /// Pins the model the engine loads (`load_config`, config.py).
    static let modelOverrideKey = "SEASTAR_MODEL"
    /// Pins the harness endpoint the engine talks to (`load_config`, config.py).
    static let baseURLOverrideKey = "SEASTAR_BASE_URL"
    /// Labels the pinned endpoint so the report reads `omlx · <url>` again.
    static let runtimeOverrideKey = "SEASTAR_RUNTIME"

    /// Resolve how to reach the engine, in precedence order:
    /// 1. `SEASTAR_CLI` — an explicit absolute path (developer override);
    /// 2. a `sea-star` executable in the search path (or the repo's `.venv/bin`);
    /// 3. `uv run --project <repo> sea-star` when `uv` and the repo are present.
    ///
    /// Returns `nil` when nothing resolves, so the caller can fail loud rather
    /// than spawn a shell that silently does nothing.
    static func resolve(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        searchDirectories: [URL] = defaultSearchDirectories(),
        repositoryURL: URL? = defaultRepositoryURL()
    ) -> EngineCommand? {
        if let override = environment[environmentOverrideKey], !override.isEmpty {
            let url = URL(fileURLWithPath: (override as NSString).expandingTildeInPath)
            return EngineCommand(executableURL: url, baseArguments: [], workingDirectoryURL: repositoryURL)
        }

        var directories = searchDirectories
        if let repo = repositoryURL, isDirectory(repo) {
            directories.insert(repo.appendingPathComponent(".venv/bin"), at: 0)
            directories.append(repo.appendingPathComponent("bin"))
        }
        if let binary = firstExecutable(named: "sea-star", in: directories) {
            return EngineCommand(executableURL: binary, baseArguments: [], workingDirectoryURL: repositoryURL)
        }

        if let repo = repositoryURL, isDirectory(repo),
           let uv = firstExecutable(named: "uv", in: searchDirectories) {
            return EngineCommand(
                executableURL: uv,
                baseArguments: ["run", "--project", repo.path, "sea-star"],
                workingDirectoryURL: repo
            )
        }

        return nil
    }

    static func defaultSearchDirectories() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent(".local/bin"),
            URL(fileURLWithPath: "/opt/homebrew/bin"),
            URL(fileURLWithPath: "/usr/local/bin"),
            URL(fileURLWithPath: "/usr/bin"),
        ]
    }

    /// The repo root baked in at build time (`SeaStarRepositoryPath` in Info.plist).
    /// A local build resolves to the checkout; a distributed build will not, and
    /// resolution then falls through to the installed-binary paths above.
    static func defaultRepositoryURL(bundle: Bundle = .main) -> URL? {
        guard let raw = bundle.object(forInfoDictionaryKey: "SeaStarRepositoryPath") as? String,
              !raw.isEmpty else { return nil }
        return URL(fileURLWithPath: raw)
    }

    static func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }

    static func firstExecutable(named name: String, in directories: [URL]) -> URL? {
        for directory in directories {
            let candidate = directory.appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }
}
