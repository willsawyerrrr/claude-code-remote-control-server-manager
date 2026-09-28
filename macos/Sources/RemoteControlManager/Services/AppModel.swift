import AppKit
import Combine
import Foundation

/// Owns the list of directories the user has added and their `claude remote-control`
/// servers, and keeps the persisted directory list in sync with changes.
@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var directories: [ManagedDirectory] = []

    init() {
        directories = DirectoryStore.load().map(ManagedDirectory.init(record:))
        for directory in directories {
            directory.start()
        }
    }

    /// Presents a directory picker and adds the chosen directory, if any and not already added.
    func addDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Add"
        panel.message = "Choose a directory to manage with Remote Control Manager."

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let standardizedURL = url.standardizedFileURL
        guard !directories.contains(where: { $0.path.standardizedFileURL == standardizedURL }) else {
            return
        }

        let directory = ManagedDirectory(path: standardizedURL)
        directories.append(directory)
        persist()
        directory.start()
    }

    /// Stops the directory's server, if running, and removes it from the list.
    func remove(_ directory: ManagedDirectory) {
        directory.stop()
        directories.removeAll { $0.id == directory.id }
        persist()
    }

    /// Sends `SIGTERM` to every running server. Used when the app is quitting.
    func stopAll() {
        for directory in directories {
            directory.stop()
        }
    }

    private func persist() {
        DirectoryStore.save(directories.map(\.record))
    }
}
