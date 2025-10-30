import Foundation

// MARK: - Camera Configuration Service Protocol

protocol CameraConfigServiceProtocol {
    func getConfiguration(for cameraId: String) -> CameraConfig?
    func getAllCameras() -> [CameraConfig]
    func saveConfiguration(_ config: CameraConfig) throws
    func deleteConfiguration(for cameraId: String) throws

    func savePassword(for cameraId: String, password: String) throws
    func getPassword(for cameraId: String) -> String?
    func deletePassword(for cameraId: String) throws
}

// MARK: - Camera Configuration Service

class CameraConfigService: ObservableObject, CameraConfigServiceProtocol {
    @Published private(set) var cameras: [CameraConfig] = []
    
    private let userDefaults: UserDefaults
    private let keychainService: KeychainServiceProtocol

    // Keychain keys for camera configurations (synced via iCloud)
    private let irisOneConfigKey = "camera_config_iris_one"
    private let irisTwoConfigKey = "camera_config_iris_two"

    init(userDefaults: UserDefaults = .standard,
         keychainService: KeychainServiceProtocol) {
        self.userDefaults = userDefaults
        self.keychainService = keychainService
        refreshCameras()
    }
    
    /// Creates a default camera configuration for a given camera ID
    static func createDefaultConfig(for cameraId: String) -> CameraConfig {
        let name = cameraId == "camera1" ? "Camera 1" : "Camera 2"
        
        return CameraConfig(
            id: cameraId,
            name: name,
            vmsType: .blueIris,
            ipAddress: "",
            port: 2671,  // Blue Iris default port
            username: "",
            path: "/ui3.htm",  // Blue Iris UI3 interface
            lastUpdated: Date()
        )
    }
    
    // MARK: - Configuration Management
    
    func getConfiguration(for cameraId: String) -> CameraConfig? {
        let key = configKey(for: cameraId)

        do {
            let data = try keychainService.retrieveData(key: key)
            let decoder = JSONDecoder()
            let config = try decoder.decode(CameraConfig.self, from: data)
            DebugLogger.log("🔍 [CameraConfigService] Found configuration for \(cameraId): isConfigured=\(config.isConfigured), ipAddress=\(config.ipAddress)", feature: .camera)
            return config
        } catch {
            // Not found
            DebugLogger.log("🔍 [CameraConfigService] No configuration found for \(cameraId)", feature: .camera)
            return nil
        }
    }

    func getAllCameras() -> [CameraConfig] {
        return cameras
    }
    
    private func refreshCameras() {
        var allCameras: [CameraConfig] = []

        // Get iris_one configuration
        if let irisOne = getConfiguration(for: "iris_one") {
            allCameras.append(irisOne)
        }

        // Get iris_two configuration
        if let irisTwo = getConfiguration(for: "iris_two") {
            allCameras.append(irisTwo)
        }

        cameras = allCameras
    }
    
    func saveConfiguration(_ config: CameraConfig) throws {
        let key = configKey(for: config.id)
        let data = try JSONEncoder().encode(config)
        try keychainService.storeData(key: key, value: data, syncable: true)  // Sync camera configs via iCloud
        refreshCameras()
    }

    func deleteConfiguration(for cameraId: String) throws {
        let key = configKey(for: cameraId)
        DebugLogger.log("🔍 [CameraConfigService] Deleting configuration for \(cameraId), key: \(key)", feature: .camera)
        try keychainService.delete(key: key)
        try deletePassword(for: cameraId)
        refreshCameras()
        DebugLogger.log("🔍 [CameraConfigService] Configuration deleted for \(cameraId), cameras count: \(cameras.count)", feature: .camera)
    }
    
    // MARK: - Password Management (Keychain)
    
    func savePassword(for cameraId: String, password: String) throws {
        try keychainService.saveCameraPassword(for: cameraId, password: password)
    }
    
    func getPassword(for cameraId: String) -> String? {
        return keychainService.getCameraPassword(for: cameraId)
    }
    
    func deletePassword(for cameraId: String) throws {
        try keychainService.deleteCameraPassword(for: cameraId)
    }
    
    // MARK: - Private Helpers

    private func configKey(for cameraId: String) -> String {
        cameraId == "iris_one" ? irisOneConfigKey : irisTwoConfigKey
    }
}
