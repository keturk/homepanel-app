# Core Models

This directory contains the core data models and configuration structures that are shared across all features of the Home Panel App.

## 📊 Overview

The core models provide the foundational data structures that support the entire application, including app configuration, error handling, and shared data types.

## 🔧 Core Models

### AppConfiguration

Centralized app configuration and settings management:

```swift
@MainActor
class AppConfiguration: ObservableObject, Codable {
    @Published var veraHubIP: String = ""
    @Published var refreshInterval: TimeInterval = 5.0
    @Published var connectionTimeout: TimeInterval = 10.0
    @Published var maxRetryAttempts: Int = 3
    @Published var enableDebugLogging: Bool = false
    @Published var autoRefreshEnabled: Bool = true
    @Published var securityLevel: SecurityLevel = .standard
    
    enum SecurityLevel: String, Codable, CaseIterable {
        case basic = "basic"
        case standard = "standard"
        case high = "high"
        case maximum = "maximum"
    }
}
```

**Key Properties:**
- `veraHubIP`: Primary Vera Hub IP address
- `refreshInterval`: Device state polling frequency
- `connectionTimeout`: Network request timeout duration
- `maxRetryAttempts`: Maximum retry attempts for failed operations
- `enableDebugLogging`: Debug logging enablement
- `autoRefreshEnabled`: Automatic refresh functionality
- `securityLevel`: App-wide security configuration

### Error Types

Comprehensive error type definitions for the entire app:

```swift
enum AppError: Error, LocalizedError {
    case networkError(Error)
    case keychainError(Error)
    case validationError(String)
    case configurationError(String)
    case securityError(String)
    case hubError(String)
    case cameraError(String)
    case alarmError(String)
    case automationError(String)
    
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
        case .hubError(let message):
            return "Hub error: \(message)"
        case .cameraError(let message):
            return "Camera error: \(message)"
        case .alarmError(let message):
            return "Alarm error: \(message)"
        case .automationError(let message):
            return "Automation error: \(message)"
        }
    }
}
```

### KeychainError

Specialized error handling for Keychain operations:

```swift
enum KeychainError: Error, LocalizedError {
    case duplicateItem
    case invalidData
    case itemNotFound
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
    case encodingError
    case decodingError
    case accessDenied
    case itemExists
    
    var errorDescription: String? {
        switch self {
        case .duplicateItem:
            return "Item already exists in Keychain"
        case .invalidData:
            return "Invalid data format for Keychain storage"
        case .itemNotFound:
            return "Item not found in Keychain"
        case .unexpectedPasswordData:
            return "Unexpected password data format"
        case .unhandledError(let status):
            return "Keychain error: \(status)"
        case .encodingError:
            return "Failed to encode data for Keychain"
        case .decodingError:
            return "Failed to decode data from Keychain"
        case .accessDenied:
            return "Access denied to Keychain item"
        case .itemExists:
            return "Keychain item already exists"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .duplicateItem, .itemExists:
            return "Try deleting the existing item first"
        case .invalidData:
            return "Check the data format and try again"
        case .itemNotFound:
            return "Verify the item key and try again"
        case .accessDenied:
            return "Check your device's security settings"
        default:
            return "Please try again or contact support"
        }
    }
}
```

## 🔐 Security Models

### Security Configuration

App-wide security configuration and policies:

```swift
struct SecurityConfiguration: Codable {
    let pinLength: Int
    let maxFailedAttempts: Int
    let lockoutDuration: TimeInterval
    let enableBiometrics: Bool
    let requireMasterPIN: Bool
    let sessionTimeout: TimeInterval
    
    static let standard = SecurityConfiguration(
        pinLength: 6,
        maxFailedAttempts: 7,
        lockoutDuration: 420, // 7 minutes
        enableBiometrics: true,
        requireMasterPIN: true,
        sessionTimeout: 1800 // 30 minutes
    )
    
    static let high = SecurityConfiguration(
        pinLength: 8,
        maxFailedAttempts: 5,
        lockoutDuration: 900, // 15 minutes
        enableBiometrics: true,
        requireMasterPIN: true,
        sessionTimeout: 900 // 15 minutes
    )
}
```

### Validation Rules

Input validation and data integrity rules:

```swift
struct ValidationRules {
    static let ipAddressPattern = #"^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"#
    static let portRange = 1...65535
    static let pinLength = 6
    static let maxRetryAttempts = 10
    static let connectionTimeoutRange = 1.0...60.0
    static let refreshIntervalRange = 1.0...300.0
}
```

## 🌐 Network Models

### Network Configuration

Network-related configuration and settings:

