# Home Panel App - Comprehensive AI Context Document

**Last Updated**: January 2025  
**Purpose**: Comprehensive standalone context document for external AI tools (Claude Pro, Perplexity Pro) for feature design and development assistance  
**Documentation Structure**: Feature-oriented README files embedded within codebase structure

**UI Documentation**: Comprehensive UI documentation available at `./docs/ui-documentation.md` covering all screens, dialogs, components, and navigation flows.

---

## Project Overview

The Home Panel App is a modern iOS home automation application built with SwiftUI, specifically designed for iPad but compatible with iPhone. The app provides secure control over Vera Hub alarm systems with advanced multi-PIN security features, live camera surveillance capabilities, and comprehensive smart home automation.

**Target Users**: Homeowners with Vera Hub alarm systems who need secure, intuitive control over their home security and automation from iOS devices. The app prioritizes security, ease of use, and local network operation for privacy and reliability.

**Core Functionality**: 
- Real-time monitoring and control of Vera Hub alarm states (Armed Away, Armed Stay, Armed Night-Stay, Disarmed) with PIN-protected mode changes
- Advanced multi-PIN security system with Master PIN and User PIN support
- Prime number-based lockout protection with cross-device synchronization
- Live camera surveillance with Blue Iris integration and secure credential management
- Multi-hub automation control for smart devices and scenes across multiple Vera hubs
- Comprehensive settings management with hub configuration and PIN administration

**Current Implementation Status**: All core features are fully implemented and production-ready:
- ✅ **Alarm System**: Complete with advanced security and real-time monitoring
- ✅ **Camera Surveillance**: Multi-VMS support with Blue Iris fully implemented, adapter pattern ready for other VMS types
- ✅ **Automation System**: Multi-hub device control with device selection interface
- ✅ **Hub Integration**: Universal hub abstraction with actor-based architecture
- ✅ **Settings Management**: Split-view interface with organized menu system
- ✅ **Device Selection**: Comprehensive device and scene selection interface
- ✅ **Security System**: Multi-PIN authentication with lockout protection
- ✅ **Adapter Pattern**: Clean separation between generic interfaces and vendor-specific implementations

## Technical Architecture

The app follows modern iOS development practices with a clean MVVM architecture, protocol-based dependency injection, and Swift 6.0 concurrency model.

## Configuration Management

### Centralized Configuration

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

### Architecture Pattern

**Model-View-ViewModel (MVVM)** with clear separation of concerns:
- **Models**: Data structures and business entities (`AlarmState`, `PINData`, `Device`, `CameraConfig`)
- **Views**: SwiftUI declarative UI components (`AlarmTabView`, `CameraWebView`, `AutomationTabView`)
- **ViewModels**: Business logic and state management (`AlarmViewModel`, `CameraViewModel`, `AutomationViewModel`)

### Dependency Injection

Modern protocol-based architecture using `DependencyContainer` with lazy initialization and factory methods:
```swift
protocol SceneServiceProtocol {
    func fetchSceneList(hubId: String) async throws -> HubScopedSceneMap
    func setAlarmMode(_ mode: AlarmMode, hubScopedSceneMap: HubScopedSceneMap, hubId: String) async throws
}

protocol HubServiceProtocol: AnyObject {
    var stateChangePublisher: AnyPublisher<StateChangeEvent, Never> { get }
    var isRunning: Bool { get }
    var registeredHubIds: [String] { get }
    
    func start() async
    func stop() async
    func registerHub(_ hub: any HubProtocol, configuration: HubConfiguration) async
    func getAllDevices() async -> [Device]
    func controlDevice(deviceId: String, action: DeviceAction) async throws
}

@MainActor
class DependencyContainer {
    private let config: AppConfigurationProtocol
    
    // Lazy service initialization
    private lazy var sharedURLSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15.0
        configuration.timeoutIntervalForResource = 30.0
        return URLSession(configuration: configuration)
    }()
    
    private lazy var sceneService: SceneServiceProtocol = {
        SceneServiceCoordinator(hubService: hubService, session: sharedURLSession)
    }()
    
    private lazy var alarmService: AlarmServiceProtocol = {
        UnifiedAlarmService(hubService: hubService, config: config)
    }()
    
    var hubService: HubServiceProtocol {
        if let service = _hubService {
            return service
        }
        let service = HubServiceCoordinator()
        _hubService = service
        return service
    }
    
    // Factory methods for ViewModels
    internal func createAlarmViewModel() -> AlarmViewModel {
        return AlarmViewModel(
            config: config,
            sceneService: sceneService,
            alarmService: alarmService,
            pinService: pinManagementService
        )
    }
}
```

