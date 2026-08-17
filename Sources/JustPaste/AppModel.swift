import Foundation
import Carbon.HIToolbox

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var isTyping = false
    @Published private(set) var statusMessage = "Ready"
    @Published private(set) var isAccessibilityTrusted = false

    private let clipboard = ClipboardService()
    private let typingEngine = TypingEngine()
    private let accessibility = AccessibilityService()
    private var globalHotKey: GlobalHotKey?

    init() {
        refreshAccessibilityStatus()
        registerGlobalHotKey()
    }

    func typeClipboard() {
        guard isAccessibilityTrusted else {
            statusMessage = "Accessibility permission is required"
            requestAccessibilityPermission()
            return
        }

        if let focusedElement = accessibility.focusedElementInfo(),
           !focusedElement.looksLikeTextInput {
            statusMessage = "No editable field is focused"
            return
        }

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

    func refreshAccessibilityStatus() {
        accessibility.refreshStatus()
        isAccessibilityTrusted = accessibility.isTrusted
    }

    func requestAccessibilityPermission() {
        accessibility.requestPermission()
        isAccessibilityTrusted = accessibility.isTrusted
    }

    private func registerGlobalHotKey() {
        do {
            globalHotKey = try GlobalHotKey(
                keyCode: UInt32(kVK_ANSI_V),
                modifiers: UInt32(cmdKey | optionKey)
            ) { [weak self] in
                Task { @MainActor in
                    self?.typeClipboard()
                }
            }
        } catch {
            statusMessage = "Global shortcut unavailable"
        }
    }
}
