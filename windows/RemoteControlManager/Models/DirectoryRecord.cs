namespace RemoteControlManager.Models;

/// <summary>
/// Persisted identity of a directory the user has added, plus the process id of its server the
/// last time this app knew about it, and the join URL it had reported. Used to reconnect, on the
/// next launch, to a server still running from before this app last quit — see
/// <see cref="DirectoryManager"/>'s constructor.
/// </summary>
public sealed class DirectoryRecord
{
    public required string Path { get; init; }

    public int? Pid { get; init; }

    public string? JoinUrl { get; init; }
}
