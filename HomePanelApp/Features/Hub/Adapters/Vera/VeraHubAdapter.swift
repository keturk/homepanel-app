import Foundation

// MARK: - Vera Hub Adapter

actor VeraHubAdapter: HubProtocol {
    let hubId: String
    let hubType: HubType
    private let baseAdapter: BaseHubAdapter
    private var lastDataVersion: String?

    init(hubId: String, hubType: HubType, connection: HubConnection, session: URLSession = URLSession.shared) {
        self.hubId = hubId
        self.hubType = hubType
        self.baseAdapter = BaseHubAdapter(hubId: hubId, hubType: hubType, connection: connection, session: session)
    }
    
    var isReachable: Bool {
        get async {
            // Use lightweight alive endpoint for connectivity checks
            // The alive endpoint returns minimal data and is designed for this purpose
            do {
                let (_, _) = try await baseAdapter.makeRequest(to: "/data_request?id=alive")
                return true
            } catch {
                return false
            }
        }
    }
    
    /// IMPORTANT: This method is required by HubProtocol for protocol conformance.
    /// It delegates to fetchDeviceStates() which is the actual implementation.
    /// Do not remove without updating the protocol.
    func fetchDevices() async throws -> [Device] {
        return try await fetchDeviceStates()
    }
    
    func updateDevice(deviceId: String, action: DeviceAction) async throws {
        // Extract raw device ID from hub-scoped ID
        // Hub-scoped format: "hub_vera-garage_device_8" -> raw: "8"
        guard let rawDeviceId = HubScopedID.extractDeviceID(from: deviceId) else {
            throw HubError.invalidDeviceId(deviceId)
        }

        let urlString: String

        switch action {
        case .turnOn:
            urlString = "/data_request?id=action&DeviceNum=\(rawDeviceId)&serviceId=urn:upnp-org:serviceId:SwitchPower1&action=SetTarget&newTargetValue=1"
        case .turnOff:
            urlString = "/data_request?id=action&DeviceNum=\(rawDeviceId)&serviceId=urn:upnp-org:serviceId:SwitchPower1&action=SetTarget&newTargetValue=0"
        case .setLevel(let level):
            let clampedLevel = max(0, min(100, level))
            urlString = "/data_request?id=action&DeviceNum=\(rawDeviceId)&serviceId=urn:upnp-org:serviceId:Dimming1&action=SetLoadLevelTarget&newLoadlevelTarget=\(clampedLevel)"
        case .lock:
            urlString = "/data_request?id=action&DeviceNum=\(rawDeviceId)&serviceId=urn:micasaverde-com:serviceId:DoorLock1&action=SetTarget&newTargetValue=1"
        case .unlock:
            urlString = "/data_request?id=action&DeviceNum=\(rawDeviceId)&serviceId=urn:micasaverde-com:serviceId:DoorLock1&action=SetTarget&newTargetValue=0"
        }

        DebugLogger.log("VeraHubAdapter: Sending device action to \(hubId) - DeviceNum=\(rawDeviceId)", feature: .automation)
        let (_, _) = try await baseAdapter.makeRequest(to: urlString)
    }

    func executeScene(sceneId: String) async throws {
        // Extract raw scene ID from hub-scoped ID
        // Hub-scoped format: "hub_vera-alarm_scene_42" -> raw: 42
        guard let rawSceneId = HubScopedID.extractSceneID(from: sceneId) else {
            throw HubError.invalidSceneId(sceneId)
        }

        let urlString = "/data_request?id=action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=RunScene&SceneNum=\(rawSceneId)"
        DebugLogger.log("VeraHubAdapter: Executing scene on \(hubId) - SceneNum=\(rawSceneId)", feature: .automation)
        let (_, _) = try await baseAdapter.makeRequest(to: urlString)
    }

    /// Fetch device states efficiently using sdata endpoint (optimized for lightweight polling)
    /// OPTIMIZED: Uses sdata (~1-21KB) instead of status (~60-240KB) for 91-96% bandwidth reduction
    /// sdata contains: device name, id, category, room, status, state - all we need for UI updates
    /// This optimization saves ~2.3GB/day when polling 3 hubs every 5 seconds
    func fetchDeviceStates() async throws -> [Device] {
        let (data, _) = try await baseAdapter.makeRequest(to: "/data_request?id=sdata&output_format=json")

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HubError.invalidResponse
        }

        DebugLogger.log("VeraHubAdapter: Fetching device states via sdata for hub \(hubId)", feature: .hubService)

        var devices: [Device] = []

        // Parse devices from sdata response
        if let devicesArray = json["devices"] as? [[String: Any]] {
            DebugLogger.log("VeraHubAdapter: Found \(devicesArray.count) devices in sdata", feature: .hubService)
            for deviceJson in devicesArray {
                if let device = parseSDataDevice(deviceJson) {
                    devices.append(device)
                }
            }
        } else {
            DebugLogger.log("VeraHubAdapter: No devices array found in sdata response", feature: .hubService)
        }

        // Parse scenes from sdata response
        if let scenesArray = json["scenes"] as? [[String: Any]] {
            for sceneJson in scenesArray {
                if let scene = parseVeraScene(sceneJson) {
                    devices.append(scene)
                }
            }
        }

        return devices
    }
    
    func fetchRooms() async throws -> [VeraRoom] {
        // Use sdata endpoint for better performance (~20KB vs ~500KB for user_data)
        let (data, _) = try await baseAdapter.makeRequest(to: "/data_request?id=sdata&output_format=json")
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HubError.invalidResponse
        }
        
        DebugLogger.log("VeraHubAdapter: Fetching rooms via sdata for hub \(hubId)", feature: .automation)
        
        // Parse rooms from the response
        var rooms: [VeraRoom] = []
        
        // The sdata endpoint returns rooms in the same format as user_data
        if let roomsArray = json["rooms"] as? [[String: Any]] {
            DebugLogger.log("VeraHubAdapter: Found \(roomsArray.count) rooms in sdata", feature: .automation)
            for roomJson in roomsArray {
                if let id = roomJson["id"] as? Int,
                   let name = roomJson["name"] as? String {
                    let room = VeraRoom(id: id, name: name)
                    rooms.append(room)
                }
            }
        } else {
            DebugLogger.log("VeraHubAdapter: No rooms array found in sdata response", feature: .automation)
        }
        
        return rooms
    }
    
    // MARK: - Private Parsing Methods

    /// Parse device from sdata response (lightweight polling data)
    private func parseSDataDevice(_ json: [String: Any]) -> Device? {
        guard let id = json["id"] as? Int,
              let name = json["name"] as? String else {
            return nil
        }

        let idString = String(id)
        let categoryNum = json["category"] as? Int ?? 0
        let deviceType = mapVeraCategoryToDeviceType(categoryNum)

        // Extract room ID
        let room: String?
        if let roomInt = json["room"] as? Int {
            room = String(roomInt)
        } else {
            room = nil
        }

        // Create hub-scoped device ID
        let hubScopedDeviceId = HubScopedID.deviceID(hubId: hubId, deviceId: idString)

        // Parse state from sdata fields (simpler than user_data)
        let statusString = json["status"] as? String
        var status = statusString.flatMap(Int.init)

        // Parse alarm partition state from detailedarmmode field
        // This is specific to category 23 (alarm partition) devices
        if let detailedArmMode = json["detailedarmmode"] as? String {
            DebugLogger.log("VeraHubAdapter: Found detailedarmmode: '\(detailedArmMode)' for device '\(name)' (category: \(categoryNum))", feature: .alarm)
            switch detailedArmMode {
            case "Disarmed":
                status = 0
                DebugLogger.log("VeraHubAdapter: Mapped 'Disarmed' to status 0", feature: .alarm)
           case "Ready":
               // "Ready" indicates the alarm is in a transitional state
               // Map it to status 0 (disarmed) as a fallback since it's not a final state
               DebugLogger.log("VeraHubAdapter: Mapped 'Ready' to disarmed status 0 (transitional state)", feature: .alarm)
               status = 0 // Map to disarmed as fallback for transitional state
            case "Away":
                status = 1
                DebugLogger.log("VeraHubAdapter: Mapped 'Away' to status 1", feature: .alarm)
            case "Stay":
                status = 2
                DebugLogger.log("VeraHubAdapter: Mapped 'Stay' to status 2", feature: .alarm)
            case "Night":
                status = 3
                DebugLogger.log("VeraHubAdapter: Mapped 'Night' to status 3", feature: .alarm)
            default:
                DebugLogger.warning("Unknown detailedarmmode value: \(detailedArmMode)", feature: .alarm)
            }
        }

        // If no status was set from either status field or detailedarmmode, 
        // and this is an alarm partition device, set a default status
        if status == nil && categoryNum == 23 {
            DebugLogger.log("VeraHubAdapter: Alarm partition device has no status, defaulting to disarmed", feature: .alarm)
            status = 0 // Default to disarmed
        }

        // Log final status value for alarm devices
        if categoryNum == 23 {
            DebugLogger.log("VeraHubAdapter: Final status for alarm device '\(name)': \(status ?? -1)", feature: .alarm)
        }

        let level = json["level"] as? Int
        let temperature = (json["temperature"] as? String).flatMap(Double.init)
        let locked = (json["locked"] as? String).flatMap(Int.init).map { $0 == 1 }
        let tripped = (json["tripped"] as? String).flatMap(Int.init).map { $0 == 1 }

        // Determine if device is on
        let isOn: Bool?
        if let levelValue = level {
            isOn = levelValue > 0
        } else if let statusValue = status {
            isOn = statusValue == 1
        } else {
            isOn = nil
        }

        let state = DeviceState(
            deviceId: hubScopedDeviceId,
            hubId: hubId,
            isOn: isOn,
            level: level,
            temperature: temperature,
            locked: locked,
            tripped: tripped,
            status: status,
            lastUpdate: Date()
        )

        let capabilities = determineSDataCapabilities(category: categoryNum, json: json)

        // Create hub-scoped room ID if room exists
        let hubScopedRoom: String?
        if let room = room {
            hubScopedRoom = HubScopedID.roomID(hubId: hubId, roomId: room)
        } else {
            hubScopedRoom = nil
        }

        return Device(
            id: hubScopedDeviceId,
            hubId: hubId,
            name: name,
            type: deviceType,
            room: hubScopedRoom,
            state: state,
            capabilities: capabilities
        )
    }

    /// Determine capabilities from sdata response
    private func determineSDataCapabilities(category: Int, json: [String: Any]) -> Set<DeviceCapability> {
        var capabilities: Set<DeviceCapability> = []

        if json["status"] != nil {
            capabilities.insert(.switchable)
        }
        if json["level"] != nil || category == 2 {
            capabilities.insert(.dimmable)
        }
        if category == 7 {
            capabilities.insert(.lockable)
        }
        if json["temperature"] != nil {
            capabilities.insert(.temperature)
        }
        if json["tripped"] != nil {
            capabilities.insert(.motion)
        }

        return capabilities
    }

    
    private func parseVeraScene(_ json: [String: Any]) -> Device? {
        guard let idString = json["id"] as? String ?? (json["id"] as? Int).map(String.init),
              let sceneIdInt = Int(idString) else {
            return nil
        }

        // Name is optional in status endpoint, use "Scene {id}" as fallback
        let name = json["name"] as? String ?? "Scene \(idString)"

        // Create hub-scoped scene ID
        let hubScopedSceneId = HubScopedID.sceneID(hubId: hubId, sceneId: sceneIdInt)

        let state = DeviceState(
            deviceId: hubScopedSceneId,
            hubId: hubId,
            isOn: nil,
            level: nil,
            temperature: nil,
            locked: nil,
            tripped: nil,
            status: nil,
            lastUpdate: Date()
        )

        // Handle room field - it can be either a string or an integer
        let roomId: String?
        if let roomString = json["room"] as? String {
            roomId = roomString
        } else if let roomInt = json["room"] as? Int {
            roomId = String(roomInt)
        } else {
            roomId = nil
        }

        return Device(
            id: hubScopedSceneId,
            hubId: hubId,
            name: name,
            type: .scene,
            room: roomId,
            state: state,
            capabilities: []
        )
    }
    private func mapVeraCategoryToDeviceType(_ category: Int) -> DeviceType {
        switch category {
        case 2: return .dimmer
            case 3: return .lightSwitch
        case 4: return .sensor
        case 5: return .thermostat
        case 7: return .lock
        default: return .lightSwitch
        }
    }
    
    private func determineCapabilities(categoryNum: Int, json: [String: Any]) -> Set<DeviceCapability> {
        var capabilities: Set<DeviceCapability> = []
        
        if json["status"] != nil {
            capabilities.insert(.switchable)
        }
        if json["level"] != nil || categoryNum == 2 {
            capabilities.insert(.dimmable)
        }
        if categoryNum == 7 {
            capabilities.insert(.lockable)
        }
        if json["temperature"] != nil {
            capabilities.insert(.temperature)
        }
        if json["tripped"] != nil {
            capabilities.insert(.motion)
        }
        
        return capabilities
    }
    
    
}
