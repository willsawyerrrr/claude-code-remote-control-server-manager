namespace RemoteControlManager.Models;

/// <summary>
/// Lifecycle state of a directory's <c>claude remote-control</c> session.
/// </summary>
public enum DirectoryStatus
{
    /// <summary>No server process is running for this directory.</summary>
    Stopped,

    /// <summary>The server process has been started but has not yet reported a join URL.</summary>
    Connecting,

    /// <summary>The server is up and its join URL is available.</summary>
    Ready,

    /// <summary>The server failed to start or exited unexpectedly.</summary>
    Error,

    /// <summary>
    /// Detected as still running from before this app last started — its process is alive, but
    /// this instance never captured its join URL, so it can only be stopped, not connected to.
    /// </summary>
    RunningUntracked,
}
