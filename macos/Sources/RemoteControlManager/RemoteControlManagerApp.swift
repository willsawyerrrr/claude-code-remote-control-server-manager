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

/// Runs the app as a menu-bar-only accessory (no Dock icon, no main window). Quitting leaves
/// any running servers running, so they keep fronting sessions someone might be connected to;
/// the next launch detects them instead of starting a competing duplicate (see
/// `ManagedDirectory.start()`).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}
