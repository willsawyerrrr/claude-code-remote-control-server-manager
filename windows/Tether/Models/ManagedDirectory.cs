namespace Tether.Models;

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

    /// <summary>
    /// Process id of the directory's <c>cmd</c>/<c>wsl</c> child, while a session this instance
    /// started is running, or while <see cref="Status"/> is
    /// <see cref="DirectoryStatus.Ready"/> or <see cref="DirectoryStatus.RunningUntracked"/>
    /// after being detected from an earlier launch. Persisted so the next launch can detect a
    /// server still running from before this app last quit.
    /// </summary>
    public int? Pid { get; set; }
}
