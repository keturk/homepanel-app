import Foundation
import UniformTypeIdentifiers

// MARK: - Backup Data Structure

/// Complete backup of all app settings
struct SettingsBackup: Codable {
    let version: String
    let exportDate: Date
    let hubConfigurations: [HubConfiguration]
    let cameraConfigurations: [CameraConfig]
    let cameraPasswords: [String: String] // cameraId -> password
    let masterPINData: MasterPINData?
    let userPINs: [PINData]
    let sceneMappings: [String: [String: String]] // hubId -> [sceneName: sceneId]
    let selectedDeviceNames: [String]
    let primaryHubId: String?
    let favoriteDestinations: [FavoriteDestination]
    
    static let currentVersion = "1.0"
}

// MARK: - Settings Backup Service

@MainActor
class SettingsBackupService: ObservableObject {
    @Published var isExporting = false
    @Published var isImporting = false
    @Published var lastError: Error?
    
    private let keychainService = KeychainService.shared
    
    // MARK: - Export
    
    /// Exports all settings to a JSON file
    func exportAllSettings(
        hubConfigStore: HubConfigurationStore,
        cameraConfigService: CameraConfigService,
        pinService: PINManagementService,
        appConfig: AppConfiguration,
        destinationStore: DestinationStore
    ) async throws -> URL {
        isExporting = true
        defer { isExporting = false }
        
        // Collect all data
        let hubConfigs = hubConfigStore.getAllHubs()
        
        // Get all camera configs
        let allCameras = cameraConfigService.getAllCameras()
        
        // Get camera passwords
        var cameraPasswords: [String: String] = [:]
        for camera in allCameras {
            if let password = keychainService.getCameraPassword(for: camera.id) {
                cameraPasswords[camera.id] = password
            }
        }
        
        // Get PIN data
        let masterPINData = pinService.masterPINData
        let userPINs = pinService.getAllPINs()
        
        // Get scene mappings
        var sceneMappings: [String: [String: String]] = [:]
        for hubId in appConfig.hubScopedSceneMap.getAllHubIds() {
            sceneMappings[hubId] = appConfig.hubScopedSceneMap.getScenes(forHub: hubId)
        }
        
        // Get selected device names
        let selectedDeviceNames = appConfig.selectedDeviceNames
        
        // Get primary hub ID
        let primaryHubId = appConfig.primaryHubId
        
        // Get favorite destinations
        let destinations = destinationStore.destinations
        
        // Create backup structure
        let backup = SettingsBackup(
            version: SettingsBackup.currentVersion,
            exportDate: Date(),
            hubConfigurations: hubConfigs,
            cameraConfigurations: allCameras,
            cameraPasswords: cameraPasswords,
            masterPINData: masterPINData,
            userPINs: userPINs,
            sceneMappings: sceneMappings,
            selectedDeviceNames: selectedDeviceNames,
            primaryHubId: primaryHubId,
            favoriteDestinations: destinations
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(backup)
        
        // Save to temporary file
        let fileName = "HomePanel_Backup_\(dateFormatter.string(from: Date())).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try jsonData.write(to: tempURL)
        
        DebugLogger.log("✅ [SettingsBackupService] Exported settings to \(fileName)", feature: .settings)
        
        return tempURL
    }
    
    // MARK: - Import
    
    /// Imports settings from a JSON backup file
    func importSettings(
        from url: URL,
        hubConfigStore: HubConfigurationStore,
        cameraConfigService: CameraConfigService,
        pinService: PINManagementService,
        appConfig: AppConfiguration,
        destinationStore: DestinationStore
    ) async throws {
        isImporting = true
        defer { isImporting = false }
        
        // Read and decode backup
        let jsonData = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let backup = try decoder.decode(SettingsBackup.self, from: jsonData)
        
        DebugLogger.log("📥 [SettingsBackupService] Importing backup version \(backup.version) from \(backup.exportDate)", feature: .settings)
        
        // Import hub configurations
        for hubConfig in backup.hubConfigurations {
            do {
                // Check if hub already exists
                if hubConfigStore.getHub(hubId: hubConfig.hubId) == nil {
                    try await hubConfigStore.addHub(hubConfig)
                } else {
                    try await hubConfigStore.updateHub(hubConfig)
                }
            } catch {
                DebugLogger.log("⚠️ [SettingsBackupService] Failed to import hub \(hubConfig.name): \(error)", feature: .settings)
                // Continue with other imports
            }
        }
        
        // Import camera configurations
        for cameraConfig in backup.cameraConfigurations {
            do {
                try cameraConfigService.saveConfiguration(cameraConfig)
                
                // Import camera password if available
                if let password = backup.cameraPasswords[cameraConfig.id] {
                    try keychainService.saveCameraPassword(for: cameraConfig.id, password: password)
                }
            } catch {
                DebugLogger.log("⚠️ [SettingsBackupService] Failed to import camera \(cameraConfig.name): \(error)", feature: .settings)
            }
        }
        
        // Import PIN data
        // Note: We restore the hash and salt, so the same PIN will work
        if let masterPIN = backup.masterPINData {
            do {
                // Save master PIN data directly to keychain
                let masterPINKey = "master_pin_data"
                let encoder = JSONEncoder()
                let data = try encoder.encode(masterPIN)
                try keychainService.storeData(key: masterPINKey, value: data, syncable: true)
                DebugLogger.log("✅ [SettingsBackupService] Restored master PIN data", feature: .settings)
            } catch {
                DebugLogger.log("⚠️ [SettingsBackupService] Failed to restore master PIN: \(error)", feature: .settings)
            }
        }
        
        // Import user PINs
        do {
            let userPINsKey = "user_pins"
            let encoder = JSONEncoder()
            let data = try encoder.encode(backup.userPINs)
            try keychainService.storeData(key: userPINsKey, value: data, syncable: true)
            DebugLogger.log("✅ [SettingsBackupService] Restored \(backup.userPINs.count) user PINs", feature: .settings)
        } catch {
            DebugLogger.log("⚠️ [SettingsBackupService] Failed to restore user PINs: \(error)", feature: .settings)
        }
        
        // Import scene mappings
        var restoredSceneMap = HubScopedSceneMap()
        for (hubId, scenes) in backup.sceneMappings {
            for (sceneName, hubScopedSceneId) in scenes {
                if let originalSceneId = HubScopedID.extractSceneID(from: hubScopedSceneId) {
                    restoredSceneMap.addScene(hubId: hubId, sceneName: sceneName, sceneId: originalSceneId)
                }
            }
        }
        appConfig.updateSceneMap(restoredSceneMap)
        
        // Import selected device names
        appConfig.updateSelectedDeviceNames(backup.selectedDeviceNames)
        
        // Import primary hub ID
        if let primaryHubId = backup.primaryHubId {
            // Only set if the hub still exists
            if hubConfigStore.getHub(hubId: primaryHubId) != nil {
                // We need to set this through AppConfiguration's internal mechanism
                // Since primaryHubId is @Published, we can set it directly
                appConfig.primaryHubId = primaryHubId
            }
        }
        
        // Import favorite destinations
        do {
            try await destinationStore.saveDestinations(backup.favoriteDestinations)
        } catch {
            DebugLogger.log("⚠️ [SettingsBackupService] Failed to import destinations: \(error)", feature: .settings)
        }
        
        DebugLogger.log("✅ [SettingsBackupService] Import completed", feature: .settings)
    }
    
    // MARK: - Helpers
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}

