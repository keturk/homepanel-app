import Foundation
import Combine


@MainActor
class AutomationViewModel: ObservableObject {
    @Published var devices: [Device] = []
    @Published var isLoading = false
    @Published var selectedHub: String = "" // Will be the hubId
    @Published var errorMessage: String?
    @Published var showSettings = false
    @Published var registeredHubs: [HubConfiguration] = [] // For settings UI
    @Published var deviceActionInProgress: Set<String> = [] // Track devices being controlled
    
    let hubService: HubServiceProtocol
    let appConfig: AppConfigurationProtocol
    let roomMappingService: RoomMappingService
    private var cancellables = Set<AnyCancellable>()
    
    init(hubService: HubServiceProtocol, appConfig: AppConfigurationProtocol) {
        self.hubService = hubService
        self.appConfig = appConfig
        
        // Use shared RoomMappingService from HubServiceCoordinator to avoid duplication
        if let coordinator = hubService as? HubServiceCoordinator {
            self.roomMappingService = coordinator.roomMappingService
        } else {
            // Fallback for testing
            self.roomMappingService = RoomMappingService(hubService: hubService)
        }
        
        // Subscribe to state changes for automatic updates
        hubService.stateChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleStateChange(event)
            }
            .store(in: &cancellables)
        
            // Note: We can't observe hubService.objectWillChange since it's a protocol
            // Instead, we'll refresh registered hubs when configurations change
        
