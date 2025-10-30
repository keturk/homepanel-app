# Hub Models

The hub models provide the core data structures and protocols for multi-hub device management, state tracking, and event-driven updates using modern Swift concurrency patterns.

## 🏗️ Model Architecture

### Core Models Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Hub Models                               │
├─────────────────────────────────────────────────────────────────┤
│  HubProtocol  │  Device  │  DeviceState  │  DeviceAction       │
│  (Protocol)   │  (Model) │  (Model)      │  (Enum)            │
├─────────────────────────────────────────────────────────────────┤
│  HubConfiguration  │  HubConnection  │  HubCredentials        │
│  (Model)           │  (Model)        │  (Model)              │
├─────────────────────────────────────────────────────────────────┤
│  StateChangeEvent  │  DeviceCapability  │  DeviceHubState     │
│  (Event)          │  (Enum)           │  (Enum)             │
└─────────────────────────────────────────────────────────────────┘
```

## 🔌 Core Protocols

### HubProtocol

**Abstract hub interface** for universal hub abstraction:

```swift
protocol HubProtocol: Sendable {
    var hubId: String { get }
    var hubType: HubType { get }
    var isReachable: Bool { get async }
    
    func fetchDevices() async throws -> [Device]
    func updateDevice(deviceId: String, action: DeviceAction) async throws
    func executeScene(sceneId: String) async throws
    
    /// Fetch device states efficiently (optimized for polling)
    /// Default implementation falls back to fetchDevices(), but hubs can provide
    /// optimized implementations (e.g., using sdata endpoint for Vera)
    func fetchDeviceStates() async throws -> [Device]
}
```

**Key Features**:
- Universal hub abstraction
- Async/await concurrency
- Optimized device state fetching
- Scene execution support

### HubType

**Hub type enumeration** for type-specific behavior:

```swift
enum HubType: String, Codable, Sendable {
    case vera // All Vera hubs (Lite, Edge, Plus) use the same API
    case zigbee
    case zwave
    case homekit
    case future // For extensibility
}
```

## 📱 Device Models

### Device

**Universal device model** for all hub types:

```swift
public struct Device: Identifiable, Codable, Sendable {
    public let id: String
    let hubId: String
    let name: String
    let type: DeviceType
    let room: String?
    var state: DeviceState
    let capabilities: Set<DeviceCapability>
    
    /// Computed property to get the hub state as an enum
    public var hubState: DeviceHubState {
        DeviceHubState(hubId: hubId)
    }
}
```

**Key Properties**:
- **id**: Unique device identifier
- **hubId**: Associated hub identifier
- **name**: Human-readable device name
- **type**: Device type (light, sensor, etc.)
- **room**: Optional room location
- **state**: Current device state
- **capabilities**: Device capabilities (switchable, dimmable, etc.)

### DeviceType

**Device type enumeration** with icons:

```swift
public enum DeviceType: String, Codable, Sendable {
    case light, dimmer, lightSwitch, lock, sensor, thermostat, scene
    
    var icon: String {
        switch self {
        case .light, .lightSwitch, .dimmer:
            return "lightbulb.fill"
        case .sensor:
            return "sensor.fill"
        case .lock:
            return "lock.fill"
        case .thermostat:
            return "thermometer"
        case .scene:
            return "sparkles"
        }
    }
}
```

### DeviceState

**Device state model** with comprehensive state tracking:

```swift
public struct DeviceState: Codable, Sendable, Equatable {
    let deviceId: String
    let hubId: String
    var isOn: Bool?
    var level: Int? // 0-100 for dimmers
    var temperature: Double?
    var locked: Bool?
    var tripped: Bool?
    var status: Int? // Raw status value from hub (e.g., alarm panel state: 0=disarmed, 1=away, 2=stay, 3=night)
    let lastUpdate: Date
    
    public static func == (lhs: DeviceState, rhs: DeviceState) -> Bool {
        lhs.deviceId == rhs.deviceId &&
        lhs.hubId == rhs.hubId &&
        lhs.isOn == rhs.isOn &&
        lhs.level == rhs.level &&
        lhs.temperature == rhs.temperature &&
        lhs.locked == rhs.locked &&
        lhs.tripped == rhs.tripped &&
        lhs.status == rhs.status
    }
}
```

**Key Properties**:
- **deviceId**: Device identifier
- **hubId**: Associated hub identifier
- **isOn**: On/off state for switches
- **level**: Dimmer level (0-100)
- **temperature**: Temperature reading
- **locked**: Lock state for locks
- **tripped**: Sensor trip state
- **status**: Raw hub status value
- **lastUpdate**: Last state update timestamp

### DeviceAction

**Device action enumeration** for control operations:

```swift
public enum DeviceAction: Sendable {
    case turnOn
    case turnOff
    case setLevel(Int) // 0-100
    case lock
    case unlock
}
```

### DeviceCapability

**Device capability enumeration** for feature detection:

```swift
public enum DeviceCapability: String, Codable, Sendable {
    case switchable, dimmable, lockable, temperature, motion
}
```

### DeviceHubState

**Hub state enumeration** for device connection status:

```swift
public enum DeviceHubState: String, Sendable, Equatable {
    case placeholder
    case disconnected
    case connected // For regular hub IDs
    
