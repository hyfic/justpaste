import AppKit

struct ClipboardSnapshot {
    let text: String
    let changeCount: Int
}

struct ClipboardService {
    func snapshot() -> ClipboardSnapshot? {
        let pasteboard = NSPasteboard.general
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else {
            return nil
        }
        return ClipboardSnapshot(text: text, changeCount: pasteboard.changeCount)
    }

    func clearIfUnchanged(_ snapshot: ClipboardSnapshot) {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount == snapshot.changeCount else {
            return
        }
        pasteboard.clearContents()
    }
}
