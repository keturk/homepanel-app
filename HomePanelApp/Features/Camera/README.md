# Camera Surveillance System

Dynamic camera management and live video streaming with multi-VMS support, featuring user-defined camera names, VMS type selection, and comprehensive configuration management through a modern settings interface.

## 📹 Overview

The camera surveillance system provides real-time video streaming from multiple camera sources with dynamic configuration management, supporting various Video Management Systems (VMS) including Blue Iris, Frigate, RTSP, MJPEG, and Generic Web View interfaces. The system features user-defined camera names, VMS type selection, Master PIN protection, and secure credential management.

## 🏗️ Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    Camera System Architecture                  │
├─────────────────────────────────────────────────────────────────┤
│  CameraWebView  │  CameraViewModel  │  CameraServiceCoordinator │
│  CameraManagementView │  AddCameraView │  EditCameraView        │
│  CameraConfigService │  VMS Adapters │  KeychainService        │
└─────────────────┬─────────────────┬─────────────────┬───────────┘
                  │                 │                 │
┌─────────────────▼─────────────────▼─────────────────▼───────────┐
│                    Data Models                                │
├─────────────────────────────────────────────────────────────────┤
│  CameraConfig  │  CameraCredentials  │  CameraConnection       │
│  VMSType       │  CameraViewType     │  VMSType Properties    │
└─────────────────┬─────────────────┬─────────────────┬───────────┘
                  │                 │                 │
┌─────────────────▼─────────────────▼─────────────────▼───────────┐
│                    VMS Adapters                               │
├─────────────────────────────────────────────────────────────────┤
│  BlueIrisCameraAdapter (✅)  │  GenericWebViewAdapter (✅)      │
│  UnsupportedVMSAdapter (❌) - for RTSP/MJPEG                    │
└─────────────────────────────────────────────────────────────────┘
```

### State Management

The camera system uses MVVM pattern with reactive state management:

```swift
@MainActor
class CameraViewModel: ObservableObject {
    @Published var cameraConfigs: [CameraConfig] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSettings = false
    @Published var selectedCamera: CameraConfig?
}
```

## 🔧 Core Features

### Dynamic Camera Management

Flexible camera configuration with user-defined names and VMS selection:

- **Multi-Camera Support**: Up to 2 cameras with custom names
- **VMS Type Selection**: Choose from Blue Iris, Frigate, RTSP, MJPEG, Generic Web View
- **User-Defined Names**: Custom camera names (legacy "Iris One"/"Iris Two" naming deprecated)
- **Full CRUD Operations**: Add, edit, delete camera configurations
- **Real-time Configuration**: Dynamic camera settings with validation

### Multi-VMS Support

Support for various Video Management Systems through adapter pattern:

- **Blue Iris**: ✅ Fully implemented - Web-based VMS with dedicated adapter and JavaScript support
- **Generic Web View**: ✅ Fully implemented - Any web-based camera interface with credential embedding
- **Frigate NVR**: ⚠️ Partial support - Falls back to Generic Web View adapter (no dedicated adapter yet)
- **RTSP Generic**: ❌ Not implemented - Throws unsupported error (planned for future)
- **MJPEG Generic**: ❌ Not implemented - Throws unsupported error (planned for future)

### VMS-Specific Configuration

Intelligent configuration based on VMS type:

- **Default Port Mapping**: Automatic port selection based on VMS type
- **JavaScript Requirements**: Automatic JavaScript enablement for supported VMS
- **Web View Requirements**: Automatic web view selection based on VMS type
- **Path Configuration**: VMS-specific URL paths and endpoints
- **Credential Handling**: VMS-specific authentication methods

### Master PIN Protection

Security for all camera operations:

- **Settings Access**: Master PIN required for configuration
- **Credential Management**: Secure storage and retrieval with Keychain
- **Configuration Changes**: PIN verification for all modifications
- **Auto-credential Embedding**: Seamless login with embedded credentials

## 🔐 Security Features

### Secure Credential Storage

iOS Keychain integration for camera credentials:

```swift
struct CameraCredentials: Codable {
    let cameraId: String
    let password: String
    let lastUpdated: Date
}
```

**Security Features:**
- Password never stored in plain text
- Automatic encryption/decryption
- Cross-device synchronization via iCloud Keychain
- Secure deletion capabilities

### Credential Embedding

Seamless authentication with embedded credentials:

```swift
func buildCameraURL(config: CameraConfig, credentials: CameraCredentials) -> URL? {
    let urlString = "http://\(credentials.username):\(credentials.password)@\(config.ipAddress):\(config.port)\(config.path)"
    return URL(string: urlString)
}
```

### Logging Standards

All camera operations use DebugLogger with `.camera` feature flag:

```swift
// Camera connection logging
DebugLogger.log("Loading camera feed: \(config.name)", feature: .camera)
DebugLogger.success("Camera connected successfully", feature: .camera)
DebugLogger.error("Camera connection failed: \(error)", feature: .camera)
DebugLogger.warning("Camera credentials missing", feature: .camera)
```

**Rules:**
- Never use `print()` directly
- Always include feature flag `.camera`
- Use appropriate log level for the operation
- Include context in error messages

## 🎨 User Interface

### CameraManagementView

Dynamic camera configuration and management interface:

```swift
struct CameraManagementView: View {
    @ObservedObject var cameraConfigService: CameraConfigService
    @State private var showingAddCamera = false
    @State private var editingCamera: CameraConfig?
    @State private var cameraToDelete: String?
    @State private var showingDeleteAlert = false
    @State private var showingCameraLimitAlert = false
    
