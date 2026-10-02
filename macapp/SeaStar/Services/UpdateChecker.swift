import Foundation

/// Compares dotted version strings. Kept as a free function so the update
/// decision is testable without touching the network.
enum Version {
    /// True when `candidate` is a strictly higher version than `current`.
    /// `v` prefixes and trailing non-numeric suffixes (`1.2.0-beta`) are
    /// tolerated, so a GitHub tag and a bundle version can be compared directly.
    static func isNewer(_ candidate: String, than current: String) -> Bool {
        let lhs = components(candidate)
        let rhs = components(current)
        for index in 0..<max(lhs.count, rhs.count) {
            let left = index < lhs.count ? lhs[index] : 0
            let right = index < rhs.count ? rhs[index] : 0
            if left != right { return left > right }
        }
        return false
    }

    /// `"v1.2.3"` → `[1, 2, 3]`; unparseable pieces fall back to `0`.
    static func components(_ version: String) -> [Int] {
        let trimmed = version.hasPrefix("v") || version.hasPrefix("V")
            ? String(version.dropFirst())
            : version
        return trimmed.split(separator: ".").map { piece in
            Int(piece.prefix { $0.isNumber }) ?? 0
        }
    }
}

/// Asks GitHub for the newest release and reports it in plain language.
struct UpdateChecker: Sendable {
    /// The subset of the GitHub release payload the app reads.
    struct Release: Decodable, Sendable {
        let tagName: String
        let htmlURL: String

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
        }
    }

    enum Outcome: Equatable, Sendable {
        case upToDate(current: String)
        case available(current: String, latest: String, url: URL)
        case failed(String)
    }

    var feed: URL = Links.latestRelease

    func check(currentVersion: String) async -> Outcome {
        var request = URLRequest(url: feed)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .failed(Strings.Updates.unreachable)
            }
            guard (200..<300).contains(http.statusCode) else {
                return .failed(Strings.Updates.badResponse(http.statusCode))
            }
            let release = try JSONDecoder().decode(Release.self, from: data)
            guard let url = URL(string: release.htmlURL) else {
                return .failed(Strings.Updates.unreachable)
            }
            let latest = Self.normalize(release.tagName)
            if Version.isNewer(latest, than: currentVersion) {
                return .available(current: currentVersion, latest: latest, url: url)
            }
            return .upToDate(current: currentVersion)
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    /// Strip a leading `v` so the alert reads `0.2.0`, not `v0.2.0`.
    static func normalize(_ tag: String) -> String {
        tag.hasPrefix("v") || tag.hasPrefix("V") ? String(tag.dropFirst()) : tag
    }
}