### Key Technologies

- **Swift 6.0** with modern concurrency (`async/await`, `@MainActor`)
- **SwiftUI** for declarative UI with reactive state management
- **Combine** for reactive programming (`@Published` properties, `PassthroughSubject`)
- **iOS Keychain** for secure credential storage with automatic encryption
- **iCloud Keychain** for cross-device synchronization
- **WKWebView** for Blue Iris camera integration
- **URLSession** for network communication with async/await

### File Organization

Feature-oriented structure with embedded documentation:
```
HomePanelApp/
├── App/                    # Application entry point and DI container
│   ├── HomePanelApp.swift
│   └── DependencyContainer.swift
├── Core/                   # Core infrastructure and shared models
│   ├── Errors/            # Error definitions
│   ├── Models/            # Core data models
│   └── Services/          # Core services (Keychain, Cloud)
├── Features/              # Feature-specific modules
│   ├── Alarm/            # Alarm system (Models, Services, ViewModels, Views)
│   ├── Camera/           # Camera surveillance (Models, Services, ViewModels, Views, Adapters)
│   │   ├── Models/       # Generic camera models
│   │   ├── Services/     # Camera-agnostic services
│   │   ├── Adapters/     # VMS-specific implementations
│   │   │   └── BlueIris/ # Blue Iris VMS adapter
│   │   ├── Views/        # Camera UI components
│   │   └── ViewModels/   # Camera business logic
│   ├── Automation/       # Device automation (ViewModels, Views)
│   ├── Hub/              # Hub integration (Models, Services, Adapters)
│   │   ├── Models/       # Generic hub models
│   │   ├── Services/     # Hub-agnostic services
│   │   └── Adapters/     # Vendor-specific implementations
│   │       └── Vera/     # Vera hub adapter and models
│   └── Settings/         # Settings management (Views)
│       ├── Views/
│       │   ├── SettingsSplitView.swift # Main split-view interface
│       │   ├── CameraManagement/       # Camera configuration views
│       │   ├── DeviceSelection/        # Device selection views
│       │   ├── HubManagement/          # Hub configuration views
│       │   └── PINManagement/          # PIN security views
├── Shared/               # Shared components and utilities
│   ├── Components/       # Reusable UI components
│   ├── DesignSystem/     # Design system
│   └── Utilities/        # Helper functions
└── Resources/            # Assets and configuration files
```

### Concurrency Model

**Mixed Concurrency Patterns**: Modern Swift concurrency with actor-based services and @MainActor coordinators:

**@MainActor Coordinators**: UI-related coordinators and ViewModels:
```swift
@MainActor
class HubServiceCoordinator: ObservableObject {
    @Published var isRunning = false
    @Published var registeredHubIds: [String] = []
    
    func registerHub(_ hub: any HubProtocol, configuration: HubConfiguration) async {
        await hubManager.registerHub(hub, configuration: configuration)
    }
}
```

**Actor-Based Services**: Thread-safe services using actors:
```swift
actor HubManager {
    private var hubs: [String: any HubProtocol] = [:]
    private var configurations: [String: HubConfiguration] = [:]
    
    func registerHub(_ hub: any HubProtocol, configuration: HubConfiguration) {
        hubs[hub.hubId] = hub
        configurations[hub.hubId] = configuration
    }
}

actor PollingService {
    private var pollingTasks: [String: Task<Void, Never>] = [:]
    
    func startPolling(forHub hubId: String) async {
        // Thread-safe polling implementation
    }
}

actor DeviceStateCache {
    private var deviceStates: [String: DeviceState] = [:]
    
    func updateState(for deviceId: String, state: DeviceState) {
        deviceStates[deviceId] = state
    }
}
```

**Async/Await Patterns**: Modern Swift concurrency for network operations:
```swift
func fetchAlarmState() async throws -> AlarmState {
    let url = buildAlarmStateURL()
    let (data, response) = try await URLSession.shared.data(from: url)
    return try parseAlarmState(from: data)
}
```

