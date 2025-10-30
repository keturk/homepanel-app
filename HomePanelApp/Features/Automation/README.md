# Automation System

The automation system provides multi-hub device control and scene management for smart home automation, featuring adaptive grid layouts, device selection management, notification-based updates, and robust state management with placeholder device support.

## 🤖 Overview

The automation system enables interactive control and monitoring of smart devices and scenes across multiple Vera hubs, with adaptive grid layout, comprehensive device selection interface, Master PIN protection, and robust device state management with graceful handling of missing or disconnected devices.

## 🏗️ Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────────┐
│                  Automation System Architecture                │
├─────────────────────────────────────────────────────────────────┤
│  AutomationTabView  │  AutomationViewModel  │  HubServiceProtocol│
│  DeviceCardView     │  RoomMappingService  │  HubServiceCoordinator│
│  DeviceSelectionManagementView │  DeviceSelectionSheet │  NotificationCenter│
└─────────────────┬─────────────────┬─────────────────┬───────────┘
                  │                 │                 │
┌─────────────────▼─────────────────▼─────────────────▼───────────┐
│                    Data Models                                │
├─────────────────────────────────────────────────────────────────┤
│  Device  │  DeviceState  │  ConfiguredItem  │  HubConfiguration│
│  PlaceholderDevice │  DisconnectedDevice │  DeviceAction    │
└─────────────────────────────────────────────────────────────────┘
```

### State Management

The automation system uses MVVM pattern with reactive state management:

```swift
@MainActor
class AutomationViewModel: ObservableObject {
    @Published var devices: [Device] = []
    @Published var isLoading = false
    @Published var selectedHub: String = ""
    @Published var errorMessage: String?
    @Published var showSettings = false
    @Published var registeredHubs: [HubConfiguration] = []
    
    private let hubService: HubServiceProtocol
    let appConfig: AppConfigurationProtocol
    let roomMappingService: RoomMappingService
    private var cancellables = Set<AnyCancellable>()
    
    init(hubService: HubServiceProtocol, appConfig: AppConfigurationProtocol) {
        self.hubService = hubService
        self.appConfig = appConfig
        
        // Use shared RoomMappingService from HubServiceCoordinator
        if let coordinator = hubService as? HubServiceCoordinator {
            self.roomMappingService = coordinator.roomMappingService
        } else {
            self.roomMappingService = RoomMappingService(hubService: hubService)
        }
        
        // Subscribe to state changes for automatic updates
        hubService.stateChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleStateChange(event)
            }
            .store(in: &cancellables)
    }
}
```

## 🔧 Core Features

### Multi-Hub Device Control

Interactive control of smart devices across multiple Vera hubs:

- **Device Types**: Lights, switches, dimmers, sensors, locks, thermostats
- **Hub Support**: Vera Lite, Vera Edge, Vera Plus
- **Real-time Control**: Toggle, dim, lock/unlock operations
- **State Monitoring**: Live device state updates
- **Placeholder Support**: Graceful handling of missing or disconnected devices

### Device Selection Management

Comprehensive device and scene selection interface:

- **Dual-Pane Selection**: 50/50 split interface for device selection
- **Hub Organization**: Devices organized by hub with expand/collapse
- **Room Organization**: Devices further organized by room
- **Search & Filter**: Real-time search across all devices
- **Drag-to-Order**: Reorder selected devices with visual feedback
- **Placeholder Support**: Handle missing or disconnected devices

### Scene Activation

Pre-configured scene execution:

- **Scene Discovery**: Automatic scene detection from Vera Hub
- **One-tap Activation**: Simple scene execution
- **Multi-hub Scenes**: Scenes across different hubs
- **State Feedback**: Visual confirmation of scene execution

### Adaptive Grid Layout

Responsive grid system for different screen sizes:

- **iPad Pro 12.9"+**: 4 columns
- **iPad Mini/Air**: 3 columns  
- **Smaller Screens**: 2 columns
- **Dynamic Sizing**: Automatic adjustment based on device

### Notification-Based Updates

Event-driven device selection updates:

- **NotificationCenter**: Real-time updates for device selection changes
- **Automatic Refresh**: UI updates when device selection changes
- **State Synchronization**: Coordinated updates across all views
- **Performance Optimization**: Efficient update mechanisms

### HubServiceProtocol Integration

Modern hub service integration for device control:

- **Unified Hub Service**: Uses HubServiceProtocol for device control
- **RoomMappingService**: Device organization and room coordination
- **Event-Driven Updates**: Real-time state changes through Combine publishers
- **Placeholder Device Support**: Graceful handling of missing devices
- **Multi-Hub Coordination**: Seamless device control across multiple hubs

## 🔐 Security Features

### Master PIN Protection

Secure access to automation settings:

- **Settings Access**: Master PIN required for configuration
- **Device Management**: PIN protection for device operations
- **Hub Configuration**: Secure hub management

### Device Filtering

Configurable device name filtering:

- **Exact Matching**: Precise device name matching
- **Partial Matching**: Flexible name filtering
- **Filter Persistence**: Saved filter preferences
- **Real-time Filtering**: Instant filter application

## 🎨 User Interface

### AutomationTabView

Main automation interface with device grid and controls:

```swift
struct AutomationTabView: View {
    @StateObject private var viewModel: AutomationViewModel
    @State private var gridColumns = 3
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.devices.isEmpty {
                emptyStateView
            } else {
                deviceGridView
            }
            
