import Foundation

/// The lifecycle state of a directory's `claude remote-control` server.
enum SessionStatus: Equatable {
    case stopped
    case connecting
    case ready(joinURL: String)
    case error(message: String)

    /// Detected as still running from before this app last quit: its process is alive, but this
    /// launch never captured its join URL, so it can only be stopped, not connected to.
    case runningUntracked

    /// Whether a child process is currently expected to be alive for this status.
    var isRunning: Bool {
        switch self {
        case .connecting, .ready, .runningUntracked:
            return true
        case .stopped, .error:
            return false
        }
    }
}
