import SwiftUI

/// The Carpet Sea Star palette (spec §7). Cold, dark canvas with bright
/// glowing accents, lifted from *Meridiastra calcar* so each install reads as
/// its own rockpool. Centralised here so no view invents a colour.
enum Palette {
    static let canvas = Color(hex: 0x10131A)

    static let deepPurple = Color(hex: 0x4B2E83)
    static let plum = Color(hex: 0x7A1F3D)
    static let mauve = Color(hex: 0xB0859E)
    static let electricBlue = Color(hex: 0x2F7FE0)
    static let teal = Color(hex: 0x26A69A)
    static let neonGreen = Color(hex: 0x8BD450)
    static let vermilion = Color(hex: 0xE2402A)
    static let orange = Color(hex: 0xF5842B)
    static let bone = Color(hex: 0xEDE3D2)

    /// Accents assigned to meaning, so the same idea always glows the same.
    static let ready = neonGreen
    static let offline = vermilion
    static let working = electricBlue
}

extension Color {
    /// Build a colour from a six-digit RGB hex literal (`0xRRGGBB`).
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