    private let maxCameras = 2
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Add New Camera Button
                Button(action: { showingAddCamera = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add New Camera")
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                // Configured Cameras List
                ForEach(configuredCameras) { camera in
                    CameraRowView(
                        configuration: camera,
                        onEdit: { editingCamera = camera },
                        onDelete: { cameraToDelete = camera.id }
                    )
                }
            }
        }
        .fullScreenCover(isPresented: $showingAddCamera) {
            AddCameraView(cameraConfigService: cameraConfigService)
        }
    }
}
```

### AddCameraView

Camera configuration interface with VMS type selection:

```swift
struct AddCameraView: View {
    @Environment(\.dismiss) private var dismiss
    let cameraConfigService: CameraConfigServiceProtocol
    let onSave: (CameraConfig) -> Void
    
    @State private var cameraName = ""
    @State private var vmsType = VMSType.blueIris
    @State private var ipAddress = ""
    @State private var port = "2671"
    @State private var username = ""
    @State private var password = ""
    @State private var path = "/ui3.htm?t=live&group=Index"
    @State private var validationErrors: [String: String] = [:]
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.large) {
                identitySection
                connectionSection
                credentialsSection
            }
            .padding()
        }
        .navigationTitle("Add Camera")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { saveCamera() }
                    .disabled(!isValidConfiguration)
            }
        }
    }
}
```

### CameraWebView

Multi-VMS camera interface with adapter pattern:

```swift
struct CameraWebView: View {
    let config: CameraConfig?
    let credentials: CameraCredentials?
    @StateObject private var webViewStore = WebViewStore()
    @StateObject private var cameraService = CameraServiceCoordinator()
    
    var body: some View {
        Group {
            if let config = config, let credentials = credentials {
                WebView(webView: webViewStore.webView)
                    .task { await loadCamera() }
                    .refreshable { await refreshCamera() }
            } else {
                VStack {
                    Image(systemName: "video.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No Camera Configured")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private func loadCamera() async {
        guard let config = config, let credentials = credentials else { return }
        do {
            let connection = try await cameraService.prepareConnection(config: config, credentials: credentials)
            webViewStore.webView.load(URLRequest(url: connection.connectionURL))
        } catch {
            // Handle connection error
        }
    }
}
```

### EditCameraView

Edit existing camera configuration:

```swift
struct EditCameraView: View {
    @Environment(\.dismiss) private var dismiss
    let configuration: CameraConfig
    let cameraConfigService: CameraConfigServiceProtocol
    let onSave: (CameraConfig) -> Void
    
    @State private var cameraName: String
    @State private var vmsType: VMSType
    @State private var ipAddress: String
    @State private var port: String
    @State private var username: String
    @State private var password: String
    @State private var path: String
    @State private var validationErrors: [String: String] = [:]
    
    init(configuration: CameraConfig, cameraConfigService: CameraConfigServiceProtocol, onSave: @escaping (CameraConfig) -> Void) {
        self.configuration = configuration
        self.cameraConfigService = cameraConfigService
        self.onSave = onSave
        
        // Initialize state with existing configuration
        self._cameraName = State(initialValue: configuration.name)
        self._vmsType = State(initialValue: configuration.vmsType)
        self._ipAddress = State(initialValue: configuration.ipAddress)
        self._port = State(initialValue: String(configuration.port))
        self._username = State(initialValue: configuration.username)
        self._password = State(initialValue: "")
        self._path = State(initialValue: configuration.path)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.large) {
                identitySection
                connectionSection
                credentialsSection
            }
            .padding()
        }
        .navigationTitle("Edit Camera")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { saveCamera() }
                    .disabled(!isValidConfiguration)
            }
        }
    }
}
```

## 🔄 State Management

### Camera Configuration Service

Centralized camera configuration management:

```swift
class CameraConfigService: CameraConfigServiceProtocol {
    private let keychainService: KeychainServiceProtocol
    private let userDefaults = UserDefaults.standard
    
