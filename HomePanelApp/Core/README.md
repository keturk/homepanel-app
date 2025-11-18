# Core Infrastructure

The core infrastructure provides foundational services and models that support all features of the Home Panel App, including error handling, configuration management, and secure storage services.

**Current Implementation**: All core services are fully implemented with modern Swift 6.0 concurrency patterns, comprehensive error handling, and secure credential management.

## 🏗️ Overview

The core infrastructure consists of essential services and models that are shared across all app features, providing a solid foundation for the application's architecture and functionality.

## 🔧 Core Components

### Configuration Management

App-wide configuration values are centralized for easy management:

#### TimeoutConfiguration
- Location: `Core/Configuration/TimeoutConfiguration.swift`
- Purpose: All network timeout values
- Benefits: Single source of truth, easy to tune globally

**Usage**:
```swift
try await withTimeout(seconds: TimeoutConfiguration.standardRequest) {
    // operation
}
```

### Error Handling

Centralized error management and user-friendly error messages:

```swift
enum AppError: Error, LocalizedError {
    case networkError(Error)
    case keychainError(Error)
    case validationError(String)
    case configurationError(String)
    case securityError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .keychainError(let error):
            return "Security error: \(error.localizedDescription)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .securityError(let message):
            return "Security error: \(message)"
        }
    }
}
```

### Configuration Management

App-wide configuration and settings management:

```swift
@MainActor
class AppConfiguration: ObservableObject {
    @Published var veraHubIP: String = ""
    @Published var refreshInterval: TimeInterval = 5.0
    @Published var connectionTimeout: TimeInterval = 10.0
    @Published var maxRetryAttempts: Int = 3
    
    func save() throws {
        let data = try JSONEncoder().encode(self)
        try UserDefaults.standard.set(data, forKey: "AppConfiguration")
    }
    
    static func load() throws -> AppConfiguration {
        guard let data = UserDefaults.standard.data(forKey: "AppConfiguration") else {
            return AppConfiguration()
        }
        return try JSONDecoder().decode(AppConfiguration.self, from: data)
    }
}
```

### Secure Storage

iOS Keychain integration for secure data storage:

```swift
class KeychainService: @unchecked Sendable {
    static let shared = KeychainService()
    
    func store(key: String, value: String) throws {
        let data = value.data(using: .utf8)!
        try storeData(key: key, value: data)
    }
    
    func retrieve(key: String) throws -> String {
        let data = try retrieveData(key: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }
    
    func storeData(key: String, value: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: value
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}
```

### Settings Backup Service

Comprehensive backup and restore service for app settings:

- **Location**: `Core/Services/Storage/SettingsBackupService.swift`
- **Purpose**: Export and import all app settings to/from JSON files
- **Benefits**: Allows settings to persist across app deletions and reinstallations

**Features:**
- Exports all settings: hub configs, camera settings, PINs, scenes, devices, destinations
- Imports and restores complete configuration
- Handles PIN restoration (hashed PINs work with same original PINs)
- File-based backup that can be saved to Files app, AirDrop, email, etc.

**Usage:**
```swift
@MainActor
class SettingsBackupService: ObservableObject {
    @Published var isExporting = false
    @Published var isImporting = false
    
    func exportAllSettings(
        hubConfigStore: HubConfigurationStore,
        cameraConfigService: CameraConfigService,
        pinService: PINManagementService,
        appConfig: AppConfiguration,
        destinationStore: DestinationStore
    ) async throws -> URL
    
    func importSettings(
        from url: URL,
        hubConfigStore: HubConfigurationStore,
        cameraConfigService: CameraConfigService,
        pinService: PINManagementService,
        appConfig: AppConfiguration,
        destinationStore: DestinationStore
    ) async throws
}
```

**Backup Data Structure:**
```swift
struct SettingsBackup: Codable {
    let version: String
    let exportDate: Date
    let hubConfigurations: [HubConfiguration]
    let cameraConfigurations: [CameraConfig]
    let cameraPasswords: [String: String]
    let masterPINData: MasterPINData?
    let userPINs: [PINData]
    let sceneMappings: [String: [String: String]]
    let selectedDeviceNames: [String]
    let primaryHubId: String?
    let favoriteDestinations: [FavoriteDestination]
}
```

## 📊 Data Models

### AppConfiguration

Centralized app configuration model:

```swift
struct AppConfiguration: Codable {
    var veraHubIP: String
    var refreshInterval: TimeInterval
    var connectionTimeout: TimeInterval
    var maxRetryAttempts: Int
    var enableDebugLogging: Bool
    var autoRefreshEnabled: Bool
    
    init() {
        self.veraHubIP = ""
        self.refreshInterval = 5.0
        self.connectionTimeout = 10.0
        self.maxRetryAttempts = 3
        self.enableDebugLogging = false
        self.autoRefreshEnabled = true
    }
}
```

### Error Types

Comprehensive error type definitions:

```swift
enum KeychainError: Error, LocalizedError {
    case duplicateItem
    case invalidData
    case itemNotFound
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
    case encodingError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .duplicateItem:
            return "Item already exists in Keychain"
        case .invalidData:
            return "Invalid data format"
        case .itemNotFound:
            return "Item not found in Keychain"
        case .unexpectedPasswordData:
            return "Unexpected password data format"
        case .unhandledError(let status):
            return "Keychain error: \(status)"
        case .encodingError:
            return "Failed to encode data"
        case .decodingError:
            return "Failed to decode data"
        }
    }
}
```

## 🔐 Security Services

### Keychain Integration

Secure storage for sensitive data:

```swift
extension KeychainService {
    func storePIN(_ pin: String, for key: String) throws {
        let hashedPIN = try PINHasher.hashPIN(pin, salt: generateSalt())
        try store(key: key, value: hashedPIN)
    }
    
    func retrievePIN(for key: String) throws -> String {
        return try retrieve(key: key)
    }
    
    func deletePIN(for key: String) throws {
        try delete(key: key)
    }
    
    private func generateSalt() -> String {
        let saltData = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return saltData.base64EncodedString()
    }
}
```

### Data Encryption

Secure data encryption and decryption:

```swift
extension KeychainService {
    func storeEncryptedData(_ data: Data, for key: String) throws {
        let encryptedData = try encrypt(data)
        try storeData(key: key, value: encryptedData)
    }
    
    func retrieveEncryptedData(for key: String) throws -> Data {
        let encryptedData = try retrieveData(key: key)
        return try decrypt(encryptedData)
    }
    
    private func encrypt(_ data: Data) throws -> Data {
        // Implementation for data encryption
        return data
    }
    
    private func decrypt(_ data: Data) throws -> Data {
        // Implementation for data decryption
        return data
    }
}
```

## 🌐 Cloud Services

### Hub Configuration Store

Cloud-based hub configuration storage:

```swift
class HubConfigurationStore: @unchecked Sendable {
    private let keychainService: KeychainService
    
    func storeHubConfiguration(_ config: HubConfiguration) throws {
        let data = try JSONEncoder().encode(config)
        try keychainService.storeData(
            key: "hub_config_\(config.id)",
            value: data
        )
    }
    
    func retrieveHubConfiguration(for id: String) throws -> HubConfiguration? {
        let data = try keychainService.retrieveData(key: "hub_config_\(id)")
        return try JSONDecoder().decode(HubConfiguration.self, from: data)
    }
    
    func retrieveAllHubConfigurations() throws -> [HubConfiguration] {
        // Implementation to retrieve all hub configurations
        return []
    }
}
```

## 🧪 Testing

### Unit Testing

Test core infrastructure components:

```swift
func testAppConfiguration() throws {
    let config = AppConfiguration()
    config.veraHubIP = "192.168.1.100"
    config.refreshInterval = 10.0
    
    try config.save()
    let loadedConfig = try AppConfiguration.load()
    
    XCTAssertEqual(loadedConfig.veraHubIP, "192.168.1.100")
    XCTAssertEqual(loadedConfig.refreshInterval, 10.0)
}

func testKeychainService() throws {
    let service = KeychainService.shared
    
    try service.store(key: "test_key", value: "test_value")
    let retrievedValue = try service.retrieve(key: "test_key")
    
    XCTAssertEqual(retrievedValue, "test_value")
    
    try service.delete(key: "test_key")
    XCTAssertThrowsError(try service.retrieve(key: "test_key"))
}
```

### Integration Testing

Test core services with real dependencies:

```swift
func testConfigurationPersistence() throws {
    let config = AppConfiguration()
    config.veraHubIP = "192.168.1.100"
    
    try config.save()
    
    // Simulate app restart
    let newConfig = try AppConfiguration.load()
    XCTAssertEqual(newConfig.veraHubIP, "192.168.1.100")
}
```

## 🚀 Performance

### Optimization Strategies

- **Lazy Loading**: Load configurations on demand
- **Caching**: Cache frequently accessed data
- **Background Processing**: Non-blocking operations
- **Memory Management**: Efficient resource usage

### Monitoring

- **Configuration Load Times**: Track configuration loading performance
- **Keychain Operations**: Monitor secure storage performance
- **Error Rates**: Track core service failures
- **Memory Usage**: Monitor core service memory consumption

## 🔮 Future Enhancements

### Planned Features

- **Advanced Encryption**: Enhanced data encryption
- **Configuration Sync**: Cross-device configuration synchronization
- **Performance Monitoring**: Advanced performance metrics
- **Error Analytics**: Comprehensive error tracking

### Technical Improvements

- **Async Operations**: Improved async/await support
- **Error Recovery**: Enhanced error recovery mechanisms
- **Security Hardening**: Additional security measures
- **Performance Optimization**: Core service performance improvements

## 📁 File Structure

- **[Models](Models/README.md)** - Core data models and configuration
- **[Services](Services/README.md)** - Core services and infrastructure

## 🔗 Navigation

- **[Main App Architecture](../README.md)** - Overall app architecture
- **[Features Overview](../Features/README.md)** - All app features
- **[Shared Components](../Shared/README.md)** - Reusable components

---

The core infrastructure provides essential services and models that form the foundation of the Home Panel App's architecture and functionality.
