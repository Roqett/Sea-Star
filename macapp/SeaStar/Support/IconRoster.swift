import SwiftUI

/// One of the app's faces. The founder produced four of these; the app shows one
/// at a time and rotates between them.
///
/// Each face is a single cut: black-on-clear PNG art whose detail lives in the
/// alpha channel, rendered as a template on every surface. The menu bar takes
/// the system's tint — white on a dark bar, black on a light one — and the
/// popover header takes whichever accent `.foregroundStyle` supplies. An earlier
/// build used a separate solid silhouette in the menu bar, but that read as a
/// blunt blob; the detailed starfish stays legible at 18pt, so both surfaces now
/// wear the same cut.
struct AppIcon: Sendable, Equatable, Identifiable {
    /// Stable name for the face.
    let id: String
    /// SF Symbol fallback, used if the art is ever missing.
    let symbol: String
    /// Glow colour for the header, so each face reads differently at a glance.
    let accentHex: UInt32
    /// The face's artwork, shared by the popover header and the menu bar
    /// (asset-catalog name).
    var asset: String?

    var accent: Color { Color(hex: accentHex) }
}

/// The set of faces the app cycles through (the founder's four Gemini icons).
enum IconRoster {
    static let all: [AppIcon] = [
        AppIcon(id: "coral", symbol: "star", accentHex: 0xF5842B, asset: "FaceCoralHeader"),
        AppIcon(id: "violet", symbol: "sparkle", accentHex: 0x2F7FE0, asset: "FaceVioletHeader"),
        AppIcon(id: "lagoon", symbol: "star.circle", accentHex: 0x8BD450, asset: "FaceLagoonHeader"),
        AppIcon(id: "ember", symbol: "seal", accentHex: 0xE2402A, asset: "FaceEmberHeader"),
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
