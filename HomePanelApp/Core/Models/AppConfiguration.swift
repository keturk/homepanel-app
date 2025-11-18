import Foundation

// MARK: - Configuration Protocols

/// Protocol defining timing configuration for the application.
/// This protocol controls how frequently the app refreshes data from external services.
@MainActor
public protocol TimingConfiguration: Sendable {
    /// The interval between automatic data refreshes from external services.
    /// - Returns: A TimeInterval in seconds specifying the refresh frequency
    var refreshInterval: TimeInterval { get }
}

/// Protocol defining scene management configuration for Vera Hub integration.
/// This protocol manages the mapping between alarm modes and Vera Hub scene IDs.
@MainActor
public protocol SceneConfiguration: Sendable {
    /// A hub-scoped scene map containing scene mappings for multiple hubs.
    /// - Returns: A HubScopedSceneMap containing scene name to ID mappings per hub
    var hubScopedSceneMap: HubScopedSceneMap { get }
    
    /// Updates the scene mapping with new values.
    /// - Parameter newSceneMap: A HubScopedSceneMap containing the updated scene name to ID mappings
    func updateSceneMap(_ newSceneMap: HubScopedSceneMap)
}

/// Protocol defining device selection configuration for automation display.
/// This protocol manages which devices are displayed in the automation tab.
@MainActor
public protocol DeviceSelectionConfiguration: Sendable {
    /// An ordered array of device names that should be displayed in the automation tab.
    /// - Returns: An array of device names in the order they should appear (e.g., ["Living Room Light", "Kitchen Switch"])
    var selectedDeviceNames: [String] { get }
    
    /// Updates the selected device names.
    /// - Parameter newDeviceNames: An array containing the device names to display in order
    func updateSelectedDeviceNames(_ newDeviceNames: [String])
    
    /// Adds a device name to the selection.
    /// - Parameter deviceName: The name of the device to add
    func addSelectedDevice(_ deviceName: String)
    
    /// Removes a device name from the selection.
    /// - Parameter deviceName: The name of the device to remove
    func removeSelectedDevice(_ deviceName: String)
}

/// Protocol defining PIN management configuration for the application.
/// This protocol provides access to the PIN management service for authentication operations.
@MainActor
internal protocol PINConfiguration: Sendable {
    /// The PIN management service instance responsible for handling PIN operations.
    /// - Returns: A PINManagementService instance for managing user and master PINs
    var pinService: any PINManagementServiceProtocol { get }
}

/// Combined configuration protocol that includes all configuration aspects.
/// This protocol aggregates all individual configuration protocols into a single interface,
/// allowing services to depend on specific aspects they need while maintaining a unified configuration system.
@MainActor
internal protocol AppConfigurationProtocol: TimingConfiguration, SceneConfiguration, DeviceSelectionConfiguration, PINConfiguration {
    /// The ID of the primary hub used for alarm operations.
    /// - Returns: A string containing the hub ID, or nil if no primary hub is set
    var primaryHubId: String? { get }

    /// Default device ID for the alarm system in Vera Hub
    var alarmDeviceId: Int { get }

    // This protocol combines all the individual configuration protocols
    // Services can depend on specific aspects they need
}

// MARK: - App Configuration Model

/// Main application configuration class that manages all configuration aspects.
/// This class implements the AppConfigurationProtocol and provides centralized configuration management
/// for timing settings, scene mappings, and PIN management.
/// All settings are stored in iCloud Keychain to persist across app deletions.
@MainActor
internal class AppConfiguration: ObservableObject, AppConfigurationProtocol {
    // PIN Management Service
    internal let pinService: any PINManagementServiceProtocol
    
    // Keychain service for persistent storage
    private let keychainService = KeychainService.shared
    
    // Keychain keys
    private enum KeychainKeys {
        static let hubScopedSceneMap = "app_config_hubScopedSceneMap"
        static let selectedDeviceNames = "app_config_selectedDeviceNames"
        static let primaryHubId = "app_config_primaryHubId"
        static let migrationCompleted = "app_config_migration_completed"
    }
    
