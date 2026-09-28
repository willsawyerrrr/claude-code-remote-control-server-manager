namespace RemoteControlManager.Models;

/// <summary>
/// Persisted identity of a directory the user has added, plus the process id of its server the
/// last time this app knew about it. Used to detect, on the next launch, a server still running
/// from before this app last quit — see <see cref="DirectoryManager"/>'s constructor — without
/// restoring any other state.
/// </summary>
public sealed class DirectoryRecord
{
    public required string Path { get; init; }

    public int? Pid { get; init; }
}