**Event-Driven Updates**: Combine publishers for reactive state management:
```swift
class StatePublisher: @unchecked Sendable {
    private let subject = PassthroughSubject<StateChangeEvent, Never>()
    
    var stateChanges: AnyPublisher<StateChangeEvent, Never> {
        subject.eraseToAnyPublisher()
    }
    
    func publishStateChange(_ event: StateChangeEvent) {
        subject.send(event)
    }
}
```

## Current Features

### Alarm System
The core feature providing real-time Vera Hub alarm control with comprehensive security:

**Alarm States**: 
- `disarmed` (Green) - System is disarmed
- `armedAway` (Red) - Armed for away mode  
- `armedStay` (Orange) - Armed for stay mode
- `armedNightStay` (Purple) - Armed for night-stay mode
- `unknown` (Gray) - State cannot be determined

**Mode Control**: PIN-protected mode changes with dynamic scene mapping from Vera Hub
**Real-time Updates**: Automatic state refresh every 5 seconds with manual refresh capability
**Error Handling**: User-friendly error messages with retry mechanisms for network issues

**Key Implementation**:
```swift
@MainActor
class AlarmViewModel: ObservableObject {
    @Published var currentState: AlarmState = .unknown
    @Published var isLoading = false
    @Published var showPINEntry = false
    @Published var pendingMode: AlarmMode?
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    
    private let alarmService: AlarmServiceProtocol
    private let sceneService: SceneServiceProtocol
    private let pinService: PINManagementServiceProtocol
    private let lockoutService: AlarmLockoutServiceProtocol
}
```

**Modern Architecture**:
- **SceneServiceCoordinator**: Coordinates scene operations across hub types
- **SceneServiceProtocol**: Generic interface for scene operations
- **VeraSceneAdapter**: Vera-specific scene implementation
- **HubServiceProtocol Integration**: Uses modern hub service protocol for multi-hub support
- **Actor-Based Concurrency**: Thread-safe operations with actor-based services
- **Event-Driven Updates**: Real-time state changes through event publishing

**Vera Hub Integration**:
- Scene List: `GET http://{IP}:3480/data_request?id=user_data`
- Scene Execution: `GET http://{IP}:3480/data_request?id=lu_action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=RunScene&SceneNum={ID}`
- Device Polling: `GET http://{IP}:3480/data_request?id=sdata&output_format=json` (preferred, 91-96% bandwidth reduction)
- Alarm State (Legacy): `GET http://{IP}:3480/data_request?id=status&DeviceNum=7&output_format=json` (deprecated for polling)

### Multi-PIN Security System
Advanced authentication system with multiple PIN types and secure storage:

**Master PIN**: Administrative access for PIN management and settings
**User PINs**: Multiple named PINs for family members with individual tracking
**Duress PIN**: Special PIN ("387377") that triggers silent security warning
**PIN Validation**: 6-digit requirement with SHA-256 hashing and random salt generation

**Security Features**:
- Secure Keychain storage (local only)
- No plain text PIN storage
- Individual PIN usage tracking
- Easy PIN management and removal

**PIN Data Structure**:
```swift
struct PINData: Codable, Identifiable {
    public let id: UUID
    public let pinHash: String  // SHA-256 hash of the PIN
    public let salt: String     // Random salt used for hashing
    public let name: String
    public let createdAt: Date
    public var lastUsed: Date?
    
    func verifyPIN(_ pin: String) -> Bool {
        return PINHasher.hashPIN(pin, salt: self.salt) == self.pinHash
    }
}
```

### Advanced Lockout System
Sophisticated brute force protection with prime number delays:

**Lockout Algorithm**: 7 attempts trigger first lockout (7 minutes), subsequent lockouts use prime numbers (11, 13, 17, 19, 23, 29 minutes)
**Local Lockout Management**: Lockout state managed locally with `LockoutManager`
**Event Publishing**: Real-time lockout state updates with `LockoutEventPublisher`
**Recovery**: Master PIN holder can reset all lockout states

**Lockout Implementation**:
```swift
private let primeLockoutMinutes = [7, 11, 13, 17, 19, 23, 29]

func recordFailedAttempt() {
    consecutiveFailures += 1
    
    if consecutiveFailures % 7 == 0 {
        let lockoutRound = consecutiveFailures / 7
        let lockoutIndex = min(lockoutRound - 1, primeLockoutMinutes.count - 1)
        let lockoutMinutes = primeLockoutMinutes[lockoutIndex]
        
        lockoutUntil = Date().addingTimeInterval(TimeInterval(lockoutMinutes * 60))
        saveLockoutState()
    }
}
```

