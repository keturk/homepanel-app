# Hub Integration

The hub integration system provides universal hub abstraction and multi-hub coordination using modern actor-based architecture, supporting multiple hub types and protocols with centralized state management.

## 🌐 Overview

The hub system enables seamless integration with multiple home automation hubs through a sophisticated service coordinator pattern, providing a unified interface for device control, state management, and scene execution across different hub types using actor-based concurrency.

## 🏗️ Architecture

### Modern Service Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Hub Integration Architecture                │
├─────────────────────────────────────────────────────────────────┤
│  HubServiceCoordinator  │  HubServiceProtocol  │  HubManager    │
│  (MainActor)            │  (DI Protocol)       │  (Actor)       │
├─────────────────────────────────────────────────────────────────┤
│  PollingService  │  DeviceStateCache  │  StatePublisher         │
│  (Actor)         │  (Actor)           │  (Event System)         │
├─────────────────────────────────────────────────────────────────┤
│  RoomMappingService  │  BaseHubAdapter  │  VeraHubAdapter       │
│  (Room Coordination) │  (Base Class)    │  (Vera Implementation)  │
└─────────────────────────────────────────────────────────────────┘
```

### Service Coordinator Pattern

The hub integration uses a modern service coordinator pattern with actor-based concurrency:

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

### Actor-Based Services

Thread-safe services using Swift actors for concurrent operations:

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

actor PollingService {
    private var pollingTasks: [String: Task<Void, Never>] = [:]
    private var isRunning = false
    
    func startPolling(forHub hubId: String) async {
        guard !isRunning else { return }
        isRunning = true
        
        pollingTasks[hubId] = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                // Polling implementation
            }
        }
    }
}

actor DeviceStateCache {
    private var deviceStates: [String: DeviceState] = [:]
    
    func updateState(for deviceId: String, state: DeviceState) {
        deviceStates[deviceId] = state
    }
    
    func getState(for deviceId: String) -> DeviceState? {
        return deviceStates[deviceId]
    }
}
```

## 🔧 Core Features

### Hub Service Protocol

Protocol-based dependency injection for hub services:

```swift
@MainActor
protocol HubServiceProtocol: AnyObject {
    var stateChangePublisher: AnyPublisher<StateChangeEvent, Never> { get }
    var isRunning: Bool { get }
    var registeredHubIds: [String] { get }
    
    func start() async
    func stop() async
    func registerHub(_ hub: any HubProtocol, configuration: HubConfiguration) async
    func unregisterHub(hubId: String) async
    func updateHubConfiguration(hubId: String, newConfiguration: HubConfiguration) async
    
    func getDevice(deviceId: String) async -> Device?
    func getDevices(forHub hubId: String) async -> [Device]
    func getAllDevices() async -> [Device]
    func getRegisteredHubs() async -> [HubConfiguration]
    
    func controlDevice(deviceId: String, action: DeviceAction) async throws
    func executeScene(sceneId: String, hubId: String) async throws
    
    func refreshHub(hubId: String) async throws
    func refreshAll() async
    func refreshRoomMappingsAfterRegistration() async
    
    func publisher(forHub hubId: String) -> AnyPublisher<StateChangeEvent, Never>
    func publisher(forDevice deviceId: String) -> AnyPublisher<StateChangeEvent, Never>
}
```

### Multi-Hub Support

Support for multiple hub types and protocols:

- **Vera Hubs**: Vera Lite, Edge, Plus with unified API
- **Protocol Abstraction**: Extensible for future hub types
- **Hub Discovery**: Automatic hub detection and configuration
- **Hub Management**: Add, remove, and configure hubs
- **Actor-Based Coordination**: Thread-safe multi-hub operations

### Device Fetching Methods

The hub system provides two methods for fetching devices:

- **`fetchDeviceStates()`**: The preferred method for fetching device states. This is optimized for polling and uses efficient endpoints (e.g., sdata for Vera hubs).
- **`fetchDevices()`**: Required by `HubProtocol` for protocol conformance. This method delegates to `fetchDeviceStates()` and should not be called directly.

