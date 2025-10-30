# Vera Hub API Integration

The Vera Hub API integration provides comprehensive communication with Vera home automation hubs for alarm control, scene management, and device monitoring through the adapter pattern architecture.

**Current Implementation**: Fully implemented with modern Swift 6.0 concurrency, actor-based services, and comprehensive error handling.

## 🌐 Overview

The Vera Hub integration uses the local HTTP API (Luup Requests) to communicate with Vera hubs on the local network. It supports scene execution, device status monitoring, and dynamic scene discovery. This integration uses the adapter pattern where generic protocols are implemented by Vera-specific adapters, allowing for future support of other hub types.

## 🏗️ Architecture

### API Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    Vera Hub API Architecture                   │
├─────────────────────────────────────────────────────────────────┤
│  SceneServiceCoordinator  │  VeraSceneAdapter  │  HubService     │
│  Scene Execution      │  Scene Discovery  │  Device Status   │
└─────────────────┬─────────────────┬─────────────────┬───────────┘
                  │                 │                 │
┌─────────────────▼─────────────────▼─────────────────▼───────────┐
│                    API Endpoints                               │
├─────────────────────────────────────────────────────────────────┤
│  Scene List  │  Scene Execution  │  Device Status  │  User Data │
└─────────────────────────────────────────────────────────────────┘
```

### Service Protocols

**AlarmServiceProtocol**:
```swift
@MainActor
protocol AlarmServiceProtocol: Sendable {
    func fetchAlarmState() async throws -> AlarmState
}

**SceneServiceProtocol**:
```swift
@MainActor
protocol SceneServiceProtocol: Sendable {
    func fetchSceneList(hubId: String) async throws -> HubScopedSceneMap
    func setAlarmMode(_ mode: AlarmMode, hubScopedSceneMap: HubScopedSceneMap, hubId: String) async throws
}
```

**HubServiceProtocol**:
```swift
@MainActor
protocol HubServiceProtocol: Sendable {
    func getAllDevices() async -> [Device]
    func controlDevice(deviceId: String, action: DeviceAction) async throws
    func executeScene(sceneId: String, hubId: String) async throws
}
```

## 🔧 API Endpoints

### Scene List Endpoint

**URL**: `http://{IP}:3480/data_request?id=user_data`

**Purpose**: Fetch all available scenes from Vera Hub

**Method**: GET

**Response Format**: JSON

**Example Response**:
```json
{
  "scenes": [
    {
      "id": 1,
      "name": "Set Away Mode",
      "room": 0,
      "active": 1
    },
    {
      "id": 2,
      "name": "Set Stay Mode",
      "room": 0,
      "active": 1
    }
  ]
}
```

**Implementation**:
```swift
func fetchSceneList() async throws -> [String: Int] {
    let veraHubIP = await veraHubConfig.veraHubIP
    let urlString = "http://\(veraHubIP):3480/data_request?id=user_data"
    
    guard let url = URL(string: urlString) else {
        throw VeraHubError.invalidURL
    }
    
    let (data, response) = try await session.data(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw VeraHubError.networkError(URLError(.badServerResponse))
    }
    
    let userDataResponse = try JSONDecoder().decode(VeraHubUserDataResponse.self, from: data)
    
    guard let scenes = userDataResponse.allScenes else {
        throw VeraHubError.sceneNotFound("No scenes found")
    }
    
    var sceneMap: [String: Int] = [:]
    for scene in scenes {
        sceneMap[scene.name] = scene.id
    }
    
    return sceneMap
}
```

### Scene Execution Endpoint

**URL**: `http://{IP}:3480/data_request?id=lu_action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=RunScene&SceneNum={ID}`

**Purpose**: Execute a specific scene

**Method**: GET

**Parameters**:
- `id`: `lu_action` (request type)
- `serviceId`: `urn:micasaverde-com:serviceId:HomeAutomationGateway1`
- `action`: `RunScene`
- `SceneNum`: Scene ID number

