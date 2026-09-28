using System;
using System.Collections.Generic;
using System.Linq;
using RemoteControlManager.Models;

namespace RemoteControlManager.Services;

/// <summary>
/// Owns the list of added directories, their persisted state, and the
/// <see cref="RemoteControlSession"/> running for each one that is started.
/// </summary>
/// <remarks>
/// <see cref="Changed"/> may be raised from a background thread (child-process output/exit
/// callbacks run off the UI thread) — subscribers are responsible for marshalling back to the
/// UI thread before touching UI controls.
/// </remarks>
public sealed class DirectoryManager : IDisposable
{
    private readonly DirectoryStore _store = new();
    private readonly Dictionary<string, RemoteControlSession> _sessions = new(StringComparer.OrdinalIgnoreCase);

    public DirectoryManager()
    {
        Directories = _store.Load()
            .Select(path => new ManagedDirectory { Path = path })
            .ToList();
    }

    /// <summary>Directories the user has added, in the order they were added.</summary>
    public List<ManagedDirectory> Directories { get; }

    /// <summary>Raised whenever the directory list or any directory's status changes.</summary>
    public event Action? Changed;

    /// <summary>
    /// Adds a directory if it isn't already present and starts its server. Returns false if it
    /// was a duplicate.
    /// </summary>
    public bool AddDirectory(string path)
    {
        if (Directories.Any(d => string.Equals(d.Path, path, StringComparison.OrdinalIgnoreCase)))
        {
            return false;
        }

        var directory = new ManagedDirectory { Path = path };
        Directories.Add(directory);
        Persist();
        StartDirectory(directory);
        return true;
    }

    /// <summary>Stops the directory's server if running, then removes it from the list.</summary>
    public void RemoveDirectory(ManagedDirectory directory)
    {
        StopDirectory(directory);
        Directories.Remove(directory);
        Persist();
        Changed?.Invoke();
    }

    /// <summary>Starts the server for <paramref name="directory"/> if it isn't already running.</summary>
    public void StartDirectory(ManagedDirectory directory)
    {
        if (_sessions.ContainsKey(directory.Path))
        {
            return;
        }

        directory.Status = DirectoryStatus.Connecting;
        directory.JoinUrl = null;
        directory.ErrorMessage = null;

        var session = new RemoteControlSession(directory.Path, directory.Name);
        session.Ready += url => OnReady(directory, url);
        session.Failed += message => OnFailed(directory, message);
        session.Exited += () => OnExited(directory);
        _sessions[directory.Path] = session;

        try
        {
            session.Start();
        }
        catch (Exception ex)
        {
            _sessions.Remove(directory.Path);
            session.Dispose();
            directory.Status = DirectoryStatus.Error;
            directory.ErrorMessage = ex.Message;
        }

        Changed?.Invoke();
    }

    /// <summary>Stops the server for <paramref name="directory"/> if it is running.</summary>
    public void StopDirectory(ManagedDirectory directory)
    {
        if (_sessions.TryGetValue(directory.Path, out var session))
        {
            session.Stop();
        }
    }

    /// <summary>Stops every running server. Called before the app quits.</summary>
    public void StopAll()
    {
        foreach (var session in _sessions.Values)
        {
            session.Stop();
        }
    }

    private void OnReady(ManagedDirectory directory, string url)
    {
        directory.Status = DirectoryStatus.Ready;
        directory.JoinUrl = url;
        directory.ErrorMessage = null;
        Changed?.Invoke();
    }

    private void OnFailed(ManagedDirectory directory, string message)
    {
        directory.Status = DirectoryStatus.Error;
        directory.ErrorMessage = message;
        directory.JoinUrl = null;
        Changed?.Invoke();
    }

    private void OnExited(ManagedDirectory directory)
    {
        if (_sessions.TryGetValue(directory.Path, out var session))
        {
            _sessions.Remove(directory.Path);
            session.Dispose();
        }

        // A session that exited without ever becoming ready already went through OnFailed
        // (RemoteControlSession guarantees Failed fires before Exited in that case), so only a
        // clean stop or a post-ready crash reach here with a non-Error status.
        if (directory.Status != DirectoryStatus.Error)
        {
            directory.Status = DirectoryStatus.Stopped;
            directory.JoinUrl = null;
        }

        Changed?.Invoke();
    }

    private void Persist()
    {
        _store.Save(Directories.Select(d => d.Path));
    }

    public void Dispose()
    {
        StopAll();
        foreach (var session in _sessions.Values)
        {
            session.Dispose();
        }
    }
}
