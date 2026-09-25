import Foundation

/// Every string the person sees lives here (AGENTS.md: client UI copy stays
/// isolated from logic). Keeping them together means the vocabulary the app
/// uses — vault, harness, model — is reviewable in one place.
enum Strings {
    enum MenuBar {
        /// Menu-bar item text. Kept well under ~30 characters (spec §8). Also the
        /// accessibility label for the glyph, which is picture-only.
        static let label = "Sea-Star"
    }

    enum Header {
        static let title = "Sea-Star"
        static let subtitle = "Your vault, on device."
    }

    enum Rows {
        static let vault = "Vault"
        static let harness = "Harness"
        static let model = "Model"
        static let notes = "Notes"
    }

    enum States {
        static let ready = "Ready"
        static let notReady = "Not ready"
        static let running = "Running"
        static let stopped = "Stopped"
        static let checking = "Checking…"
        static let unknown = "—"
    }

    enum Actions {
        static let start = "Start"
        static let stop = "Stop"
        static let refresh = "Refresh"
        static let chooseVault = "Switch vault…"
        static let chooseModel = "Choose model…"
        static let chooseHarness = "Switch harness…"
    }

    /// Plain-language guidance — the app never drops the person into a shell
    /// (spec §10.1). Each message names the fix, not just the fault.
    enum Guidance {
        static let noVault = "No vault found. Point Sea-Star at your Obsidian vault, or set SEASTAR_VAULT."
        static let noRuntime = "No local model server answered. Start osaurus, Ollama or oMLX, then refresh."
        static let noCandidates = "No other Obsidian vaults were found."
    }

    enum Errors {
        static let engineNotResolved =
            "Couldn't find the sea-star command. Set SEASTAR_CLI to its full path, then reopen."
        static func launchFailed(_ reason: String) -> String {
            "Couldn't run the engine: \(reason)"
        }
        static func emptyOutput(_ detail: String) -> String {
            detail.isEmpty
                ? "The engine returned no output."
                : "The engine returned no output. \(detail)"
        }
    }
}