**Example Request**:
```
http://192.168.1.100:3480/data_request?id=lu_action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=RunScene&SceneNum=1
```

**Implementation**:
```swift
func setAlarmMode(_ mode: AlarmMode, sceneMap: [String: Int]) async throws {
    let veraHubIP = await veraHubConfig.veraHubIP
    let sceneName = mode.sceneName
    
    guard let sceneId = sceneMap[sceneName] else {
        throw VeraHubError.sceneNotFound(sceneName)
    }
    
    let urlString = "http://\(veraHubIP):3480/data_request?id=lu_action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=RunScene&SceneNum=\(sceneId)"
    
    guard let url = URL(string: urlString) else {
        throw VeraHubError.invalidURL
    }
    
    let (data, response) = try await session.data(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw VeraHubError.networkError(URLError(.badServerResponse))
    }
    
    // Parse response for error checking
    if let responseString = String(data: data, encoding: .utf8),
       responseString.contains("error") {
        throw VeraHubError.sceneExecutionFailed(sceneName)
    }
}
```

### Device Status Endpoint (Legacy)

**URL**: `http://{IP}:3480/data_request?id=status&DeviceNum={ID}&output_format=json`

**Purpose**: Fetch device status information (legacy endpoint)

**Method**: GET

**Status**: ⚠️ **DEPRECATED** - Use sdata endpoint for polling instead

**Note**: This endpoint returns large responses (~60-240KB) and is no longer used for device polling. The app now uses the sdata endpoint which provides 91-96% bandwidth reduction (~1-21KB responses).

**Parameters**:
- `id`: `status`
- `DeviceNum`: Device ID number
- `output_format`: `json`

**Example Request**:
```
http://192.168.1.100:3480/data_request?id=status&DeviceNum=7&output_format=json
```

**Example Response**:
```json
{
  "Device_Num_7": {
    "id": 7,
    "name": "Ademco Vista",
    "states": [
      {
        "id": 0,
        "service": "urn:micasaverde-com:serviceId:SecuritySensor1",
        "variable": "Armed",
        "value": "1"
      }
    ],
    "armed": "1",
    "state": "Armed Away",
    "status": 1
  }
}
```

**Legacy Implementation** (no longer used):
```swift
// DEPRECATED: This method has been replaced by sdata endpoint polling
func fetchAlarmState() async throws -> AlarmState {
    let veraHubIP = await veraHubConfig.veraHubIP
    let alarmDeviceId = await veraHubConfig.alarmDeviceId
    let urlString = "http://\(veraHubIP):3480/data_request?id=status&DeviceNum=\(alarmDeviceId)&output_format=json"
    
    guard let url = URL(string: urlString) else {
        throw VeraHubError.invalidURL
    }
    
    let (data, response) = try await session.data(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw VeraHubError.networkError(URLError(.badServerResponse))
    }
    
    return try await alarmStateParser.parseAlarmState(from: data)
}
```

### SData Endpoint (Preferred for Polling)

**URL**: `http://{IP}:3480/data_request?id=sdata&output_format=json`

**Purpose**: Fetch device states efficiently for polling

**Method**: GET

**Status**: ✅ **CURRENT** - Primary endpoint for device polling

**Benefits**:
- 91-96% bandwidth reduction compared to status endpoint
- Optimized for frequent polling (every 5 seconds)
- Contains all necessary device information for UI updates
- Saves ~2.3GB/day when polling 3 hubs every 5 seconds

**Parameters**:
- `id`: `sdata`
- `output_format`: `json`

**Example Request**:
```
http://192.168.1.100:3480/data_request?id=sdata&output_format=json
```

**Implementation**:
```swift
func fetchDeviceStates() async throws -> [Device] {
    let (data, _) = try await baseAdapter.makeRequest(to: "/data_request?id=sdata&output_format=json")
    
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw HubError.invalidResponse
    }
    
    var devices: [Device] = []
    
    if let devicesArray = json["devices"] as? [[String: Any]] {
        for deviceJson in devicesArray {
            if let device = parseSDataDevice(deviceJson) {
                devices.append(device)
            }
        }
    }
    
    return devices
}
```

