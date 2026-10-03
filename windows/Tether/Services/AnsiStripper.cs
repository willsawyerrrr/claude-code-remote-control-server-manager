using System.Text.RegularExpressions;

namespace Tether.Services;

/// <summary>
/// Strips ANSI escape sequences from text emitted by <c>claude remote-control</c>'s live
/// status panel (e.g. cursor-movement codes like <c>\x1b[7A\x1b[J</c>) so plain lines can be
/// parsed out of it.
/// </summary>
public static class AnsiStripper
{
    // Matches ANSI CSI sequences: ESC '[' followed by parameter bytes (0x30-0x3F), intermediate
    // bytes (0x20-0x2F), and a final byte (0x40-0x7E).
    private static readonly Regex CsiSequence = new(@"\x1B\[[0-?]*[ -/]*[@-~]", RegexOptions.Compiled);

    /// <summary>Returns <paramref name="text"/> with all ANSI CSI escape sequences removed.</summary>
    public static string Strip(string text) => CsiSequence.Replace(text, string.Empty);
}
