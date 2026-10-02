import Foundation

/// Which kind of nudge the note beside the starfish is carrying.
enum HarnessTipKind: Equatable, Sendable {
    /// A harness the person has never been on — it likely needs setting up.
    case fresh
    /// A gently-worded "are you sure this is the right vault?" reminder.
    case wrongVault
    /// The quiet, everyday note that a known harness is connected.
    case reconnected
}

/// One line of guidance to show beside the active starfish (spec §8.7).
struct HarnessTip: Equatable, Sendable {
    let kind: HarnessTipKind
    let body: String
}

/// The tip rule, kept pure so it can be proven without a screen (spec §8.7).
///
/// It decides *one* thing to say, in priority order: a never-seen harness comes
/// first (it needs configuring), then a wrong-vault nudge, then the plain
/// "connected" note for a harness the person already knows.
enum HarnessTips {
    static func tip(
        inferenceName: String,
        isNew: Bool,
        isReady: Bool,
        model: String,
        vaultName: String,
        otherVaults: Int
    ) -> HarnessTip? {
        if isNew {
            return HarnessTip(kind: .fresh, body: Strings.Tips.newHarness(inferenceName))
        }
        if otherVaults > 0 {
            return HarnessTip(
                kind: .wrongVault,
                body: Strings.Tips.wrongVault(vaultName, otherVaults)
            )
        }
        if isReady {
            return HarnessTip(
                kind: .reconnected,
                body: Strings.Tips.connected(inferenceName, model)
            )
        }
        return nil
    }

    /// Fold a harness identity into the remembered set, returning the new set.
    /// Pure, so the persistence around it stays trivial.
    static func remembered(_ seen: Set<String>, adding id: String) -> Set<String> {
        var updated = seen
        updated.insert(id)
        return updated
    }

    /// The identity a harness is remembered by — its endpoint, the same key the
    /// rest of the app uses, because two names can share one address.
    static func identity(baseURL: String) -> String { "harness:\(baseURL)" }
}
