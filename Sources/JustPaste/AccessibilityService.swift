import ApplicationServices
import AppKit
import Foundation

struct FocusedElementInfo {
    let role: String?
    let subrole: String?

    var looksLikeTextInput: Bool {
        let textRoles = [
            kAXTextFieldRole as String,
            kAXTextAreaRole as String,
            kAXComboBoxRole as String
        ]

        return textRoles.contains(role ?? "")
            || subrole == (kAXSecureTextFieldSubrole as String)
    }
}

@MainActor
final class AccessibilityService: ObservableObject {
    @Published private(set) var isTrusted = false

    func refreshStatus() {
        isTrusted = AXIsProcessTrusted()
    }

    func requestPermission() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        isTrusted = AXIsProcessTrustedWithOptions(options)
    }

    func focusedElementInfo() -> FocusedElementInfo? {
        guard isTrusted,
              let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let application = AXUIElementCreateApplication(frontmostApplication.processIdentifier)
        var focusedValue: CFTypeRef?
        let focusedError = AXUIElementCopyAttributeValue(
            application,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        )

        guard focusedError == .success,
              let focusedValue,
              CFGetTypeID(focusedValue) == AXUIElementGetTypeID() else {
            return nil
        }

        let focusedElement = focusedValue as! AXUIElement
        var roleValue: CFTypeRef?
        var subroleValue: CFTypeRef?
        AXUIElementCopyAttributeValue(focusedElement, kAXRoleAttribute as CFString, &roleValue)
        AXUIElementCopyAttributeValue(focusedElement, kAXSubroleAttribute as CFString, &subroleValue)

        return FocusedElementInfo(
            role: roleValue as? String,
            subrole: subroleValue as? String
        )
    }
}
