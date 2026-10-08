import AppKit
import SwiftUI

/// The Carpet Sea Star palette (spec §7). Cold, dark canvas with bright
/// glowing accents, lifted from *Meridiastra calcar* so each install reads as
/// its own rockpool. Centralised here so no view invents a colour.
///
/// The palette has two layers. *Chrome* — the panel background and its ink —
/// adapts to the system appearance, so the cockpit is legible in light and dark
/// mode alike. The *pool* the starfield floats in is deliberately fixed dark: a
/// graph of glowing orbs only reads right on a dark ground, so it stays the
/// rockpool even when the surrounding chrome turns light (spec §7).
enum Palette {
    /// The cockpit chrome behind everything; adaptive, so the panel reads
    /// correctly in either appearance.
    static let canvas = adaptive(dark: 0x10131A, light: 0xF7F3EC)

    /// The starfield's pool. Fixed dark on purpose — see the note above.
    static let pool = Color(hex: 0x10131A)

    static let deepPurple = Color(hex: 0x4B2E83)
    static let plum = Color(hex: 0x7A1F3D)
    static let mauve = Color(hex: 0xB0859E)
    static let electricBlue = Color(hex: 0x2F7FE0)
    static let teal = Color(hex: 0x26A69A)
    static let neonGreen = Color(hex: 0x8BD450)
    static let vermilion = Color(hex: 0xE2402A)
    static let orange = Color(hex: 0xF5842B)
    static let bone = Color(hex: 0xEDE3D2)

    /// Primary ink for the panel chrome — the words that have to be read. Light
    /// on the dark canvas, near-black on the light one.
    static let ink = adaptive(dark: 0xEDE3D2, light: 0x1C1A17)
    /// Secondary ink — labels, hints and quiet metadata.
    static let inkMuted = adaptive(dark: 0xB0859E, light: 0x6E5A66)

    /// Accents assigned to meaning, so the same idea always glows the same.
    static let ready = neonGreen
    static let offline = vermilion
    static let working = electricBlue

    /// Entity colours for the starfield: each kind of thing glows its own hue,
    /// so the graph reads as meaning, not decoration (spec §8.7).
    /// A harness is the app driving Sea-Star, so it wears the working blue.
    static let harnessGlow = electricBlue
    /// The vault is the pool itself — bone, the colour of the notes' paper,
    /// so the one thing everything sits in is not competing with a model's green.
    static let vaultGlow = bone
    /// Inference on this machine: teal, "about the machine".
    static let inferenceGlow = teal
    /// Inference that is not on this machine: plum, "what is coming in". The
    /// tone is deliberately the palette's most closed, sober red — a remote
    /// endpoint is the one thing here that leaves the house.
    static let apiInferenceGlow = plum
    static let modelGlow = neonGreen
    /// Agents are the person's own personas — the crew *they* built — so they
    /// glow warm, apart from the cool infrastructure (vault, harness, model)
    /// they run on (spec §8.7).
    static let agentGlow = orange
    /// Sea-Star itself: the one entity that is not a thing it watches. Mauve is
    /// the palette's quiet structural voice — the colour the pool's own rays and
    /// rules are already drawn in — which is exactly the claim: this is the
    /// frame become a body, not another party in the pool. It is deliberately
    /// *not* the vault's bone, or the hub and the memory it lives in would read
    /// as the same kind of thing.
    static let coreGlow = mauve

    /// Log ink and ground, drawn from the blue-white nudibranch strip and
    /// adaptive alongside the panel they sit in.
    static let logInk = adaptive(dark: 0x9FC6FF, light: 0x1F5FB0)
    static let logSurface = adaptive(dark: 0x0A0C12, light: 0xF2F6FF)

    /// Build a colour that resolves differently in light and dark appearances.
    static func adaptive(dark: UInt32, light: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        })
    }
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

private extension NSColor {
    /// The AppKit twin of `Color(hex:)`, for the dynamic appearance provider.
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
