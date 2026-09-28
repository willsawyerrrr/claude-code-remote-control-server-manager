using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;

namespace RemoteControlManager.Services;

/// <summary>
/// Persists the list of added directory paths (not their running state) as JSON under
/// <c>%APPDATA%\RemoteControlManager\directories.json</c>.
/// </summary>
public sealed class DirectoryStore
{
    private static readonly string FilePath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "RemoteControlManager",
        "directories.json");

    /// <summary>
    /// Loads the persisted directory paths, or an empty list if none have been saved yet or the
    /// file cannot be read.
    /// </summary>
    public List<string> Load()
    {
        try
        {
            if (!File.Exists(FilePath))
            {
                return new List<string>();
            }

            var json = File.ReadAllText(FilePath);
            var paths = JsonSerializer.Deserialize<List<string>>(json);
            return paths ?? new List<string>();
        }
        catch (Exception)
        {
            return new List<string>();
        }
    }

    /// <summary>Persists <paramref name="paths"/>, creating the containing directory if needed.</summary>
    public void Save(IEnumerable<string> paths)
    {
        var directory = Path.GetDirectoryName(FilePath);
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }

        var json = JsonSerializer.Serialize(paths.ToList(), new JsonSerializerOptions { WriteIndented = true });
        File.WriteAllText(FilePath, json);
    }
}
