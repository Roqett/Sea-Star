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

    /// A known harness app installed on this Mac but not answering on a port —
    /// an IDE or runtime app that carries its own model loop (Xcode, OpenCode).
    /// It is not connected, but the person may still want it floating on the
    /// graph, so the cockpit toggles it on and off rather than hiding it.
    struct LatentHarnessInfo: Decodable, Sendable, Equatable {
        let name: String
        let bundleID: String
        let path: String

        enum CodingKeys: String, CodingKey {
            case name
            case bundleID = "bundle_id"
            case path
        }
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
    let latentHarnesses: [LatentHarnessInfo]?
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
        case latentHarnesses = "latent_harnesses"
        case server
        case servers
    }

    /// Every live harness the engine found, oldest bridge first. Empty when the
    /// engine predates multi-harness detection (`runtimes` absent).
    var detectedRuntimes: [RuntimeInfo] { runtimes ?? [] }

    /// Every agent the engine found. Empty when the engine predates agent
    /// discovery (`agents` absent), so the app degrades to the old graph.
    var detectedAgents: [AgentInfo] { agents ?? [] }

    /// Every installed-but-idle harness the engine found. Empty when the engine
    /// predates latent-harness scanning (`latent_harnesses` absent).
    var detectedLatentHarnesses: [LatentHarnessInfo] { latentHarnesses ?? [] }
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
