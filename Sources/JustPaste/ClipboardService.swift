import AppKit

struct ClipboardService {
    func readText() -> String? {
        NSPasteboard.general.string(forType: .string)
    }
}
