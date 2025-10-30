# Hub Services

The hub services provide the core infrastructure for multi-hub coordination, device state management, and event-driven updates using modern actor-based concurrency patterns.

## 🏗️ Service Architecture

### Service Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Hub Services                             │
├─────────────────────────────────────────────────────────────────┤
│  HubServiceCoordinator  │  HubServiceProtocol  │  HubManager    │
│  (MainActor)            │  (DI Protocol)       │  (Actor)       │
├─────────────────────────────────────────────────────────────────┤
│  PollingService  │  DeviceStateCache  │  StatePublisher         │
│  (Actor)         │  (Actor)           │  (Event System)         │
├─────────────────────────────────────────────────────────────────┤
│  RoomMappingService  │  BaseHubAdapter  │  VeraHubAdapter       │
│  (Room Coordination) │  (Base Class)    │  (Vera Implementation) │
└─────────────────────────────────────────────────────────────────┘
```

## 🔧 Core Services

### HubServiceCoordinator

**Main service coordinator** managing the overall hub service lifecycle:

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
    
    func start() async {
        DebugLogger.log("Starting hub service coordinator...", feature: .hubService)
        await pollingService.startPolling()
        isRunning = true
        DebugLogger.success("Hub service coordinator started", feature: .hubService)
    }
}
```

**Key Responsibilities**:
- Hub registration and lifecycle management
- Service coordination and state publishing
- Room mapping service integration
- Polling service coordination

### HubServiceProtocol

**Protocol-based dependency injection** for hub services:

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

**Key Features**:
- Protocol-based dependency injection
- Event-driven state management
- Hub lifecycle management
- Device control and scene execution

## 🎭 Actor-Based Services

### HubManager

**Actor-based hub coordination** for thread-safe operations:

```swift
actor HubManager {
    private var hubs: [String: any HubProtocol] = [:]
    private var configurations: [String: HubConfiguration] = [:]
    private let stateCache: DeviceStateCache
    private let publishStateChange: (StateChangeEvent) -> Void
    private var hubReachabilityState: [String: Bool] = [:]
    
    func registerHub(_ hub: any HubProtocol, configuration: HubConfiguration) {
        hubs[hub.hubId] = hub
        configurations[hub.hubId] = configuration
    }
    
    func unregisterHub(hubId: String) async {
        hubs.removeValue(forKey: hubId)
        configurations.removeValue(forKey: hubId)
        await stateCache.removeDevices(forHub: hubId)
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

**Key Responsibilities**:
- Thread-safe hub registration and management
- Device state coordination across hubs
- Hub reachability monitoring
- State change event publishing

### PollingService

**Background polling coordinator** for device state updates:

```swift
actor PollingService {
    private let hubManager: HubManager
    private var pollingTasks: [String: Task<Void, Never>] = [:]
    private var isRunning = false
    
    init(hubManager: HubManager) {
        self.hubManager = hubManager
    }
    
    func startPolling() {
        guard !isRunning else { return }
        isRunning = true
        
        Task {
            let hubIds = await hubManager.getRegisteredHubIds()
            for hubId in hubIds {
                await startPolling(forHub: hubId)
            }
        }
    }
    
    func startPolling(forHub hubId: String) async {
        guard pollingTasks[hubId] == nil else { return }
        
        pollingTasks[hubId] = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                await pollHub(hubId)
            }
        }
    }
}
```

**Key Responsibilities**:
- Background polling for device state updates
- Hub-specific polling management
- Polling task lifecycle management
- Performance optimization

### DeviceStateCache

**Thread-safe device state storage** using actor pattern:

```swift
actor DeviceStateCache {
    private var deviceStates: [String: DeviceState] = [:]
    
    func updateState(for deviceId: String, state: DeviceState) {
        deviceStates[deviceId] = state
    }
    
    func getState(for deviceId: String) -> DeviceState? {
        return deviceStates[deviceId]
    }
    
    func removeDevices(forHub hubId: String) {
        deviceStates = deviceStates.filter { $0.value.hubId != hubId }
    }
    
    func getAllStates() -> [String: DeviceState] {
        return deviceStates
    }
}
```

**Key Responsibilities**:
- Thread-safe device state storage
- State retrieval and updates
- Hub-specific state management
- State cleanup and maintenance

## 📡 Event System

### StatePublisher

**Event-driven state management** using Combine:

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

**Key Features**:
- Event-driven state updates
- Combine-based reactive programming
- Thread-safe event publishing
- State change tracking

## 🏠 Room Coordination

### RoomMappingService

**Device organization and room coordination**:

```swift
class RoomMappingService {
    private let hubService: HubServiceProtocol
    