## 📊 Data Models

### VeraHubUserDataResponse

**Purpose**: Scene list response parsing

```swift
struct VeraHubUserDataResponse: Codable {
    let sections: [VeraHubSection]?
    let scenes: [VeraHubScene]?
    let categoryFilter: [VeraHubCategoryFilter]?
    
    var allScenes: [VeraHubScene]? {
        var foundScenes: [VeraHubScene] = []
        
        if let topLevelScenes = scenes {
            foundScenes.append(contentsOf: topLevelScenes)
        }
        
        if let sections = sections {
            for section in sections {
                if let id = section.id, let name = section.name {
                    let scene = VeraHubScene(id: id, name: name, room: nil, active: nil)
                    foundScenes.append(scene)
                }
                if let sectionScenes = section.scenes {
                    foundScenes.append(contentsOf: sectionScenes)
                }
            }
        }
        
        return foundScenes.isEmpty ? nil : foundScenes
    }
}
```

### VeraHubScene

**Purpose**: Individual scene information

```swift
struct VeraHubScene: Codable {
    let id: Int
    let name: String
    let room: Int?
    let active: Int?
}
```

### VeraHubDeviceStatusResponse

**Purpose**: Device status response parsing

```swift
struct VeraHubDeviceStatusResponse: Codable {
    let devices: [String: VeraHubDevice]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dictionary = try container.decode([String: AnyCodable].self)
        
        var devices: [String: VeraHubDevice] = [:]
        for (key, value) in dictionary {
            if key.hasPrefix("Device_Num_") {
                let jsonData = try JSONSerialization.data(withJSONObject: value.value)
                let device = try JSONDecoder().decode(VeraHubDevice.self, from: jsonData)
                devices[key] = device
            }
        }
        self.devices = devices.isEmpty ? nil : devices
    }
}
```

## 🔧 Error Handling

### VeraHubError

**Purpose**: Comprehensive error handling for Vera Hub operations

```swift
enum VeraHubError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case parsingError(Error)
    case sceneNotFound(String)
    case deviceNotFound(Int)
    case sceneExecutionFailed(String)
    case invalidResponse
    case timeout
}
```

**Error Descriptions**:
```swift
var errorDescription: String? {
    switch self {
    case .invalidURL:
        return "Invalid URL for Vera Hub request"
    case .networkError(let error):
        return "Network error: \(error.localizedDescription)"
    case .parsingError(let error):
        return "Failed to parse response: \(error.localizedDescription)"
    case .sceneNotFound(let sceneName):
        return "Scene '\(sceneName)' not found on Vera Hub"
    case .deviceNotFound(let deviceId):
        return "Device \(deviceId) not found on Vera Hub"
    case .sceneExecutionFailed(let sceneName):
        return "Failed to execute scene '\(sceneName)'"
    case .invalidResponse:
        return "Invalid response from Vera Hub"
    case .timeout:
        return "Request timed out"
    }
}
```

## 🔄 State Parsing

### AlarmStateParser

**Purpose**: Parse alarm state from Vera Hub responses

