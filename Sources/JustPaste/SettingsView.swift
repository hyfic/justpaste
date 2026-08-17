import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section("Shortcut") {
                HStack {
                    Text(model.shortcut.displayName)
                        .font(.system(.body, design: .monospaced))

                    Spacer()

                    Button(model.isRecordingShortcut ? "Listening…" : "Change") {
                        if model.isRecordingShortcut {
                            model.cancelShortcutRecording()
                        } else {
                            model.beginShortcutRecording()
                        }
                    }
                }

                Text(model.isRecordingShortcut
                     ? "Press the new shortcut, or Escape to cancel."
                     : "The shortcut types the current clipboard text into the focused field.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Typing") {
                HStack {
                    Text("Character delay")
                    Slider(
                        value: Binding(
                            get: { model.typingInterval },
                            set: { model.setTypingInterval($0) }
                        ),
                        in: 0...0.1,
                        step: 0.005
                    )
                    Text("\(Int(model.typingInterval * 1_000)) ms")
                        .font(.caption.monospacedDigit())
                        .frame(width: 48, alignment: .trailing)
                }

                Toggle(
                    "Clear clipboard after successful typing",
                    isOn: Binding(
                        get: { model.clearClipboardAfterUse },
                        set: { model.setClearClipboardAfterUse($0) }
                    )
                )
            }

            Section("Privacy") {
                Text("JustPaste keeps no clipboard history and does not send clipboard contents over the network. Clipboard clearing is optional and only occurs if the clipboard has not changed during typing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 360)
    }
}
