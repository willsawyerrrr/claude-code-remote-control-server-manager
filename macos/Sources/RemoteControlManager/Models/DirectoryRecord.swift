import Foundation

/// The persisted representation of a directory the user has added, plus the process id of its
/// server the last time this app knew about it — used to detect, on the next launch, a server
/// still running from before this app last quit (see `ManagedDirectory.start()`).
struct DirectoryRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let path: String
    let pid: pid_t?
}