    init(hubId: String) {
        switch hubId {
        case "placeholder":
            self = .placeholder
        case "disconnected":
            self = .disconnected
        default:
            self = .connected
        }
    }
}
```

## 🔧 Hub Configuration

### HubConfiguration

**Hub configuration model** for multi-hub management:

```swift
public struct HubConfiguration: Identifiable, Codable, Sendable {
    public let id: String // UUID for CloudKit
    let hubId: String
    let hubType: HubType
    var name: String // User-friendly name
    var isEnabled: Bool
    var isAlarmHub: Bool // Whether this hub handles alarm operations
    var connection: HubConnection
    var credentials: HubCredentials?
    var pollInterval: TimeInterval // seconds
    
    init(id: String = UUID().uuidString, hubId: String, hubType: HubType, name: String, isEnabled: Bool, isAlarmHub: Bool = false, connection: HubConnection, credentials: HubCredentials? = nil, pollInterval: TimeInterval = 5.0) {
        self.id = id
        self.hubId = hubId
        self.hubType = hubType
        self.name = name
        self.isEnabled = isEnabled
        self.isAlarmHub = isAlarmHub
        self.connection = connection
        self.credentials = credentials
        self.pollInterval = pollInterval
    }
}
```

**Key Properties**:
- **id**: Unique configuration identifier
- **hubId**: Hub identifier
- **hubType**: Hub type (vera, zigbee, etc.)
- **name**: User-friendly hub name
- **isEnabled**: Hub enabled status
- **isAlarmHub**: Alarm hub designation
- **connection**: Hub connection details
- **credentials**: Optional hub credentials
- **pollInterval**: Polling interval in seconds

### HubConnection

**Hub connection model** for network configuration:

```swift
public struct HubConnection: Codable, Sendable, Equatable {
    var type: ConnectionType
    var address: String // IP address or hostname
    var port: Int?
    var useHTTPS: Bool
    var credentials: HubCredentials? // Added credentials to HubConnection
    
    public enum ConnectionType: String, Codable, Sendable, CaseIterable {
        case localIP
        case remoteURL
    }
    
    static let defaultVeraPort = 3480
}
```

### HubCredentials

**Hub credentials model** for authentication:

```swift
public struct HubCredentials: Codable, Sendable, Equatable {
    let username: String?
    let password: String?
    let apiKey: String?
    let token: String?
    
    init(username: String? = nil, password: String? = nil, apiKey: String? = nil, token: String? = nil) {
        self.username = username
        self.password = password
        self.apiKey = apiKey
        self.token = token
    }
}
```

## 📡 Event Models

### StateChangeEvent

**State change event model** for event-driven updates:

```swift
public struct StateChangeEvent: Sendable {
    let device: Device
    let oldState: DeviceState?
    let newState: DeviceState
    let timestamp: Date
}
```

**Key Properties**:
- **device**: Device that changed
- **oldState**: Previous device state
- **newState**: New device state
- **timestamp**: Change timestamp

## 🧪 Testing

### Unit Testing

Test model serialization and equality:

```swift
func testDeviceSerialization() throws {
    let device = Device(
        id: "test-device",
        hubId: "test-hub",
        name: "Test Light",
        type: .light,
        room: "Living Room",
        state: DeviceState(deviceId: "test-device", hubId: "test-hub", isOn: true),
        capabilities: [.switchable]
    )
    
    let data = try JSONEncoder().encode(device)
    let decodedDevice = try JSONDecoder().decode(Device.self, from: data)
    
    XCTAssertEqual(device.id, decodedDevice.id)
    XCTAssertEqual(device.name, decodedDevice.name)
}

func testDeviceStateEquality() {
    let state1 = DeviceState(deviceId: "test", hubId: "hub", isOn: true)
    let state2 = DeviceState(deviceId: "test", hubId: "hub", isOn: true)
    let state3 = DeviceState(deviceId: "test", hubId: "hub", isOn: false)
    
    XCTAssertEqual(state1, state2)
    XCTAssertNotEqual(state1, state3)
}
```

### Integration Testing

Test model interactions:

```swift
func testHubConfiguration() {
    let connection = HubConnection(
        type: .localIP,
        address: "192.168.1.100",
        port: 3480,
        useHTTPS: false
    )
    
    let config = HubConfiguration(
        hubId: "vera-1",
        hubType: .vera,
        name: "Living Room Hub",
        isEnabled: true,
        isAlarmHub: true,
        connection: connection
    )
    
    XCTAssertEqual(config.hubType, .vera)
    XCTAssertTrue(config.isAlarmHub)
    XCTAssertEqual(config.connection.address, "192.168.1.100")
}
```

## 🚀 Performance

### Optimization Strategies

- **Sendable Conformance**: Thread-safe model types
- **Codable Support**: Efficient serialization
- **Equatable Implementation**: Fast equality comparisons
- **Memory Efficiency**: Optimized model structures

### Best Practices

- Use `Sendable` for thread-safe models
- Implement `Equatable` for state comparisons
- Use `Codable` for persistence
- Keep models lightweight and focused

## 🔗 Navigation

- **[Hub Services](../Services/README.md)** - Hub service implementations
- **[Hub Integration](../README.md)** - Overall hub integration architecture
- **[Features Overview](../../README.md)** - All app features
- **[Main App Architecture](../../../README.md)** - Overall app architecture

---

The hub models provide comprehensive data structures and protocols for multi-hub device management with modern Swift concurrency patterns, thread-safe operations, and efficient serialization.
