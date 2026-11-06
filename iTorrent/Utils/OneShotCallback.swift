import Foundation

/// Claims a callback before invoking it, even if callers arrive concurrently
/// or the callback reenters the operation that produced it.
final class OneShotCallback<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var callback: ((Value) -> Void)?

    init(_ callback: @escaping (Value) -> Void) {
        self.callback = callback
    }

    func call(_ value: Value) {
        lock.lock()
        let callback = self.callback
        self.callback = nil
        lock.unlock()

        callback?(value)
    }
}
