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
        static let onboarding = "Set up Sea-Star…"
        static let settings = "Settings…"
        static let checkForUpdates = "Check for Updates…"
        static let help = "Help & Comments"
        static let patchdog = "Patchdog"
        static let quit = "Quit Sea-Star"
        static func version(_ value: String) -> String { "Version \(value)" }
    }

    enum Onboarding {
        static let title = "Set up Sea-Star"
        static let subtitle = "Here is what is on this machine — and what to call it."
        static let done = "Done"
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
        /// The list of installed harnesses and whether each floats on the graph.
        /// Lived under the heading "Idle" once; the heading lied the moment the
        /// list started carrying running apps, so it now names the question the
        /// list actually answers.
        static let onGraph = "On your graph"
        static let onGraphHelp = "Installed harnesses float on the graph by default; take any off to quiet it."
        static let nothingToReport = "Nothing to report — no app is doing anything Sea-Star can see."
        static let nothingToDecide = "Nothing to decide — everything on this machine has been named."
        static let noHarnessesInstalled = "No other harness apps are installed."
        static func noteCount(_ count: Int) -> String {
            count == 1 ? "1 note" : "\(count) notes"
        }
        /// The register's question (D-005): what the engine found and has not
        /// been told about. Asked once per thing, ever.
        /// The cascade's three honest cases (D-013): where an agent runs.
        /// Said as sentences so the panel and the MCP answer can share them.
        static let agentRidesWhatever = "Rides whatever the endpoint is serving."
        static func agentRunsOn(_ model: String, _ endpoint: String) -> String {
            "Runs on \(model) — served by \(endpoint)."
        }
        static func agentBuiltFor(_ model: String, _ endpoint: String) -> String {
            "Runs on \(model) — \(endpoint) is up, but not serving it."
        }
        static func agentModelNowhere(_ model: String) -> String {
            "Runs on \(model) — not offered by any running endpoint."
        }
        static let newHere = "New on this machine"
        /// How many things are waiting to be decided about, said as a sentence
        /// rather than left for the person to count.
        static func newHereCount(_ count: Int) -> String {
            count == 1
                ? "1 thing found and not decided about yet."
                : "\(count) things found and not decided about yet."
        }
        static let newHereHelp =
            "Found on this machine and not decided about yet. Answer once and it is remembered; nothing is proposed twice."
        /// What each app is doing with models. The heading names the subject
        /// rather than the sentiment: the panel reports, it does not accuse.
        static let behaviour = "What each app is doing"
        /// The flagged case, said as the two observations it is made of.
        static func idleServer(_ ports: [Int]) -> String {
            let list = ports.map(String.init).joined(separator: ", ")
            return "inbuilt server on \(list), reaching outside instead"
        }
        static let behaviourHelp =
            "Read from what is running and connected on this machine. Facts only — no app is described by its intentions."
        /// Help for each of the four rows, naming what the row is *for* so the
        /// split is readable without a manual.
        static let vaultHelp =
            "The notes Sea-Star reads. Everything it knows starts here."
        static let harnessHelp =
            "The app driving Sea-Star right now. Only an app can attach itself, so this reads rather than switches."
        static let agentHelp =
            "Which persona inside that harness you are talking to."
        static let inferenceHelp =
            "Where the model call goes. Choose the endpoint here; the model list below follows it."
        static let modelHelp =
            "The model that endpoint is serving. Choosing one changes what Sea-Star thinks with."

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
        static func label(_ variant: PanelLayout) -> String {
            switch variant {
            case .stack: return stack
            case .chain: return chain
            }
        }
        static func help(_ variant: PanelLayout) -> String {
            switch variant {
            case .stack: return stackHelp
            case .chain: return chainHelp
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
        /// No harness is attached to the engine. Deliberately not "not
        /// connected": nothing is wrong, it simply means no app is driving
        /// Sea-Star at this moment.
        static let noHarness = "None attached"
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
        /// The two answers to the register's one question.
        static let showAll = "Show all"
        static let showFewer = "Show fewer"
        static let itIsAHarness = "It's a harness"
        static let notAHarness = "Not a harness"
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

        /// The two depths the graph can be read at. One switch, two
        /// readings, all off the same model — the depth changes the camera and
        /// the drawing, never the facts (spec §8.7).
        enum Depth: String, CaseIterable, Identifiable {
            case flat
            case deep

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
                }
            }

            var label: String {
                switch self {
                case .flat: return Strings.Views.flat
                case .deep: return Strings.Views.deep
                }
            }

            var help: String {
                switch self {
                case .flat: return Strings.Views.flatHelp
                case .deep: return Strings.Views.deepHelp
                }
            }
        }

        static let flat = "Pool"
        static let deep = "Deep"
        static let flatHelp = "Read the graph as a flat pool"
        static let deepHelp = "Read the graph in three dimensions"
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
        /// Where models come from — this machine's endpoints and any API.
        static let inference = "Inference"
        static let notes = "Notes"
        static let found = "Found via"
        static let nearby = "Nearby"
        static let endpoint = "Endpoint"
        static let models = "Models"
        /// The actual model names an endpoint serves. Never a bare count:
        /// "five models" tells the person nothing they can act on.
        static let serves = "Serves"
        static let servedBy = "Served by"
        static let uses = "Uses"
        static let usedBy = "Used by"
        static let provider = "Provider"
        static let path = "Path"
        static let status = "Status"
        static let current = "Current"
        static let available = "Available"
        static let attached = "Attached"
        static let since = "Since"
        static let process = "Process"
        static let bundle = "Bundle"
        /// What an attached harness can do with Sea-Star, and the one tool it
        /// calls. Naming the tool is the whole point: a harness on this graph is
        /// not a label, it is something with a contract against the engine.
        static let canCall = "Can call"
        static let askTool = "ask_seastar"
        /// Whether an endpoint is on this Mac or reached over the network. The
        /// distinction the founder asked for: local is "about the machine",
        /// remote is "what is coming in".
        static let location = "Runs"
        static let onThisMac = "On this Mac"
        static let remoteAPI = "Remote API"
        /// An endpoint that is built into an app rather than standing alone.
        /// The owner is named because the dependency is real: this server stops
        /// when that app does.
        static let insideApp = "Runs inside"
        static let warning = "Careful"
        static func stopsWith(_ app: String) -> String {
            "Stops when \(app) quits — Sea-Star's own model lives here."
        }
        /// Whose roster an agent row is reading.
        static let roster = "Roster"
        /// A latent harness: installed, but nothing is answering on its port.
        static let latent = "Idle"
        static let notConnected = "Not connected"

        /// The ladder rungs, as a person reads them. Foundation §2 says show the
        /// highest rung reached *and* show the rung, so each state gets its own
        /// words rather than one yes/no.
        static let rungConnected = "Driving Sea-Star now"
        static let rungListening = "Answering on its port"
        static let rungRunning = "Up, not answering yet"
        static let rungPresent = "Installed, not running"
        /// The second line of the Harness card when no app is attached at all.
        /// Said as a sentence, so it cannot be confused with a rung, which is a
        /// fact about some particular app.
        static let nobodyAttached = "No app is driving Sea-Star right now"

        static func nearbyVaults(_ count: Int) -> String {
            count == 1 ? "1 other" : "\(count) others"
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
        /// The connected note names the model that actually answered. A count
        /// ("5 models on offer") is the kind of empty indicator the founder
        /// objected to: it is a number you cannot act on.
        static func connected(_ name: String, _ model: String) -> String {
            guard !model.isEmpty, model != Strings.States.unknown else {
                return "\(name) is connected."
            }
            return "\(name) is connected — answering as \(model)."
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
        static let version = "Version"
        static let status = "Status"
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
        /// A verdict the engine refused to store. Said plainly, because a
        /// decision that did not save must not look like one that did.
        static let verdictNotSaved = "That could not be recorded."
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
