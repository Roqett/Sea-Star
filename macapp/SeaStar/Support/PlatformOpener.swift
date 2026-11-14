import AppKit

/// The thin AppKit edge of "click a node, bring its platform up" (founder,
/// 2026-11-09). The *mapping* from a node to a platform lives in
/// ``EntityGraphModel/openTarget(for:)`` and is fully unit-tested; this file
/// only performs the opening, resolving bundle ids to app URLs at the last
/// moment, so the mapping stays a pure fact about the report and nothing
/// here can decide what a node means.
@MainActor
enum PlatformOpener {
    static func open(_ target: EntityGraphModel.OpenTarget) {
        switch target {
        case .application(let path), .folder(let path):
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        case .bundleID(let id):
            // Not every recorded bundle id resolves on this machine — a
            // harness entry may name an app that has since been removed.
            // Absence is a no-op, not an error: the click still inspected
            // the node, and there is nothing honest to show in its place.
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id)
            else { return }
            NSWorkspace.shared.open(url)
        }
    }
}
