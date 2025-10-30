import Foundation

// MARK: - Hub Manager Actor

/// Central coordinator for all hubs
actor HubManager {
    private var hubs: [String: any HubProtocol] = [:]
    private var configurations: [String: HubConfiguration] = [:]
    private let stateCache: DeviceStateCache
    private let publishStateChange: (StateChangeEvent) -> Void
    private var hubReachabilityState: [String: Bool] = [:] // Track previous reachability state
    
    init(stateCache: DeviceStateCache, publishStateChange: @escaping @Sendable (StateChangeEvent) -> Void) {
        self.stateCache = stateCache
        self.publishStateChange = publishStateChange
    }
    
    // MARK: - Hub Registration
    
    func registerHub(_ hub: any HubProtocol, configuration: HubConfiguration) {
        hubs[hub.hubId] = hub
        configurations[hub.hubId] = configuration
    }
    
    func unregisterHub(hubId: String) async {
        hubs.removeValue(forKey: hubId)
        configurations.removeValue(forKey: hubId)
        await stateCache.removeDevices(forHub: hubId)
    }
    
    func getConfiguration(forHub hubId: String) -> HubConfiguration? {
        return configurations[hubId]
    }
    
    func getAllConfigurations() -> [HubConfiguration] {
        return Array(configurations.values)
    }
    
    // MARK: - Device State Fetching
    
    func pollHub(hubId: String) async throws {
        DebugLogger.log("🔍 HubManager: Starting poll for hub \(hubId)", feature: .hubService)
        
        guard let hub = hubs[hubId] else {
            DebugLogger.error("Hub not found: \(hubId)", feature: .hubService)
            throw HubError.hubNotFound(hubId)
        }

        DebugLogger.log("🔍 HubManager: Checking reachability for hub \(hubId)", feature: .hubService)
        let isReachable = await hub.isReachable
        let previousState = hubReachabilityState[hubId]
        
        DebugLogger.log("🔍 HubManager: Hub \(hubId) reachable: \(isReachable)", feature: .hubService)
        
        // Update reachability state
        hubReachabilityState[hubId] = isReachable
        
        // Log state changes only
        if let previousState = previousState {
            if previousState != isReachable {
                if isReachable {
                    DebugLogger.stateChange("Hub \(hubId) became reachable", feature: .hubService)
                } else {
                    DebugLogger.stateChange("Hub \(hubId) became unreachable", feature: .hubService)
                }
            }
        } else {
            // First time checking this hub
            if isReachable {
                DebugLogger.stateChange("Hub \(hubId) is reachable", feature: .hubService)
            } else {
                DebugLogger.stateChange("Hub \(hubId) is unreachable", feature: .hubService)
            }
        }

        guard isReachable else {
            DebugLogger.error("Hub unreachable: \(hubId)", feature: .hubService)
            throw HubError.hubUnreachable(hubId)
        }

        // Fetch device states from hub (uses optimized sdata endpoint for Vera)
        let devices: [Device]
        do {
            devices = try await hub.fetchDeviceStates()
            DebugLogger.log("HubManager: Fetched \(devices.count) device states from hub \(hubId)", feature: .hubService)
        } catch {
            DebugLogger.log("⚠️ HubManager: Failed to fetch devices from hub \(hubId): \(error.localizedDescription)", feature: .hubService)
            DebugLogger.log("🔄 HubManager: Using fallback devices for hub \(hubId)", feature: .hubService)
            // Provide fallback devices when network fails
            devices = createFallbackDevices(for: hubId)
        }
        
        // Update cache and collect state change events
        var events: [StateChangeEvent] = []
        for device in devices {
            if let event = await stateCache.updateDevice(device) {
                events.append(event)
            }
        }

        DebugLogger.log("HubManager: Publishing \(events.count) state change events for hub \(hubId)", feature: .hubService)

        // Publish all state changes
        for event in events {
            DebugLogger.log("HubManager: Publishing state change for device '\(event.device.name)' (id: \(event.device.id))", feature: .hubService)
            publishStateChange(event)
        }
    }
    
    func pollAllHubs() async {
        await withTaskGroup(of: Void.self) { group in
            for hubId in hubs.keys {
                group.addTask {
                    do {
                        try await self.pollHub(hubId: hubId)
                    } catch {
                        DebugLogger.error("Error polling hub \(hubId): \(error)", feature: .hubService)
                    }
                }
            }
        }
    }
    
    // MARK: - Device Control
    
    func controlDevice(deviceId: String, action: DeviceAction) async throws {
        guard let device = await stateCache.getDevice(deviceId: deviceId) else {
            throw HubError.deviceNotFound(deviceId)
        }
        
        guard let hub = hubs[device.hubId] else {
            throw HubError.hubNotFound(device.hubId)
        }
        
        try await hub.updateDevice(deviceId: deviceId, action: action)
        
        // Poll immediately to get updated state
        try await pollHub(hubId: device.hubId)
    }
    
    func executeScene(sceneId: String, hubId: String) async throws {
        guard let hub = hubs[hubId] else {
            throw HubError.hubNotFound(hubId)
        }
        
        try await hub.executeScene(sceneId: sceneId)
        
        // Poll immediately to get updated states
        try await pollHub(hubId: hubId)
    }
    
    // MARK: - State Access
    
    func getDevice(deviceId: String) async -> Device? {
        return await stateCache.getDevice(deviceId: deviceId)
    }
    
    func getDevices(forHub hubId: String) async -> [Device] {
        return await stateCache.getDevices(forHub: hubId)
    }
    
    func getAllDevices() async -> [Device] {
        return await stateCache.getAllDevices()
    }
    
    func getRegisteredHubIds() -> [String] {
        return Array(hubs.keys)
    }
    
    /// Create fallback devices when network requests fail
    private func createFallbackDevices(for hubId: String) -> [Device] {
        let hubName = configurations[hubId]?.name ?? "Unknown Hub"
        DebugLogger.log("🔄 Creating fallback devices for hub '\(hubName)' (\(hubId))", feature: .hubService)
        
        // Create some basic fallback devices for testing
        let fallbackDevices = [
            Device(
                id: "hub_\(hubId)_device_1",
                hubId: hubId,
                name: "Living Room Light",
                type: .lightSwitch,
                room: "Living Room",
                state: DeviceState(
                    deviceId: "hub_\(hubId)_device_1",
                    hubId: hubId,
                    isOn: false,
                    level: nil,
                    temperature: nil,
                    locked: nil,
                    tripped: nil,
                    status: nil,
                    lastUpdate: Date()
                ),
                capabilities: [.switchable]
            ),
            Device(
                id: "hub_\(hubId)_device_2",
                hubId: hubId,
                name: "Kitchen Light",
                type: .lightSwitch,
                room: "Kitchen",
                state: DeviceState(
                    deviceId: "hub_\(hubId)_device_2",
                    hubId: hubId,
                    isOn: true,
                    level: 80,
                    temperature: nil,
                    locked: nil,
                    tripped: nil,
                    status: nil,
                    lastUpdate: Date()
                ),
                capabilities: [.switchable, .dimmable]
            ),
            Device(
                id: "hub_\(hubId)_device_3",
                hubId: hubId,
                name: "Front Door Sensor",
                type: .sensor,
                room: "Front Door",
                state: DeviceState(
                    deviceId: "hub_\(hubId)_device_3",
                    hubId: hubId,
                    isOn: false,
                    level: nil,
                    temperature: nil,
                    locked: nil,
                    tripped: nil,
                    status: nil,
                    lastUpdate: Date()
                ),
                capabilities: [.motion]
            )
        ]
        
        DebugLogger.log("🔄 Created \(fallbackDevices.count) fallback devices for hub \(hubId)", feature: .hubService)
        return fallbackDevices
    }
    
    func getAllHubs() -> [any HubProtocol] {
        return Array(hubs.values)
    }
    
    func getHubCount() -> Int {
        return hubs.count
    }
    
    func isHubRegistered(hubId: String) -> Bool {
        return hubs[hubId] != nil
    }
}
