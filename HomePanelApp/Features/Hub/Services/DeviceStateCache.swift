import Foundation

// MARK: - State Cache Actor

/// Thread-safe device state cache
actor DeviceStateCache {
    private var devices: [String: Device] = [:] // deviceId -> Device
    private var statesByHub: [String: Set<String>] = [:] // hubId -> Set<deviceId>
    
    func updateDevice(_ device: Device) -> StateChangeEvent? {
        let oldDevice = devices[device.id]
        devices[device.id] = device

        // Track hub association
        var hubDevices = statesByHub[device.hubId] ?? Set()
        hubDevices.insert(device.id)
        statesByHub[device.hubId] = hubDevices

        // Create event if:
        // 1. This is a new device (no oldDevice), OR
        // 2. The device state has changed
        if oldDevice == nil {
            // New device discovered - publish event so UI can replace placeholders
            return StateChangeEvent(
                device: device,
                oldState: nil,
                newState: device.state,
                timestamp: Date()
            )
        } else if let oldDevice = oldDevice, oldDevice.state != device.state {
            // Device state changed
            return StateChangeEvent(
                device: device,
                oldState: oldDevice.state,
                newState: device.state,
                timestamp: Date()
            )
        }
        return nil
    }
    
    func getDevice(deviceId: String) -> Device? {
        return devices[deviceId]
    }
    
    func getDevices(forHub hubId: String) -> [Device] {
        guard let deviceIds = statesByHub[hubId] else { return [] }
        return deviceIds.compactMap { devices[$0] }
    }
    
    func getAllDevices() -> [Device] {
        let allDevices = Array(devices.values)
        return allDevices
    }
    
    func removeDevices(forHub hubId: String) {
        guard let deviceIds = statesByHub[hubId] else { return }
        deviceIds.forEach { devices.removeValue(forKey: $0) }
        statesByHub.removeValue(forKey: hubId)
    }
    
    func getDeviceCount(forHub hubId: String) -> Int {
        return statesByHub[hubId]?.count ?? 0
    }
    
    func getAllHubIds() -> [String] {
        return Array(statesByHub.keys)
    }
    
    func clearAll() {
        devices.removeAll()
        statesByHub.removeAll()
    }
}