**Note**: Always use `fetchDeviceStates()` in your code. The `fetchDevices()` method exists only for protocol compliance.

### Device State Management

Centralized device state coordination with actor-based caching:

- **Actor-Based State Cache**: Thread-safe device state storage
- **Real-time Updates**: Live state synchronization through StatePublisher
- **State Publishing**: Event-driven state updates with Combine
- **Conflict Resolution**: Handle state conflicts across hubs
- **Room Mapping**: Device organization through RoomMappingService

### Event-Driven Architecture

Modern event-driven state management:

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

struct StateChangeEvent: Sendable {
    let device: Device
    let oldState: DeviceState?
    let newState: DeviceState
    let timestamp: Date
}
```

## 🌐 Hub Adapters

### Adapter Pattern Implementation

Abstract base class for hub implementations:

```swift
class BaseHubAdapter: @unchecked Sendable {
    let hubId: String
    let hubType: HubType
    let configuration: HubConfiguration
    
    init(hubId: String, hubType: HubType, configuration: HubConfiguration) {
        self.hubId = hubId
        self.hubType = hubType
        self.configuration = configuration
    }
    
    func buildBaseURL() -> URL? {
        URL(string: "http://\(configuration.ipAddress):\(configuration.port)")
    }
    
    func checkConnectivity() async -> Bool {
        guard let url = buildBaseURL() else { return false }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}
```

### Vera Hub Adapter

Vera hub implementation with unified API:

```swift
class VeraHubAdapter: @unchecked Sendable, HubProtocol {
    let hubId: String
    let hubType: HubType = .vera
    private let configuration: VeraHubConfiguration
    
    var isReachable: Bool {
        get async {
            return await checkHubConnectivity()
        }
    }
    
    func fetchDevices() async throws -> [Device] {
        let url = buildDevicesURL()
        let (data, response) = try await URLSession.shared.data(from: url)
        return try parseDevices(from: data)
    }
    
    func updateDevice(deviceId: String, action: DeviceAction) async throws {
        let url = buildDeviceActionURL(deviceId: deviceId, action: action)
        let (_, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw HubError.deviceUpdateFailed
        }
    }
}
```

## 🔄 State Management

### Hub Coordination

Actor-based hub management and coordination:

```swift
// HubServiceCoordinator manages the overall service lifecycle
@MainActor
class HubServiceCoordinator: ObservableObject {
    func start() async {
        DebugLogger.log("Starting hub service coordinator...", feature: .hubService)
        await pollingService.startPolling()
        isRunning = true
        DebugLogger.success("Hub service coordinator started", feature: .hubService)
    }
    
    func stop() async {
        await pollingService.stopAllPolling()
        isRunning = false
    }
}
```

### Room Mapping Service

Device organization and room coordination:

```swift
class RoomMappingService {
    private let hubService: HubServiceProtocol
    
    init(hubService: HubServiceProtocol) {
        self.hubService = hubService
    }
    