    func getAllCameras() -> [CameraConfig] {
        // Load all configured cameras from UserDefaults
        let cameraIds = userDefaults.stringArray(forKey: "configuredCameraIds") ?? []
        return cameraIds.compactMap { loadConfiguration(for: $0) }
    }
    
    func saveConfiguration(_ config: CameraConfig) throws {
        // Save camera configuration to UserDefaults
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        userDefaults.set(data, forKey: "camera_\(config.id)")
        
        // Update camera IDs list
        var cameraIds = userDefaults.stringArray(forKey: "configuredCameraIds") ?? []
        if !cameraIds.contains(config.id) {
            cameraIds.append(config.id)
            userDefaults.set(cameraIds, forKey: "configuredCameraIds")
        }
    }
    
    func deleteConfiguration(for cameraId: String) throws {
        // Remove camera configuration
        userDefaults.removeObject(forKey: "camera_\(cameraId)")
        
        // Remove from camera IDs list
        var cameraIds = userDefaults.stringArray(forKey: "configuredCameraIds") ?? []
        cameraIds.removeAll { $0 == cameraId }
        userDefaults.set(cameraIds, forKey: "configuredCameraIds")
        
        // Remove credentials from Keychain
        try keychainService.deleteCameraPassword(for: cameraId)
    }
}
```

### VMS Adapter Pattern

VMS-specific camera connection handling:

```swift
protocol CameraServiceProtocol {
    func prepareConnection(config: CameraConfig, credentials: CameraCredentials) async throws -> CameraConnection
    func validateConfiguration(config: CameraConfig) throws
    func getViewType(for config: CameraConfig) -> CameraViewType
}

class CameraServiceCoordinator: CameraServiceProtocol {
    func prepareConnection(config: CameraConfig, credentials: CameraCredentials) async throws -> CameraConnection {
        let adapter = getAdapter(for: config.vmsType)
        return try await adapter.prepareConnection(config: config, credentials: credentials)
    }
    
    private func getAdapter(for vmsType: VMSType) -> CameraServiceProtocol {
        switch vmsType {
        case .blueIris:
            return BlueIrisCameraAdapter()
        case .frigate:
            return FrigateCameraAdapter()
        case .rtspGeneric:
            return RTSPCameraAdapter()
        case .mjpegGeneric:
            return MJPEGCameraAdapter()
        case .genericWebView:
            return GenericWebViewAdapter()
        }
    }
}
```

### Notification-Based Updates

Real-time camera configuration updates:

```swift
extension Notification.Name {
    static let cameraConfigurationChanged = Notification.Name("cameraConfigurationChanged")
}

// In CameraManagementView
.onReceive(NotificationCenter.default.publisher(for: .cameraConfigurationChanged)) { _ in
    // Refresh camera list
    Task {
        await refreshCameras()
    }
}

// When saving camera configuration
NotificationCenter.default.post(name: .cameraConfigurationChanged, object: nil)
```

## 🌐 Blue Iris Integration

### Web View Configuration

WKWebView setup for Blue Iris UI:

```swift
private func configureWebView() {
    let configuration = WKWebViewConfiguration()
    configuration.allowsInlineMediaPlayback = true
    configuration.mediaTypesRequiringUserActionForPlayback = []
    
    webView = WKWebView(frame: .zero, configuration: configuration)
    webView.navigationDelegate = self
    webView.uiDelegate = self
}
```

### URL Building

Dynamic URL construction with embedded credentials:

```swift
func buildCameraURL() -> URL? {
    guard let credentials = loadCredentials() else { return nil }
    
    let urlString = "http://\(credentials.username):\(credentials.password)@\(config.ipAddress):\(config.port)/ui3.htm?t=live&group=Index"
    return URL(string: urlString)
}
```

### Real-time Updates

Web view refresh on configuration changes:

```swift
func updateConfiguration(_ newConfig: CameraConfig) {
    self.config = newConfig
    
    // Force web view reload with new configuration
    let uuid = UUID().uuidString
    webView.load(URLRequest(url: URL(string: "about:blank")!))
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.loadCameraFeed()
    }
}
```

## 🧪 Testing

### Unit Testing

Test camera configuration and credential management:

```swift
func testCameraConfigCreation() {
    let config = CameraConfig(
        id: "iris-one",
        ipAddress: "192.168.1.100",
        port: 2671,
        username: "admin"
    )
    
    XCTAssertEqual(config.ipAddress, "192.168.1.100")
    XCTAssertEqual(config.port, 2671)
    XCTAssertEqual(config.username, "admin")
}

