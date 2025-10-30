# Camera Services

This directory contains the business logic and external integrations for camera management, including the adapter pattern architecture, configuration services, credential management, and VMS-specific integrations.

## 🔧 Core Services

### CameraServiceProtocol

Generic protocol for camera/VMS operations across all system types.

```swift
@MainActor
public protocol CameraServiceProtocol: Sendable {
    /// Prepares a connection to the camera system
    func prepareConnection(
        config: CameraConfig,
        credentials: CameraCredentials
    ) async throws -> CameraConnection

    /// Validates that a camera configuration is valid for this VMS type
    func validateConfiguration(config: CameraConfig) throws

    /// Returns the view type needed for this camera system
    func getViewType(for config: CameraConfig) -> CameraViewType
}
```

**Key Methods:**
- `prepareConnection(config:credentials:)` - Prepares camera connection with VMS-specific logic
- `validateConfiguration(config:)` - Validates configuration for specific VMS type
- `getViewType(for:)` - Returns appropriate view type for the VMS

### CameraServiceCoordinator

Coordinator that routes camera operations to appropriate VMS-specific adapters.

```swift
@MainActor
public class CameraServiceCoordinator: CameraServiceProtocol {
    /// Cache of adapters by VMS type to avoid recreating them
    private var adapterCache: [VMSType: CameraServiceProtocol] = [:]

    func prepareConnection(
        config: CameraConfig,
        credentials: CameraCredentials
    ) async throws -> CameraConnection {
        let adapter = getAdapter(for: config.vmsType)
        try adapter.validateConfiguration(config: config)
        return try await adapter.prepareConnection(config: config, credentials: credentials)
    }

    private func getAdapter(for vmsType: VMSType) -> CameraServiceProtocol {
        // Routes to appropriate VMS adapter (Blue Iris, Frigate, etc.)
    }
}
```

**Key Features:**
- **VMS Routing**: Routes requests to appropriate VMS adapter
- **Adapter Caching**: Caches adapters to avoid recreation
- **Configuration Validation**: Validates config before connection
- **Error Handling**: Centralized error handling for all VMS types

### CameraConfigService

Primary service for camera configuration management and persistence.

```swift
class CameraConfigService: @unchecked Sendable {
    private let keychainService: KeychainService
    private let userDefaults: UserDefaults
    
    func loadConfigurations() -> [CameraConfig]
    func saveConfiguration(_ config: CameraConfig) throws
    func deleteConfiguration(_ id: String) throws
    func loadCredentials(for cameraId: String) throws -> CameraCredentials?
    func saveCredentials(_ credentials: CameraCredentials) throws
    func deleteCredentials(for cameraId: String) throws
}
```

**Key Methods:**
- `loadConfigurations()` - Retrieves all camera configurations
- `saveConfiguration(_:)` - Persists camera configuration
- `loadCredentials(for:)` - Retrieves secure credentials for camera
- `saveCredentials(_:)` - Stores secure credentials in Keychain

### KeychainService Integration

Secure credential storage using iOS Keychain:

```swift
extension CameraConfigService {
    private func storeCredentials(_ credentials: CameraCredentials) throws {
        let data = try JSONEncoder().encode(credentials)
        try keychainService.storeData(
            key: "camera_credentials_\(credentials.cameraId)",
            value: data
        )
    }
    
    private func loadCredentials(for cameraId: String) throws -> CameraCredentials? {
        let data = try keychainService.retrieveData(
            key: "camera_credentials_\(cameraId)"
        )
        return try JSONDecoder().decode(CameraCredentials.self, from: data)
    }
}
```

## 🔐 Security Services

### Credential Management

Secure handling of camera authentication credentials:

```swift
extension CameraConfigService {
    func updateCredentials(for cameraId: String, password: String) throws {
        let credentials = CameraCredentials(
            cameraId: cameraId,
            password: password
        )
        try saveCredentials(credentials)
    }
    
    func validateCredentials(for cameraId: String) -> Bool {
        do {
            let credentials = try loadCredentials(for: cameraId)
            return credentials != nil && !credentials!.isExpired
        } catch {
            return false
        }
    }
}
```

### Master PIN Protection

Integration with Master PIN system for secure access:

```swift
extension CameraConfigService {
    func requireMasterPIN() -> Bool {
        // Check if Master PIN is required for camera settings
        return true
    }
    
    func verifyMasterPIN(_ pin: String) -> Bool {
        // Verify Master PIN before allowing configuration changes
        return pinManagementService.verifyMasterPIN(pin)
    }
}
```