    func refreshRoomMappings() async {
        // Room mapping implementation with centralized timeout
        // Uses global withTimeout() function from AsyncUtilities
    }
}
```

## Fallback Device Mechanism

The hub integration implements graceful degradation when hubs become unreachable:

### How It Works

1. **Reachability Check**: `BaseHubAdapter.isReachable` returns `true` even on connection errors
2. **UI Continuity**: App continues to display device controls using cached state
3. **Last Known State**: Users can view device status from the most recent successful fetch
4. **Natural Failure**: Operations attempted on offline hubs fail with appropriate error messages

### Design Philosophy

This approach prioritizes **availability over accuracy**:
- **Better UX**: Show something rather than nothing during temporary outages
- **Graceful Degradation**: App remains functional with cached data
- **Clear Feedback**: Actual control operations provide error messages if hub is offline
- **Home Automation Priority**: Users need visibility into their devices even during connectivity issues

### Implementation Details

See `BaseHubAdapter.isReachable` in `Services/BaseHubAdapter.swift` for the implementation and detailed comments.

## 🧪 Testing

### Unit Testing

Test hub integration logic with actor-based services:

```swift
func testHubServiceCoordinator() async {
    let coordinator = HubServiceCoordinator()
    let mockHub = MockHubAdapter(hubId: "test-hub")
    
    await coordinator.registerHub(mockHub, configuration: testConfiguration)
    
    let devices = await coordinator.getAllDevices()
    XCTAssertEqual(devices.count, 2)
    XCTAssertEqual(devices.first?.hubId, "test-hub")
}

func testDeviceStateCache() async {
    let cache = DeviceStateCache()
    let deviceId = "test-device"
    let state = DeviceState(deviceId: deviceId, isOn: true)
    
    await cache.updateState(for: deviceId, state: state)
    
    let cachedState = await cache.getState(for: deviceId)
    XCTAssertEqual(cachedState?.isOn, true)
}
```

### Integration Testing

Test with real hub services:

```swift
func testVeraHubIntegration() async throws {
    let configuration = VeraHubConfiguration(ipAddress: "192.168.1.100", port: 3480)
    let adapter = VeraHubAdapter(hubId: "vera-1", configuration: configuration)
    
    let isReachable = await adapter.isReachable
    XCTAssertTrue(isReachable)
    
    let devices = try await adapter.fetchDeviceStates()
    XCTAssertFalse(devices.isEmpty)
}
```

## 🔧 Configuration

### Hub Configuration

Hub setup and configuration management:

- **IP Address**: Hub network address
- **Port**: Hub communication port
- **Authentication**: Hub credentials and security
- **Polling Interval**: Device state update frequency
- **Actor-Based Management**: Thread-safe configuration updates

### Device Configuration

Device management and filtering:

- **Device Discovery**: Automatic device detection
- **Device Filtering**: Name and type-based filtering
- **Device Grouping**: Logical device organization through RoomMappingService
- **State Preferences**: Default device states

## 🚀 Performance

### Optimization Strategies

- **Actor-Based Concurrency**: Thread-safe operations with actors
- **Parallel Processing**: Simultaneous hub operations
- **State Caching**: Efficient device state storage with DeviceStateCache actor
- **Event-Driven Updates**: Reactive state management with Combine
- **Memory Management**: Proper resource cleanup

### Monitoring

- **Hub Connectivity**: Track hub connection status
- **Response Times**: Monitor hub communication performance
- **Error Rates**: Track hub operation failures
- **State Sync**: Monitor state synchronization accuracy
- **Actor Performance**: Monitor actor-based service performance

## 🔮 Future Enhancements

### Planned Features

- **Additional Hub Types**: Zigbee, Z-Wave, HomeKit support
- **Hub Federation**: Cross-hub device control
- **Advanced Polling**: Intelligent polling strategies
- **Hub Analytics**: Usage and performance metrics

### Technical Improvements

- **Protocol Extensions**: Support for new hub protocols
- **State Optimization**: Advanced state management
- **Error Recovery**: Enhanced error handling
- **Performance Tuning**: Optimized hub communication
- **Actor Optimization**: Enhanced actor-based concurrency patterns

## 📁 File Structure

- **[Models](Models/README.md)** - Universal device models and hub protocols
- **[Services](Services/README.md)** - Hub management, polling, and state coordination

## 🔗 Navigation

- **[Features Overview](../README.md)** - All app features
- **[Main App Architecture](../../README.md)** - Overall app architecture
- **[Core Infrastructure](../../Core/README.md)** - Shared infrastructure
- **[Shared Components](../../Shared/README.md)** - Reusable components

---

The hub integration system provides a robust, actor-based foundation for multi-hub home automation with universal device abstraction, centralized state management, and modern Swift concurrency patterns.