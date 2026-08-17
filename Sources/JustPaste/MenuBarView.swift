import AppKit
import SwiftUI

struct MenuBarView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("JustPaste", systemImage: "doc.on.clipboard")
                .font(.headline)

            Text("Menu-bar shell ready")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Button("Quit JustPaste") {
                NSApp.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 240)
    }
}
