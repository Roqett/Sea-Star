import Foundation

/// The decoded `sea-star doctor --json` bridge object (spec §6).
///
/// Field names are frozen by the engine's bridge contract and versioned via
/// ``schemaVersion``; the engine only ever adds keys, so decoding stays additive.
struct DoctorReport: Decodable, Sendable, Equatable {
    struct Vault: Decodable, Sendable, Equatable {
        let path: String
        let source: String
        let noteCount: Int
        let candidates: [String]

        enum CodingKeys: String, CodingKey {
            case path
            case source
            case noteCount = "note_count"
            case candidates
        }
    }

    struct ServerState: Decodable, Sendable, Equatable {
        let state: String
    }

    struct BridgedServer: Decodable, Sendable, Equatable {
        let name: String
        let command: String
        let include: [String]
        let exclude: [String]
    }

    /// One live local harness the engine found. More than one can be up at a
    /// time (Osaurus *and* oMLX), so the report lists them all.
    struct RuntimeInfo: Decodable, Sendable, Equatable {
        let name: String
        let baseURL: String
        let model: String
        let models: [String]

        enum CodingKeys: String, CodingKey {
            case name
            case baseURL = "base_url"
            case model
            case models
        }
    }

    /// One persona the person built in a harness (Osaurus agents). It is a
    /// thing they *talk to*, as opposed to a ``RuntimeInfo`` which is the
    /// machine serving a model. The bound model is optional: an agent may ride
    /// whatever model the harness is currently set to.
    struct AgentInfo: Decodable, Sendable, Equatable {
        let name: String
        let model: String?
        let description: String

        enum CodingKeys: String, CodingKey {
            case name
            case model
            case description
        }
    }

    /// A known harness app installed on this Mac but not attached over MCP —
    /// an IDE, a runtime's own app, or another agent harness that carries its
    /// own model loop. It is not connected, but the person may still want it
    /// floating on the graph, so the cockpit toggles it on and off rather than
    /// hiding it. ``rung`` says how far it got: ``"running"`` means a process
    /// owns the app right now, ``"present"`` means it is only installed.
    struct LatentHarnessInfo: Decodable, Sendable, Equatable {
        let name: String
        let bundleID: String
        let path: String
        /// Absent from an engine that predates rungs; ``nil`` then means "the
        /// engine could not say how far this one climbed", never "not running".
        let rung: String?

        enum CodingKeys: String, CodingKey {
            case name
            case bundleID = "bundle_id"
            case path
            case rung
        }
    }

    /// What a harness *says* it gets its models from, read out of that harness's
    /// own settings. This is a **declaration, not a connection** — foundation §2
    /// rung 0 — and the distinction is load-bearing: a configured provider holds
    /// no socket, so no probe could ever have shown it. It is drawn as a stated
    /// binding and never as liveness, and the absence of a ``baseURL`` is itself
    /// the honest fact (a bare model name names a model but no place to get it).
    struct ConfiguredProviderInfo: Decodable, Sendable, Equatable {
        let harness: String
        let provider: String
        let baseURL: String?
        let model: String?
        /// `"configured"` today. Carried rather than assumed so a future claim
        /// kind can be told apart from a declaration by whoever reads it.
        let evidence: String
        /// Whether the declared route is a loopback endpoint on this machine —
        /// the only kind the graph can resolve to a node it already draws.
        let isLocal: Bool

        enum CodingKeys: String, CodingKey {
            case harness
            case provider
            case baseURL = "base_url"
            case model
            case evidence
            case isLocal = "local"
        }
    }

    /// One host currently attached to the engine over stdio. The engine
    /// records who spawned its `serve` process and prunes the record when the
    /// process dies, so this is proof of a live connection — the stdio
    /// equivalent of a port probe, since a stdio host never answers a port.
    struct McpClientInfo: Decodable, Sendable, Equatable {
        let name: String
        let bundleID: String?
        let pid: Int
        let startedAt: String

        enum CodingKeys: String, CodingKey {
            case name
            case bundleID = "bundle_id"
            case pid
            case startedAt = "started_at"
        }
    }

    /// Something found on this machine that the person has not decided about
    /// yet. ``evidence`` is the load-bearing field: each line is a fact that was
    /// actually observed, so the question can be judged rather than trusted.
    struct CandidateInfo: Decodable, Sendable, Equatable, Identifiable {
        let identity: String
        let name: String
        let bundleID: String?
        let path: String?
        let evidence: [String]
        let suggestedName: String?

        var id: String { identity }

        enum CodingKeys: String, CodingKey {
            case identity
            case name
            case bundleID = "bundle_id"
            case path
            case evidence
            case suggestedName = "suggested_name"
        }
    }

    /// What one app on this machine is doing with models, as observations.
    ///
    /// Every field is something the engine saw. The type deliberately has no
    /// field for *why* an app is doing it: the person is the one who gets to
    /// judge that, and a cockpit that editorialises stops being trusted.
    struct HarnessBehaviourInfo: Decodable, Sendable, Equatable, Identifiable {
        let name: String
        let appPath: String?
        let serves: [Int]
        let usingOwnServer: Bool
        let reachesOut: Int
        let ownsIdleServer: Bool
        /// Ports the app owns that look like model servers but were never
        /// confirmed to answer. `nil` from an engine that predates the split.
        let listening: [Int]?

        var id: String { appPath ?? name }

        /// Owned ports that carried the vocabulary but no answer.
        ///
        /// Kept apart from ``serves`` because the difference between "answers as
        /// a model server" and "looks like one" is the difference between a fact
        /// and a guess, and the panel must not dress one as the other.
        var unconfirmed: [Int] {
            (listening ?? []).filter { !serves.contains($0) }
        }