    @Published internal var hubScopedSceneMap: HubScopedSceneMap = HubScopedSceneMap() {
        didSet {
            // Store hub-scoped scene map in iCloud Keychain as JSON
            // Convert to a format that can be serialized: [hubId: [sceneName: sceneId]]
            var serializableMap: [String: [String: String]] = [:]
            for hubId in hubScopedSceneMap.getAllHubIds() {
                serializableMap[hubId] = hubScopedSceneMap.getScenes(forHub: hubId)
            }
            
            if let data = try? JSONSerialization.data(withJSONObject: serializableMap, options: []) {
                try? keychainService.storeData(key: KeychainKeys.hubScopedSceneMap, value: data, syncable: true)
            }
        }
    }
    
    @Published internal var selectedDeviceNames: [String] = [] {
        didSet {
            // Store selected device names in iCloud Keychain as JSON
            if let data = try? JSONSerialization.data(withJSONObject: selectedDeviceNames, options: []) {
                try? keychainService.storeData(key: KeychainKeys.selectedDeviceNames, value: data, syncable: true)
            }
        }
    }
    
    @Published internal var primaryHubId: String? {
        didSet {
            if let hubId = primaryHubId {
                // Store primary hub ID in iCloud Keychain
                if let data = hubId.data(using: .utf8) {
                    try? keychainService.storeData(key: KeychainKeys.primaryHubId, value: data, syncable: true)
                }
            } else {
                // Remove from keychain if nil
                try? keychainService.delete(key: KeychainKeys.primaryHubId)
            }
        }
    }
    
    // MARK: - Primary Hub Management
    
    /// Automatically selects a primary hub if none is set
    /// Priority: 1) Alarm hub, 2) First Vera hub, 3) First enabled hub, 4) First hub
    func autoSelectPrimaryHub(from availableHubs: [HubConfiguration]) {
        DebugLogger.log("🔍 [AppConfiguration] autoSelectPrimaryHub called. Current primaryHubId: \(primaryHubId ?? "nil"), Available hubs: \(availableHubs.count)", feature: .settings)
        for (i, hub) in availableHubs.enumerated() {
            DebugLogger.log("🔍 [AppConfiguration] Hub \(i): \(hub.name) (\(hub.hubId)) - isAlarmHub: \(hub.isAlarmHub), isEnabled: \(hub.isEnabled)", feature: .settings)
        }

        guard primaryHubId == nil else {
            DebugLogger.log("🔍 [AppConfiguration] Primary hub already set to: \(primaryHubId!)", feature: .settings)
            return
        }

        // Priority 1: Use alarm hub if set
        if let alarmHub = availableHubs.first(where: { $0.isAlarmHub }) {
            DebugLogger.log("✅ [AppConfiguration] Setting primary hub to alarm hub: \(alarmHub.name) (\(alarmHub.hubId))", feature: .settings)
            primaryHubId = alarmHub.hubId
            return
        }
        DebugLogger.log("⚠️ [AppConfiguration] No alarm hub found, trying Vera hub", feature: .settings)

        // Priority 2: First Vera hub
        if let veraHub = availableHubs.first(where: { $0.hubType == .vera && $0.isEnabled }) {
            DebugLogger.log("✅ [AppConfiguration] Setting primary hub to Vera hub: \(veraHub.name) (\(veraHub.hubId))", feature: .settings)
            primaryHubId = veraHub.hubId
            return
        }
        DebugLogger.log("⚠️ [AppConfiguration] No Vera hub found, trying first enabled hub", feature: .settings)

        // Priority 3: First enabled hub
        if let enabledHub = availableHubs.first(where: { $0.isEnabled }) {
            DebugLogger.log("✅ [AppConfiguration] Setting primary hub to first enabled hub: \(enabledHub.name) (\(enabledHub.hubId))", feature: .settings)
            primaryHubId = enabledHub.hubId
            return
        }
        DebugLogger.log("⚠️ [AppConfiguration] No enabled hub found, trying first hub", feature: .settings)

        // Priority 4: First hub (even if disabled)
        if let firstHub = availableHubs.first {
            DebugLogger.log("✅ [AppConfiguration] Setting primary hub to first hub: \(firstHub.name) (\(firstHub.hubId))", feature: .settings)
            primaryHubId = firstHub.hubId
        } else {
            DebugLogger.log("❌ [AppConfiguration] No hubs available", feature: .settings)
        }
    }
    
