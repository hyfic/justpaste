import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var isTyping = false
    @Published private(set) var statusMessage = "Ready"

    private let clipboard = ClipboardService()
    private let typingEngine = TypingEngine()

    func typeClipboard() {
        guard let text = clipboard.readText(), !text.isEmpty else {
            statusMessage = "The clipboard has no text"
            return
        }

        guard !text.contains(where: { $0 == "\n" || $0 == "\r" }) else {
            statusMessage = "Multiline text is not supported yet"
            return
        }

        guard typingEngine.startTyping(text, completion: { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isTyping = false

                switch result {
                case .completed:
                    self.statusMessage = "Typing complete"
                case .cancelled:
                    self.statusMessage = "Typing cancelled"
                case .failed:
                    self.statusMessage = "Unable to type clipboard text"
                }
            }
        }) else {
            statusMessage = "Already typing"
            return
        }

        isTyping = true
        statusMessage = "Typing clipboard text…"
    }

    func cancelTyping() {
        guard isTyping else { return }
        typingEngine.cancel()
        statusMessage = "Cancelling…"
    }
}