    init(hubService: HubServiceProtocol) {
        self.hubService = hubService
    }
    
    func refreshRoomMappings() async {
        // Room mapping implementation with centralized timeout
        // Uses TimeoutConfiguration for consistent timeout values
        // Coordinates device organization across hubs
    }
}
```

**Key Responsibilities**:
- Device room organization
- Cross-hub room coordination
- Device grouping and filtering
- Room-based device management
- Centralized timeout handling using TimeoutConfiguration

### Timeout Configuration

All hub services use centralized timeout values from `TimeoutConfiguration`:

- Reachability checks: `TimeoutConfiguration.reachabilityCheck` (3s)
- Standard requests: `TimeoutConfiguration.standardRequest` (30s)
- Room mapping: `TimeoutConfiguration.roomMapping` (15s)

## 🔌 Hub Adapters

### BaseHubAdapter

**Abstract base class** for hub implementations:

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

### VeraHubAdapter

**Vera hub implementation** with unified API:

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

## Reachability Check Fallback Behavior

The `BaseHubAdapter.isReachable` property implements a deliberate fallback mechanism that prioritizes availability over strict connectivity validation:

**Design Decision**: Returns `true` even when hub connection fails

**Rationale**:
- Allows app to show fallback devices with last known state
- Provides graceful degradation instead of blocking UI completely
- Better user experience during temporary connectivity issues
- Actual operations will fail with appropriate errors if hub is truly offline

**Implementation**: When the reachability check encounters an error (network timeout, connection refused, etc.), it logs a warning and returns `true`. This permits the UI to continue showing devices from the cache. Later operations that require live hub communication will fail naturally with proper error messages.

**Trade-off**: Users may see stale device states during outages, but this is preferable to showing no information at all.

## 🧪 Testing

### Unit Testing

Test individual services in isolation:

```swift
func testHubServiceCoordinator() async {
    let coordinator = HubServiceCoordinator()
    let mockHub = MockHubAdapter(hubId: "test-hub")
    
    await coordinator.registerHub(mockHub, configuration: testConfiguration)
    
    let devices = await coordinator.getAllDevices()
    XCTAssertEqual(devices.count, 2)
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

Test service interactions:

```swift
func testHubServiceIntegration() async throws {
    let coordinator = HubServiceCoordinator()
    let veraHub = VeraHubAdapter(hubId: "vera-1", configuration: testConfig)
    
    await coordinator.registerHub(veraHub, configuration: testConfig)
    await coordinator.start()
    
    let devices = await coordinator.getAllDevices()
    XCTAssertFalse(devices.isEmpty)
}
```

## 🚀 Performance

### Optimization Strategies

- **Actor-Based Concurrency**: Thread-safe operations with actors
- **Event-Driven Updates**: Reactive state management
- **Background Polling**: Efficient device state updates
- **State Caching**: Optimized device state storage
- **Memory Management**: Proper resource cleanup

### Monitoring

- **Service Performance**: Monitor actor-based service performance
- **Event Processing**: Track event-driven update performance
- **Memory Usage**: Monitor state cache memory consumption
- **Polling Efficiency**: Track polling service performance

## 🔗 Navigation

- **[Hub Integration](../README.md)** - Overall hub integration architecture
- **[Hub Models](../Models/README.md)** - Device models and hub protocols
- **[Features Overview](../../README.md)** - All app features
- **[Main App Architecture](../../../README.md)** - Overall app architecture

---

The hub services provide a comprehensive, actor-based foundation for multi-hub home automation with thread-safe operations, event-driven updates, and modern Swift concurrency patterns.
