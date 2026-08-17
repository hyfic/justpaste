import AppKit
import SwiftUI

@main
struct JustPasteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("JustPaste", systemImage: "doc.on.clipboard") {
            MenuBarView(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
