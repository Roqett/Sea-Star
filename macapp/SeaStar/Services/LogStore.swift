import Foundation
import Observation

/// The app's rolling log: the plain text the engine emits, kept short-lived on
/// purpose (spec §8.8).
///
/// Most apps let logs pile up on the disk for years. A menu-bar helper has no
/// business doing that, so this store keeps a small file, prunes it on every
/// write against a retention window the person chooses in Settings (default
/// fourteen days), and can be wiped in one click.
@MainActor
@Observable
final class LogStore {
    struct Entry: Identifiable, Sendable {
        let id = UUID()
        let date: Date
        let text: String
    }

    private(set) var entries: [Entry] = []

    /// The retention windows Settings offers. `0` means "keep until I clear".
    nonisolated static let retentionOptions: [Int] = [0, 7, 14, 30]

    /// How long a line survives. Persisted, and pruning runs on every change so
    /// the file never grows past the window without a decision.
    var retentionDays: Int {
        didSet {
            UserDefaults.standard.set(retentionDays, forKey: Self.retentionKey)
            prune()
        }
    }

    /// The file the lines are kept in, for "Reveal in Finder".
    var logFileURL: URL? { Self.fileURL }

    private static let retentionKey = "SeaStar.logRetentionDays"
    private static let timestamp = ISO8601DateFormatter()

    private static var fileURL: URL? {
        guard let library = FileManager.default
            .urls(for: .libraryDirectory, in: .userDomainMask).first
        else { return nil }
        return library
            .appendingPathComponent("Logs/Sea-Star", isDirectory: true)
            .appendingPathComponent("sea-star.log")
    }

    init() {
        let stored = UserDefaults.standard.object(forKey: Self.retentionKey) as? Int
        retentionDays = stored ?? 14
        load()
    }

    func append(_ text: String) {
        let lines = text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !lines.isEmpty else { return }
        for line in lines {
            entries.append(Entry(date: Date(), text: line))
        }
        prune()
        persist()
    }

    /// Wipe the log now — the "Clear now" button in Settings.
    func clear() {
        entries.removeAll()
        persist()
    }

    // MARK: - Disk

    private func load() {
        guard let url = Self.fileURL,
              let contents = try? String(contentsOf: url, encoding: .utf8)
        else { return }
        entries = contents
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap(Self.decode)
        prune()
        persist()
    }

    private func persist() {
        guard let url = Self.fileURL else { return }
        let directory = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let body = entries
            .map { "\(Self.timestamp.string(from: $0.date))\t\($0.text)" }
            .joined(separator: "\n")
        try? body.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Drop anything older than the retention window. `0` keeps everything.
    private func prune() {
        entries = Self.retained(entries, within: retentionDays)
    }

    /// The retention rule itself, pure so it can be proven without a clock or a
    /// disk. `0` keeps everything.
    nonisolated static func retained(_ entries: [Entry], within days: Int, now: Date = Date()) -> [Entry] {
        guard days > 0,
              let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now)
        else { return entries }
        return entries.filter { $0.date >= cutoff }
    }

    private static func decode(_ line: Substring) -> Entry? {
        let parts = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2,
              let date = timestamp.date(from: String(parts[0]))
        else { return nil }
        return Entry(date: date, text: String(parts[1]))
    }
}
