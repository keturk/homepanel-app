# Camera ViewModels

This directory contains the ViewModels that manage UI state and business logic for the camera surveillance system, providing the bridge between SwiftUI views and the camera service coordinator with VMS adapter support.

## 🧠 Core ViewModels

### CameraViewModel

Primary ViewModel for camera state management and configuration.

```swift
@MainActor
class CameraViewModel: ObservableObject {
    @Published var cameraConfigs: [CameraConfig] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSettings = false
    @Published var selectedCamera: CameraConfig?
    @Published var camera1Config: CameraConfig?  // First camera (user-defined name)
    @Published var camera2Config: CameraConfig?  // Second camera (user-defined name)
    
    private let cameraService: CameraServiceProtocol
    private let configService: CameraConfigServiceProtocol
    private let pinService: PINManagementServiceProtocol
}
```

**Key Responsibilities:**
- Camera configuration management with VMS support
- VMS-specific connection preparation via coordinator
- Credential handling and security
- Web view state coordination
- Settings interface management with VMS selection

## 🔄 State Management

### Published Properties

The ViewModel uses `@Published` properties for reactive UI updates:

```swift
@Published var cameraConfigs: [CameraConfig] = []
@Published var isLoading = false
@Published var errorMessage: String?
@Published var showSettings = false
@Published var selectedCamera: CameraConfig?
@Published var camera1Config: CameraConfig?
@Published var camera2Config: CameraConfig?
```

### Configuration Loading

Load camera configurations on initialization:

```swift
func loadConfigurations() {
    isLoading = true
    errorMessage = nil
    
    do {
        let configs = configService.loadConfigurations()
        await MainActor.run {
            self.cameraConfigs = configs
            self.setupDefaultConfigs()
            self.isLoading = false
        }
    } catch {
        await MainActor.run {
            self.errorMessage = "Failed to load camera configurations: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
}

private func setupDefaultConfigs() {
    camera1Config = cameraConfigs.first { $0.id == "camera1" }
    camera2Config = cameraConfigs.first { $0.id == "camera2" }
}
```

## 🔐 Security Management

### Master PIN Verification

Secure access to camera settings:

```swift
func requestSettingsAccess() {
    guard pinService.hasMasterPIN() else {
        errorMessage = "Master PIN not set. Please configure in Settings."
        return
    }
    
    showSettings = true
}

func verifyMasterPIN(_ pin: String) -> Bool {
    let isValid = pinService.verifyMasterPIN(pin)
    
    if !isValid {
        errorMessage = "Invalid Master PIN. Please try again."
    }
    
    return isValid
}
```

### Credential Management

Secure credential handling:

```swift
func loadCredentials(for cameraId: String) -> CameraCredentials? {
    do {
        return try configService.loadCredentials(for: cameraId)
    } catch {
        errorMessage = "Failed to load credentials: \(error.localizedDescription)"
        return nil
    }
}

func saveCredentials(_ credentials: CameraCredentials) {
    do {
        try configService.saveCredentials(credentials)
        errorMessage = nil
    } catch {
        errorMessage = "Failed to save credentials: \(error.localizedDescription)"
    }
}
```

## 🎨 UI State Management

### Settings Management

Handle settings interface state:

```swift
func openSettings(for camera: CameraConfig) {
    selectedCamera = camera
    showSettings = true
}

func closeSettings() {
    showSettings = false
    selectedCamera = nil
    errorMessage = nil
}

func saveConfiguration(_ config: CameraConfig) {
    do {
        try configService.saveConfiguration(config)
        updateLocalConfigs(config)
        errorMessage = nil
    } catch {
        errorMessage = "Failed to save configuration: \(error.localizedDescription)"
    }
}

private func updateLocalConfigs(_ config: CameraConfig) {
    if config.id == "camera1" {
        camera1Config = config
    } else if config.id == "camera2" {
        camera2Config = config
    }
    
    // Update camera configs array
    if let index = cameraConfigs.firstIndex(where: { $0.id == config.id }) {
        cameraConfigs[index] = config
    } else {
        cameraConfigs.append(config)
    }
}
```

### Web View Management

Coordinate web view state and updates:

```swift
func refreshWebView(for cameraId: String) {
    // Trigger web view refresh
    NotificationCenter.default.post(
        name: .cameraWebViewRefresh,
        object: cameraId
    )
}

func buildCameraURL(for config: CameraConfig) async -> URL? {
    guard let credentials = loadCredentials(for: config.id) else {
        return config.buildBaseURL()
    }
    
    do {
        let connection = try await cameraService.prepareConnection(
            config: config, 
            credentials: credentials
        )
        return connection.connectionURL
    } catch {
        errorMessage = "Failed to build camera URL: \(error.localizedDescription)"
        return nil
    }
}
```

## 🔄 Configuration Flow

