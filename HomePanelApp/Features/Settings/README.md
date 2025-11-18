# Settings Management

The settings management system provides comprehensive configuration and administration interfaces for the Home Panel App, featuring a modern split-view architecture with resizable panes, organized menu structure, and specialized management interfaces for cameras, devices, and security.

## ⚙️ Overview

The settings system enables users to configure all aspects of the app through an intuitive split-pane interface, providing centralized administration for Vera Hub connections, camera management, device selection, and security settings.

## 🏗️ Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────────┐
│                  Settings Management Architecture              │
├─────────────────────────────────────────────────────────────────┤
│  SettingsSplitView  │  SettingsContext  │  Menu System         │
│  CameraManagement   │  DeviceSelection  │  PINManagement       │
│  HubManagement      │  ResetLockouts    │  ClearAllSettings    │
└─────────────────┬─────────────────┬─────────────────┬───────────┘
                  │                 │                 │
┌─────────────────▼─────────────────▼─────────────────▼───────────┐
│                    Data Models                                │
├─────────────────────────────────────────────────────────────────┤
│  AppConfiguration  │  CameraConfig  │  HubConfiguration       │
│  PINData           │  Device        │  SettingsMenuItem       │
└─────────────────────────────────────────────────────────────────┘
```

### Split-View Architecture

The settings system uses a modern split-pane interface with resizable divider:

```swift
struct SettingsSplitView: View {
    @State private var leftPaneWidth: CGFloat = 300
    @State private var selectedSetting: SettingsMenuItem?
    @State private var showingSaveDiscardDialog = false
    
    var body: some View {
        HStack(spacing: 0) {
            leftPane                    // Settings menu
            resizableDivider           // Draggable divider
            rightPane                  // Selected setting detail
        }
    }
}
```

### State Management

The settings system uses MVVM pattern with reactive state management and context-based state coordination:

```swift
@MainActor
class SettingsContext: ObservableObject {
    @Published var hasUnsavedChanges = false
    @Published var isSaving = false
    @Published var toastMessage: ToastMessage?
    
    func save() async {
        // Coordinated save across all settings
    }
    
    func discard() {
        // Discard unsaved changes
    }
}

enum SettingsMenuItem: String, CaseIterable {
    case pinManagement = "PIN Management"
    case cameraSettings = "Cameras"
    case devicesAndScenes = "Devices & Scenes"
    case hubManagement = "Automation Hubs"
    case resetLockouts = "Reset Lockouts"
    case clearAllSettings = "Clear All Settings"
}
```

## 🔧 Core Features

### Split-View Interface

Modern resizable split-pane interface with organized menu system:

- **Resizable Divider**: Draggable divider with UserDefaults persistence
- **Menu Navigation**: 7 organized menu items with icons and descriptions
- **Save/Discard Pattern**: Coordinated state management across all settings
- **Toast Notifications**: User feedback for all operations

### Camera Management

Dynamic camera configuration and management system:

- **Multi-Camera Support**: Up to 2 cameras with user-defined names
- **VMS Type Selection**: Support for Blue Iris, Frigate, RTSP, MJPEG, Generic Web View
- **Full CRUD Operations**: Add, edit, delete camera configurations
- **Secure Credentials**: Master PIN protection with Keychain storage
- **Real-time Configuration**: Dynamic camera settings with validation

### Device Selection Management

Comprehensive device and scene selection interface:

- **Dual-Pane Selection**: 50/50 split interface for device selection
- **Hub Organization**: Devices organized by hub and room
- **Drag-to-Order**: Reorder selected devices with visual feedback
- **Search & Filter**: Real-time search and filtering capabilities
- **Placeholder Support**: Graceful handling of missing or disconnected devices

### Hub Management

Comprehensive Vera Hub configuration and management:

- **Hub Discovery**: Automatic hub detection on local network
- **Hub Configuration**: IP address, port, and authentication settings
- **Hub Status**: Connection status monitoring and health checks
- **Multi-Hub Support**: Manage multiple Vera hubs simultaneously

### Alarm Users

Advanced alarm user security system administration:

- **Master PIN Setup**: Initial Master PIN configuration
- **User PIN Management**: Add, edit, and remove user PINs
- **PIN Security**: Secure PIN storage and validation
- **Lockout Management**: Reset lockout states and manage security

### Backup & Restore

Comprehensive settings backup and restore functionality:

- **Export Settings**: Export all app settings to a JSON file
- **Import Settings**: Restore all settings from a backup file
- **Complete Backup**: Includes hub configs, camera settings, PINs, scenes, devices, and destinations
- **File Sharing**: Export via Files app, AirDrop, email, or other sharing methods
- **Secure Import**: File picker with confirmation dialog before importing
- **Data Persistence**: Allows settings to survive app deletion and reinstallation

**Backup Includes:**
- Hub configurations (all hubs with connection details)
- Camera configurations (IP, port, credentials, VMS type)
- Camera passwords (securely stored)
- Master PIN and user PINs (hashed, so same PINs work after restore)
- Scene mappings (hub-scoped scene name to ID mappings)
- Selected device names (ordered list)
- Primary hub ID
- Favorite destinations (location data)

**Usage:**
```swift
// Export settings
let backupURL = try await backupService.exportAllSettings(
    hubConfigStore: hubConfigStore,
    cameraConfigService: cameraConfigService,
    pinService: pinService,
    appConfig: appConfig,
    destinationStore: destinationStore
)

