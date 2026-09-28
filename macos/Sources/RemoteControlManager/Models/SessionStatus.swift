import Foundation

/// The lifecycle state of a directory's `claude remote-control` server.
enum SessionStatus: Equatable {
    case stopped
    case connecting
    case ready(joinURL: String)
    case error(message: String)

    /// Whether a child process is currently expected to be alive for this status.
    var isRunning: Bool {
        switch self {
        case .connecting, .ready:
            return true
        case .stopped, .error:
            return false
        }
    }
}
