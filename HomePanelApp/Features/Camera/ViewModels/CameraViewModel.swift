import Foundation
import SwiftUI

// MARK: - Notification Names

extension Notification.Name {
    static let cameraConfigurationChanged = Notification.Name("cameraConfigurationChanged")
}

// MARK: - Camera ViewModel

@MainActor
class CameraViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var config: CameraConfig
    @Published var isConfigured: Bool = false
    @Published var isLoading: Bool = false
    @Published var showSettings: Bool = false
    @Published var showPINEntry: Bool = false
    @Published var errorMessage: String?
    @Published var webViewURL: URL?
    @Published var webViewKey: UUID = UUID()  // Force reload
    
    // MARK: - URL Change Tracking (for logging only)
    private var lastURLChange: Date = Date()
    
    // MARK: - Dependencies
    private let cameraId: String
    private let configService: CameraConfigServiceProtocol
    let pinService: any PINManagementServiceProtocol
    private let cameraService: CameraServiceProtocol
    
    init(cameraId: String,
         configService: CameraConfigServiceProtocol,
         pinService: any PINManagementServiceProtocol,
         cameraService: CameraServiceProtocol = CameraServiceCoordinator()) {
        self.cameraId = cameraId
        self.configService = configService
        self.pinService = pinService
        self.cameraService = cameraService
        
        // Load saved configuration or use default
        self.config = configService.getConfiguration(for: cameraId) 
            ?? (cameraId == "iris_one" ? .camera1() : .camera2())
        self.isConfigured = self.config.isConfigured
        
        // Initialize webViewURL if configured
        if self.config.isConfigured {
            Task {
                await loadCameraView()
            }
        }
        
        // Listen for configuration changes
        NotificationCenter.default.addObserver(
            forName: .cameraConfigurationChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleConfigurationChange()
            }
        }
    }
    
    // MARK: - Public Methods
    
    func loadCameraView() async {
        guard config.isConfigured else {
            webViewURL = nil
            return
        }
        
        // For Blue Iris, credentials are not required - create dummy credentials
        let credentials: CameraCredentials
        if config.vmsType == .blueIris {
            credentials = CameraCredentials(cameraId: cameraId, password: "")
        } else {
            // For other VMS types, get password from keychain
            guard let password = configService.getPassword(for: cameraId) else {
                DebugLogger.error("❌ No camera credentials available", feature: .camera)
                errorMessage = "Camera credentials not set"
                webViewURL = nil
                return
            }
            credentials = CameraCredentials(cameraId: cameraId, password: password)
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Use camera service to prepare connection
            let connection = try await cameraService.prepareConnection(
                config: config,
                credentials: credentials
            )
            
            if connection.isValid {
                self.webViewURL = connection.connectionURL
                DebugLogger.log("✅ Camera URL loaded: \(config.name)", feature: .camera)
            } else if let error = connection.errorMessage {
                errorMessage = error
                DebugLogger.error("❌ Camera connection error: \(error)", feature: .camera)
            }
            
        } catch {
            errorMessage = error.localizedDescription
            DebugLogger.error("❌ Failed to prepare camera connection: \(error)", feature: .camera)
        }
        
        isLoading = false
    }
    
    func openSettings() {
        showPINEntry = true
    }
    
    func verifyPIN(_ pin: String) async {
        do {
            let isValid = try await pinService.verifyMasterPIN(pin)
            if isValid {
                showPINEntry = false
                showSettings = true
            } else {
                errorMessage = "Invalid Master PIN"
            }
        } catch {
            errorMessage = "PIN verification failed: \(error.localizedDescription)"
        }
    }
    
    func saveConfiguration(
        name: String,
        vmsType: VMSType,
        ipAddress: String, 
        port: String, 
        path: String, 
        username: String, 
        password: String
    ) async {
        do {
            // Create new configuration (immutable struct)
            let portInt = Int(port) ?? 81
            config = CameraConfig(
                id: cameraId,
                name: name.isEmpty ? (cameraId == "iris_one" ? "Camera 1" : "Camera 2") : name,
                vmsType: vmsType,
                ipAddress: ipAddress,
                port: portInt,
                username: username,
                path: path,
                lastUpdated: Date()
            )
            
            // Save to UserDefaults
            try configService.saveConfiguration(config)
            
            // Save password to Keychain
            if !password.isEmpty {
                try configService.savePassword(for: cameraId, password: password)
            }
            
            // Update state
            isConfigured = config.isConfigured
            showSettings = false
            
            // Reload web view
            await loadCameraView()
            webViewKey = UUID()  // Force reload
            
            // Post notification to refresh camera tabs
            NotificationCenter.default.post(name: .cameraConfigurationChanged, object: nil)
        } catch {
            errorMessage = "Failed to save configuration: \(error.localizedDescription)"
        }
    }
    
    func getSavedPassword() -> String {
        return configService.getPassword(for: cameraId) ?? ""
    }
    
    func refresh() {
        webViewKey = UUID()  // Force reload
    }
    
    func clearConfiguration() async {
        do {
            try configService.deleteConfiguration(for: cameraId)
            config = cameraId == "iris_one" ? .camera1() : .camera2()
            isConfigured = false
            webViewURL = nil
            showSettings = false
        } catch {
            errorMessage = "Failed to clear configuration: \(error.localizedDescription)"
        }
    }
    
    // MARK: - URL Change Handling (Logging Only)
    
    /// Called when the WebView URL changes - logs for debugging
    func handleURLChange(_ url: URL) {
        lastURLChange = Date()
        
        // Parse and log Blue Iris specific parameters
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            
            // Check for camera parameter
            if let cameraParam = queryItems.first(where: { $0.name == "cam" }),
               let cameraId = cameraParam.value, !cameraId.isEmpty {
                DebugLogger.log("Camera: \(cameraId)", feature: .camera)
                return
            }

            // Check for group parameter
            if let groupParam = queryItems.first(where: { $0.name == "group" }),
               let groupValue = groupParam.value {
                if groupValue == "Index" {
                    DebugLogger.log("Group view", feature: .camera)
                    return
                } else {
                    DebugLogger.log("Group: \(groupValue)", feature: .camera)
                    return
                }
            }
        }

        // Fallback for other URL changes
        DebugLogger.log("URL: \(url.absoluteString)", feature: .camera)
    }
    
    // MARK: - Private Methods
    
    private func handleConfigurationChange() async {
        // Reload configuration from service
        let newConfig = configService.getConfiguration(for: cameraId) 
            ?? (cameraId == "iris_one" ? .camera1() : .camera2())
        
        DebugLogger.log("🔍 [CameraViewModel] Configuration change detected for \(cameraId). Old: isConfigured=\(config.isConfigured), New: isConfigured=\(newConfig.isConfigured)", feature: .camera)
        
        // Check if configuration has changed
        if newConfig.id != config.id || newConfig.isConfigured != config.isConfigured {
            config = newConfig
            isConfigured = config.isConfigured
            
            if config.isConfigured {
                // Configuration was added or updated, load the camera
                DebugLogger.log("🔍 [CameraViewModel] Loading camera for \(cameraId)", feature: .camera)
                await loadCameraView()
            } else {
                // Configuration was deleted, clear the web view
                DebugLogger.log("🔍 [CameraViewModel] Clearing camera for \(cameraId) - configuration deleted", feature: .camera)
                webViewURL = nil
                errorMessage = nil
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}