// Import settings
try await backupService.importSettings(
    from: backupURL,
    hubConfigStore: hubConfigStore,
    cameraConfigService: cameraConfigService,
    pinService: pinService,
    appConfig: appConfig,
    destinationStore: destinationStore
)
```

### Administrative Functions

System administration and maintenance:

- **Lockout Reset**: Clear all PIN attempt counters and lockout timers
- **Settings Reset**: Complete settings reset with Master PIN restoration
- **Backup & Restore**: Export and import all settings via JSON files (see Backup & Restore section above)

## 🎨 User Interface

### SettingsSplitView

Modern split-pane interface with resizable divider:

```swift
struct SettingsSplitView: View {
    @State private var selectedSetting: SettingsMenuItem? = .pinManagement
    @State private var leftPaneWidth: CGFloat = 300
    @State private var showingSaveDiscardDialog = false
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                leftPane                    // Settings menu
                    .frame(width: leftPaneWidth)
                
                resizableDivider           // Draggable divider
                
                rightPane                  // Selected setting detail
                    .frame(maxWidth: .infinity)
            }
        }
        .alert("Unsaved Changes", isPresented: $showingSaveDiscardDialog) {
            Button("Save") { /* Save changes */ }
            Button("Discard", role: .destructive) { /* Discard changes */ }
            Button("Cancel", role: .cancel) { /* Cancel navigation */ }
        }
    }
}
```

### Menu System

Organized menu structure with 6 main categories:

```swift
enum SettingsMenuItem: String, CaseIterable {
    case pinManagement = "PIN Management"
    case cameraSettings = "Cameras"
    case devicesAndScenes = "Devices & Scenes"
    case hubManagement = "Automation Hubs"
    case resetLockouts = "Reset Lockouts"
    case clearAllSettings = "Clear All Settings"
    
