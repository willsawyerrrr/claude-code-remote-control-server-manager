namespace RemoteControlManager.Models;

/// <summary>
/// A directory the user has added, and the state of its <c>claude remote-control</c> session.
/// </summary>
public sealed class ManagedDirectory
{
    /// <summary>Absolute path to the directory on disk.</summary>
    public required string Path { get; init; }

    /// <summary>
    /// Display name for the directory: its folder name, falling back to the full path if the
    /// folder name cannot be determined (e.g. a root path like <c>C:\</c>).
    /// </summary>
    public string Name
    {
        get
        {
            var trimmed = Path.TrimEnd(
                System.IO.Path.DirectorySeparatorChar,
                System.IO.Path.AltDirectorySeparatorChar);
            var name = System.IO.Path.GetFileName(trimmed);
            return string.IsNullOrEmpty(name) ? Path : name;
        }
    }

    /// <summary>Current lifecycle state of this directory's server process.</summary>
    public DirectoryStatus Status { get; set; } = DirectoryStatus.Stopped;

    /// <summary>Join URL for the running server, set once <see cref="Status"/> is <see cref="DirectoryStatus.Ready"/>.</summary>
    public string? JoinUrl { get; set; }

    /// <summary>Error message set when <see cref="Status"/> is <see cref="DirectoryStatus.Error"/>.</summary>
    public string? ErrorMessage { get; set; }
}