        Task { @MainActor in
            await self.refreshRegisteredHubs()
            self.selectedHub = self.registeredHubs.first?.hubId ?? ""
            await self.loadDevices()
        }
    }
    
    private func refreshRegisteredHubs() async {
        registeredHubs = await hubService.getRegisteredHubs()
    }
    
    
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

        // Wait for polling service to have a chance to fetch devices
        // Give it more time since network requests are timing out
        DebugLogger.log("📊 AutomationViewModel: Waiting for polling service to fetch devices...", feature: .automation)
        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds

        // Retry mechanism: try up to 5 times with longer delays
        for attempt in 1...5 {

            // Get all devices from all hubs, then filter by selected device names
            let allDevices = await hubService.getAllDevices()
            let hubConfigurations = await hubService.getRegisteredHubs()

            DebugLogger.log("📊 AutomationViewModel: Attempt \(attempt) - Found \(allDevices.count) devices total", feature: .automation)
            DebugLogger.log("📊 Looking for devices: \(appConfig.selectedDeviceNames)", feature: .automation)
            DebugLogger.log("📊 Available hubs: \(hubConfigurations.map { "\($0.name) (\($0.hubId))" })", feature: .automation)

            if !allDevices.isEmpty {
                DebugLogger.log("📊 Available device names: \(allDevices.map { $0.name })", feature: .automation)
            }

            if allDevices.isEmpty && attempt < 5 {
                let delaySeconds = attempt * 3 // 3, 6, 9, 12 seconds
                DebugLogger.log("⚠️ No devices found, retrying in \(delaySeconds) seconds... (attempt \(attempt)/5)", feature: .automation)
                try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                continue
            }



            if appConfig.selectedDeviceNames.isEmpty {
                devices = []
            } else {
                // Filter devices and maintain the order defined in settings
                // Create placeholder devices for names that don't exist yet
                // Create disconnected devices for devices from disabled hubs
                var orderedDevices: [Device] = []
                for deviceName in appConfig.selectedDeviceNames {
                    if let device = allDevices.first(where: { $0.name == deviceName }) {
                        DebugLogger.log("✅ Found device '\(deviceName)' from hub \(device.hubId)", feature: .automation)
                        // Found existing device - check if its hub is enabled
                        let hubConfig = hubConfigurations.first(where: { $0.hubId == device.hubId })
                        if let config = hubConfig, !config.isEnabled {
                            // Hub is disabled, create disconnected device
                            DebugLogger.log("⚠️ Hub \(device.hubId) is disabled for device '\(deviceName)'", feature: .automation)
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
                        DebugLogger.log("❌ Device '\(deviceName)' NOT FOUND in allDevices", feature: .automation)
                        let placeholderDevice = createPlaceholderDevice(name: deviceName, state: .missing)
                        orderedDevices.append(placeholderDevice)
                    }
                }
                devices = orderedDevices
            }

            // Log device details for debugging

            break // Exit retry loop
        }

        // If still no devices found after all attempts, show helpful error
        if devices.isEmpty && !appConfig.selectedDeviceNames.isEmpty {
            errorMessage = "No devices found. This may be due to network connectivity issues. Please check your hub connections and try again."
            DebugLogger.log("❌ AutomationViewModel: No devices found after 5 attempts. Network may be down.", feature: .automation)
        }

        isLoading = false
    }
    
    
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

        // Remove device from in-progress set
        deviceActionInProgress.remove(device.id)
    }
    
    func setDimmerLevel(_ device: Device, level: Int) async {
        // Don't allow controlling placeholder or disconnected devices
        guard device.hubState != .placeholder && device.hubState != .disconnected else {
            let status = device.hubState == .placeholder ? "not available yet" : "disconnected"
            errorMessage = "Device '\(device.name)' is \(status). Please check your hub connection."
            return
        }

        // Mark device as being controlled
        deviceActionInProgress.insert(device.id)

        do {
            try await hubService.controlDevice(
                deviceId: device.id,
                action: .setLevel(level)
            )

            // Keep the indicator visible for a short time to provide feedback
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        } catch {
            errorMessage = "Failed to set dimmer level: \(error.localizedDescription)"
        }

        // Remove device from in-progress set
        deviceActionInProgress.remove(device.id)
    }
    
    func executeScene(_ scene: Device) async {
        // Don't allow executing placeholder or disconnected scenes
        guard scene.hubState != .placeholder && scene.hubState != .disconnected else {
            let status = scene.hubState == .placeholder ? "not available yet" : "disconnected"
            errorMessage = "Scene '\(scene.name)' is \(status). Please check your hub connection."
            return
        }

        // Mark scene as being executed
        deviceActionInProgress.insert(scene.id)

        do {
            try await hubService.executeScene(sceneId: scene.id, hubId: scene.hubId)

            // Keep the indicator visible for a short time to provide feedback
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second for scenes
        } catch {
            errorMessage = "Failed to execute scene: \(error.localizedDescription)"
        }

        // Remove scene from in-progress set
        deviceActionInProgress.remove(scene.id)
    }
    
    private func handleStateChange(_ event: StateChangeEvent) {
        DebugLogger.log("🔄 AutomationViewModel: Received state change for '\(event.device.name)' (hub: \(event.device.hubId), hubState: \(event.device.hubState))", feature: .automation)

        // Process devices from all hubs, but only show those that match our filter criteria
        // Match by both device ID AND hub ID to avoid conflicts between hubs
        if let index = devices.firstIndex(where: { $0.id == event.device.id && $0.hubId == event.device.hubId }) {
            // Update existing device
            DebugLogger.log("✅ Updating existing device at index \(index)", feature: .automation)
            devices[index] = event.device
        } else if let placeholderIndex = devices.firstIndex(where: { $0.name == event.device.name && $0.hubState == .placeholder }) {
            // Replace placeholder device with real device
            DebugLogger.log("✅ Replacing placeholder device at index \(placeholderIndex)", feature: .automation)
            devices[placeholderIndex] = event.device
        } else if let disconnectedIndex = devices.firstIndex(where: { $0.name == event.device.name && $0.hubState == .disconnected }) {
            // Replace disconnected device with real device (hub was re-enabled)
            DebugLogger.log("✅ Replacing disconnected device at index \(disconnectedIndex)", feature: .automation)
            devices[disconnectedIndex] = event.device
        } else {
            // Add new device if it matches our filter criteria
            if shouldIncludeDevice(event.device) {
                DebugLogger.log("✅ Adding new device (matches filter)", feature: .automation)
                devices.append(event.device)
            } else {
                DebugLogger.log("⏭️ Skipping device (doesn't match filter)", feature: .automation)
            }
        }
    }
    
    private func shouldIncludeDevice(_ device: Device) -> Bool {
        // If no devices are selected, show nothing (don't show all devices)
        if appConfig.selectedDeviceNames.isEmpty {
            return false
        }

        // Only do EXACT matches to avoid partial matches with scenes
        let shouldInclude = appConfig.selectedDeviceNames.contains(device.name)
        if shouldInclude {
        } else {
        }
        return shouldInclude
    }
    
    // MARK: - Hub Management (for SettingsView)
    
    func addHub(_ config: HubConfiguration) async {
        let adapter = config.createAdapter()
        await hubService.registerHub(adapter, configuration: config)
        await refreshRegisteredHubs()
    }
    
    func updateHub(_ config: HubConfiguration) async {
        await hubService.updateHubConfiguration(hubId: config.hubId, newConfiguration: config)
        await refreshRegisteredHubs()
    }
    
    func addHub(name: String, hubType: HubType, connectionType: HubConnection.ConnectionType, address: String, port: Int?, useHTTPS: Bool, pollInterval: TimeInterval) async throws {
        let newHubId = UUID().uuidString // Unique ID for the new hub
        let connection = HubConnection(type: connectionType, address: address, port: port, useHTTPS: useHTTPS)
        let newConfig = HubConfiguration(hubId: newHubId, hubType: hubType, name: name, isEnabled: true, connection: connection, pollInterval: pollInterval)
        
        let adapter = newConfig.createAdapter()
        await hubService.registerHub(adapter, configuration: newConfig)
    }
    
    func updateHub(id: String, name: String, hubType: HubType, connectionType: HubConnection.ConnectionType, address: String, port: Int?, useHTTPS: Bool, pollInterval: TimeInterval, isEnabled: Bool) async throws {
        // For now, we'll need to unregister and re-register to update
        // In a more sophisticated implementation, we'd have an update method
        await hubService.unregisterHub(hubId: id)
        
        if isEnabled {
            let connection = HubConnection(type: connectionType, address: address, port: port, useHTTPS: useHTTPS)
            let updatedConfig = HubConfiguration(hubId: id, hubType: hubType, name: name, isEnabled: isEnabled, connection: connection, pollInterval: pollInterval)
            let adapter = updatedConfig.createAdapter()
            await hubService.registerHub(adapter, configuration: updatedConfig)
        }
    }
    
    func deleteHub(id: String) async throws {
        await hubService.unregisterHub(hubId: id)
    }
    
    func getAllDevices() async -> [Device] {
        return await hubService.getAllDevices()
    }
    
    // MARK: - Helper Methods
    
    private enum PlaceholderState {
        case missing
        case disconnected(Device)
    }
    
    private func createPlaceholderDevice(
        name: String,
        type: DeviceType = .light,
        state: PlaceholderState,
        room: String? = nil,
        capabilities: Set<DeviceCapability> = []
    ) -> Device {
        let (hubId, deviceIdPrefix) = switch state {
            case .missing: (DeviceHubState.placeholder.rawValue, "placeholder_")
            case .disconnected: (DeviceHubState.disconnected.rawValue, "disconnected_")
        }
        
        let placeholderId = "\(deviceIdPrefix)\(name.replacingOccurrences(of: " ", with: "_"))"
        let placeholderState = DeviceState(
            deviceId: placeholderId,
            hubId: hubId,
            isOn: nil,
            level: nil,
            temperature: nil,
            locked: nil,
            tripped: nil,
            lastUpdate: Date()
        )
        
        return Device(
            id: placeholderId,
            hubId: hubId,
            name: name,
            type: type,
            room: room,
            state: placeholderState,
            capabilities: capabilities
        )
    }
    
}