            settingsButton
        }
        .onAppear {
            calculateGridColumns()
            viewModel.startPolling()
        }
        .onDisappear {
            viewModel.stopPolling()
        }
    }
}
```

### DeviceCardView

Individual device control component:

```swift
struct DeviceCardView: View {
    let device: Device
    let onToggle: () -> Void
    let onDim: (Int) -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.buttonSpacing) {
            deviceIcon
            deviceName
            deviceState
            controlButtons
        }
        .padding()
        .background(deviceBackgroundColor)
        .cornerRadius(DesignSystem.CornerRadius.card)
        .shadow(radius: 2)
    }
}
```

### DeviceSelectionManagementView

Device and scene selection interface with dual-pane design:

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

### DeviceSelectionSheet

Dual-pane device selection interface with hub and room organization:

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

## 🔄 State Management

### Device Selection Updates

Notification-based device selection updates:

```swift
extension Notification.Name {
    static let deviceSelectionChanged = Notification.Name("deviceSelectionChanged")
}

// In AutomationTabView
.onReceive(NotificationCenter.default.publisher(for: .deviceSelectionChanged)) { _ in
    DebugLogger.log("AutomationTabView received deviceSelectionChanged notification", feature: .automation)
    Task {
        await viewModel.loadDevices()
    }
}

// When device selection changes
NotificationCenter.default.post(name: .deviceSelectionChanged, object: nil)
```

### Device State Polling

Real-time device state updates with placeholder support:

```swift
func loadDevices() async {
    isLoading = true
    errorMessage = nil

        // Refresh room mappings first (with timeout)
        do {
            try await withTimeout(seconds: TimeoutConfiguration.automationRoomMapping) { [self] in
                await roomMappingService.refreshRoomMappings()
            }
        } catch {
            DebugLogger.log("⚠️ Room mapping refresh failed: \(error.localizedDescription)", feature: .automation)
            // Continue anyway - fallback room mappings will be used
        }

    // Get all devices from all hubs, then filter by selected device names
    let allDevices = await hubService.getAllDevices()
    let hubConfigurations = await hubService.getRegisteredHubs()

    if appConfig.selectedDeviceNames.isEmpty {
        devices = []
    } else {
        // Filter devices and maintain the order defined in settings
        // Create placeholder devices for names that don't exist yet
        // Create disconnected devices for devices from disabled hubs
        var orderedDevices: [Device] = []
        for deviceName in appConfig.selectedDeviceNames {
            if let device = allDevices.first(where: { $0.name == deviceName }) {
                // Found existing device - check if its hub is enabled
                let hubConfig = hubConfigurations.first(where: { $0.hubId == device.hubId })
                if let config = hubConfig, !config.isEnabled {
                    // Hub is disabled, create disconnected device
                    let disconnectedDevice = createPlaceholderDevice(
                        name: device.name,
                        type: device.type,
                        state: .disconnected(device),
                        room: device.room,
                        capabilities: device.capabilities
                    )
                    orderedDevices.append(disconnectedDevice)
                } else {
                    // Hub is enabled, use the real device
                    orderedDevices.append(device)
                }
            } else {
                // Create placeholder device for names that don't exist yet
                let placeholderDevice = createPlaceholderDevice(name: deviceName, state: .missing)
                orderedDevices.append(placeholderDevice)
            }
        }
        devices = orderedDevices
    }

    isLoading = false
}
```

### Device Control

Handle device control operations with placeholder support:

```swift
func toggleDevice(_ device: Device) async {
    // Don't allow toggling placeholder or disconnected devices
    guard device.hubState != .placeholder && device.hubState != .disconnected else {
        let status = device.hubState == .placeholder ? "not available yet" : "disconnected"
        errorMessage = "Device '\(device.name)' is \(status). Please check your hub connection."
        return
    }

    guard let isOn = device.state.isOn else { return }

    // Mark device as being controlled
    deviceActionInProgress.insert(device.id)

    do {
        let action: DeviceAction = isOn ? .turnOff : .turnOn
        try await hubService.controlDevice(deviceId: device.id, action: action)

        // Keep the indicator visible for a short time to provide feedback
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    } catch {
        errorMessage = "Failed to toggle device: \(error.localizedDescription)"
    }

    // Remove from action in progress
    deviceActionInProgress.remove(device.id)
}

