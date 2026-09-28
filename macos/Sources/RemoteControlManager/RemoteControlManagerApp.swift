import AppKit
import Foundation
import SwiftUI

@main
struct RemoteControlManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Remote Control Manager", systemImage: "network") {
            MenuBarContentView()
                .environmentObject(appDelegate.model)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Runs the app as a menu-bar-only accessory (no Dock icon, no main window) and makes
/// sure every child process is signalled before the app actually quits.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()

    /// How long to wait for running servers to exit cleanly before quitting anyway.
    private static let shutdownTimeout: TimeInterval = 3

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let hasRunningServers = model.directories.contains { $0.status.isRunning }
        guard hasRunningServers else { return .terminateNow }

        model.stopAll()

        let deadline = Date().addingTimeInterval(Self.shutdownTimeout)
        while Date() < deadline, model.directories.contains(where: { $0.status.isRunning }) {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        return .terminateNow
    }
}
