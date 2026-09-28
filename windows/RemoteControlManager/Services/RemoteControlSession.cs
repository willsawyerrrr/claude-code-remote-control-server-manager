using System;
using System.Diagnostics;
using System.Text.RegularExpressions;

namespace RemoteControlManager.Services;

/// <summary>
/// Wraps a single <c>claude remote-control</c> child process for one directory: starts it,
/// parses its stdout/stderr for readiness and errors, and stops it.
/// </summary>
public sealed class RemoteControlSession : IDisposable
{
    private static readonly Regex JoinUrlPattern =
        new(@"https://claude\.ai/code\?environment=\S+", RegexOptions.Compiled);

    private const string WorkspaceNotTrustedPrefix = "Error: Workspace not trusted";

    private readonly string _directoryPath;
    private readonly string _name;
    private Process? _process;

    public RemoteControlSession(string directoryPath, string name)
    {
        _directoryPath = directoryPath;
        _name = name;
    }

    /// <summary>Raised with the join URL once the server reports it is ready.</summary>
    public event Action<string>? Ready;

    /// <summary>Raised with an error message if the process reports a failure (e.g. untrusted workspace).</summary>
    public event Action<string>? Failed;

    /// <summary>Raised when the process exits, for any reason.</summary>
    public event Action? Exited;

    /// <summary>
    /// Starts <c>claude remote-control</c> with its working directory set to the target
    /// directory. Runs headless: stdin is closed immediately, and stdout/stderr are read
    /// asynchronously line by line.
    /// </summary>
    public void Start()
    {
        var startInfo = new ProcessStartInfo
        {
            // Route through cmd.exe rather than invoking "claude" directly: npm-installed
            // global CLIs on Windows are typically a .cmd/.bat shim, and Process.Start does not
            // probe PATHEXT the way cmd.exe does, so a direct launch can fail to resolve it.
            FileName = "cmd.exe",
            WorkingDirectory = _directoryPath,
            UseShellExecute = false,
            CreateNoWindow = true,
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
        };
        startInfo.ArgumentList.Add("/c");
        startInfo.ArgumentList.Add("claude");
        startInfo.ArgumentList.Add("remote-control");
        startInfo.ArgumentList.Add("--name");
        startInfo.ArgumentList.Add(_name);
        startInfo.ArgumentList.Add("--no-create-session-in-dir");

        var process = new Process { StartInfo = startInfo, EnableRaisingEvents = true };
        process.OutputDataReceived += OnOutputDataReceived;
        process.ErrorDataReceived += OnErrorDataReceived;
        process.Exited += (_, _) => Exited?.Invoke();
        _process = process;

        process.Start();
        process.StandardInput.Close();
        process.BeginOutputReadLine();
        process.BeginErrorReadLine();
    }

    private void OnOutputDataReceived(object? sender, DataReceivedEventArgs e)
    {
        if (e.Data is null)
        {
            return;
        }

        var line = AnsiStripper.Strip(e.Data);
        var match = JoinUrlPattern.Match(line);
        if (match.Success)
        {
            Ready?.Invoke(match.Value);
        }
    }

    private void OnErrorDataReceived(object? sender, DataReceivedEventArgs e)
    {
        if (e.Data is null)
        {
            return;
        }

        var line = AnsiStripper.Strip(e.Data);
        if (line.StartsWith(WorkspaceNotTrustedPrefix, StringComparison.Ordinal))
        {
            Failed?.Invoke(line);
        }
    }

    /// <summary>
    /// Terminates the process. A detached child process has no console to deliver a Ctrl+C /
    /// Ctrl+Break event to on Windows, so there is no graceful-shutdown signal available the way
    /// SIGTERM is on Unix; killing the whole process tree is the only reliable option.
    /// </summary>
    public void Stop()
    {
        if (_process is null)
        {
            return;
        }

        try
        {
            if (!_process.HasExited)
            {
                _process.Kill(entireProcessTree: true);
            }
        }
        catch (InvalidOperationException)
        {
            // Process already exited between the HasExited check and Kill.
        }
    }

    public void Dispose()
    {
        if (_process is null)
        {
            return;
        }

        _process.OutputDataReceived -= OnOutputDataReceived;
        _process.ErrorDataReceived -= OnErrorDataReceived;
        _process.Dispose();
    }
}
