import AppKit
import Foundation
import SwiftUI

@main
struct TetherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Tether", systemImage: "network") {
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
    private lazy var controlServer = ControlServer { [model] request in
        await model.handle(request)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        controlServer.start()
    }
}
