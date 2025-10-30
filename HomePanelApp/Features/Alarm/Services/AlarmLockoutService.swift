import Foundation
import Combine

// MARK: - Alarm Lockout Service

@MainActor
class AlarmLockoutService: ObservableObject {
    // Delegate lockout management to the shared LockoutManager
    private let lockoutManager: LockoutManager
    
    private let keychain = KeychainService.shared
    private let eventPublisher = LockoutEventPublisher.shared
    
    init() {
        self.lockoutManager = LockoutManager(
            lockoutUntilKey: "alarm_lockout_until",
            consecutiveFailuresKey: "alarm_consecutive_failures",
            debugFeature: .alarm
        )
        
        // LockoutManager properties are already @Published, so UI will update automatically
    }
    
    
    // MARK: - Public Methods
    
    func isLockedOut() -> Bool {
        return lockoutManager.isLockedOut()
    }
    
    func recordFailedAttempt() {
        lockoutManager.recordFailedAttempt()
    }
    
    func recordSuccessfulAttempt() {
        lockoutManager.recordSuccessfulAttempt()
    }
    
    // Method to clear all lockout state (for resetting from old version)
    func clearLockoutState() {
        lockoutManager.clearLockoutState()
    }
    
    // Method to reload lockout state from storage (useful after external reset)
    func reloadLockoutState() {
        lockoutManager.reloadLockoutState()
    }
    
    // Method to reset all lockouts (Master PIN and Alarm PIN)
    func resetAllLockouts(pinService: any PINManagementServiceProtocol) {
        // Reset Master PIN lockouts
        pinService.clearLockoutState()
        
        // Reset Alarm PIN lockouts by clearing the specific keys used by AlarmViewModel
        let alarmLockoutKeys = [
            "alarm_lockout_until",
            "alarm_consecutive_failures"
        ]
        
        // Clear UserDefaults
        for key in alarmLockoutKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        
        // Publish lockouts reset event using the new publisher
        eventPublisher.publishLockoutsReset()
        
        DebugLogger.log("All lockouts reset successfully", feature: .alarm)
        DebugLogger.log("Cleared Master PIN lockouts via pinService.clearLockoutState()", feature: .alarm)
        DebugLogger.log("Cleared Alarm PIN lockouts via UserDefaults", feature: .alarm)
        DebugLogger.log("Published lockoutsReset event", feature: .alarm)
    }
    
    func getRemainingLockoutTime() -> String {
        return lockoutManager.getRemainingLockoutTime()
    }
    
    // Expose lockout state for UI display
    func getConsecutiveFailures() -> Int {
        return lockoutManager.consecutiveFailures
    }
    
}
