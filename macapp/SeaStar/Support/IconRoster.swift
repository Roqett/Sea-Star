import SwiftUI

/// One of the app's faces. The founder produced four of these; the app shows one
/// at a time and rotates between them.
///
/// Each face has two cuts: the full-detail art for the popover header, and a
/// filled silhouette for the menu bar (the detailed art turns to grey mush at
/// 18pt, so the menu bar gets the solid version). Both cuts are black-on-clear
/// PNGs whose detail lives in the alpha channel — `AppIconMark` renders them as
/// templates so each surface can tint them.
struct AppIcon: Sendable, Equatable, Identifiable {
    /// Stable name for the face.
    let id: String
    /// SF Symbol fallback, used if a cut is ever missing.
    let symbol: String
    /// Glow colour for the header, so each face reads differently at a glance.
    let accentHex: UInt32
    /// Detailed artwork for the popover header (asset-catalog name).
    var headerAsset: String?
    /// Filled silhouette for the menu bar (asset-catalog name).
    var menuBarAsset: String?

    var accent: Color { Color(hex: accentHex) }
}

/// The set of faces the app cycles through (the founder's four Gemini icons).
enum IconRoster {
    static let all: [AppIcon] = [
        AppIcon(
            id: "coral", symbol: "star", accentHex: 0xF5842B,
            headerAsset: "FaceCoralHeader", menuBarAsset: "FaceCoralMenuBar"
        ),
        AppIcon(
            id: "violet", symbol: "sparkle", accentHex: 0x2F7FE0,
            headerAsset: "FaceVioletHeader", menuBarAsset: "FaceVioletMenuBar"
        ),
        AppIcon(
            id: "lagoon", symbol: "star.circle", accentHex: 0x8BD450,
            headerAsset: "FaceLagoonHeader", menuBarAsset: "FaceLagoonMenuBar"
        ),
        AppIcon(
            id: "ember", symbol: "seal", accentHex: 0xE2402A,
            headerAsset: "FaceEmberHeader", menuBarAsset: "FaceEmberMenuBar"
        ),
    ]

    /// The face the app opens on.
    static var first: AppIcon { all[0] }

    /// Pick a face that isn't `current`, so it never repeats twice in a row —
    /// the detail that makes the rotation feel deliberate rather than glitchy.
    static func next(after current: AppIcon?) -> AppIcon {
        let pool = all.filter { $0.id != current?.id }
        return pool.randomElement() ?? first
    }
}