func executeScene(_ device: Device) async {
    // Don't allow executing scenes for placeholder or disconnected devices
    guard device.hubState != .placeholder && device.hubState != .disconnected else {
        let status = device.hubState == .placeholder ? "not available yet" : "disconnected"
        errorMessage = "Scene '\(device.name)' is \(status). Please check your hub connection."
        return
    }

    // Mark device as being controlled
    deviceActionInProgress.insert(device.id)

    do {
        try await hubService.executeScene(sceneId: device.id)

        // Keep the indicator visible for a short time to provide feedback
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    } catch {
        errorMessage = "Failed to execute scene: \(error.localizedDescription)"
    }

    // Remove from action in progress
    deviceActionInProgress.remove(device.id)
}
```

## 🌐 Hub Integration

### Multi-Hub Support

Support for multiple Vera hub types:

```swift
enum HubType: String, CaseIterable {
    case veraLite = "vera-lite"
    case veraEdge = "vera-edge" 
    case veraPlus = "vera-plus"
}
```

### Device State Caching

Efficient device state management:

```swift
class DeviceStateCache: @unchecked Sendable {
    private var deviceStates: [String: DeviceState] = [:]
    private let cacheQueue = DispatchQueue(label: "device.cache", attributes: .concurrent)
    
    func updateState(for deviceId: String, state: DeviceState) {
        cacheQueue.async(flags: .barrier) {
            self.deviceStates[deviceId] = state
        }
    }
    
    func getState(for deviceId: String) -> DeviceState? {
        return cacheQueue.sync {
            deviceStates[deviceId]
        }
    }
}
```

## 🧪 Testing

### Unit Testing

Test automation logic in isolation:

```swift
func testDeviceToggle() async {
    let mockHubManager = MockHubManager()
    let viewModel = AutomationViewModel(hubManager: mockHubManager)
    
    let device = Device(id: "1", name: "Test Light", type: .light, state: DeviceState(deviceId: "1", isOn: false))
    
    await viewModel.toggleDevice(device)
    
    XCTAssertTrue(mockHubManager.lastAction == .turnOn)
}

func testDeviceFiltering() {
    let viewModel = AutomationViewModel(hubManager: MockHubManager())
    
    let devices = [
        Device(id: "1", name: "Living Room Light", type: .light),
        Device(id: "2", name: "Kitchen Light", type: .light),
        Device(id: "3", name: "Bedroom Fan", type: .light)
    ]
    
    viewModel.devices = devices
    viewModel.deviceFilter = "Light"
    
    let filteredDevices = viewModel.filteredDevices
    XCTAssertEqual(filteredDevices.count, 2)
}
```

### Integration Testing

Test with real hub services:

```swift
func testMultiHubDeviceControl() async throws {
    let hubManager = HubManager()
    let viewModel = AutomationViewModel(hubManager: hubManager)
    
    await viewModel.startPolling()
    
    // Wait for devices to load
    try await Task.sleep(nanoseconds: 1_000_000_000)
    
    XCTAssertFalse(viewModel.devices.isEmpty)
    XCTAssertFalse(viewModel.isLoading)
}
```

## 🔧 Configuration

### Hub Management

Multi-hub configuration and management:

- **Hub Discovery**: Automatic hub detection
- **Hub Configuration**: IP address and port settings
- **Hub Status**: Connection status monitoring
- **Hub Selection**: Choose active hubs for control

### Device Filtering

Configurable device filtering options:

- **Name Filtering**: Filter by device name patterns
- **Type Filtering**: Filter by device type
- **Room Filtering**: Filter by room location
- **Status Filtering**: Filter by device status

## 🚀 Performance

### Optimization Strategies

- **Parallel Polling**: Simultaneous hub requests
- **State Caching**: Efficient device state management
- **Retry Logic**: Network reliability improvements
- **Memory Management**: Proper resource cleanup

### Monitoring

- **Response Times**: Track hub communication performance
- **Error Rates**: Monitor device control failures
- **Memory Usage**: Track device state cache usage
- **User Interactions**: Monitor device control patterns

## 🔮 Future Enhancements

### Planned Features

- **Scheduling**: Time-based device automation
- **Scenes**: Custom scene creation and management
- **Groups**: Device grouping for batch operations
- **Analytics**: Usage statistics and patterns

### Technical Improvements

- **Offline Mode**: Local device state caching
- **Batch Operations**: Multiple device control
- **Advanced Filtering**: Complex filter combinations
- **Performance Optimization**: Faster device updates

## 📁 File Structure

```
Automation/
├── Services/
│   └── (Empty - uses HubServiceProtocol from Hub feature)
├── ViewModels/
│   └── AutomationViewModel.swift       # Device state management and automation logic
├── Views/
│   ├── AutomationTabView.swift        # Main automation interface
│   ├── DeviceCardView.swift           # Individual device control component
│   ├── DeviceSelectionView.swift      # Legacy device selection (deprecated)
│   └── AutomationSettingsView.swift   # Legacy automation settings (deprecated)
└── README.md                          # This documentation
```

## 🔗 Navigation

- **[Automation ViewModels](ViewModels/README.md)** - Device state management and automation logic
- **[Automation Views](Views/README.md)** - Device cards, automation interface, and device selection
- **[Features Overview](../README.md)** - All app features
- **[Main App Architecture](../../README.md)** - Overall app architecture
- **[Core Infrastructure](../../Core/README.md)** - Shared infrastructure
- **[Shared Components](../../Shared/README.md)** - Reusable components

---

The automation system provides comprehensive smart home device control with multi-hub support, adaptive interfaces, device selection management, notification-based updates, and robust state management with graceful handling of missing or disconnected devices.
