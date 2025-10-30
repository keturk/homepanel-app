import Foundation
import Combine

// MARK: - Alarm Service Protocol

/// Protocol for Vera Hub alarm operations
@MainActor
public protocol VeraHubAlarmServiceProtocol: Sendable {
    /// Fetches the current alarm state from the alarm device
    func fetchAlarmState() async throws -> AlarmState

    /// Subscribes to real-time alarm state changes
    /// - Returns: A publisher that emits AlarmState whenever the alarm device state changes
    func subscribeToStateChanges() -> AnyPublisher<AlarmState, Never>
}

// MARK: - Unified Alarm Service

/// Modern alarm service that uses the unified device state management system
/// instead of making separate API calls. This eliminates duplicate logic and
/// ensures alarm state is always in sync with the polling service.
@MainActor
class UnifiedAlarmService: @unchecked Sendable, VeraHubAlarmServiceProtocol {
    private let hubService: HubServiceProtocol
    private let config: AppConfigurationProtocol

    init(hubService: HubServiceProtocol, config: AppConfigurationProtocol) {
        self.hubService = hubService
        self.config = config
    }

    func fetchAlarmState() async throws -> AlarmState {
        // Check if primary hub is configured
        guard let primaryHubId = config.primaryHubId else {
            DebugLogger.error("No primary hub configured", feature: .alarm)
            throw HubError.invalidConfiguration
        }

        // Build hub-scoped device ID for the alarm device
        // Example: alarmDeviceId=7 + primaryHubId="vera-alarm" -> "hub_vera-alarm_device_7"
        let alarmDeviceIdString = String(config.alarmDeviceId)
        let hubScopedDeviceId = HubScopedID.deviceID(hubId: primaryHubId, deviceId: alarmDeviceIdString)

        DebugLogger.log("Fetching alarm state for device: \(hubScopedDeviceId)", feature: .alarm)

        // Get all devices from the unified cache
        let allDevices = await hubService.getAllDevices()

        // Find the alarm device
        guard let alarmDevice = allDevices.first(where: { $0.id == hubScopedDeviceId }) else {
            DebugLogger.error("Alarm device not found: \(hubScopedDeviceId)", feature: .alarm)
            DebugLogger.log("Available devices: \(allDevices.filter { $0.hubId == primaryHubId }.map { $0.id })", feature: .alarm)
            throw HubError.deviceNotFound("Alarm device \(config.alarmDeviceId)")
        }

        DebugLogger.success("Found alarm device: \(alarmDevice.name) (ID: \(alarmDevice.id))", feature: .alarm)

        // Parse alarm state from the device
        return try parseAlarmState(from: alarmDevice)
    }

    /// Subscribe to alarm device state changes for real-time updates
    func subscribeToStateChanges() -> AnyPublisher<AlarmState, Never> {
        guard let primaryHubId = config.primaryHubId else {
            return Empty<AlarmState, Never>().eraseToAnyPublisher()
        }

        let alarmDeviceIdString = String(config.alarmDeviceId)
        let hubScopedDeviceId = HubScopedID.deviceID(hubId: primaryHubId, deviceId: alarmDeviceIdString)

        DebugLogger.log("Setting up alarm state subscription for device: \(hubScopedDeviceId)", feature: .alarm)

        // Return a publisher that doesn't capture self - all parsing is done inline
        return hubService.stateChangePublisher
            .receive(on: DispatchQueue.main)  // Ensure we're on main thread for the closure
            .compactMap { event -> AlarmState? in
                // Only process events for our alarm device
                guard event.device.id == hubScopedDeviceId else {
                    return nil
                }

                DebugLogger.log("Received alarm device state change event (status: \(event.device.state.status ?? -1))", feature: .alarm)

                // Parse alarm state from the device using static parsing logic
                guard let statusValue = event.device.state.status else {
                    DebugLogger.warning("Alarm device has no status value", feature: .alarm)
                    return nil
                }


                let alarmState: AlarmState
                switch statusValue {
                case 0: alarmState = .disarmed
                case 1: alarmState = .armedAway
                case 2: alarmState = .armedStay
                case 3: alarmState = .armedNightStay
                default:
                    DebugLogger.warning("Unknown status value: \(statusValue)", feature: .alarm)
                    return nil
                }

                DebugLogger.log("Alarm state changed via real-time event: \(alarmState) (status=\(statusValue))", feature: .alarm)
                return alarmState
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    /// Parse alarm state from a Device object
    /// Uses the same logic as VeraHubAlarmStateParser but operates on the cached Device
    private func parseAlarmState(from device: Device) throws -> AlarmState {
        // The alarm device state is stored in device.state.status
        // Status values for Vera alarm panels:
        // - 0 = Disarmed
        // - 1 = Armed Away
        // - 2 = Armed Stay
        // - 3 = Armed Night/Stay

        guard let statusValue = device.state.status else {
            DebugLogger.warning("Alarm device has no status value, defaulting to Unknown", feature: .alarm)
            return .unknown
        }


        let alarmState: AlarmState
        switch statusValue {
        case 0:
            alarmState = .disarmed
        case 1:
            alarmState = .armedAway
        case 2:
            alarmState = .armedStay
        case 3:
            alarmState = .armedNightStay
        default:
            DebugLogger.warning("Unknown alarm status value: \(statusValue)", feature: .alarm)
            alarmState = .unknown
        }

        DebugLogger.log("Parsed alarm state: \(alarmState) (status=\(statusValue))", feature: .alarm)
        return alarmState
    }
}

// MARK: - Helper Notes

// AlarmViewModel can optionally subscribe to real-time updates using:
// UnifiedAlarmService.subscribeToStateChanges()
//
// This provides instant alarm state updates instead of timer-based polling
