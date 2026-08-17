import Foundation
import Carbon.HIToolbox
import AppKit

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var isTyping = false
    @Published private(set) var statusMessage = "Ready"
    @Published private(set) var isAccessibilityTrusted = false
    @Published var typingInterval: Double
    @Published var clearClipboardAfterUse: Bool
    @Published private(set) var shortcut: ShortcutBinding
    @Published private(set) var isRecordingShortcut = false

    private let clipboard = ClipboardService()
    private let typingEngine = TypingEngine()
    private let accessibility = AccessibilityService()
    private var globalHotKey: GlobalHotKey?
    private var shortcutMonitor: Any?

    init() {
        shortcut = ShortcutBinding(defaults: .standard) ?? .default
        typingInterval = UserDefaults.standard.object(forKey: "typing.interval") as? Double ?? 0.01
        clearClipboardAfterUse = UserDefaults.standard.bool(forKey: "clipboard.clearAfterUse")
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

        guard let snapshot = clipboard.snapshot() else {
            statusMessage = "The clipboard has no text"
            return
        }

        let text = snapshot.text

        guard !text.contains(where: { $0 == "\n" || $0 == "\r" }) else {
            statusMessage = "Multiline text is not supported yet"
            return
        }

        guard typingEngine.startTyping(text, interval: typingInterval, completion: { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isTyping = false

                switch result {
                case .completed:
                    if self.clearClipboardAfterUse {
                        self.clipboard.clearIfUnchanged(snapshot)
                    }
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

    func setTypingInterval(_ value: Double) {
        typingInterval = value
        UserDefaults.standard.set(value, forKey: "typing.interval")
    }

    func setClearClipboardAfterUse(_ value: Bool) {
        clearClipboardAfterUse = value
        UserDefaults.standard.set(value, forKey: "clipboard.clearAfterUse")
    }

    func beginShortcutRecording() {
        guard shortcutMonitor == nil else { return }

        isRecordingShortcut = true
        statusMessage = "Press a shortcut with a modifier"
        shortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            Task { @MainActor in
                self.captureShortcut(event)
            }
            return nil
        }
    }

    func cancelShortcutRecording() {
        if let shortcutMonitor {
            NSEvent.removeMonitor(shortcutMonitor)
            self.shortcutMonitor = nil
        }
        isRecordingShortcut = false
    }

    private func registerGlobalHotKey() {
        globalHotKey = nil

        do {
            globalHotKey = try GlobalHotKey(
                keyCode: shortcut.keyCode,
                modifiers: shortcut.modifiers
            ) { [weak self] in
                Task { @MainActor in
                    self?.typeClipboard()
                }
            }
        } catch {
            statusMessage = "Global shortcut unavailable"
        }
    }

    private func captureShortcut(_ event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            cancelShortcutRecording()
            statusMessage = "Shortcut change cancelled"
            return
        }

        guard let newShortcut = ShortcutBinding.from(event: event) else {
            statusMessage = "Use Command, Option, Control, or Shift"
            return
        }

        shortcut = newShortcut
        shortcut.save()
        cancelShortcutRecording()
        registerGlobalHotKey()
        statusMessage = "Shortcut updated"
    }
}