    var icon: String {
        switch self {
        case .pinManagement: return "key.fill"
        case .cameraSettings: return "video.fill"
        case .devicesAndScenes: return "lightbulb.fill"
        case .hubManagement: return "network"
        case .resetLockouts: return "lock.open"
        case .clearAllSettings: return "exclamationmark.triangle.fill"
        }
    }
}
```

### CameraManagementView

Dynamic camera configuration and management:

```swift
struct CameraManagementView: View {
    @ObservedObject var cameraConfigService: CameraConfigService
    @State private var showingAddCamera = false
    @State private var editingCamera: CameraConfig?
    
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
                        onDelete: { /* Delete camera */ }
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

### DeviceSelectionManagementView

Device and scene selection interface:

```swift
struct DeviceSelectionManagementView: View {
    @ObservedObject var viewModel: AutomationViewModel
    @State private var showingDeviceSelection = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Configure Devices Button
                Button(action: { showingDeviceSelection = true }) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Configure Devices & Scenes")
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                // Selected Devices List
                ForEach(Array(viewModel.appConfig.selectedDeviceNames.enumerated()), id: \.offset) { index, deviceName in
                    HStack {
                        Text("\(index + 1).")
                        Text(deviceName)
                        Spacer()
                        if let device = viewModel.devices.first(where: { $0.name == deviceName }) {
                            Image(systemName: device.type.icon)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .fullScreenCover(isPresented: $showingDeviceSelection) {
            DeviceSelectionSheet(viewModel: viewModel)
        }
    }
}
```

### PINManagementView

PIN security system administration:

```swift
struct PINManagementView: View {
    @StateObject private var pinService: PINManagementService
    @State private var showingAddPIN = false
    @State private var showingChangeMasterPIN = false
    
    var body: some View {
        NavigationView {
            List {
                masterPINSection
                userPINsSection
                lockoutSection
            }
            .navigationTitle("PIN Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add PIN") {
                        showingAddPIN = true
                    }
                }
            }
            .sheet(isPresented: $showingAddPIN) {
                AddPINView(pinService: pinService)
            }
            .sheet(isPresented: $showingChangeMasterPIN) {
                ChangeMasterPINView(pinService: pinService)
            }
        }
    }
}
```

## 🔐 Security Features

### Master PIN Protection

Secure access to sensitive settings:

- **Settings Access**: Master PIN required for security settings
- **PIN Management**: Master PIN required for PIN operations
- **Hub Configuration**: Master PIN required for hub management
- **Data Export**: Master PIN required for data export

## 🔍 Logging Standards

All Settings feature logging uses the centralized DebugLogger utility:

- **Use DebugLogger**: All logging must use DebugLogger methods
- **No Direct print()**: Never use print() statements directly
- **Feature Flag**: Use `.settings` or appropriate feature flag
- **Log Levels**: Choose appropriate level (.log, .success, .error, .warning)

Example:
```swift
DebugLogger.log("Camera configuration loaded", feature: .settings)
DebugLogger.success("Hub saved successfully", feature: .settings)
DebugLogger.error("Failed to load PINs: \(error)", feature: .settings)
```

### Secure Storage

iOS Keychain integration for sensitive data:

- **PIN Storage**: Secure PIN hash and salt storage
- **Hub Credentials**: Secure hub authentication storage
- **App Secrets**: Secure app-specific data storage
- **Cross-Device Sync**: iCloud Keychain synchronization

### Data Protection

Comprehensive data protection measures:

- **Encryption**: All sensitive data encrypted at rest
- **Access Control**: Role-based access to settings
- **Audit Logging**: Security event logging
- **Data Cleanup**: Secure data deletion

## 🔄 State Management

### SettingsContext Coordination

Centralized state management across all settings:

```swift
@MainActor
class SettingsContext: ObservableObject {
    @Published var hasUnsavedChanges = false
    @Published var isSaving = false
    @Published var toastMessage: ToastMessage?
    
    func save() async {
        isSaving = true
        // Coordinated save across all settings components
        await performSave()
        isSaving = false
        hasUnsavedChanges = false
    }
    
    func discard() {
        // Discard all unsaved changes
        hasUnsavedChanges = false
    }
    
    private func performSave() async {
        // Save all settings components
    }
}
```

### Resizable Divider State

Persistent divider position with UserDefaults:

```swift
struct SettingsSplitView: View {
    @State private var leftPaneWidth: CGFloat = 300
    private let userDefaultsKey = "settingsSplitViewLeftPaneWidth"
    
    var body: some View {
        // ... view implementation
        .onAppear {
            let savedWidth = UserDefaults.standard.double(forKey: userDefaultsKey)
            if savedWidth > 0 {
                leftPaneWidth = max(minimumLeftPaneWidth, min(savedWidth, maxWidth))
            } else {
                leftPaneWidth = screenWidth / 3
            }
        }
    }
    
    private func saveDividerPosition() {
        UserDefaults.standard.set(leftPaneWidth, forKey: userDefaultsKey)
    }
}
```

### Save/Discard Dialog Pattern

Coordinated navigation with unsaved changes protection:

```swift
private func navigateToSetting(_ newSetting: SettingsMenuItem) {
    if settingsContext.hasUnsavedChanges && selectedSetting != newSetting {
        showingSaveDiscardDialog = true
        pendingNavigation = {
            selectedSetting = newSetting
        }
    } else {
        selectedSetting = newSetting
    }
}
```

## 🧪 Testing

### Unit Testing

Test settings logic in isolation:

```swift
func testHubManagement() {
    let hubManager = HubManager()
    let hub = HubConfiguration(ipAddress: "192.168.1.100", port: 3480)
    
    hubManager.addHub(hub)
    XCTAssertEqual(hubManager.hubs.count, 1)
    
    hubManager.removeHub(hub.id)
    XCTAssertEqual(hubManager.hubs.count, 0)
}

func testPINManagement() {
    let pinService = PINManagementService()
    
    let success = pinService.setMasterPIN("123456")
    XCTAssertTrue(success)
    
    let isValid = pinService.verifyPIN("123456")
    XCTAssertTrue(isValid)
}
```

### Integration Testing

Test settings with real services:

```swift
func testConfigurationSave() {
    let viewModel = SettingsViewModel()
    
    viewModel.appConfiguration.veraHubIP = "192.168.1.100"
    viewModel.saveConfiguration()
    
    let loadedConfig = AppConfiguration.load()
    XCTAssertEqual(loadedConfig.veraHubIP, "192.168.1.100")
}
```

## 🔧 Configuration

### App Settings

General app configuration options:

- **Vera Hub IP**: Primary Vera Hub IP address
- **Refresh Interval**: Device state polling frequency
- **Timeout Settings**: Network request timeouts
- **UI Preferences**: Display and interaction preferences

### Security Settings

Security configuration options:

- **PIN Requirements**: PIN length and complexity requirements
- **Lockout Settings**: Lockout duration and retry limits
- **Session Timeout**: Automatic session expiration
- **Biometric Settings**: Face ID/Touch ID preferences

### Network Settings

Network configuration options:

- **Connection Timeout**: Network request timeout duration
- **Retry Logic**: Automatic retry configuration
- **Proxy Settings**: Network proxy configuration
- **SSL Settings**: SSL/TLS configuration

## 🚀 Performance

### Optimization Strategies

- **Lazy Loading**: Load settings on demand
- **Caching**: Cache frequently accessed settings
- **Background Processing**: Non-blocking configuration updates
- **Memory Management**: Efficient resource usage

### Monitoring

- **Load Times**: Track settings loading performance
- **Save Times**: Monitor configuration save performance
- **Error Rates**: Track settings operation failures
- **User Interactions**: Monitor settings usage patterns

## 🔮 Future Enhancements

### Planned Features

- **Advanced Security**: Multi-factor authentication
- **User Profiles**: Multiple user configurations
- **Backup/Restore**: Configuration backup and restore
- **Analytics**: Settings usage analytics

### Technical Improvements

- **Settings Sync**: Cross-device settings synchronization
- **Validation**: Advanced settings validation
- **Migration**: Settings migration between versions
- **Performance**: Optimized settings loading and saving

## 📁 File Structure

```
Settings/
├── Views/
│   ├── SettingsSplitView.swift          # Main split-view interface
│   ├── CameraManagement/               # Camera configuration views
│   │   ├── AddCameraView.swift         # Add new camera
│   │   ├── CameraManagementView.swift # Camera list and management
│   │   └── EditCameraView.swift        # Edit existing camera
│   ├── DeviceSelection/               # Device selection views
│   │   ├── DeviceSelectionManagementView.swift # Device management interface
│   │   └── DeviceSelectionSheet.swift  # Dual-pane selection sheet
│   ├── HubManagement/                 # Hub configuration views
│   │   ├── HubManagementView.swift    # Hub list and management
│   │   ├── AddHubView.swift           # Add new hub
│   │   └── EditHubView.swift          # Edit existing hub
│   └── PINManagement/                 # PIN security views
│       ├── PINManagementView.swift    # PIN list and management
│       ├── AddPINView.swift           # Add new PIN
│       └── ChangeMasterPINView.swift  # Change Master PIN
└── README.md                          # This documentation
```

## 🔗 Navigation

- **[Settings Views](Views/README.md)** - Detailed view documentation
- **[Features Overview](../README.md)** - All app features
- **[Main App Architecture](../../README.md)** - Overall app architecture
- **[Core Infrastructure](../../Core/README.md)** - Shared infrastructure
- **[Shared Components](../../Shared/README.md)** - Reusable components

---

The settings management system provides comprehensive configuration and administration capabilities for the Home Panel App with a modern split-view architecture, organized menu system, and specialized management interfaces for cameras, devices, and security.
