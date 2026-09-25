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

    let schemaVersion: Int
    let ready: Bool
    let version: String
    let vault: Vault
    let runtime: String
    let baseURL: String
    let model: String
    let models: [String]
    let runtimes: [RuntimeInfo]?
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
        case server
        case servers
    }

    /// Every live harness the engine found, oldest bridge first. Empty when the
    /// engine predates multi-harness detection (`runtimes` absent).
    var detectedRuntimes: [RuntimeInfo] { runtimes ?? [] }
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
