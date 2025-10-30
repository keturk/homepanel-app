# Settings Views

This directory contains the SwiftUI user interface components for settings management, featuring a modern split-view architecture with resizable panes, organized menu system, and specialized management interfaces for cameras, devices, and security.

## 🎨 Core Views

### SettingsSplitView

Main settings interface with modern split-pane architecture and resizable divider.

```swift
struct SettingsSplitView: View {
    @ObservedObject var config: AppConfiguration
    @ObservedObject var pinService: PINManagementService
    let cameraConfigService: CameraConfigService
    @StateObject var automationViewModel: AutomationViewModel
    @StateObject var settingsContext = SettingsContext()
    @ObservedObject var hubConfigStore: HubConfigurationStore
    
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

**Key Features:**
- **Resizable Divider**: Draggable divider with UserDefaults persistence
- **Menu Navigation**: 6 organized menu items with icons and descriptions
- **Save/Discard Pattern**: Coordinated state management across all settings
- **Toast Notifications**: User feedback for all operations

### CameraManagementView

Dynamic camera configuration and management interface with full CRUD operations.

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

**Key Features:**
- **Multi-Camera Support**: Up to 2 cameras with user-defined names
- **VMS Type Selection**: Support for Blue Iris, Frigate, RTSP, MJPEG, Generic Web View
- **Full CRUD Operations**: Add, edit, delete camera configurations
- **Secure Credentials**: Master PIN protection with Keychain storage
- **Real-time Configuration**: Dynamic camera settings with validation

**Logging Pattern:**
```swift
// Camera deletion with proper logging
do {
    DebugLogger.log("Attempting to delete camera: \(cameraId)", feature: .camera)
    try cameraConfigService.deleteConfiguration(for: cameraId)
    DebugLogger.success("Camera deleted successfully", feature: .camera)
} catch {
    DebugLogger.error("Failed to delete camera: \(error)", feature: .camera)
}
```

### DeviceSelectionManagementView

Device and scene selection interface with dual-pane design.

```swift
struct DeviceSelectionManagementView: View {
    @ObservedObject var viewModel: AutomationViewModel
    @EnvironmentObject var settingsContext: SettingsContext
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

**Key Features:**
- **Dual-Pane Selection**: 50/50 split interface for device selection
- **Hub Organization**: Devices organized by hub and room
- **Drag-to-Order**: Reorder selected devices with visual feedback
- **Search & Filter**: Real-time search and filtering capabilities
- **Placeholder Support**: Graceful handling of missing or disconnected devices

### DeviceSelectionSheet

Dual-pane device selection interface with hub and room organization.

```swift
struct DeviceSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AutomationViewModel
    
    @State private var selectedDeviceNames: Set<String> = []
    @State private var orderedDeviceNames: [String] = []
    @State private var allDevices: [Device] = []
    @State private var hubConfigurations: [HubConfiguration] = []
    @State private var expandedHubs: Set<String> = []
    @State private var expandedRooms: Set<String> = []
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Cancel/Save buttons
            headerView
            
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left: Device Selection
                    deviceSelectionPane
                        .frame(width: geometry.size.width * 0.5)
                    
                    Divider()
                    
                    // Right: Selected & Ordered
                    selectedDevicesPane
                        .frame(width: geometry.size.width * 0.5)
                }
            }
        }
        .frame(maxWidth: 1600)
        .task { await loadDevices() }
    }
}
```

**Key Features:**
- **Two-Pane Interface**: 50/50 split for device selection and ordering
- **Hub Organization**: Devices grouped by hub with expand/collapse
- **Room Organization**: Devices further organized by room
- **Search & Filter**: Real-time search across all devices
- **Drag-to-Order**: Reorder selected devices with visual feedback
- **Placeholder Support**: Handle missing or disconnected devices

### PINManagementView

PIN security system administration with SettingsContext integration.

```swift
struct PINManagementView: View {
    @ObservedObject var pinService: PINManagementService
    @EnvironmentObject var settingsContext: SettingsContext
    @State private var showingAddPIN = false
    @State private var showingChangeMasterPIN = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Master PIN Section
                masterPINSection
                
                // User PINs Section
                userPINsSection
                
                // Lockout Management Section
                lockoutSection
            }
            .padding()
        }
        .navigationTitle("PIN Management")
        .sheet(isPresented: $showingAddPIN) {
            AddPINView(pinService: pinService)
        }
        .sheet(isPresented: $showingChangeMasterPIN) {
            ChangeMasterPINView(pinService: pinService)
        }
    }
}
```

**Key Features:**
- **Master PIN Management**: Setup and change Master PIN
- **User PIN Management**: Add, edit, and remove user PINs
- **Lockout Management**: Reset lockout states and manage security
- **SettingsContext Integration**: Coordinated state management
- **PIN Usage Tracking**: Track PIN usage and statistics

## 🎨 UI Components

### Camera Configuration Form

Input fields for camera configuration with VMS type selection:

```swift
private var cameraConfigurationSection: some View {
    Section("Camera Configuration") {
        // Camera Name
        HStack {
            Text("Camera Name")
            Spacer()
            TextField("Front Door", text: $cameraName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        
        // VMS Type Selection
        HStack {
            Text("Camera System")
            Spacer()
            Picker("VMS Type", selection: $vmsType) {
                ForEach(VMSType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
        
        // Connection Details
        HStack {
            Text("IP Address")
            Spacer()
            TextField("192.168.1.100", text: $ipAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numbersAndPunctuation)
        }
        
        HStack {
            Text("Port")
            Spacer()
            TextField("\(vmsType.defaultPort)", text: $port)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
        }
        
        // Credentials
        HStack {
            Text("Username")
            Spacer()
            TextField("admin", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        
        HStack {
            Text("Password")
            Spacer()
            SecureField("Enter password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}
```

### PIN Entry Interface

Secure PIN entry with validation:

```swift
struct PINEntryHeaderView: View {
    let title: String
    let subtitle: String
    let isSecure: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.buttonSpacing) {
            Image(systemName: isSecure ? "lock.fill" : "person.fill")
                .font(.system(size: DesignSystem.FontSize.large))
                .foregroundColor(isSecure ? .red : .blue)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
```

### Settings Menu System

Organized menu structure with icons and descriptions:

```swift
enum SettingsMenuItem: String, CaseIterable {
    case pinManagement = "Alarm Users"
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

struct SettingsRowView: View {
    let item: SettingsMenuItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .primary)
                    .frame(width: 24)
                
                Text(item.rawValue)
                    .font(.headline)
                    .foregroundColor(isSelected ? .blue : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

## 🔄 State Management

### Form Validation

Real-time validation of configuration inputs:

```swift
private func validateInput() {
    let ipValid = IPValidator.isValid(ipAddress)
    let portValid = Int(port).map { $0 > 0 && $0 <= 65535 } ?? false
    let nameValid = !hubName.isEmpty
    
    isFormValid = ipValid && portValid && nameValid
}

private func validatePINInput() {
    let pinValid = enteredPIN.count == 6 && enteredPIN.allSatisfy { $0.isNumber }
    let nameValid = !pinName.isEmpty
    
    isFormValid = pinValid && nameValid
}
```

### Settings Persistence

Save configuration changes with error handling:

```swift
private func saveConfiguration() {
    do {
        try appConfiguration.save()
        try hubManager.saveHubs()
        try pinService.saveUserPINs()
        
        errorMessage = nil
        showingSuccessMessage = true
    } catch {
        errorMessage = "Failed to save configuration: \(error.localizedDescription)"
    }
}

private func resetToDefaults() {
    appConfiguration.resetToDefaults()
    hubManager.clearHubs()
    pinService.clearUserPINs()
    
    saveConfiguration()
}
```

## 🎨 Design System Integration

### Section Headers

Consistent section header styling:

```swift
private var sectionHeader: some View {
    HStack {
        Image(systemName: "gear")
            .foregroundColor(.blue)
        Text("Configuration")
            .font(.headline)
            .fontWeight(.semibold)
    }
    .padding(.vertical, DesignSystem.Spacing.buttonSpacing)
}
```

### Status Indicators

Visual status indicators for various states:

```swift
private var hubStatusIndicator: some View {
    HStack {
        Circle()
            .fill(hub.isConnected ? Color.green : Color.red)
            .frame(width: 8, height: 8)
        
        Text(hub.isConnected ? "Connected" : "Disconnected")
            .font(.caption)
            .foregroundColor(hub.isConnected ? .green : .red)
    }
}
```

### Action Buttons

Consistent action button styling:

```swift
private var actionButtons: some View {
    Section {
        Button("Save Configuration") {
            saveConfiguration()
        }
        .disabled(!isFormValid)
        
        Button("Test Connection") {
            testConnection()
        }
        .disabled(!isFormValid)
        
        Button("Reset to Defaults", role: .destructive) {
            showingResetAlert = true
        }
    }
}
```

## 🧪 Testing

### UI Testing

Test user interactions and form validation:

```swift
func testHubConfiguration() {
    let app = XCUIApplication()
    app.launch()
    
    // Navigate to settings
    app.buttons["Settings"].tap()
    
    // Open hub management
    app.buttons["Manage Hubs"].tap()
    
    // Add new hub
    app.buttons["Add Hub"].tap()
    
    // Fill hub form
    app.textFields["IP Address"].tap()
    app.textFields["IP Address"].typeText("192.168.1.100")
    
    app.textFields["Port"].tap()
    app.textFields["Port"].typeText("3480")
    
    app.textFields["Name"].tap()
    app.textFields["Name"].typeText("Vera Hub")
    
    // Save hub
    app.buttons["Save"].tap()
    
    // Verify hub was added
    XCTAssertTrue(app.staticTexts["Vera Hub"].exists)
}

func testPINManagement() {
    let app = XCUIApplication()
    app.launch()
    
    // Navigate to PIN management
    app.buttons["Settings"].tap()
    app.buttons["PIN Management"].tap()
    
    // Add new PIN
    app.buttons["Add PIN"].tap()
    
    // Fill PIN form
    app.textFields["PIN Name"].tap()
    app.textFields["PIN Name"].typeText("Test PIN")
    
    app.secureFields["Enter PIN"].tap()
    app.secureFields["Enter PIN"].typeText("123456")
    
    // Save PIN
    app.buttons["Save"].tap()
    
    // Verify PIN was added
    XCTAssertTrue(app.staticTexts["Test PIN"].exists)
}
```

### Accessibility Testing

Test accessibility features:

```swift
func testAccessibility() {
    let app = XCUIApplication()
    app.launch()
    
    // Test settings navigation
    let settingsButton = app.buttons["Settings"]
    XCTAssertTrue(settingsButton.isAccessibilityElement)
    XCTAssertEqual(settingsButton.label, "Settings")
    
    // Test form accessibility
    let ipField = app.textFields["IP Address"]
    XCTAssertTrue(ipField.isAccessibilityElement)
    XCTAssertEqual(ipField.label, "IP Address")
}
```

## 🚀 Performance

### Optimization Strategies

- **Lazy Loading**: Load settings sections on demand
- **Form Validation**: Efficient real-time validation
- **State Caching**: Cache frequently accessed settings
- **Memory Management**: Proper cleanup of resources

### Responsive Design

Adapt to different screen sizes:

```swift
private var formColumns: Int {
    UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1
}

private var sectionSpacing: CGFloat {
    UIDevice.current.userInterfaceIdiom == .pad ? 20 : 16
}
```

## 📁 Files

### Main Settings Interface
- **SettingsSplitView.swift** - Main split-view interface with resizable divider
- **SettingsTabView.swift** - Legacy settings interface (deprecated)
- **SettingsView.swift** - Legacy settings interface (deprecated)

### Camera Management
- **CameraManagement/AddCameraView.swift** - Add new camera interface
- **CameraManagement/CameraManagementView.swift** - Camera list and management
- **CameraManagement/EditCameraView.swift** - Edit existing camera

### Device Selection
- **DeviceSelection/DeviceSelectionManagementView.swift** - Device management interface
- **DeviceSelection/DeviceSelectionSheet.swift** - Dual-pane selection sheet

### Hub Management
- **HubManagement/HubManagementView.swift** - Hub list and management
- **HubManagement/AddHubView.swift** - Add new hub interface
- **HubManagement/EditHubView.swift** - Edit existing hub
- **HubManagement/HubRowView.swift** - Hub list row component
- **HubManagement/PrimaryHubRowView.swift** - Primary hub row component

### PIN Management
- **PINManagement/PINManagementView.swift** - PIN list and management
- **PINManagement/AddPINView.swift** - Add new PIN interface
- **PINManagement/ChangeMasterPINView.swift** - Change Master PIN interface
- **PINManagement/MasterPINEntryView.swift** - Master PIN entry interface
- **PINManagement/StandardPINEntryView.swift** - Standard PIN entry interface
- **PINManagement/PINRowView.swift** - PIN list row component

### Legacy Components
- **UnifiedCameraSettingsView.swift** - Legacy camera settings (deprecated)

## 🔗 Navigation

- **[Settings System](../README.md)** - Main settings system documentation
- **[Features Overview](../../README.md)** - All app features
- **[Main App Architecture](../../../README.md)** - Overall app architecture

---

These SwiftUI views provide intuitive, secure, and responsive user interfaces for comprehensive settings management with a modern split-view architecture, organized menu system, and specialized management interfaces for cameras, devices, and security.