### Camera Surveillance System
**Multi-VMS Support**: Flexible camera integration supporting multiple Video Management Systems (VMS) through adapter pattern.

**Supported VMS Types**:
- **Blue Iris**: Web-based VMS with dual camera support
- **Frigate NVR**: Open-source NVR (planned)
- **RTSP Generic**: Direct RTSP camera streams (planned)
- **MJPEG Generic**: Direct MJPEG camera streams (planned)
- **Generic Web View**: Any web-based camera interface

**Key Features**:
- **User-Defined Names**: Customizable camera names (not "Iris One"/"Iris Two")
- **VMS Selection**: Choose camera system type in settings
- **Adapter Pattern**: Clean separation between generic interfaces and VMS-specific implementations
- **Secure Credentials**: Master PIN protection with iOS Keychain storage
- **URL Embedding**: VMS-specific authentication handling
- **Real-time Configuration**: Dynamic camera settings
- **Error Handling**: User-friendly error messages with retry options
- **Pull-to-refresh**: Manual refresh capability

**Architecture**:
```swift
// Generic Protocol
protocol CameraServiceProtocol {
    func prepareConnection(config: CameraConfig, credentials: CameraCredentials) async throws -> CameraConnection
    func validateConfiguration(config: CameraConfig) throws
    func getViewType(for config: CameraConfig) -> CameraViewType
}

// Coordinator (Router)
class CameraServiceCoordinator: CameraServiceProtocol {
    func prepareConnection(config: CameraConfig, credentials: CameraCredentials) async throws -> CameraConnection {
        let adapter = getAdapter(for: config.vmsType)
        return try await adapter.prepareConnection(config: config, credentials: credentials)
    }
}

// Blue Iris Adapter
class BlueIrisCameraAdapter: CameraServiceProtocol {
    func prepareConnection(config: CameraConfig, credentials: CameraCredentials) async throws -> CameraConnection {
        // Blue Iris specific: embed credentials in URL
        let url = "http://\(config.username):\(credentials.password)@\(config.ipAddress):\(config.port)\(config.path)"
        // ...
    }
}
```

**Technical Implementation**:
```swift
struct CameraConfig: Codable, Identifiable {
    public let id: String
    public let name: String           // User-defined name
    public let vmsType: VMSType       // Blue Iris, Frigate, RTSP, etc.
    public let ipAddress: String
    public let port: Int
    public let username: String
    public let path: String
    public let lastUpdated: Date
}

enum VMSType: String, Codable {
    case blueIris = "Blue Iris"
    case frigate = "Frigate NVR"
    case rtspGeneric = "RTSP Camera"
    case mjpegGeneric = "MJPEG Camera"
    case genericWebView = "Generic Web View"
}

struct CameraConnection: Sendable {
    public let viewType: CameraViewType
    public let connectionURL: URL
    public let additionalHeaders: [String: String]?
    public let requiresJavaScript: Bool
}
```

**Camera Web View**:
```swift
struct CameraWebView: View {
    let config: CameraConfig?
    let credentials: CameraCredentials?
    @StateObject private var webViewStore = WebViewStore()
    @StateObject private var cameraService = CameraServiceCoordinator()

    var body: some View {
        WebView(webView: webViewStore.webView)
            .task { await loadCamera() }
            .refreshable { await refreshCamera() }
    }

    private func loadCamera() async {
        guard let config = config, let credentials = credentials else { return }
        let connection = try await cameraService.prepareConnection(config: config, credentials: credentials)
        webViewStore.webView.load(URLRequest(url: connection.connectionURL))
    }
}
```

### Automation System
**Multi-Hub Device Control**: Interactive control and monitoring of smart devices and scenes across multiple Vera hubs with comprehensive device selection interface and notification-based updates.

