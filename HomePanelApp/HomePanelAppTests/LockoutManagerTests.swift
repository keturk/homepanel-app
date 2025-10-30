import XCTest
@testable import HomePanelApp

// MARK: - Lockout Manager Tests

@MainActor
class LockoutManagerTests: XCTestCase {

    var lockoutManager: LockoutManager!

    override func setUp() async throws {
        try await super.setUp()
        // Create instance with unique keys for testing
        lockoutManager = LockoutManager(
            lockoutUntilKey: "test_lockout_until_\(UUID().uuidString)",
            consecutiveFailuresKey: "test_consecutive_failures_\(UUID().uuidString)",
            debugFeature: .alarm
        )
        lockoutManager.clearLockoutState()
    }

    override func tearDown() async throws {
        lockoutManager.clearLockoutState()
        lockoutManager = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        // When checking initial state
        let isLocked = lockoutManager.isLockedOut()

        // Then should not be locked out
        XCTAssertFalse(isLocked, "Should not be locked out initially")
        XCTAssertEqual(lockoutManager.consecutiveFailures, 0, "Should have 0 consecutive failures")
    }

    func testInitialRemainingTime() {
        // When checking initial remaining time
        let remainingTime = lockoutManager.getRemainingLockoutTime()

        // Then should be empty
        XCTAssertTrue(remainingTime.isEmpty, "Should have no remaining time initially")
    }

    // MARK: - Failed Attempt Tests

    func testRecordFailedAttempt() {
        // When recording a failed attempt
        lockoutManager.recordFailedAttempt()

        // Then consecutive failures should increase
        XCTAssertEqual(lockoutManager.consecutiveFailures, 1, "Should have 1 consecutive failure")
        XCTAssertFalse(lockoutManager.isLockedOut(), "Should not be locked out after 1 failure")
    }

    func testLockoutAfter7Attempts() {
        // When recording 7 failed attempts
        for _ in 1...7 {
            lockoutManager.recordFailedAttempt()
        }

        // Then should be locked out
        XCTAssertTrue(lockoutManager.isLockedOut(), "Should be locked out after 7 attempts")
        XCTAssertEqual(lockoutManager.consecutiveFailures, 7, "Should have 7 consecutive failures")
    }

    func testNoLockoutBefore7Attempts() {
        // When recording 6 failed attempts
        for _ in 1...6 {
            lockoutManager.recordFailedAttempt()
        }

        // Then should not be locked out
        XCTAssertFalse(lockoutManager.isLockedOut(), "Should not be locked out before 7 attempts")
        XCTAssertEqual(lockoutManager.consecutiveFailures, 6, "Should have 6 consecutive failures")
    }

    // MARK: - Successful Attempt Tests

    func testSuccessfulAttemptClearsCount() {
        // Given some failed attempts
        lockoutManager.recordFailedAttempt()
        lockoutManager.recordFailedAttempt()
        lockoutManager.recordFailedAttempt()

        // When recording successful attempt
        lockoutManager.recordSuccessfulAttempt()

        // Then should clear failures
        XCTAssertEqual(lockoutManager.consecutiveFailures, 0, "Should clear consecutive failures")
        XCTAssertFalse(lockoutManager.isLockedOut(), "Should not be locked out")
    }

    func testSuccessfulAttemptClearsLockout() {
        // Given locked out state
        for _ in 1...7 {
            lockoutManager.recordFailedAttempt()
        }
        XCTAssertTrue(lockoutManager.isLockedOut(), "Should be locked out")

        // When recording successful attempt
        lockoutManager.recordSuccessfulAttempt()

        // Then should clear lockout
        XCTAssertFalse(lockoutManager.isLockedOut(), "Should clear lockout")
        XCTAssertEqual(lockoutManager.consecutiveFailures, 0, "Should clear failures")
    }

    // MARK: - Remaining Time Tests

    func testRemainingTimeWhenLockedOut() {
        // Given locked out state
        for _ in 1...7 {
            lockoutManager.recordFailedAttempt()
        }

        // When getting remaining time
        let remainingTime = lockoutManager.getRemainingLockoutTime()

        // Then should have time remaining
        XCTAssertFalse(remainingTime.isEmpty, "Should have remaining time")
        XCTAssertTrue(remainingTime.contains("m") || remainingTime.contains("s"), "Should contain time units")
    }

    func testRemainingTimeWhenNotLockedOut() {
        // When not locked out
        let remainingTime = lockoutManager.getRemainingLockoutTime()

        // Then should be empty
        XCTAssertTrue(remainingTime.isEmpty, "Should have no remaining time")
    }

    // MARK: - Clear Lockout Tests