```swift
struct NetworkConfiguration: Codable {
    let baseURL: String
    let timeout: TimeInterval
    let retryAttempts: Int
    let retryDelay: TimeInterval
    let enableSSL: Bool
    let certificateValidation: Bool
    
    static let defaultVeraHub = NetworkConfiguration(
        baseURL: "http://[HUB_IP]:3480",
        timeout: 10.0,
        retryAttempts: 3,
        retryDelay: 2.0,
        enableSSL: false,
        certificateValidation: false
    )
}
```

### API Endpoints

Centralized API endpoint definitions:

```swift
enum APIEndpoint {
    case alarmState
    case sceneList
    case executeScene(sceneId: String)
    case deviceList
    case deviceState(deviceId: String)
    case updateDevice(deviceId: String)
    
    var path: String {
        switch self {
        case .alarmState:
            return "/data_request?id=status&DeviceNum=7&output_format=json"
        case .sceneList:
            return "/data_request?id=user_data"
        case .executeScene(let sceneId):
            return "/data_request?id=lu_action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=RunScene&SceneNum=\(sceneId)"
        case .deviceList:
            return "/data_request?id=user_data"
        case .deviceState(let deviceId):
            return "/data_request?id=status&DeviceNum=\(deviceId)&output_format=json"
        case .updateDevice(let deviceId):
            return "/data_request?id=lu_action&serviceId=urn:micasaverde-com:serviceId:SwitchPower1&action=SetTarget&newTargetValue=1&DeviceNum=\(deviceId)"
        }
    }
}
```

## 🧪 Testing

### Model Testing

Test core model functionality:

```swift
func testAppConfiguration() {
    let config = AppConfiguration()
    config.veraHubIP = "192.168.1.100"
    config.refreshInterval = 10.0
    
    XCTAssertEqual(config.veraHubIP, "192.168.1.100")
    XCTAssertEqual(config.refreshInterval, 10.0)
    XCTAssertTrue(config.isValid)
}

func testErrorHandling() {
    let error = AppError.networkError(URLError(.notConnectedToInternet))
    XCTAssertEqual(error.localizedDescription, "Network error: The Internet connection appears to be offline.")
    
    let keychainError = KeychainError.itemNotFound
    XCTAssertEqual(keychainError.localizedDescription, "Item not found in Keychain")
    XCTAssertNotNil(keychainError.recoverySuggestion)
}
```

### Validation Testing

Test input validation and data integrity:

```swift
func testIPAddressValidation() {
    XCTAssertTrue(ValidationRules.isValidIPAddress("192.168.1.1"))
    XCTAssertTrue(ValidationRules.isValidIPAddress("10.0.0.1"))
    XCTAssertFalse(ValidationRules.isValidIPAddress("256.1.1.1"))
    XCTAssertFalse(ValidationRules.isValidIPAddress("192.168.1"))
    XCTAssertFalse(ValidationRules.isValidIPAddress("invalid"))
}

func testPortValidation() {
    XCTAssertTrue(ValidationRules.isValidPort(80))
    XCTAssertTrue(ValidationRules.isValidPort(443))
    XCTAssertTrue(ValidationRules.isValidPort(3480))
    XCTAssertFalse(ValidationRules.isValidPort(0))
    XCTAssertFalse(ValidationRules.isValidPort(70000))
}
```

## 🚀 Performance

### Optimization Strategies

- **Lazy Loading**: Load configurations on demand
- **Caching**: Cache frequently accessed data
- **Validation**: Efficient input validation
- **Memory Management**: Proper model cleanup

### Monitoring

- **Configuration Load Times**: Track configuration loading performance
- **Validation Performance**: Monitor validation operation speed
- **Error Rates**: Track error occurrence frequency
- **Memory Usage**: Monitor model memory consumption

## 🔮 Future Enhancements

### Planned Features

- **Advanced Validation**: More sophisticated validation rules
- **Configuration Sync**: Cross-device configuration synchronization
- **Error Analytics**: Comprehensive error tracking and analysis
- **Performance Metrics**: Model performance monitoring

### Technical Improvements

- **Async Operations**: Improved async/await support
- **Validation Caching**: Cache validation results
- **Error Recovery**: Enhanced error recovery mechanisms
- **Performance Optimization**: Model operation optimization

## 📁 Files

- **AppConfiguration.swift** - Centralized app configuration
- **AppErrors.swift** - Comprehensive error type definitions

## 🔗 Navigation

- **[Core Infrastructure](../README.md)** - Main core infrastructure documentation
- **[Services](../Services/README.md)** - Core services and infrastructure
- **[Main App Architecture](../../README.md)** - Overall app architecture

---

The core models provide the foundational data structures and configuration management that support the entire Home Panel App.