**Key Features**:
- **Device Control**: Toggle lights, switches, dimmers, sensors, and locks
- **Scene Activation**: Run pre-configured scenes with single tap
- **Multi-Hub Support**: Vera Lite, Vera Edge, Vera Plus
- **Adaptive Grid**: 4 columns (iPad Pro 12.9"+), 3 columns (iPad Mini/Air), 2 columns (smaller screens)
- **Device Selection Management**: Comprehensive device and scene selection interface
- **Dual-Pane Selection**: 50/50 split interface for device selection
- **Hub Organization**: Devices organized by hub with expand/collapse
- **Room Organization**: Devices further organized by room
- **Search & Filter**: Real-time search across all devices
- **Drag-to-Order**: Reorder selected devices with visual feedback
- **Master PIN Protection**: Settings access requires Master PIN verification
- **Real-time Polling**: 5-second intervals with parallel hub requests
- **Notification-Based Updates**: Real-time UI synchronization for device selection changes
- **Robust State Detection**: Accurate device state detection
- **HubServiceProtocol Integration**: Unified hub service for device control
- **RoomMappingService**: Device organization and room coordination with centralized timeout handling
- **Placeholder Device Support**: Graceful handling of missing or disconnected devices

**Device Model**:
```swift
public struct Device: Identifiable, Codable, Sendable {
    public let id: String
    let hubId: String
    let name: String
    let type: DeviceType
    let room: String?
    var state: DeviceState
    let capabilities: Set<DeviceCapability>
}

public enum DeviceType: String, Codable, Sendable {
    case light, dimmer, lightSwitch, lock, sensor, thermostat, scene
    
    var icon: String {
        switch self {
        case .light, .lightSwitch, .dimmer: return "lightbulb.fill"
        case .sensor: return "sensor.fill"
        case .lock: return "lock.fill"
        case .thermostat: return "thermometer"
        case .scene: return "sparkles"
        }
    }
}
```

**Hub Integration**:
```swift
protocol HubProtocol: Sendable {
    var hubId: String { get }
    var hubType: HubType { get }
    var isReachable: Bool { get async }
    
    func fetchDevices() async throws -> [Device]
    func fetchDeviceState(deviceId: String) async throws -> DeviceState
    func updateDevice(deviceId: String, action: DeviceAction) async throws
    func executeScene(sceneId: String) async throws
}
```

### Hub Integration System
**Universal Hub Abstraction**: Multi-hub coordination with centralized state management using modern actor-based architecture.

**Key Features**:
- **HubServiceCoordinator**: Main service coordinator with @MainActor
- **HubServiceProtocol**: Protocol-based dependency injection
- **Actor-Based Services**: Thread-safe hub coordination with actors
- **Device State Caching**: Efficient device state storage with DeviceStateCache actor
- **Real-time Updates**: Live state synchronization through StatePublisher
- **Polling Service**: Background polling with PollingService actor
- **State Publishing**: Event-driven state updates
- **Adapter Pattern**: BaseHubAdapter and VeraHubAdapter for hub abstraction
- **RoomMappingService**: Device organization and room coordination with centralized timeout handling

**Hub Service Architecture**:
```swift
@MainActor
class HubServiceCoordinator: ObservableObject {
    @Published var isRunning = false
    @Published var registeredHubIds: [String] = []
    
    private let stateCache: DeviceStateCache
    private let statePublisher: StatePublisher
    private let hubManager: HubManager
    private let pollingService: PollingService
    lazy var roomMappingService: RoomMappingService = RoomMappingService(hubService: self)
    
    func registerHub(_ hub: any HubProtocol, configuration: HubConfiguration) async {
        await hubManager.registerHub(hub, configuration: configuration)
        await updateRegisteredHubs()
        
        if isRunning {
            await pollingService.startPolling(forHub: hub.hubId)
        }
    }
}
```

**Actor-Based Hub Manager**:
```swift
actor HubManager {
    private var hubs: [String: any HubProtocol] = [:]
    private var configurations: [String: HubConfiguration] = [:]
    private let stateCache: DeviceStateCache
    private let publishStateChange: (StateChangeEvent) -> Void
    
    func registerHub(_ hub: any HubProtocol, configuration: HubConfiguration) {
        hubs[hub.hubId] = hub
        configurations[hub.hubId] = configuration
    }
    
    func getAllDevices() async -> [Device] {
        var allDevices: [Device] = []
        
        for hub in hubs.values {
            do {
                let devices = try await hub.fetchDeviceStates()
                allDevices.append(contentsOf: devices)
            } catch {
                print("Failed to fetch devices from hub \(hub.hubId): \(error)")
            }
        }
        
        return allDevices
    }
}
```

### Adapter Pattern Architecture

The app uses the Adapter Pattern to support multiple hub vendors while maintaining clean separation between generic interfaces and vendor-specific implementations.

**Pattern Structure**:
```
Generic Protocol → Coordinator (Router) → Vendor-Specific Adapter
```

**Example: Scene Service**:
```swift
// 1. Generic Protocol (hub-agnostic)
protocol SceneServiceProtocol {
    func fetchSceneList(hubId: String) async throws -> HubScopedSceneMap
    func setAlarmMode(_ mode: AlarmMode, hubScopedSceneMap: HubScopedSceneMap, hubId: String) async throws
}

// 2. Coordinator (routes based on hub type)
class SceneServiceCoordinator: SceneServiceProtocol {
    func fetchSceneList(hubId: String) async throws -> HubScopedSceneMap {
        let hub = try await getHub(hubId)
        let adapter = getAdapter(for: hub.hubType)  // Routes to appropriate adapter
        return try await adapter.fetchSceneList(hubId: hubId)
    }
}

// 3. Vendor-Specific Adapter (Vera implementation)
class VeraSceneAdapter: SceneServiceProtocol {
    func fetchSceneList(hubId: String) async throws -> HubScopedSceneMap {
        // Vera-specific: port 3480, user_data endpoint, JSON parsing
        let url = "http://\(hub.address):3480/data_request?id=user_data"
        // ... Vera-specific implementation
    }
}
```

**Example: Camera Service**:
```swift
// 1. Generic Protocol (VMS-agnostic)
protocol CameraServiceProtocol {
    func prepareConnection(config: CameraConfig, credentials: CameraCredentials) async throws -> CameraConnection
    func validateConfiguration(config: CameraConfig) throws
    func getViewType(for config: CameraConfig) -> CameraViewType
}

// 2. Coordinator (routes based on VMS type)
class CameraServiceCoordinator: CameraServiceProtocol {
    func prepareConnection(config: CameraConfig, credentials: CameraCredentials) async throws -> CameraConnection {
        let adapter = getAdapter(for: config.vmsType)  // Routes to appropriate VMS adapter
        return try await adapter.prepareConnection(config: config, credentials: credentials)
    }
}

// 3. VMS-Specific Adapter (Blue Iris implementation)
class BlueIrisCameraAdapter: CameraServiceProtocol {
    func prepareConnection(config: CameraConfig, credentials: CameraCredentials) async throws -> CameraConnection {
        // Blue Iris specific: embed credentials in URL, require JavaScript
        let url = "http://\(config.username):\(credentials.password)@\(config.ipAddress):\(config.port)\(config.path)"
        return CameraConnection(viewType: .webView, connectionURL: URL(string: url)!, requiresJavaScript: true)
    }
}
```

**Benefits**:
- **Extensibility**: Add new hub types without modifying existing code
- **Testability**: Mock generic protocols without vendor dependencies
- **Separation of Concerns**: Hub-specific quirks isolated to adapters
- **Maintainability**: Clear boundaries between generic and specific code

**Current Implementations**:
- ✅ **Hub Service**: `HubProtocol` → `HubServiceCoordinator` → `VeraHubAdapter`
- ✅ **Scene Service**: `SceneServiceProtocol` → `SceneServiceCoordinator` → `VeraSceneAdapter`
- ✅ **Camera Service**: `CameraServiceProtocol` → `CameraServiceCoordinator` → `BlueIrisCameraAdapter`
- 🔄 **Alarm Service**: Refactoring in progress

### Architecture Decision: Graceful Degradation for Hub Connectivity

**Decision**: Hub reachability check returns `true` even on connection errors

**Context**: The `BaseHubAdapter.isReachable` property is used to determine if a hub is accessible before attempting operations. A strict connectivity check would return `false` on any error, potentially blocking the UI from displaying device controls.

**Rationale**:
- **Availability Priority**: Home automation apps should prioritize showing information over strict accuracy
- **Graceful Degradation**: Display last known device states when hub is temporarily offline
- **User Experience**: Better to show cached data with potential staleness than no data at all
- **Natural Failure Points**: Actual operations will fail with proper errors if hub is truly inaccessible

**Implementation**: 
- Location: `BaseHubAdapter.isReachable` in `HomePanelApp/Features/Hub/Services/BaseHubAdapter.swift`
- Behavior: Returns `true` in catch block, logs warning with DebugLogger
- Cache Integration: Works with `DeviceStateCache` actor to show last known states

**Trade-offs**:
- ✅ Users can view device status during temporary outages
- ✅ UI remains responsive and functional
- ✅ Reduces frustration from connectivity blips
- ⚠️ Users may see stale data without explicit "offline" indicator
- ⚠️ Actual staleness depends on cache lifetime and last successful refresh

**Alternative Considered**: Strict connectivity checks that return `false` on error would block the UI but provide accuracy guarantees. Rejected due to poor UX for home automation scenarios where intermittent connectivity is common.

### Settings Management System
**Split-View Interface**: Modern settings interface with resizable panes, organized menu system, and specialized management interfaces for cameras, devices, and security.

**Key Features**:
- **Split-View Architecture**: Resizable divider with UserDefaults persistence
- **Menu System**: 6 organized menu items with icons and descriptions
- **Save/Discard Pattern**: Coordinated state management across all settings
- **Camera Management**: Dynamic camera configuration with multi-VMS support
- **Device Selection**: Comprehensive device and scene selection interface
- **Hub Management**: Add, edit, and remove Vera hubs
- **PIN Management**: Master PIN and User PIN administration
- **App Configuration**: General app settings and preferences
- **Data Export/Import**: Configuration backup and restore
- **Security Settings**: Security policies and lockout management
- **Toast Notifications**: User feedback for all operations

**Settings Structure**:
```swift
struct SettingsView: View {
    @ObservedObject var config: AppConfiguration
    @StateObject private var lockoutService = AlarmLockoutService()
    
    var body: some View {
        NavigationView {
            Form {
                hubManagementSection
                veraHubSection
                securitySection
                informationSection
                actionsSection
            }
            .navigationTitle("Settings")
        }
    }
}
```

## Design System & UX Patterns

The app uses a comprehensive design system (`DesignSystem.swift`) for consistent UI patterns:

### Typography System
Semantic font sizes with consistent scaling:
```swift
enum FontSize {
    static let pico: CGFloat = 16
    static let small: CGFloat = 20
    static let medium: CGFloat = 24
    static let large: CGFloat = 32
    static let xlarge: CGFloat = 48
    static let xxlarge: CGFloat = 64
    static let extraLarge: CGFloat = 80
}
```

### Spacing System
Consistent spacing scale for all UI elements:
```swift
enum Spacing {
    static let nano: CGFloat = 2
    static let micro: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xlarge: CGFloat = 24
    static let xxlarge: CGFloat = 32
    static let massive: CGFloat = 40
}
```

### Color System
Dynamic colors with semantic meaning:
```swift
extension Color {
    static let alarmDisarmed = Color.green
    static let alarmArmedAway = Color.red
    static let alarmArmedStay = Color.orange
    static let alarmArmedNightStay = Color.purple
    static let alarmUnknown = Color.gray
    
    static let buttonPrimary = Color.blue
    static let buttonSecondary = Color.gray
    static let buttonDestructive = Color.red
    static let buttonSuccess = Color.green
}
```

### Common UI Patterns
- **Grid Layouts**: 2-column mode buttons, 3-column keypad, adaptive camera grids
- **Loading States**: `ProgressView` with design system styling
- **Error Handling**: User-friendly error messages with retry options
- **Button Styles**: Primary, secondary, destructive, keypad, and mode-specific styles
- **PIN Entry**: Phone-style keypad with visual feedback and animations

### Accessibility Features
- **VoiceOver Support**: Comprehensive accessibility labels and hints
- **Dynamic Type**: Support for iOS Dynamic Type scaling
- **High Contrast**: High contrast mode compatibility
- **Haptic Feedback**: Tactile feedback for user interactions

## Integration Points

### Hub API Integration

The app uses an adapter pattern to support multiple hub vendors:

**Vera Hub Integration** (via VeraSceneAdapter):
- **Scene Discovery**: `GET http://{IP}:3480/data_request?id=user_data`
- **Scene Execution**: `GET http://{IP}:3480/data_request?id=lu_action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=RunScene&SceneNum={ID}`
- **Alarm State**: `GET http://{IP}:3480/data_request?id=status&DeviceNum=7&output_format=json`
- **Device Control**: `GET http://{IP}:3480/data_request?id=lu_action&serviceId=urn:micasaverde-com:serviceId:SwitchPower1&action=SetTarget&newTargetValue=1&DeviceNum={ID}`

**Future Hub Support**:
Adding support for new hub types requires:
1. Create adapter implementing `HubProtocol`
2. Create scene adapter implementing `SceneServiceProtocol`
3. Add hub type to `HubType` enum
4. Register adapter in coordinators

### Keychain Services
Secure storage for sensitive data:
- **PIN Storage**: SHA-256 hashed PINs with random salts
- **Lockout States**: Prime number-based lockout timers
- **Camera Credentials**: Blue Iris passwords and usernames
- **Hub Configurations**: Secure hub connection details
- **Cross-Device Sync**: iCloud Keychain synchronization

### UserDefaults Storage
Non-sensitive configuration storage:
- **Vera Hub IP**: Primary hub IP address
- **Scene Mappings**: Dynamic scene name to ID mappings
- **Camera Configuration**: IP addresses, ports, usernames
- **UI Preferences**: Display and interaction settings
- **App Settings**: General application configuration

### Local Network Architecture
Privacy-focused local-only communication:
- **No Cloud Dependencies**: All operations on local network
- **Fast Response Times**: Direct hub communication
- **Offline Capability**: Works without internet connection
- **Privacy Protection**: No data leaves local network

## Key Constraints

### Platform Requirements
- **iOS 18.7+** minimum deployment target
- **iPad-optimized** primary target with iPhone compatibility
- **Swift 6.0** language version with modern concurrency
- **Xcode 16.4+** for development (May 2025)

### Architecture Constraints
- **Local Network Only**: No external cloud services or APIs
- **@MainActor**: All UI-related classes must be main actor
- **Protocol-Based**: Services must conform to protocols for testability
- **Async/Await**: All network operations use modern Swift concurrency

### Security Constraints
- **PIN Requirements**: All PINs must be exactly 6 digits
- **Secure Storage**: All sensitive data must use Keychain
- **No Plain Text**: No credentials stored in plain text
- **Local Security**: Security state managed locally per device

### Performance Constraints
- **Memory Management**: Efficient resource usage for long-running app
- **Network Efficiency**: Minimal network requests with appropriate caching
- **UI Responsiveness**: All UI updates must occur on main thread
- **Battery Optimization**: Efficient background operations

## Development Workflow

### Code Organization
- **Feature-Oriented Structure**: Each feature has its own Models, Services, ViewModels, Views
- **Embedded Documentation**: README files at every folder level
- **Protocol-Based Design**: All services implement protocols for testability
- **Dependency Injection**: Centralized service management

### Testing Strategy
- **Unit Testing**: Individual component testing with mocks
- **Integration Testing**: Service interaction testing
- **UI Testing**: User interaction and accessibility testing
- **Performance Testing**: Memory and CPU usage monitoring

### Build and Deployment
- **Xcode Project**: Standard iOS project structure
- **Simulator Testing**: iPad Pro 13-inch (M4) primary target
- **Device Testing**: Real device testing for performance
- **Continuous Integration**: Automated build and test pipeline

## Future Roadmap

### Planned Features
- **Recording Controls**: Camera playback and motion detection
- **Push Notifications**: Alarm event notifications
- **Widgets**: Home screen widgets for quick access
- **Apple Watch**: Companion app for quick control
- **Voice Control**: Siri integration for hands-free operation

### Technical Improvements
- **Offline Mode**: Local state caching for offline operation
- **Batch Operations**: Multiple state changes in single operation
- **Advanced Analytics**: Usage statistics and performance metrics
- **Custom Scenes**: User-defined automation scenes

## Development Standards

### Logging Standards

All logging in the Home Panel App uses the centralized DebugLogger utility:

**Requirements:**
- ❌ Never use `print()` directly in application code
- ✅ Always use `DebugLogger.log()`, `.success()`, `.error()`, `.warning()`
- ✅ Include appropriate feature flag: `.camera`, `.alarm`, `.settings`, `.hubService`, `.automation`, `.common`
- ✅ Choose appropriate log level based on operation type

**Examples:**
```swift
// Standard operations
DebugLogger.log("Loading camera configuration", feature: .camera)

// Successful operations
DebugLogger.success("PIN verification successful", feature: .alarm)

// Errors
DebugLogger.error("Failed to connect to hub: \(error)", feature: .hubService)

// Warnings
DebugLogger.warning("Device not responding", feature: .automation)
```

**Benefits:**
- Feature-specific logging control
- Consistent log format with timestamps
- Emoji-based visual indicators
- Debug-only compilation (no logs in release)

---

This comprehensive document provides essential context for AI tools to understand the Home Panel App's architecture, features, constraints, and development patterns when designing new features or providing development assistance. The app follows modern iOS development practices with a focus on security, performance, and user experience.
