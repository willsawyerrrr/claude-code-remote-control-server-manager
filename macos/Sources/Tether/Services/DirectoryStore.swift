import Foundation

/// Persists the list of added directories to
/// `~/Library/Application Support/Tether/directories.json`.
enum DirectoryStore {
    private static let fileManager = FileManager.default

    private static var supportDirectory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Tether", isDirectory: true)
    }

    private static var fileURL: URL {
        supportDirectory.appendingPathComponent("directories.json", isDirectory: false)
    }

    /// Loads the saved directory list, or an empty list if none has been saved yet
    /// or the file can't be read.
    static func load() -> [DirectoryRecord] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([DirectoryRecord].self, from: data)) ?? []
    }

    /// Overwrites the saved directory list, creating the containing directory if needed.
    static func save(_ records: [DirectoryRecord]) {
        do {
            try fileManager.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("Tether: failed to save directory list: \(error.localizedDescription)")
        }
    }
}
