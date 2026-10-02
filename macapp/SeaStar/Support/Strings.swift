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
        static let agent = "Agent"
        static let inference = "Inference"
        static let model = "Model"
        static let notes = "Notes"
        /// The label for the row of installed-but-idle harnesses — apps that
        /// carry their own model loop but are not answering on a port.
        static let latent = "Idle"
        static let latentHelp = "Installed but not connected — all float by default; take any off the graph to quiet it."

        /// Help for each of the four rows, naming what the row is *for* so the
        /// split is readable without a manual.
        static let vaultHelp =
            "The notes Sea-Star reads. Everything it knows starts here."
        static let harnessHelp =
            "Which app answers. Switch it here; the endpoint and model move with it."
        static let agentHelp =
            "Which persona inside that harness you are talking to."
        static let inferenceHelp =
            "Where the model call actually goes — the endpoint and the model."

        /// The honest states the Agent row can be in. These are deliberately
        /// separate strings: a roster that was never found is not the same as a
        /// roster that was found and turned out to be empty, and neither is the
        /// same as a harness that has no concept of agents at all.
        static let agentNoneFound = "No roster found"
        static let agentRosterEmpty = "Roster is empty"
        static let agentScopeUnknown = "Scope unknown"
        static func agentRosterFrom(_ source: String) -> String {
            "\(source) roster"
        }
        static func agentCount(_ count: Int) -> String {
            count == 1 ? "1 agent" : "\(count) agents"
        }
    }

    /// The `Working now` band: what the cockpit can see happening *right now*.
    ///
    /// It is observation-only by design. Nothing here is a prompt, an output, or
    /// a claim that a person used anything — only what a probe actually reached.
    enum WorkingNow {
        static let title = "Working now"
        static let idle = "Nothing in flight"
        static let endpoint = "Endpoint"
        static let server = "Server"
        static let harness = "Harness"
        /// Proven reachable: a probe answered on this port during the last read.
        static let answering = "Answering"
        /// Configured and known, but nothing is answering it right now.
        static let notAnswering = "Not answering"
        /// The server this app started and is holding open.
        static let serving = "Serving"
        static let notServing = "Stopped"
        /// A host attached to the engine over stdio, proven by the engine's
        /// own live connection record — never by a port, which a stdio host
        /// never answers.
        static let host = "Host"
        static let hostDetail = "stdio connection record"

        /// The evidence line under the band. It names *how far* the claim was
        /// proven, which is the whole point: "live" here means "answered a
        /// probe", never "a person used it".
        static let evidenceProbe = "Live means a probe answered, just now."
        static let evidenceNone = "No probe has answered yet."
        /// Evidence for the attached-host row: the engine holds the record
        /// because it *is* the process this host spawned.
        static let evidenceMcp = "Attached means the engine holds the host's own live connection record."
    }

    /// The ways to lay the same four rows out, so the choice is a picture
    /// rather than an argument (DECISIONS.md D-001).
    enum PanelVariant {
        /// A vertical list of rows — the familiar reading, everything scannable.
        static let stack = "Stack"
        static let stackHelp = "Four rows, one under the next"
        /// Connected cards that read as a chain of cause: each row hands off to
        /// the one below it, which is what actually happens to a request.
        static let chain = "Chain"
        static let chainHelp = "Linked cards, reading top to bottom"
        /// Not a third design — the two of them at once, so choosing between them
        /// is a single look rather than a memory test.
        static let both = "Both"
        static let bothHelp = "Side by side, to compare"
        static func label(_ variant: PanelLayout) -> String {
            switch variant {
            case .stack: return stack
            case .chain: return chain
            case .both: return both
            }
        }
        static func help(_ variant: PanelLayout) -> String {
            switch variant {
            case .stack: return stackHelp
            case .chain: return chainHelp
            case .both: return bothHelp
            }
        }
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
        static let floatHarness = "Float on the graph"
        static let sinkHarness = "Take off the graph"
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
            "Left-drag to move · scroll to zoom · right-drag to rotate in 2D · click a star to inspect · double-click to focus"
        /// The tide-out chip that appears while a star is focused: names what you
        /// are zoomed into and returns the pool to its whole reading (spec §8.7).
        static let exitFocus = "Exit focus"
        static let exitFocusHelp = "Show the whole pool again"

        /// The same hint for the deep pool. Different verbs, because the deep
        /// hands orbit to the camera rather than implementing them itself: you
        /// turn the *water*, not the stars. Saying "drag to pan" here would be a
        /// small lie the first time someone tried it.
        static let orbitHint =
            "Drag to orbit · scroll or pinch to zoom · right-drag to pan · click a sphere to inspect · double-click to focus"

        /// The three depths the graph can be read at. One switch, three
        /// readings, all off the same model — the depth changes the camera and
        /// the drawing, never the facts (spec §8.7).
        enum Depth: String, CaseIterable, Identifiable {
            case flat
            case deep
            case both

            var id: String { rawValue }

            /// A person who has not chosen gets the flat pool, which is the
            /// reading the cockpit has always opened in.
            static func resolved(from raw: String) -> Depth {
                Depth(rawValue: raw) ?? .flat
            }

            var symbol: String {
                switch self {
                case .flat: return "square.grid.2x2"
                case .deep: return "cube.transparent"
                case .both: return "rectangle.split.2x1"
                }
            }

            var label: String {
                switch self {
                case .flat: return Strings.Views.flat
                case .deep: return Strings.Views.deep
                case .both: return Strings.Views.both
                }
            }

            var help: String {
                switch self {
                case .flat: return Strings.Views.flatHelp
                case .deep: return Strings.Views.deepHelp
                case .both: return Strings.Views.bothHelp
                }
            }
        }

        static let flat = "Pool"
        static let deep = "Deep"
        static let both = "Both"
        static let flatHelp = "Read the graph as a flat pool"
        static let deepHelp = "Read the graph in three dimensions"
        static let bothHelp = "Read the flat pool and the deep side by side"
    }

    /// The card that blooms when a starfish is clicked (spec §8.7): the plain
    /// facts the engine already hands us, laid out so a node is inspectable at a
    /// glance. Nothing here needs a new engine call — it is all in the report.
    enum Detail {
        static let vault = "Vault"
        static let harness = "Harness"
        static let model = "Model"
        /// A persona the person built in their harness; the thing they actually
        /// talk to, as opposed to the model it runs on (spec §8.7).
        static let agent = "Agent"
        static let notes = "Notes"
        static let found = "Found via"
        static let nearby = "Nearby"
        static let endpoint = "Endpoint"
        static let models = "Models"
        static let servedBy = "Served by"
        static let uses = "Uses"
        static let provider = "Provider"
        static let path = "Path"
        static let status = "Status"
        static let current = "Current"
        static let available = "Available"
        /// A latent harness: installed, but nothing is answering on its port.
        static let latent = "Idle"
        static let notConnected = "Not connected"
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

    /// Longer asides, shown on hover, for the places where the short label has
    /// to give up something. They exist so the panel can be brief on screen and
    /// still be honest underneath.
    enum Advice {
        /// Shown when the engine found no roster at all. Names the reason
        /// rather than implying the person has no personas.
        static let agentScopeHint =
            "Sea-Star looks for a roster where a harness keeps one. None was found, so there is no agent to show — that is not the same as having none."
        /// Shown against an engine too old to report a roster's scope. The app
        /// refuses to guess whose agents these are.
        static let agentScopeUnconfirmed =
            "This engine does not say whose roster these are, so the cockpit will not claim they are yours. Update Sea-Star's engine to have it say."
        /// The Inference row's fuller reading.
        static let inferenceReading = "The endpoint and the model are both properties of the call, so they live together."
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
