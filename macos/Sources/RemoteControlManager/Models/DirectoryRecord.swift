import Foundation

/// The persisted representation of a directory the user has added, plus the process id of its
/// server and its join URL the last time this app knew about them — used to reconnect, on the
/// next launch, to a server still running from before this app last quit (see
/// `ManagedDirectory.start()`).
struct DirectoryRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let path: String
    let pid: pid_t?
    let joinURL: String?
}
