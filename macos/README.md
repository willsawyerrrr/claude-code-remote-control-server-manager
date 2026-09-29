# Remote Control Manager (macOS)

A menu bar app for starting, watching, and stopping `claude remote-control`
server sessions — one per directory — without keeping a terminal open. No
Dock icon, no main window: the menu bar icon and its popover are the entire
UI.

Targets macOS 13+.

## Structure

This is a Swift Package Manager executable target, not an `.xcodeproj`:

- `Package.swift` — package manifest.
- `Sources/RemoteControlManager/` — app source.
  - `RemoteControlManagerApp.swift` — `MenuBarExtra` scene and app delegate
    (accessory activation policy).
  - `Models/` — `SessionStatus`, `DirectoryRecord`, `ManagedDirectory`.
  - `Services/` — `RemoteControlProcess` (spawns and parses
    `claude remote-control`), `DirectoryStore` (persistence), `AppModel`
    (app-wide state).
  - `Views/` — `MenuBarContentView`, `DirectoryRowView`.

## Opening and running

- In Xcode: `open Package.swift`, then run the `RemoteControlManager` scheme.
- From the command line: `swift run` (from this directory).

## Notes

- The directory list persists across launches at
  `~/Library/Application Support/RemoteControlManager/directories.json`.
  Quitting the app leaves any running servers running, so they keep fronting
  sessions someone might be connected to. Every launch starts a server for
  each directory in that list, or, for one detected as still running from
  before this app last quit, reuses the join URL it reported (persisted with
  the directory) rather than starting a competing duplicate. If it hadn't
  reported one yet, it's marked running and can only be stopped.
- A directory must already have its Claude Code workspace trust dialog
  accepted (`claude` run there once, interactively) before its server can
  start; otherwise the directory's status surfaces the trust error verbatim.
