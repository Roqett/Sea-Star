import Foundation

/// Every external URL the app can open, gathered in one place so no view or
/// menu invents its own link (AGENTS.md: copy and destinations stay reviewable).
enum Links {
    /// The project home. Also the source of releases and the update feed.
    static let repository = URL(string: "https://github.com/Roqett/Sea-Star")!

    /// Where help and comments live — the issue tracker.
    static let issues = URL(string: "https://github.com/Roqett/Sea-Star/issues")!

    /// Patchdog, the agent that will triage and reply to reports. A placeholder
    /// address until that repo exists (founder's call).
    static let patchdog = URL(string: "https://github.com/Roqett/patchdog")!

    /// The GitHub Releases API feed the update check reads.
    static let latestRelease = URL(string: "https://api.github.com/repos/Roqett/Sea-Star/releases/latest")!
}