## 🔌 VMS Adapters

### BlueIrisCameraAdapter

Blue Iris-specific camera adapter implementation.

```swift
@MainActor
class BlueIrisCameraAdapter: CameraServiceProtocol {
    func prepareConnection(
        config: CameraConfig,
        credentials: CameraCredentials
    ) async throws -> CameraConnection {
        // Blue Iris specific: embed credentials in URL
        let urlString = buildBlueIrisURL(config: config, credentials: credentials)
        
        guard let url = URL(string: urlString) else {
            throw CameraError.invalidURL
        }

        return CameraConnection(
            viewType: .webView,
            connectionURL: url,
            additionalHeaders: nil,
            requiresJavaScript: true  // Blue Iris requires JavaScript
        )
    }

    func validateConfiguration(config: CameraConfig) throws {
        // Blue Iris specific validation
        guard config.port > 0 && config.port < 65536 else {
            throw CameraError.invalidPort
        }
        guard config.path.hasPrefix("/") else {
            throw CameraError.invalidPath
        }
    }

    func getViewType(for config: CameraConfig) -> CameraViewType {
        return .webView
    }
}
```

**Key Features:**
- **URL Embedding**: Embeds credentials directly in URL
- **JavaScript Support**: Enables JavaScript for Blue Iris UI
- **Path Validation**: Validates Blue Iris-specific path format
- **Port Validation**: Validates port range for Blue Iris

### GenericWebViewAdapter

Generic web view adapter for simple web-based cameras.

```swift
@MainActor
class GenericWebViewAdapter: CameraServiceProtocol {
    func prepareConnection(
        config: CameraConfig,
        credentials: CameraCredentials
    ) async throws -> CameraConnection {
        // Build URL with embedded credentials
        let urlString = "http://\(config.username):\(credentials.password)@\(config.ipAddress):\(config.port)\(config.path)"
        
        guard let url = URL(string: urlString) else {
            throw CameraError.invalidURL
        }

        return CameraConnection(
            viewType: .webView,
            connectionURL: url,
            additionalHeaders: nil,
            requiresJavaScript: false
        )
    }

    func validateConfiguration(config: CameraConfig) throws {
        guard config.port > 0 && config.port < 65536 else {
            throw CameraError.invalidPort
        }
    }

    func getViewType(for config: CameraConfig) -> CameraViewType {
        return .webView
    }
}
```

**Key Features:**
- **Generic Implementation**: Works with any web-based camera
- **No JavaScript**: Disables JavaScript by default
- **Simple Validation**: Basic port and URL validation
- **Universal Compatibility**: Works with most web cameras

## 🌐 Blue Iris Integration

### URL Building Service

Dynamic URL construction for Blue Iris web interface:

```swift
class BlueIrisURLBuilder: @unchecked Sendable {
    func buildCameraURL(config: CameraConfig, credentials: CameraCredentials?) -> URL? {
        guard let credentials = credentials else {
            return buildPublicURL(config: config)
        }
        
        let urlString = "http://\(config.username):\(credentials.password)@\(config.ipAddress):\(config.port)\(config.path)"
        return URL(string: urlString)
    }
    
    private func buildPublicURL(config: CameraConfig) -> URL? {
        let urlString = "http://\(config.ipAddress):\(config.port)\(config.path)"
        return URL(string: urlString)
    }
}
```

### Web View Configuration

WKWebView setup and configuration for Blue Iris:

```swift
class BlueIrisWebViewConfigurator: @unchecked Sendable {
    func configureWebView() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsAirPlayForMediaPlayback = true
        
        // Configure for Blue Iris specific requirements
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        return configuration
    }
}
```

## 🔄 Service Coordination

### Configuration Updates

Handle configuration changes and web view updates:

```swift
extension CameraConfigService {
    func updateConfiguration(_ config: CameraConfig) throws {
        try saveConfiguration(config)
        
        // Notify observers of configuration change
        NotificationCenter.default.post(
            name: .cameraConfigurationChanged,
            object: config
        )
    }
    
    func refreshWebView(for cameraId: String) {
        // Trigger web view refresh with new configuration
        NotificationCenter.default.post(
            name: .cameraWebViewRefresh,
            object: cameraId
        )
    }
}
```

### Error Handling

Comprehensive error handling for camera operations:

```swift
enum CameraError: Error, LocalizedError {
    case configurationNotFound
    case credentialsNotFound
    case invalidConfiguration
    case keychainError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .configurationNotFound:
            return "Camera configuration not found"
        case .credentialsNotFound:
            return "Camera credentials not found"
        case .invalidConfiguration:
            return "Invalid camera configuration"
        case .keychainError(let error):
            return "Keychain error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
```

## 🧪 Testing

### Service Testing

Test individual service functionality:

```swift
func testCameraConfigService() throws {
    let service = CameraConfigService()
    
    let config = CameraConfig(
        ipAddress: "192.168.1.100",
        port: 2671,
        username: "admin"
    )
    
    try service.saveConfiguration(config)
    let loadedConfigs = service.loadConfigurations()
    
    XCTAssertEqual(loadedConfigs.count, 1)
    XCTAssertEqual(loadedConfigs.first?.ipAddress, "192.168.1.100")
}

func testCredentialStorage() throws {
    let service = CameraConfigService()
    
    let credentials = CameraCredentials(
        cameraId: "iris-one",
        password: "secret123"
    )
    
    try service.saveCredentials(credentials)
    let loadedCredentials = try service.loadCredentials(for: "iris-one")
    
    XCTAssertEqual(loadedCredentials?.password, "secret123")
}
```

### Integration Testing

Test service interactions:

```swift
func testConfigurationUpdate() throws {
    let service = CameraConfigService()
    let urlBuilder = BlueIrisURLBuilder()
    
    let config = CameraConfig(
        ipAddress: "192.168.1.100",
        port: 2671,
        username: "admin"
    )
    
    let credentials = CameraCredentials(
        cameraId: config.id,
        password: "secret123"
    )
    
    try service.saveConfiguration(config)
    try service.saveCredentials(credentials)
    
    let url = urlBuilder.buildCameraURL(config: config, credentials: credentials)
    XCTAssertNotNil(url)
    XCTAssertTrue(url!.absoluteString.contains("192.168.1.100"))
}
```

### Security Testing

Test security features:

```swift
func testCredentialSecurity() throws {
    let service = CameraConfigService()
    
    let credentials = CameraCredentials(
        cameraId: "iris-one",
        password: "secret123"
    )
    
    try service.saveCredentials(credentials)
    
    // Verify credentials are stored securely
    let keychainData = try KeychainService.shared.retrieveData(
        key: "camera_credentials_iris-one"
    )
    
    // Should not contain plain text password
    let keychainString = String(data: keychainData, encoding: .utf8) ?? ""
    XCTAssertFalse(keychainString.contains("secret123"))
}
```

## 🚀 Performance

### Optimization Strategies

- **Configuration Caching**: Efficient configuration storage and retrieval
- **Credential Caching**: Secure credential caching with expiration
- **Memory Management**: Proper cleanup of web view resources
- **Network Optimization**: Efficient URL building and validation

### Monitoring

- **Configuration Load Times**: Track configuration retrieval performance
- **Credential Access**: Monitor credential retrieval frequency
- **Error Rates**: Track service failure rates
- **Memory Usage**: Monitor service memory consumption

## 📊 Service Dependencies

### Service Hierarchy

```
CameraConfigService
├── KeychainService
├── UserDefaults
└── PINManagementService (for Master PIN verification)

BlueIrisURLBuilder
└── CameraConfig
    └── CameraCredentials

BlueIrisWebViewConfigurator
└── WKWebViewConfiguration
```

### Error Handling Flow

```
Service Call → Validation → Keychain/Storage → Success/Error
     ↓             ↓            ↓                ↓
Input Check ← Config Check ← Secure Store ← Result Return
```

## 📁 Files

- **CameraServiceProtocol.swift** - Generic camera service protocol
- **CameraServiceCoordinator.swift** - VMS routing coordinator
- **CameraConfigService.swift** - Camera configuration management
- **BlueIrisURLBuilder.swift** - URL construction for Blue Iris (legacy)
- **BlueIrisWebViewConfigurator.swift** - Web view configuration (legacy)

## 🔗 Navigation

- **[Camera System](../README.md)** - Main camera system documentation
- **[Models](../Models/README.md)** - Camera data models
- **[ViewModels](../ViewModels/README.md)** - Camera state and configuration logic
- **[Views](../Views/README.md)** - Camera interface and settings components

---

These services provide the business logic and external integrations that power the camera surveillance system's functionality and security features.
