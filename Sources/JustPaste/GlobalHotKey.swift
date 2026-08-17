import Carbon.HIToolbox
import Foundation

final class GlobalHotKey {
    enum RegistrationError: Error {
        case eventHandlerInstallFailed(OSStatus)
        case registrationFailed(OSStatus)
    }

    typealias Handler = () -> Void

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let handler: Handler

    init(keyCode: UInt32, modifiers: UInt32, handler: @escaping Handler) throws {
        self.handler = handler

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            GlobalHotKey.eventHandler,
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )

        guard installStatus == noErr else {
            throw RegistrationError.eventHandlerInstallFailed(installStatus)
        }

        let hotKeyID = EventHotKeyID(signature: 0x4A505354, id: 1)
        let registrationStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard registrationStatus == noErr else {
            if let eventHandlerRef {
                RemoveEventHandler(eventHandlerRef)
                self.eventHandlerRef = nil
            }
            throw RegistrationError.registrationFailed(registrationStatus)
        }
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    private static let eventHandler: EventHandlerUPP = { _, _, userData in
        guard let userData else {
            return noErr
        }

        let hotKey = Unmanaged<GlobalHotKey>
            .fromOpaque(userData)
            .takeUnretainedValue()
        hotKey.handler()
        return noErr
    }
}
