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

            Button("Quit JustPaste") {
                NSApp.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 240)
    }
}
