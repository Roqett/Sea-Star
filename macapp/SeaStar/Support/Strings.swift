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

    /// The right-click menu on the menu-bar glyph (the standard app menu an
    /// accessory app otherwise has nowhere to put).
    enum Menu {
        static let settings = "Settings…"
        static let checkForUpdates = "Check for Updates…"
        static let help = "Help & Comments"
        static let patchdog = "Patchdog"
        static let quit = "Quit Sea-Star"
        static func version(_ value: String) -> String { "Version \(value)" }
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
        static let openFolder = "Open folder…"
        static let checkNow = "Check now"
    }

    /// The rolling log: what the engine said, kept short-lived on purpose
    /// (spec §8.8). Other apps let logs pile up for years; this one doesn't.
    enum Logs {
        static let title = "Logs"
        static let empty = "Nothing logged yet."
        static let retention = "Keep logs for"
        static let entries = "Entries"
        static let clearNow = "Clear now"
        static let reveal = "Reveal in Finder"
        static let show = "Show logs"
        static let hide = "Hide logs"
        static func retentionLabel(_ days: Int) -> String {
            days == 0 ? "Forever" : "\(days) days"
        }
    }

    /// The two ways to read the cockpit (spec §8.7): the starfield graph, or the
    /// plain chrome the founder calls "the letterface".
    enum Views {
        static let graph = "Graph"
        static let list = "List"
        static let graphHelp = "Show the graph"
        static let listHelp = "Show the list"
        /// The tide-out control on the starfield: puts the pool back the way it
        /// was found after it has been dragged, zoomed or turned (spec §8.7).
        static let recentre = "Recentre"
        static let recentreHelp = "Put the pool back the way it was"
        /// The hint a person reads on the starfield. Names both the trackpad
        /// gestures and the mouse ones, so neither device is left guessing.
        static let panHint =
            "Drag to drift, scroll or pinch to zoom, ⌥-drag or twist to turn — click a star to inspect it"
    }

    /// The card that blooms when a starfish is clicked (spec §8.7): the plain
    /// facts the engine already hands us, laid out so a node is inspectable at a
    /// glance. Nothing here needs a new engine call — it is all in the report.
    enum Detail {
        static let vault = "Vault"
        static let harness = "Harness"
        static let model = "Model"
        static let notes = "Notes"
        static let found = "Found via"
        static let nearby = "Nearby"
        static let endpoint = "Endpoint"
        static let models = "Models"
        static let servedBy = "Served by"
        static let path = "Path"
        static let status = "Status"
        static let current = "Current"
        static let available = "Available"
        static func nearbyVaults(_ count: Int) -> String {
            count == 1 ? "1 other" : "\(count) others"
        }
        static func modelCount(_ count: Int) -> String {
            count == 1 ? "1 model" : "\(count) models"
        }
        /// How the engine came to be reading this vault, in plain words.
        static func source(_ raw: String) -> String {
            switch raw.lowercased() {
            case "env", "environment": return "environment"
            case "toml", "config": return "config file"
            case "obsidian": return "Obsidian"
            case "auto", "autodetect", "detected": return "detected"
            default: return raw
            }
        }
    }

    /// The one-time choice between the two readings, offered on first launch
    /// (spec §8.7); afterwards the header toggle swaps them.
    enum Mode {
        static let firstRunTitle = "How should the cockpit open?"
        static let firstRunBody = "The graph shows the shape of things; the list shows the plain rows. Pick one — you can swap from the header any time."
    }

    /// The note that grows beside the active starfish (spec §8.7): the settable
    /// hint for a brand-new harness, a wrong-vault nudge, and the everyday
    /// "connected" line. Plain language, and it names the fix, not just a fault.
    enum Tips {
        static let dismiss = "Got it"
        static func newHarness(_ name: String) -> String {
            "First time on \(name). Point your own tools at its endpoint — this note will settle once you have."
        }
        static func wrongVault(_ vault: String, _ others: Int) -> String {
            let count = others == 1 ? "one other vault" : "\(others) other vaults"
            return "Reading \(vault). \(count) nearby — switch if that's not the one."
        }
        static func connected(_ name: String, _ models: Int) -> String {
            let count = models == 1 ? "1 model" : "\(models) models"
            return "\(name) is connected — \(count) on offer."
        }
    }

    /// The Settings window: the configuration surface the menu opens (spec §8.4).
    enum Settings {
        static let title = "Sea-Star Settings"
        static let engine = "Engine"
        static let engineResolved = "Engine found"
        static let engineMissing = "Engine not found"
        static let engineHint = "Set SEASTAR_CLI to the full path of the sea-star command."
        static let vault = "Vault"
        static let vaultSearch = "Search vaults"
        static let vaultDetected = "Use detected vault"
        static let harness = "Harness"
        static let model = "Model"
        static let updates = "Updates"
        static let links = "Links"
    }

    /// The update-check alerts (spec §8.5).
    enum Updates {
        static let checking = "Checking for updates…"
        static let upToDateTitle = "Up to date"
        static let availableTitle = "Update available"
        static let failedTitle = "Couldn't check for updates"
        static let unreachable = "GitHub didn't answer."
        static let openRelease = "Open Release Page"
        static let later = "Later"
        static let dismiss = "OK"
        static func upToDate(_ current: String) -> String {
            "Sea-Star \(current) is the newest version."
        }
        static func available(current: String, latest: String) -> String {
            "Sea-Star \(latest) is available — you're on \(current)."
        }
        static func badResponse(_ status: Int) -> String {
            "GitHub returned status \(status)."
        }
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
