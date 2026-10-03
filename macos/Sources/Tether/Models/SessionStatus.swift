import Foundation

/// The lifecycle state of a directory's `claude remote-control` server.
enum SessionStatus: Equatable {
    case stopped
    case connecting
    case ready(joinURL: String)
    case error(message: String)

    /// Detected as still running from before this app last quit, but it hadn't yet reported a
    /// join URL by then, so it can only be stopped, not connected to.
    case runningUntracked

    /// The join URL, once the server has reported one.
    var joinURL: String? {
        if case .ready(let joinURL) = self { return joinURL }
        return nil
    }

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