    func testClearLockoutState() {
        // Given locked out state
        for _ in 1...7 {
            lockoutManager.recordFailedAttempt()
        }
        XCTAssertTrue(lockoutManager.isLockedOut(), "Should be locked out")

        // When clearing lockout
        lockoutManager.clearLockoutState()

        // Then should clear everything
        XCTAssertFalse(lockoutManager.isLockedOut(), "Should not be locked out")
        XCTAssertEqual(lockoutManager.consecutiveFailures, 0, "Should clear failures")
    }

    // MARK: - Multiple Lockout Tests

    func testSecondLockoutAfter14Attempts() {
        // When recording 14 failed attempts
        for _ in 1...14 {
            lockoutManager.recordFailedAttempt()
        }

        // Then should be locked out
        XCTAssertTrue(lockoutManager.isLockedOut(), "Should be locked out after 14 attempts")
        XCTAssertEqual(lockoutManager.consecutiveFailures, 14, "Should have 14 consecutive failures")
    }

    func testThirdLockoutAfter21Attempts() {
        // When recording 21 failed attempts
        for _ in 1...21 {
            lockoutManager.recordFailedAttempt()
        }

        // Then should be locked out
        XCTAssertTrue(lockoutManager.isLockedOut(), "Should be locked out after 21 attempts")
        XCTAssertEqual(lockoutManager.consecutiveFailures, 21, "Should have 21 consecutive failures")
    }

    // MARK: - Persistence Tests

    func testLockoutStatePersists() {
        // Given locked out state
        let testKey1 = "test_persist_lockout_\(UUID().uuidString)"
        let testKey2 = "test_persist_failures_\(UUID().uuidString)"

        let manager1 = LockoutManager(
            lockoutUntilKey: testKey1,
            consecutiveFailuresKey: testKey2,
            debugFeature: .alarm
        )

        for _ in 1...7 {
            manager1.recordFailedAttempt()
        }
        XCTAssertTrue(manager1.isLockedOut(), "Should be locked out")

        // When creating new instance with same keys
        let manager2 = LockoutManager(
            lockoutUntilKey: testKey1,
            consecutiveFailuresKey: testKey2,
            debugFeature: .alarm
        )

        // Then should restore lockout state
        XCTAssertTrue(manager2.isLockedOut(), "Should restore locked out state")
        XCTAssertEqual(manager2.consecutiveFailures, 7, "Should restore failure count")

        // Cleanup
        manager1.clearLockoutState()
        manager2.clearLockoutState()
    }

    func testFailureCountPersists() {
        // Given some failures
        let testKey1 = "test_persist_lockout2_\(UUID().uuidString)"
        let testKey2 = "test_persist_failures2_\(UUID().uuidString)"

        let manager1 = LockoutManager(
            lockoutUntilKey: testKey1,
            consecutiveFailuresKey: testKey2,
            debugFeature: .alarm
        )

        for _ in 1...5 {
            manager1.recordFailedAttempt()
        }

        // When creating new instance
        let manager2 = LockoutManager(
            lockoutUntilKey: testKey1,
            consecutiveFailuresKey: testKey2,
            debugFeature: .alarm
        )

        // Then should restore count
        XCTAssertEqual(manager2.consecutiveFailures, 5, "Should restore failure count")

        // Cleanup
        manager1.clearLockoutState()
        manager2.clearLockoutState()
    }

    // MARK: - Reload Tests

    func testReloadLockoutState() {
        // Given locked out state
        for _ in 1...7 {
            lockoutManager.recordFailedAttempt()
        }

        // When clearing in memory (but not storage)
        lockoutManager.consecutiveFailures = 0
        lockoutManager.lockoutUntil = nil

        // Then reloading should restore state
        lockoutManager.reloadLockoutState()

        // Should restore the state from storage
        XCTAssertEqual(lockoutManager.consecutiveFailures, 7, "Should reload failure count")
    }

    // MARK: - Edge Cases

    func testManyFailedAttempts() {
        // When recording many failed attempts (multiple lockout cycles)
        for _ in 1...50 {
            lockoutManager.recordFailedAttempt()
        }

        // Then should still be locked out
        XCTAssertTrue(lockoutManager.isLockedOut(), "Should be locked out after 50 attempts")
        XCTAssertEqual(lockoutManager.consecutiveFailures, 50, "Should track all failures")
    }

    func testIsLockedOutMultipleCalls() {
        // Given locked out state
        for _ in 1...7 {
            lockoutManager.recordFailedAttempt()
        }

        // When checking lockout multiple times
        let result1 = lockoutManager.isLockedOut()
        let result2 = lockoutManager.isLockedOut()
        let result3 = lockoutManager.isLockedOut()

        // Then all should be true
        XCTAssertTrue(result1, "First check should be true")
        XCTAssertTrue(result2, "Second check should be true")
        XCTAssertTrue(result3, "Third check should be true")
    }
}
