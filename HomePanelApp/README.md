# Home Panel App - Architecture Overview

The Home Panel App is a modern iOS home automation application built with SwiftUI, specifically designed for iPad but compatible with iPhone. This document provides a comprehensive overview of the app's architecture, design patterns, and core components.

**Current Status**: All core features are fully implemented and production-ready with modern Swift 6.0 concurrency patterns, adapter pattern architecture, and comprehensive security features.

## 🏗️ Architecture Overview

The app follows modern iOS development practices with a clean MVVM architecture, protocol-based dependency injection, and Swift 6.0 concurrency model.

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                            │
├─────────────────────────────────────────────────────────────────┤
│  AlarmTabView  │  CameraGridView  │  AutomationTabView  │  ...  │
└─────────────────┬───────────────────┬─────────────────┬─────────┘
                  │                   │                 │
┌─────────────────▼───────────────────▼─────────────────▼─────────┐
│                      ViewModels                                │
├─────────────────────────────────────────────────────────────────┤
│  AlarmViewModel  │  CameraViewModel  │  AutomationViewModel  │   │
└─────────────────┬───────────────────┬─────────────────┬─────────┘
                  │                   │                 │
┌─────────────────▼───────────────────▼─────────────────▼─────────┐
│                       Services                                │
├─────────────────────────────────────────────────────────────────┤
│  UnifiedAlarmService  │  SceneServiceCoordinator  │  PINService  │  ...     │
└─────────────────┬───────────────────┬─────────────────┬─────────┘
                  │                   │                 │
┌─────────────────▼───────────────────▼─────────────────▼─────────┐
│                      Data Models                               │
├─────────────────────────────────────────────────────────────────┤
│  AlarmState  │  PINData  │  Device  │  ...   │
└─────────────────────────────────────────────────────────────────┘
```

## 🎯 Design Patterns

### MVVM (Model-View-ViewModel)

The app follows the MVVM pattern for clean separation of concerns:

- **Models**: Data structures and business entities
- **Views**: SwiftUI views for UI presentation  
- **ViewModels**: Business logic and state management

```swift
// Example: AlarmViewModel
@MainActor
class AlarmViewModel: ObservableObject {
    @Published var currentState: AlarmState = .unknown
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let alarmService: AlarmServiceProtocol
    private let sceneService: SceneServiceProtocol
    
    func refreshState() {
        // Business logic here
    }
}
```

### Dependency Injection

Protocol-based dependency injection for improved testability:

```swift
protocol AlarmServiceProtocol {
    func fetchAlarmState() async throws -> AlarmState
}

protocol SceneServiceProtocol {
    func fetchSceneList(hubId: String) async throws -> HubScopedSceneMap
    func setAlarmMode(_ mode: AlarmMode, hubScopedSceneMap: HubScopedSceneMap, hubId: String) async throws
}

class AlarmViewModel {
    private let alarmService: AlarmServiceProtocol
    private let sceneService: SceneServiceProtocol
    
    init(alarmService: AlarmServiceProtocol, sceneService: SceneServiceProtocol) {
        self.alarmService = alarmService
        self.sceneService = sceneService
    }
}
```

### Repository Pattern

Services act as repositories for external data sources:

- **UnifiedAlarmService**: Unified alarm state management
- **SceneServiceCoordinator**: Scene operations coordinator with adapter pattern
- **KeychainService**: Secure credential storage
- **PINManagementService**: PIN data management

## 🔧 Core Components

### Services Layer

| Service | Responsibility | Dependencies |
|---------|---------------|--------------|
| `UnifiedAlarmService` | Modern alarm state management | `HubServiceProtocol`, `AppConfigurationProtocol` |
| `SceneServiceCoordinator` | Scene operations coordinator | `HubServiceProtocol`, `URLSession` |
| `HubServiceCoordinator` | Multi-hub coordination | `HubManager`, `PollingService`, `StatePublisher` |
| `HubManager` | Actor-based hub management | `DeviceStateCache`, `StatePublisher` |
| `PollingService` | Background device polling | `HubManager` |
| `DeviceStateCache` | Thread-safe state storage | Actor-based concurrency |
| `StatePublisher` | Event-driven state updates | Combine publishers |
| `RoomMappingService` | Device organization | `HubServiceProtocol` |
| `PINManagementService` | PIN CRUD operations | `KeychainService`, `LockoutManager` |
| `AlarmLockoutService` | Alarm-specific lockout management | `LockoutManager` |
| `LockoutManager` | Base lockout functionality | `KeychainService` |
| `KeychainService` | Secure storage operations | iOS Keychain |
| `CameraConfigService` | Camera configuration management | `KeychainService`, `UserDefaults` |

### Data Models

| Model | Purpose | Key Properties |
|-------|---------|----------------|
| `AlarmState` | Alarm system states | `rawValue`, `backgroundColor`, `iconName` |
| `AlarmMode` | Alarm mode operations | `sceneName`, `expectedState`, `buttonColor` |
| `Device` | Universal device model | `id`, `name`, `type`, `room`, `state`, `capabilities` |
| `ConfiguredItem` | UI device representation | `name`, `veraId`, `hubIP`, `type`, `isFound` |
| `PINData` | User PIN information | `pinHash`, `salt`, `name`, `lastUsed` |
| `MasterPINData` | Master PIN information | `pinHash`, `salt`, `lastUsed` |
| `CameraConfig` | Camera configuration | `ipAddress`, `port`, `username`, `path` |
| `CameraCredentials` | Camera credentials | `cameraId`, `password`, `lastUpdated` |

### ViewModels

| ViewModel | Purpose | Key Responsibilities |
|-----------|---------|---------------------|
| `AlarmViewModel` | Alarm state management | State polling, mode changes, PIN validation |
| `CameraViewModel` | Camera management | Blue Iris integration, configuration management |
| `AutomationViewModel` | Device and scene control | Multi-hub polling, device matching, state management |

## 🧵 Concurrency Model

### Mixed Concurrency Patterns

Modern Swift concurrency with actor-based services and @MainActor coordinators:

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

@MainActor
class AlarmViewModel: ObservableObject {
    @Published var currentState: AlarmState = .unknown
    @Published var isLoading = false
    
    func refreshState() async {
        // UI updates are automatically on main thread
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

## 🔒 Security Architecture

### Multi-Layer Security

1. **Network Security**
   - Local network only (no external communication)
   - HTTPS for external APIs when needed
   - Request timeout and retry logic

2. **Data Security**
   - Keychain storage for all credentials
   - PIN hashing with salt
   - Secure credential management

3. **Access Control**
   - PIN-based authentication for all operations
   - Master PIN for administrative functions
   - Advanced lockout system with prime number delays

### Security Flow

```
User Action → PIN Validation → Service Call → External API
     ↓              ↓              ↓            ↓
