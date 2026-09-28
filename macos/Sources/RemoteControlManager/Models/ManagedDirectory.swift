import Combine
import Foundation

/// A directory the user has added, and the `claude remote-control` server managing it.
@MainActor
final class ManagedDirectory: ObservableObject, Identifiable {
    let id: UUID
    let path: URL

    /// The current lifecycle state of this directory's server.
    @Published private(set) var status: SessionStatus = .stopped

    private var process: RemoteControlProcess?

    var name: String { path.lastPathComponent }

    init(id: UUID = UUID(), path: URL) {
        self.id = id
        self.path = path
    }

    init(record: DirectoryRecord) {
        self.id = record.id
        self.path = URL(fileURLWithPath: record.path, isDirectory: true)
    }

    /// The persistable form of this directory.
    var record: DirectoryRecord {
        DirectoryRecord(id: id, path: path.path)
    }

    /// Spawns `claude remote-control` for this directory, if it isn't already running.
    func start() {
        guard !status.isRunning else { return }

        status = .connecting

        let process = RemoteControlProcess(directoryURL: path, name: name) { [weak self] newStatus in
            self?.status = newStatus
        }
        self.process = process
        process.start()
    }

    /// Sends `SIGTERM` to the running server, if any, and waits for it to exit.
    func stop() {
        process?.stop()
    }
}
