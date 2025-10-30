import Foundation

// MARK: - Hub Configuration Store

@MainActor
class HubConfigurationStore: ObservableObject {
    @Published var configurations: [HubConfiguration] = []
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?

    private let keychainService = KeychainService.shared
    private let key = "hub_configurations"  // iCloud Keychain key

    init() {
        loadConfigurations()
    }
    
    // MARK: - Public Interface
    
    func addHub(_ configuration: HubConfiguration) async throws {
        DebugLogger.log("🔍 [HubConfigurationStore] addHub called with: \(configuration.name) (\(configuration.hubId))", feature: .settings)
        
        // Check if hub already exists
        if configurations.contains(where: { $0.hubId == configuration.hubId }) {
            DebugLogger.log("🔍 [HubConfigurationStore] Hub already exists: \(configuration.hubId)", feature: .settings)
            throw HubError.hubAlreadyExists(configuration.hubId)
        }
        
        configurations.append(configuration)
        DebugLogger.log("🔍 [HubConfigurationStore] Added hub to configurations. Total count: \(configurations.count)", feature: .settings)
        try await saveConfigurations()
        DebugLogger.log("🔍 [HubConfigurationStore] Saved configurations to UserDefaults", feature: .settings)
    }
    
    func updateHub(_ configuration: HubConfiguration) async throws {
        guard let index = configurations.firstIndex(where: { $0.hubId == configuration.hubId }) else {
            throw HubError.hubNotFound(configuration.hubId)
        }
        
        configurations[index] = configuration
        try await saveConfigurations()
    }
    
    func removeHub(hubId: String) async throws {
        guard let index = configurations.firstIndex(where: { $0.hubId == hubId }) else {
            throw HubError.hubNotFound(hubId)
        }
        
        configurations.remove(at: index)
        try await saveConfigurations()
    }
    
    func getHub(hubId: String) -> HubConfiguration? {
        return configurations.first(where: { $0.hubId == hubId })
    }
    
    func getAllHubs() -> [HubConfiguration] {
        return configurations
    }
    
    func getEnabledHubs() -> [HubConfiguration] {
        return configurations.filter { $0.isEnabled }
    }
    
    func getAlarmHub() -> HubConfiguration? {
        return configurations.first(where: { $0.isAlarmHub })
    }
    
    func setAlarmHub(hubId: String) async throws {
        // First, unset any existing alarm hub
        for i in 0..<configurations.count {
            configurations[i].isAlarmHub = false
        }
        
        // Then set the new alarm hub
        guard let index = configurations.firstIndex(where: { $0.hubId == hubId }) else {
            throw HubError.hubNotFound(hubId)
        }
        
        configurations[index].isAlarmHub = true
        try await saveConfigurations()
    }
    
    func unsetAlarmHub() async throws {
        for i in 0..<configurations.count {
            configurations[i].isAlarmHub = false
        }
        try await saveConfigurations()
    }
    
    func toggleHubEnabled(hubId: String) async throws {
        guard let index = configurations.firstIndex(where: { $0.hubId == hubId }) else {
            throw HubError.hubNotFound(hubId)
        }
        
        configurations[index].isEnabled.toggle()
        try await saveConfigurations()
    }
    
    func clearAllConfigurations() async throws {
        DebugLogger.log("🔍 [HubConfigurationStore] Clearing all hub configurations", feature: .settings)
        configurations = []
        try await saveConfigurations()
        DebugLogger.log("🔍 [HubConfigurationStore] All configurations cleared", feature: .settings)
    }
    
    func debugPrintStoredConfigurations() {
        DebugLogger.log("🔍 [HubConfigurationStore] Debug: Current stored configurations:", feature: .settings)
        for (index, config) in configurations.enumerated() {
            DebugLogger.log("🔍 [HubConfigurationStore] Stored Config \(index): \(config.name) (\(config.hubId)) - enabled: \(config.isEnabled)", feature: .settings)
        }
    }
    
    
    // MARK: - Private Methods

    private func loadConfigurations() {
        do {
            let data = try keychainService.retrieveData(key: key)
            let configs = try JSONDecoder().decode([HubConfiguration].self, from: data)

            DebugLogger.log("🔍 [HubConfigurationStore] Loaded \(configs.count) configurations from iCloud Keychain", feature: .settings)
            for (index, config) in configs.enumerated() {
                DebugLogger.log("🔍 [HubConfigurationStore] Config \(index): \(config.name) (\(config.hubId)) - enabled: \(config.isEnabled)", feature: .settings)
            }

            configurations = configs
        } catch {
            DebugLogger.log("🔍 [HubConfigurationStore] No stored configurations found, starting with empty array", feature: .settings)
            configurations = []
        }
    }

    private func saveConfigurations() async throws {
        let data = try JSONEncoder().encode(configurations)
        try keychainService.storeData(key: key, value: data, syncable: true)  // Sync hub configs via iCloud
        lastSyncDate = Date()
        DebugLogger.log("🔍 [HubConfigurationStore] Saved \(configurations.count) configurations to iCloud Keychain", feature: .settings)
    }

}