UI Update ← State Update ← Response Parse ← Network Response
```

## 📱 UI Architecture

### SwiftUI Best Practices

- **Declarative UI**: State-driven interface updates
- **Component Reusability**: Shared components in `Views/Components/`
- **Accessibility**: VoiceOver support and accessibility labels
- **Responsive Design**: Works on iPhone and iPad

### State Management

- **@Published Properties**: Reactive UI updates
- **@StateObject**: ViewModel lifecycle management
- **@ObservedObject**: Service dependency injection
- **@Environment**: Shared configuration and services

## 🔄 Data Flow

### Alarm State Management

```
User Tap → ViewModel → Service → Vera Hub API
    ↓         ↓         ↓           ↓
UI Update ← State ← Response ← JSON Data
```

### Camera Management

```
View Appear → ViewModel → Web View → Blue Iris
     ↓           ↓           ↓          ↓
UI Display ← Web Content ← HTML/JS ← Blue Iris UI
```

## 🧪 Testing Architecture

### Testability Features

- **Protocol-Based Services**: Easy mocking for unit tests
- **Dependency Injection**: Testable ViewModels
- **Error Handling**: Comprehensive error scenarios
- **State Management**: Predictable state changes

### Testing Strategy

1. **Unit Tests**: ViewModels and Services
2. **Integration Tests**: API communication
3. **UI Tests**: User interaction flows
4. **Performance Tests**: Memory and CPU usage

## 📊 Performance Considerations

### Memory Management

- **Web View Lifecycle**: Automatic pause/resume for off-screen cameras
- **Configuration Caching**: Efficient configuration storage and cleanup
- **Timer Management**: Proper timer invalidation

### Network Optimization

- **Request Batching**: Combine multiple API calls
- **Timeout Management**: Appropriate timeouts for different operations
- **Error Recovery**: Retry logic with exponential backoff

## 🔮 Future Architecture Considerations

### Scalability

- **Modular Design**: Easy to add new features
- **Protocol Extensions**: Simple to add new service types
- **Configuration Management**: Centralized settings

### Maintainability

- **Clear Separation**: Each layer has distinct responsibilities
- **Documentation**: Comprehensive code documentation
- **Code Standards**: Consistent coding patterns

## 📁 Project Structure

```
HomePanelApp/
├── App/                    # Application entry point and DI container
├── Core/                   # Core infrastructure and shared models
│   ├── Errors/            # Error definitions
│   ├── Models/            # Core data models
│   └── Services/          # Core services (Keychain, Cloud)
├── Features/              # Feature-specific modules
│   ├── Alarm/            # Alarm system
│   ├── Camera/           # Camera surveillance
│   ├── Automation/       # Device automation
│   ├── Hub/              # Hub integration
│   └── Settings/         # Settings management
├── Shared/               # Shared components and utilities
│   ├── Components/       # Reusable UI components
│   ├── DesignSystem/     # Design system
│   └── Utilities/        # Helper functions
└── Resources/            # Assets and configuration
```

## 🔗 Navigation

- **[Features Overview](Features/README.md)** - All app features
- **[Core Infrastructure](Core/README.md)** - Core services and models
- **[Shared Components](Shared/README.md)** - Reusable components
- **[App Entry Point](App/README.md)** - Dependency injection and app setup

## 📚 Additional Documentation

- **[PROJECT_CONTEXT.md](../PROJECT_CONTEXT.md)** - Comprehensive project context for AI tools
- **[Integration Guides](../docs/README.md)** - External API integration documentation
- **[Development Guides](../docs/development/)** - Setup, building, and testing

---

This architecture provides a solid foundation for the Home Panel App while maintaining flexibility for future enhancements and improvements.
