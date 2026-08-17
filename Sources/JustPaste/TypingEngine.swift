import CoreGraphics
import Foundation

final class TypingEngine {
    enum Result {
        case completed
        case cancelled
        case failed
    }

    private let lock = NSLock()
    private var cancellationRequested = false
    private var typingInProgress = false

    var isTyping: Bool {
        lock.lock()
        defer { lock.unlock() }
        return typingInProgress
    }

    @discardableResult
    func startTyping(
        _ text: String,
        interval: TimeInterval = 0.01,
        completion: @escaping (Result) -> Void
    ) -> Bool {
        lock.lock()
        guard !typingInProgress else {
            lock.unlock()
            return false
        }
        typingInProgress = true
        cancellationRequested = false
        lock.unlock()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            var result: Result = .completed

            for scalar in text.unicodeScalars {
                if self.shouldCancel() {
                    result = .cancelled
                    break
                }

                guard self.post(scalar: scalar) else {
                    result = .failed
                    break
                }

                if interval > 0 {
                    Thread.sleep(forTimeInterval: interval)
                }
            }

            self.lock.lock()
            self.typingInProgress = false
            self.cancellationRequested = false
            self.lock.unlock()

            completion(result)
        }

        return true
    }

    func cancel() {
        lock.lock()
        cancellationRequested = true
        lock.unlock()
    }

    private func shouldCancel() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancellationRequested
    }

    private func post(scalar: UnicodeScalar) -> Bool {
        let utf16 = Array(String(scalar).utf16)

        return utf16.withUnsafeBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress,
                  let keyDown = CGEvent(
                    keyboardEventSource: nil,
                    virtualKey: 0,
                    keyDown: true
                  ),
                  let keyUp = CGEvent(
                    keyboardEventSource: nil,
                    virtualKey: 0,
                    keyDown: false
                  ) else {
                return false
            }

            keyDown.keyboardSetUnicodeString(
                stringLength: buffer.count,
                unicodeString: baseAddress
            )
            keyUp.keyboardSetUnicodeString(
                stringLength: buffer.count,
                unicodeString: baseAddress
            )

            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
            return true
        }
    }
}