func testCredentialStorage() {
    let credentials = CameraCredentials(
        cameraId: "iris-one",
        password: "secret123",
        lastUpdated: Date()
    )
    
    let success = cameraConfigService.storeCredentials(credentials)
    XCTAssertTrue(success)
    
    let retrieved = cameraConfigService.loadCredentials(for: "iris-one")
    XCTAssertEqual(retrieved?.password, "secret123")
}
```

### Integration Testing

Test web view integration:

```swift
func testWebViewLoading() {
    let config = createMockCameraConfig()
    let webView = CameraWebView(config: config)
    
    // Simulate web view loading
    webView.loadCameraFeed()
    
    // Verify URL construction
    XCTAssertNotNil(webView.currentURL)
    XCTAssertTrue(webView.currentURL?.absoluteString.contains("192.168.1.100") == true)
}
```

### UI Testing

Test user interactions:

```swift
func testCameraSettings() {
    let app = XCUIApplication()
    app.launch()
    
    // Navigate to camera tab
    app.tabBars.buttons["Camera"].tap()
    
    // Open settings
    app.buttons["Settings"].tap()
    
    // Enter Master PIN
    app.buttons["1"].tap()
    app.buttons["2"].tap()
    // ... continue with PIN entry
    
    // Configure camera
    app.textFields["IP Address"].tap()
    app.textFields["IP Address"].typeText("192.168.1.100")
    
    app.buttons["Save"].tap()
    
    // Verify configuration saved
    XCTAssertTrue(app.staticTexts["Configuration saved"].exists)
}
```

## 🔧 Configuration

### Camera Settings

**IP Address**: Blue Iris server IP address
**Port**: Blue Iris web port (default: 2671)
**Username**: Blue Iris login username
**Password**: Blue Iris login password (stored securely)
**Path**: Fixed Blue Iris path for optimal viewing

### Security Settings

**Master PIN**: Required for all camera settings access
**Credential Storage**: iOS Keychain for secure password storage
**Auto-login**: Embedded credentials for seamless access

## 🚀 Performance

### Optimization Strategies

- **Web View Lifecycle**: Automatic pause/resume for off-screen cameras
- **Configuration Caching**: Efficient configuration storage and retrieval
- **Memory Management**: Proper web view cleanup
- **Network Optimization**: Efficient credential embedding

### Monitoring

- **Load Times**: Track web view loading performance
- **Error Rates**: Monitor connection and authentication failures
- **Memory Usage**: Track web view memory consumption
- **User Interactions**: Monitor settings usage patterns

## 🔮 Future Enhancements

### Planned Features

- **Recording Controls**: Playback and motion detection
- **Multi-camera Grid**: 4+ camera simultaneous viewing
- **PTZ Controls**: Pan, tilt, zoom functionality
- **Motion Alerts**: Real-time motion detection notifications

### Technical Improvements

- **Offline Mode**: Local camera feed caching
- **Advanced Streaming**: H.265 support and adaptive bitrate
- **Custom Overlays**: User-defined camera overlays
- **Analytics**: Usage statistics and performance metrics

## 📁 File Structure

```
Camera/
├── Models/
│   ├── CameraConfig.swift           # Camera configuration model
│   ├── CameraCredentials.swift     # Camera credential model
│   ├── VMSType.swift              # VMS type enumeration
│   └── CameraConnection.swift     # Camera connection model
├── Services/
│   ├── CameraConfigService.swift  # Camera configuration management
│   ├── CameraServiceCoordinator.swift # VMS adapter coordinator
│   └── BlueIrisCameraAdapter.swift # Blue Iris specific adapter
├── Adapters/
│   └── BlueIris/
│       └── BlueIrisCameraAdapter.swift # Blue Iris VMS adapter
├── ViewModels/
│   └── CameraViewModel.swift       # Camera state management
├── Views/
│   ├── CameraWebView.swift        # Multi-VMS camera interface
│   ├── CameraGridView.swift       # Camera grid layout
│   └── CameraSettingsView.swift   # Legacy camera settings (deprecated)
└── README.md                      # This documentation
```

## 🔗 Navigation

- **[Camera Models](Models/README.md)** - Camera configuration and credential models
- **[Camera Services](Services/README.md)** - Camera configuration and VMS management
- **[Camera ViewModels](ViewModels/README.md)** - Camera state and configuration logic
- **[Camera Views](Views/README.md)** - Camera interface and management components
- **[Features Overview](../README.md)** - All app features
- **[Main App Architecture](../../README.md)** - Overall app architecture

---

The camera surveillance system provides comprehensive video streaming capabilities with multi-VMS support, dynamic camera management, user-defined camera names, and secure credential management with Master PIN protection.