    /// Validates that the current primary hub is still available
    func validatePrimaryHub(with availableHubs: [HubConfiguration]) {
        guard let currentPrimaryId = primaryHubId else { return }
        
        // If current primary hub is no longer available, auto-select a new one
        if !availableHubs.contains(where: { $0.hubId == currentPrimaryId }) {
            primaryHubId = nil
            autoSelectPrimaryHub(from: availableHubs)
        }
    }
    
    /// Updates the scene mapping with new values.
    func updateSceneMap(_ newSceneMap: HubScopedSceneMap) {
        self.hubScopedSceneMap = newSceneMap
    }
    
    // MARK: - Constants
    
    /// Default device ID for the alarm system in Vera Hub
    internal static let defaultAlarmDeviceId = 7
    
    /// Default refresh interval for external service updates (in seconds)
    internal static let defaultRefreshInterval: TimeInterval = 30.0
    
    
    // Instance properties using constants
    internal let alarmDeviceId = AppConfiguration.defaultAlarmDeviceId
    internal let refreshInterval: TimeInterval = AppConfiguration.defaultRefreshInterval
    
    internal init(pinService: any PINManagementServiceProtocol) {
        self.pinService = pinService
        
        // Migrate from UserDefaults to Keychain if needed (one-time migration)
        migrateFromUserDefaultsIfNeeded()
        
        // Load hub-scoped scene map from iCloud Keychain
        if let data = try? keychainService.retrieveData(key: KeychainKeys.hubScopedSceneMap),
           let serializableMap = try? JSONSerialization.jsonObject(with: data) as? [String: [String: String]] {
            var loadedSceneMap = HubScopedSceneMap()
            for (hubId, scenes) in serializableMap {
                for (sceneName, hubScopedSceneId) in scenes {
                    // Extract original scene ID from hub-scoped ID
                    if let originalSceneId = HubScopedID.extractSceneID(from: hubScopedSceneId) {
                        loadedSceneMap.addScene(hubId: hubId, sceneName: sceneName, sceneId: originalSceneId)
                    }
                }
            }
            self.hubScopedSceneMap = loadedSceneMap
        }
        
        // Load selected device names from iCloud Keychain
        if let data = try? keychainService.retrieveData(key: KeychainKeys.selectedDeviceNames),
           let deviceNamesArray = try? JSONSerialization.jsonObject(with: data) as? [String] {
            self.selectedDeviceNames = deviceNamesArray
        }
        
        // Load primary hub ID from iCloud Keychain
        if let data = try? keychainService.retrieveData(key: KeychainKeys.primaryHubId),
           let hubId = String(data: data, encoding: .utf8) {
            self.primaryHubId = hubId
        }
    }
    
    // MARK: - Migration from UserDefaults
    