```swift
@MainActor
class VeraHubAlarmStateParser: AlarmStateParserProtocol {
    private let veraHubConfig: VeraHubConfiguration
    
    func parseAlarmState(from data: Data) async throws -> AlarmState {
        let response = try JSONDecoder().decode(VeraHubDeviceStatusResponse.self, from: data)
        
        guard let devices = response.devices else {
            throw VeraHubError.invalidResponse
        }
        
        // Find the alarm device
        let deviceKey = "Device_Num_\(veraHubConfig.alarmDeviceId)"
        guard let device = devices[deviceKey] else {
            throw VeraHubError.deviceNotFound(veraHubConfig.alarmDeviceId)
        }
        
        // Parse armed state
        if let armed = device.armed {
            return parseArmedState(armed)
        } else if let state = device.state {
            return parseStateString(state)
        } else {
            return .unknown
        }
    }
    
    private func parseArmedState(_ armed: String) -> AlarmState {
        switch armed {
        case "0": return .disarmed
        case "1": return .armedAway
        case "2": return .armedStay
        case "3": return .armedNightStay
        default: return .unknown
        }
    }
    
    private func parseStateString(_ state: String) -> AlarmState {
        switch state.lowercased() {
        case "disarmed": return .disarmed
        case "armed away": return .armedAway
        case "armed stay": return .armedStay
        case "armed night-stay": return .armedNightStay
        default: return .unknown
        }
    }
}
```

## 🧪 Testing

### Unit Testing

Test individual API methods:

```swift
func testSceneListFetching() async throws {
    let mockService = MockSceneService()
    let scenes = try await mockService.fetchSceneList()
    XCTAssertEqual(scenes["Set Away Mode"], 1)
}

func testSceneExecution() async throws {
    let mockService = MockSceneService()
    let sceneMap = ["Set Away Mode": 1]
    try await mockService.setAlarmMode(.away, sceneMap: sceneMap)
    // Verify scene was executed
}
```

### Integration Testing

Test with real Vera Hub:

```swift
func testRealVeraHubIntegration() async throws {
    let config = AppConfiguration()
    config.veraHubIP = "192.168.1.100"
    
    let sceneService = SceneServiceCoordinator(hubService: hubService, session: URLSession.shared)
    let alarmService = UnifiedAlarmService(hubService: hubService, config: config)
    
    let scenes = try await sceneService.fetchSceneList()
    XCTAssertFalse(scenes.isEmpty)
    
    let alarmState = try await alarmService.fetchAlarmState()
    XCTAssertNotEqual(alarmState, .unknown)
}
```

### Error Testing

Test error scenarios:

```swift
func testNetworkError() async throws {
    let service = SceneServiceCoordinator(hubService: hubService, session: URLSession.shared)
    
    do {
        _ = try await service.fetchSceneList()
        XCTFail("Should have thrown an error")
    } catch {
        XCTAssertTrue(error is VeraHubError)
    }
}
```

## 🔧 Configuration

### Network Settings

**Default Configuration**:
- IP Address: 192.168.1.100
- Port: 3480
- Protocol: HTTP
- Timeout: 15 seconds

**Custom Configuration**:
```swift
let config = AppConfiguration()
config.veraHubIP = "192.168.1.100"
config.alarmDeviceId = 7
config.refreshInterval = 5.0
```

### Security Considerations

**Local Network Only**:
- No external network communication
- HTTP only (local network)
- No authentication required
- Firewall protection

**Error Handling**:
- Comprehensive error messages
- User-friendly error display
- Retry logic for transient errors
- Fallback mechanisms

## 🚀 Performance

### Optimization

**Caching**:
- Scene list caching
- State caching
- Connection pooling
- Request batching

**Network Efficiency**:
- Appropriate timeouts
- Retry logic
- Error recovery
- Minimal data transfer

### Monitoring

**Debug Information**:
- Request/response logging
- Error tracking
- Performance metrics
- Connection status

**User Feedback**:
- Loading indicators
- Error messages
- Status updates
- Progress tracking

## 🔮 Future Enhancements

### Advanced Features

**Scene Management**:
- Custom scene creation
- Scene scheduling
- Scene groups
- Conditional execution

**Device Integration**:
- Additional device types
- Device control
- Status monitoring
- Event handling

### API Improvements

**Authentication**:
- Secure authentication
- API key support
- Role-based access
- Audit logging

**Real-time Updates**:
- WebSocket support
- Push notifications
- Event streaming
- Live updates

---

The Vera Hub API integration provides comprehensive communication with Vera home automation hubs, supporting alarm control, scene management, and device monitoring with robust error handling and performance optimization.
