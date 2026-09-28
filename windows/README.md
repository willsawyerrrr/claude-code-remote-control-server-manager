# Remote Control Manager (Windows)

Native Windows system tray app for managing `claude remote-control` server
sessions, one per directory. Built with WinForms
(`System.Windows.Forms.NotifyIcon`) targeting `net8.0-windows`. There's no
main window — everything happens through the tray icon's context menu.

## Requirements

- Windows, with the .NET 8 SDK and the "Windows Desktop" (WinForms) workload.
- The `claude` CLI on `PATH`, logged in, with a Claude subscription.
- Each directory you manage must already have had its Claude Code workspace
  trust dialog accepted (run `claude` in it once, interactively, first).

## Build & run

From `windows/RemoteControlManager/`:

```
dotnet run
```

or open the `windows/RemoteControlManager/` folder directly in Visual Studio
(File → Open → Folder) and run/debug from there — no `.sln` is needed.

## Usage

- Left- or right-click the tray icon for the context menu.
- **Add Directory...** opens a folder picker; the directory is added to the
  list (stopped) and persisted.
- Each directory is a submenu showing its status (Stopped / Connecting /
  Ready / Error) with **Start**/**Stop**, **Copy Join URL** (once Ready), and
  **Remove**.
- **Quit** stops every running server before exiting.

The directory list persists across restarts at
`%APPDATA%\RemoteControlManager\directories.json`; servers are never
auto-started on launch.