    /// Migrates settings from UserDefaults to iCloud Keychain (one-time migration)
    private func migrateFromUserDefaultsIfNeeded() {
        // Check if migration has already been completed
        do {
            _ = try keychainService.retrieveData(key: KeychainKeys.migrationCompleted)
            // Migration already completed, skip
            return
        } catch {
            // Migration not completed, proceed
        }
        
        DebugLogger.log("🔄 [AppConfiguration] Starting migration from UserDefaults to iCloud Keychain", feature: .settings)
        
        // Migrate hub-scoped scene map
        if let jsonString = UserDefaults.standard.string(forKey: "hubScopedSceneMap"),
           let data = jsonString.data(using: .utf8) {
            try? keychainService.storeData(key: KeychainKeys.hubScopedSceneMap, value: data, syncable: true)
            DebugLogger.log("✅ [AppConfiguration] Migrated hubScopedSceneMap to Keychain", feature: .settings)
        }
        
        // Migrate selected device names
        if let jsonString = UserDefaults.standard.string(forKey: "selectedDeviceNames"),
           let data = jsonString.data(using: .utf8) {
            try? keychainService.storeData(key: KeychainKeys.selectedDeviceNames, value: data, syncable: true)
            DebugLogger.log("✅ [AppConfiguration] Migrated selectedDeviceNames to Keychain", feature: .settings)
        }
        
        // Migrate primary hub ID
        if let hubId = UserDefaults.standard.string(forKey: "primaryHubId"),
           let data = hubId.data(using: .utf8) {
            try? keychainService.storeData(key: KeychainKeys.primaryHubId, value: data, syncable: true)
            DebugLogger.log("✅ [AppConfiguration] Migrated primaryHubId to Keychain", feature: .settings)
        }
        
        // Mark migration as completed
        if let migrationData = "migrated".data(using: .utf8) {
            try? keychainService.storeData(key: KeychainKeys.migrationCompleted, value: migrationData, syncable: true)
            DebugLogger.log("✅ [AppConfiguration] Migration completed", feature: .settings)
        }
    }
    
    // MARK: - Validation Methods
    
    /// Validates whether the provided string is a valid IPv4 address.
    /// - Parameter ip: The IP address string to validate
    /// - Returns: True if the string is a valid IPv4 address, false otherwise
    internal func isValidIPAddress(_ ip: String) -> Bool {
        return IPValidator.isValidIPv4(ip)
    }
    
    /// Validates whether the provided string is a valid 6-digit PIN.
    /// - Parameter pin: The PIN string to validate
    /// - Returns: True if the string is exactly 6 digits, false otherwise
    internal func isValidPIN(_ pin: String) -> Bool {
        return pin.count == 6 && pin.allSatisfy { $0.isNumber }
    }
    
    // MARK: - Configuration Management
    
    /// Updates the scene mapping with new values and persists the changes.
    /// - Parameter newSceneMap: A dictionary containing the updated scene name to ID mappings
    
    /// Updates the selected device names and persists the changes.
    /// - Parameter newDeviceNames: An array containing the device names to display in order
    internal func updateSelectedDeviceNames(_ newDeviceNames: [String]) {
        selectedDeviceNames = newDeviceNames
    }
    
    /// Adds a device name to the selection and persists the changes.
    /// - Parameter deviceName: The name of the device to add
    internal func addSelectedDevice(_ deviceName: String) {
        if !selectedDeviceNames.contains(deviceName) {
            selectedDeviceNames.append(deviceName)
        }
    }
    
    /// Removes a device name from the selection and persists the changes.
    /// - Parameter deviceName: The name of the device to remove
    internal func removeSelectedDevice(_ deviceName: String) {
        selectedDeviceNames.removeAll { $0 == deviceName }
    }
    
    /// Resets the configuration to default values.
    /// Note: Hub configurations are now managed by HubConfigurationStore
    internal func resetToDefaults() {
        // Clear scene maps and device selections
        hubScopedSceneMap = HubScopedSceneMap()
        selectedDeviceNames = []
        primaryHubId = nil
    }
    
    /// Exports the current configuration as a dictionary for backup or debugging purposes.
    /// - Returns: A dictionary containing the current configuration values
    internal func exportConfiguration() -> [String: Any] {
        return [
            "alarmDeviceId": alarmDeviceId,
            "refreshInterval": refreshInterval,
            "primaryHubId": primaryHubId as Any,
            "selectedDeviceNames": selectedDeviceNames
        ]
    }
}
