//===----------------------------------------------------------------------===//
//
// Debug metrics bridge for NIOSSH internals.
// Consumers set handlers to receive counters and timestamped events
// from the SSH multiplexer and child channels.
//
//===----------------------------------------------------------------------===//

import Dispatch
import NIOConcurrencyHelpers
import NIOCore

/// Provides visibility into NIOSSH internal operations for debugging.
/// Set handlers once at startup; all methods are thread-safe.
public final class NIOSSHDebug: @unchecked Sendable {
    public static let shared = NIOSSHDebug()

    private let lock = NIOLock()
    private var _increment: (@Sendable (String, Int64) -> Void)?
    private var _set: (@Sendable (String, Int64) -> Void)?
    private var _event: (@Sendable (String) -> Void)?
    private var _tsLog: (@Sendable (String) -> Void)?

    private init() {}

    /// Wire up handlers to receive metrics. Call once before SSH connections start.
    public func setHandlers(
        increment: @escaping @Sendable (String, Int64) -> Void,
        set: @escaping @Sendable (String, Int64) -> Void,
        event: @escaping @Sendable (String) -> Void,
        tsLog: @escaping @Sendable (String) -> Void
    ) {
        lock.lock()
        _increment = increment
        _set = set
        _event = event
        _tsLog = tsLog
        lock.unlock()
    }

    func increment(_ key: String, by value: Int64 = 1) {
        lock.lock()
        let handler = _increment
        lock.unlock()
        handler?(key, value)
    }

    func set(_ key: String, value: Int64) {
        lock.lock()
        let handler = _set
        lock.unlock()
        handler?(key, value)
    }

    func event(_ text: String) {
        lock.lock()
        let handler = _event
        lock.unlock()
        handler?(text)
    }

    /// Time-series log entry — written to file for export.
    func tsLog(_ text: String) {
        lock.lock()
        let handler = _tsLog
        lock.unlock()
        handler?(text)
    }

    /// Current time in microseconds for duration measurements.
    static func nowUs() -> Int64 {
        Int64(DispatchTime.now().uptimeNanoseconds / 1000)
    }
}
