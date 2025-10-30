import Foundation

// MARK: - Async Utilities

// Note: TimeoutError is defined in HomePanelApp/Core/Errors/AppErrors.swift
// This is the centralized timeout implementation used throughout the app.
// All services should use this global withTimeout() function.

/// Execute an async operation with a timeout
/// - Parameters:
///   - seconds: Maximum time to wait for the operation to complete
///   - operation: The async operation to execute
/// - Returns: The result of the operation if it completes before the timeout
/// - Throws: TimeoutError if the operation doesn't complete in time, or the operation's error
func withTimeout<T: Sendable>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: TimeoutResult<T>.self) { group in
        // Add the actual operation
        group.addTask {
            do {
                let result = try await operation()
                return .completed(result)
            } catch {
                return .failed(error)
            }
        }

        // Add the timeout task
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            return .timedOut
        }

        // Wait for the first result
        guard let firstResult = try await group.next() else {
            throw TimeoutError()
        }

        // Cancel remaining tasks (this won't affect the completed operation)
        group.cancelAll()

        // Process the result
        switch firstResult {
        case .completed(let value):
            return value
        case .failed(let error):
            throw error
        case .timedOut:
            throw TimeoutError()
        }
    }
}

/// Internal result type for timeout wrapper
private enum TimeoutResult<T: Sendable>: Sendable {
    case completed(T)
    case failed(Error)
    case timedOut
}
