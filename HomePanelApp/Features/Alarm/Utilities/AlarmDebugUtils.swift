import Foundation

// MARK: - Alarm Debug Utilities

struct AlarmDebugUtils {

    // MARK: - Debug Methods

    @MainActor
    static func printConfiguration(config: AppConfigurationProtocol) {
        DebugLogger.log("AlarmViewModel initialized with:", feature: .alarm)
        DebugLogger.log("  - Primary Hub ID: \(config.primaryHubId ?? "None")", feature: .alarm)
        DebugLogger.log("  - Alarm Device ID: \(config.alarmDeviceId)", feature: .alarm)
        DebugLogger.log("  - PIN Management: Available", feature: .alarm)
        DebugLogger.log("  - Refresh Interval: \(config.refreshInterval)s", feature: .alarm)
        DebugLogger.log("  - Hub-Scoped Scene Map: \(config.hubScopedSceneMap)", feature: .alarm)
    }

    static func printModeChangeAttempt(mode: AlarmMode, sceneMap: [String: String]) {
        DebugLogger.log("performModeChange called with mode: \(mode.rawValue)", feature: .alarm)
        DebugLogger.log("Calling service.setAlarmMode(\(mode.rawValue)) with scene map: \(sceneMap)", feature: .alarm)
    }

    static func printModeChangeSuccess(mode: AlarmMode) {
        DebugLogger.success("service.setAlarmMode completed successfully", feature: .alarm)
        DebugLogger.log("Mode change to \(mode.rawValue) completed", feature: .alarm)
    }

    static func printModeChangeError(mode: AlarmMode, error: Error) {
        DebugLogger.error("Mode change to \(mode.rawValue) failed: \(error.localizedDescription)", feature: .alarm)
    }

    static func printRefreshAttempt() {
        DebugLogger.log("Starting refresh...", feature: .alarm)
    }

    static func printRefreshSuccess() {
        DebugLogger.success("Refresh completed successfully", feature: .alarm)
    }

    static func printRefreshError(error: Error) {
        DebugLogger.error("Refresh failed: \(error.localizedDescription)", feature: .alarm)
    }

    static func printPINVerificationResult(success: Bool, mode: AlarmMode) {
        if success {
            DebugLogger.success("PIN verification successful for mode: \(mode.rawValue)", feature: .alarm)
        } else {
            DebugLogger.error("PIN verification failed for mode: \(mode.rawValue)", feature: .alarm)
        }
    }

    static func printLockoutStatus(isLockedOut: Bool, remainingTime: String) {
        if isLockedOut {
            DebugLogger.lockout("Alarm PIN is locked out. Remaining time: \(remainingTime)", feature: .alarm)
        } else {
            DebugLogger.log("Alarm PIN is not locked out", feature: .alarm)
        }
    }

    static func printStateChange(from oldState: AlarmState, to newState: AlarmState) {
        DebugLogger.stateChange("State changed from \(oldState.rawValue) to \(newState.rawValue)", feature: .alarm)
    }

    static func printErrorState(error: String) {
        DebugLogger.error("Error state: \(error)", feature: .alarm)
    }

    static func printTimerStatus(isActive: Bool, interval: TimeInterval) {
        if isActive {
            DebugLogger.timer("Auto-refresh timer started with \(interval)s interval", feature: .alarm)
        } else {
            DebugLogger.timer("Auto-refresh timer stopped", feature: .alarm)
        }
    }

    static func printSceneMapStatus(sceneMap: [String: String]) {
        if sceneMap.isEmpty {
            DebugLogger.warning("Scene map is empty - alarm mode changes will fail", feature: .alarm)
        } else {
            DebugLogger.success("Scene map loaded with \(sceneMap.count) scenes", feature: .alarm)
        }
    }
}