### New Configuration

Handle new camera configuration creation:

```swift
func createNewConfiguration(
    ipAddress: String,
    port: Int,
    username: String,
    cameraId: String = UUID().uuidString
) -> CameraConfig? {
    let config = CameraConfig(
        id: cameraId,
        ipAddress: ipAddress,
        port: port,
        username: username
    )
    
    guard config.isValid else {
        errorMessage = "Invalid configuration: \(config.validationErrors.joined(separator: ", "))"
        return nil
    }
    
    return config
}
```

### Configuration Updates

Handle configuration modifications:

```swift
func updateConfiguration(
    _ config: CameraConfig,
    ipAddress: String? = nil,
    port: Int? = nil,
    username: String? = nil
) -> CameraConfig? {
    var updatedConfig = config
    
    if let ipAddress = ipAddress {
        updatedConfig.ipAddress = ipAddress
    }
    if let port = port {
        updatedConfig.port = port
    }
    if let username = username {
        updatedConfig.username = username
    }
    
    updatedConfig.lastUpdated = Date()
    
    guard updatedConfig.isValid else {
        errorMessage = "Invalid configuration: \(updatedConfig.validationErrors.joined(separator: ", "))"
        return nil
    }
    
    return updatedConfig
}
```

## 🧪 Testing

### Unit Testing

Test ViewModel logic in isolation:

```swift
func testCameraConfigurationLoading() {
    let mockConfigService = MockCameraConfigService()
    let viewModel = CameraViewModel(
        configService: mockConfigService,
        pinService: MockPINManagementService()
    )
    
    viewModel.loadConfigurations()
    
    XCTAssertEqual(viewModel.cameraConfigs.count, 2)
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertNil(viewModel.errorMessage)
}

func testMasterPINVerification() {
    let mockPINService = MockPINManagementService()
    let viewModel = CameraViewModel(
        configService: MockCameraConfigService(),
        pinService: mockPINService
    )
    
    let isValid = viewModel.verifyMasterPIN("123456")
    XCTAssertTrue(isValid)
    
    let isInvalid = viewModel.verifyMasterPIN("654321")
    XCTAssertFalse(isInvalid)
}
```

### Integration Testing

Test ViewModel with real services:

```swift
func testConfigurationSave() {
    let viewModel = createCameraViewModel()
    
    let config = CameraConfig(
        ipAddress: "192.168.1.100",
        port: 2671,
        username: "admin"
    )
    
    viewModel.saveConfiguration(config)
    
    XCTAssertTrue(viewModel.cameraConfigs.contains { $0.id == config.id })
    XCTAssertNil(viewModel.errorMessage)
}
```

### Mock Services

Test with mock implementations:

```swift
class MockCameraConfigService: CameraConfigServiceProtocol {
    var mockConfigs: [CameraConfig] = []
    var shouldThrowError = false
    
    func loadConfigurations() -> [CameraConfig] {
        if shouldThrowError {
            throw CameraError.configurationNotFound
        }
        return mockConfigs
    }
    
    func saveConfiguration(_ config: CameraConfig) throws {
        if shouldThrowError {
            throw CameraError.invalidConfiguration
        }
        mockConfigs.append(config)
    }
}
```

## 🚀 Performance

### Optimization Strategies

- **@MainActor**: Ensures UI updates on main thread
- **Configuration Caching**: Reduces service calls
- **Error Recovery**: Automatic retry logic
- **Memory Management**: Proper cleanup of resources

### State Updates

Efficient state management:

```swift
private func updateUIState() {
    // Batch UI updates for better performance
    DispatchQueue.main.async { [weak self] in
        self?.objectWillChange.send()
    }
}
```

## 📊 State Flow

### Configuration Loading

```
View Appear → loadConfigurations() → Service Call → Update State
     ↓              ↓                    ↓            ↓
UI Update ← Configuration Load ← Service Response ← State Change
```

### Settings Access

```
Settings Tap → Master PIN Check → PIN Entry → Configuration Form
     ↓              ↓                ↓            ↓
PIN Required ← PIN Verification ← PIN Entry ← Settings Display
```

### Configuration Save

```
Form Submit → Validation → Service Save → State Update → Web Refresh
     ↓            ↓            ↓            ↓            ↓
Input Check ← Config Check ← Keychain Store ← UI Update ← Web Reload
```

## 📁 Files

- **CameraViewModel.swift** - Main camera ViewModel

## 🔗 Navigation

- **[Camera System](../README.md)** - Main camera system documentation
- **[Models](../Models/README.md)** - Camera data models
- **[Services](../Services/README.md)** - Camera services and business logic
- **[Views](../Views/README.md)** - SwiftUI components

---

The Camera ViewModels provide the business logic and state management that powers the camera surveillance system's user interface and configuration management.
