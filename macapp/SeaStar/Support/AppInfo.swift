import Foundation

/// The bundle's identity, read once so the menu, the alert and the Settings
/// window all agree on what version is running (source: project.yml →
/// `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` → Info.plist).
enum AppInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    /// `0.1.0 (1)` — the line the right-click menu shows.
    static var versionLine: String { "\(version) (\(build))" }
}
