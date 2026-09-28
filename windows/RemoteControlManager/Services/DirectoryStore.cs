using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using RemoteControlManager.Models;

namespace RemoteControlManager.Services;

/// <summary>
/// Persists each added directory's path and last-known server process id as JSON under
/// <c>%APPDATA%\RemoteControlManager\directories.json</c>.
/// </summary>
public sealed class DirectoryStore
{
    private static readonly string FilePath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "RemoteControlManager",
        "directories.json");

    /// <summary>
    /// Loads the persisted directory records, or an empty list if none have been saved yet or the
    /// file cannot be read. Also understands the plain path-array format saved before a record
    /// carried a process id, treating every entry from it as having none.
    /// </summary>
    public List<DirectoryRecord> Load()
    {
        try
        {
            if (!File.Exists(FilePath))
            {
                return new List<DirectoryRecord>();
            }

            var json = File.ReadAllText(FilePath);

            try
            {
                var records = JsonSerializer.Deserialize<List<DirectoryRecord>>(json);
                if (records is not null)
                {
                    return records;
                }
            }
            catch (JsonException)
            {
                // Not the current format — fall through and try the legacy one below.
            }

            var paths = JsonSerializer.Deserialize<List<string>>(json);
            return paths?.Select(p => new DirectoryRecord { Path = p }).ToList() ?? new List<DirectoryRecord>();
        }
        catch (Exception)
        {
            return new List<DirectoryRecord>();
        }
    }

    /// <summary>Persists <paramref name="records"/>, creating the containing directory if needed.</summary>
    public void Save(IEnumerable<DirectoryRecord> records)
    {
        var directory = Path.GetDirectoryName(FilePath);
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }

        var json = JsonSerializer.Serialize(records.ToList(), new JsonSerializerOptions { WriteIndented = true });
        File.WriteAllText(FilePath, json);
    }
}