        enum CodingKeys: String, CodingKey {
            case name
            case appPath = "app_path"
            case serves
            case usingOwnServer = "using_own_server"
            case reachesOut = "reaches_out"
            case ownsIdleServer = "owns_idle_server"
            case listening
        }
    }

    /// A port on this machine that answers as a model server, and the app that
    /// owns it. On this machine every one of them is *inbuilt* — the server
    /// lives inside a harness and stops when that harness quits — so the owner
    /// is the single most useful fact about the endpoint, not decoration.
    struct ModelLikeInfo: Decodable, Sendable, Equatable {
        let port: Int
        let appName: String?
        let appPath: String?
        let baseURL: String
        /// Whether this port **answered** as a model server, rather than merely
        /// looking like one. Optional so an older engine reads as unproved
        /// instead of being credited with an answer it never gave.
        let answering: Bool?

        /// Proved, or merely suspected. Nothing may be stated as serving on the
        /// strength of the port alone.
        var isProved: Bool { answering == true }

        enum CodingKeys: String, CodingKey {
            case port
            case appName = "app_name"
            case appPath = "app_path"
            case baseURL = "base_url"
            case answering
        }

        /// Whether this server is built into an app rather than standing alone.
        var isBundled: Bool { appName != nil || appPath != nil }
    }

    let schemaVersion: Int
    let ready: Bool
    let version: String
    let vault: Vault
    let runtime: String
    let baseURL: String
    let model: String
    let models: [String]
    let runtimes: [RuntimeInfo]?
    let agents: [AgentInfo]?
    /// Which adapter produced ``agents`` — `"osaurus"` today. `nil` means no
    /// roster was found, which is a *different fact* from "found, and empty",
    /// so the panel can say the difference rather than showing a blank row.
    let agentSource: String?
    let latentHarnesses: [LatentHarnessInfo]?
    /// What each harness *declares* it gets models from. `nil` from an engine
    /// that predates the reader — the absence of the key is then "this build did
    /// not look", never "no harness uses any model".
    let providers: [ConfiguredProviderInfo]?
    /// What the engine found and has not been told about. `nil` from an engine
    /// that predates the register, which the panel reads as "nothing to ask".
    let candidates: [CandidateInfo]?
    let modelLike: [ModelLikeInfo]?
    let behaviour: [HarnessBehaviourInfo]?
    /// Hosts attached over stdio right now. `nil` when the engine predates
    /// connection records — the app then shows no attached host rather than
    /// inventing one.
    let mcpClients: [McpClientInfo]?
    /// Workspace markers found in the current directory — the only evidence
    /// family that proves *use* rather than installation.
    let workspaceMarkers: [String]?
    let server: ServerState
    let servers: [BridgedServer]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case ready
        case version
        case vault
        case runtime
        case baseURL = "base_url"
        case model
        case models
        case runtimes
        case agents
        case agentSource = "agent_source"
        case latentHarnesses = "latent_harnesses"
        case providers
        case candidates
        case modelLike = "model_like"
        case behaviour
        case mcpClients = "mcp_clients"
        case workspaceMarkers = "workspace_markers"
        case server
        case servers
    }

    /// What each app is doing with models. Absent from an engine that predates
    /// the ledger, which the cockpit reads as "nothing to say" rather than
    /// inventing a picture of the machine.
    var appBehaviour: [HarnessBehaviourInfo] { behaviour ?? [] }

    /// Every loopback port that answers as a model server. Absent from an
    /// engine that predates reconnaissance, so the cockpit says nothing rather
    /// than guessing where a model comes from.
    var modelServers: [ModelLikeInfo] { modelLike ?? [] }

    /// What is on this machine and undecided. Empty when the engine predates
    /// the register, so the cockpit shows no questions rather than inventing
    /// them — and never nags about something the person already answered.
    var undecided: [CandidateInfo] { candidates ?? [] }

    /// Every live harness the engine found, oldest bridge first. Empty when the
    /// engine predates multi-harness detection (`runtimes` absent).
    var detectedRuntimes: [RuntimeInfo] { runtimes ?? [] }

    /// What harnesses declare they use. Empty when the engine predates the
    /// reader, which is read as "nothing declared" rather than as a claim that
    /// no harness needs a model.
    var declaredProviders: [ConfiguredProviderInfo] { providers ?? [] }

    /// Every agent the engine found. Empty when the engine predates agent
    /// discovery (`agents` absent), so the app degrades to the old graph.
    var detectedAgents: [AgentInfo] { agents ?? [] }

    /// Whether the engine can name whose roster ``agents`` is. An older engine
    /// omits the key, and then the app must *not* assume a global roster — the
    /// panel says the scope is unconfirmed rather than guessing.
    var hasKnownAgentSource: Bool { agentSource != nil }

    /// Every installed-but-idle harness the engine found. Empty when the engine
    /// predates latent-harness scanning (`latent_harnesses` absent).
    var detectedLatentHarnesses: [LatentHarnessInfo] { latentHarnesses ?? [] }

    /// Every host attached over stdio right now. Empty when the engine
    /// predates connection records (`mcp_clients` absent).
    var attachedMcpClients: [McpClientInfo] { mcpClients ?? [] }
    
    /// Workspace markers found in the current directory. Empty when no
    /// markers are found or the engine predates workspace detection.
    var detectedWorkspaceMarkers: [String] { workspaceMarkers ?? [] }
}

/// The bridge answers with either the report or a fail-loud error object.
enum DoctorResponse: Decodable, Sendable, Equatable {
    case report(DoctorReport)
    case failure(String)

    private enum ProbeKeys: String, CodingKey {
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ProbeKeys.self)
        if let message = try container.decodeIfPresent(String.self, forKey: .error) {
            self = .failure(message)
        } else {
            self = .report(try DoctorReport(from: decoder))
        }
    }
}
