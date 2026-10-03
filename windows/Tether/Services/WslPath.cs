using System.Text.RegularExpressions;

namespace Tether.Services;

/// <summary>Translates a Windows-side directory path into the Linux path WSL sees it as.</summary>
public static class WslPath
{
    private static readonly Regex UncPattern =
        new(@"^\\\\wsl(?:\.localhost|\$)\\(?<distro>[^\\]+)\\(?<rest>.*)$", RegexOptions.IgnoreCase | RegexOptions.Compiled);

    private static readonly Regex DrivePattern =
        new(@"^(?<drive>[A-Za-z]):\\(?<rest>.*)$", RegexOptions.Compiled);

    /// <summary>
    /// Translates <paramref name="windowsPath"/> to a Linux path, and to the WSL distro that owns
    /// it when the path names one explicitly (a <c>\\wsl.localhost\&lt;Distro&gt;\...</c> path,
    /// which Explorer's folder picker can produce when Browse into a WSL location). Returns a
    /// null distro for an ordinary drive path (e.g. <c>C:\...</c>), which is translated assuming
    /// the default <c>/mnt/&lt;drive&gt;</c> mount point — the standard default, but not
    /// guaranteed if a distro has been configured with custom drvfs mount settings.
    /// </summary>
    public static (string LinuxPath, string? Distro) Translate(string windowsPath)
    {
        var uncMatch = UncPattern.Match(windowsPath);
        if (uncMatch.Success)
        {
            var rest = uncMatch.Groups["rest"].Value.Replace('\\', '/');
            return ($"/{rest}", uncMatch.Groups["distro"].Value);
        }

        var driveMatch = DrivePattern.Match(windowsPath);
        if (driveMatch.Success)
        {
            var drive = driveMatch.Groups["drive"].Value.ToLowerInvariant();
            var rest = driveMatch.Groups["rest"].Value.Replace('\\', '/');
            return ($"/mnt/{drive}/{rest}", null);
        }

        return (windowsPath.Replace('\\', '/'), null);
    }
}
