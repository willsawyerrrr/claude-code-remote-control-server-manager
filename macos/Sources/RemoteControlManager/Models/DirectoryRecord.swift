import Foundation

/// The persisted representation of a directory the user has added.
///
/// Only the directory's identity is persisted; a server's running state is never
/// restored across launches.
struct DirectoryRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let path: String
}
