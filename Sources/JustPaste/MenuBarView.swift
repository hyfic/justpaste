import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("JustPaste", systemImage: "doc.on.clipboard")
                .font(.headline)

            Text(model.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Shortcut: ⌘⌥V")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            if model.isTyping {
                Button("Cancel Typing") {
                    model.cancelTyping()
                }
            } else {
                Button("Type Clipboard") {
                    model.typeClipboard()
                }
            }

            if model.isAccessibilityTrusted {
                Label("Accessibility enabled", systemImage: "checkmark.shield")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Button("Enable Accessibility") {
                    model.requestAccessibilityPermission()
                }
                .font(.caption)
            }

            Button("Quit JustPaste") {
                NSApp.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 240)
    }
}
