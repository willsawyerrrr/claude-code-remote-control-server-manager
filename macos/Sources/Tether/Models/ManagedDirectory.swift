import Combine
import Darwin
import Foundation

/// A directory the user has added, and the `claude remote-control` server managing it.
@MainActor
final class ManagedDirectory: ObservableObject, Identifiable {
    let id: UUID
    let path: URL

    /// The current lifecycle state of this directory's server.
    @Published private(set) var status: SessionStatus = .stopped

    /// The process id of this directory's server, once known — kept so a still-running server
    /// can be recognised (and stopped) after this app restarts, even though this launch never
    /// started it itself.
    @Published private(set) var pid: pid_t?

    private var process: RemoteControlProcess?

    /// The join URL restored from a record, reused if that record's server is still running.
    private let restoredJoinURL: String?

    var name: String { path.lastPathComponent }

    init(id: UUID = UUID(), path: URL) {
        self.id = id
        self.path = path
        self.restoredJoinURL = nil
    }

    init(record: DirectoryRecord) {
        self.id = record.id
        self.path = URL(fileURLWithPath: record.path, isDirectory: true)
        self.pid = record.pid
        self.restoredJoinURL = record.joinURL
    }

    /// The persistable form of this directory.
    var record: DirectoryRecord {
        DirectoryRecord(id: id, path: path.path, pid: pid, joinURL: status.joinURL)
    }

    /// Starts `claude remote-control` for this directory, unless it's already running — whether
    /// as a process this instance launched, or one detected as still running from before this
    /// app last quit (see `isOrphanStillRunning`). A still-running server keeps the join URL it
    /// reported before the quit, so it comes back as `.ready`; if it hadn't reported one yet,
    /// it's surfaced as `.runningUntracked`. Either way no competing duplicate is started.
    func start() {
        guard !status.isRunning else { return }

        if let pid, Self.isOrphanStillRunning(pid: pid) {
            status = restoredJoinURL.map { .ready(joinURL: $0) } ?? .runningUntracked
            return
        }

        pid = nil
        status = .connecting

        let process = RemoteControlProcess(directoryURL: path, name: name) { [weak self] newStatus in
            self?.status = newStatus
            if !newStatus.isRunning {
                self?.pid = nil
            }
        }
        self.process = process
        process.start()
        pid = process.pid
    }

    /// Stops the running server, if any: `SIGTERM` to a process this instance launched, or
    /// directly to a process detected as still running from before this app last quit.
    func stop() {
        if let process {
            process.stop()
            return
        }

        if status.isRunning, let pid {
            kill(pid, SIGTERM)
            status = .stopped
            self.pid = nil
        }
    }

    /// Whether `pid` still belongs to a live `claude` process. `claude remote-control` is
    /// launched via `env`, which execs into `claude` in place rather than forking, so the pid
    /// stays the same across the exec — checking the process name guards against a coincidental
    /// pid reuse by some unrelated process since this app last quit.
    private static func isOrphanStillRunning(pid: pid_t) -> Bool {
        guard kill(pid, 0) == 0 else { return false }

        var buffer = [CChar](repeating: 0, count: 64)
        guard proc_name(pid, &buffer, UInt32(buffer.count)) > 0 else { return false }
        return String(cString: buffer) == "claude"
    }
}
