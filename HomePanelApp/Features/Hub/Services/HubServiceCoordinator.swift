import Foundation
import Combine

// MARK: - Main Service Coordinator

@MainActor
class HubServiceCoordinator: ObservableObject {
    @Published var isRunning = false
    @Published var registeredHubIds: [String] = []

    private let stateCache: DeviceStateCache
    private let statePublisher: StatePublisher
    private let hubManager: HubManager
    private let pollingService: PollingService
    private let session: URLSession
    lazy var roomMappingService: RoomMappingService = RoomMappingService(hubService: self)

    init(session: URLSession = URLSession.shared) {
        let stateCache = DeviceStateCache()
        let statePublisher = StatePublisher()

        self.stateCache = stateCache
        self.statePublisher = statePublisher
        self.session = session
        self.hubManager = HubManager(stateCache: stateCache) { [weak statePublisher] event in
            statePublisher?.publish(event)
        }
        self.pollingService = PollingService(hubManager: hubManager)
    }
    
    func registerHub(_ hub: any HubProtocol, configuration: HubConfiguration) async {
        await hubManager.registerHub(hub, configuration: configuration)
        await updateRegisteredHubs()

        // Always start polling for newly registered hubs
        await pollingService.startPolling(forHub: hub.hubId)

        // Perform immediate initial poll to populate device cache
        do {
            try await hubManager.pollHub(hubId: hub.hubId)
            DebugLogger.log("✅ Initial poll completed for hub: \(hub.hubId)", feature: .hubService)
        } catch {
            DebugLogger.log("❌ Initial poll failed for hub: \(hub.hubId), error: \(error)", feature: .hubService)
        }

        // Note: Room mapping refresh is now handled by the caller after all hubs are registered
    }
    
    func unregisterHub(hubId: String) async {
        await pollingService.stopPolling(forHub: hubId)
        await hubManager.unregisterHub(hubId: hubId)
        await updateRegisteredHubs()
    }
    
    func updateHubConfiguration(hubId: String, newConfiguration: HubConfiguration) async {
        // Unregister and re-register to apply new configuration, especially poll interval
        await unregisterHub(hubId: hubId)
        // Note: This assumes the HubProtocol instance can be recreated with the new config.
        // For Vera, this means creating a new VeraHubAdapter.
        let newHubAdapter = newConfiguration.createAdapter(session: session)
        await registerHub(newHubAdapter, configuration: newConfiguration)
    }
    
    private func updateRegisteredHubs() async {
        registeredHubIds = await hubManager.getRegisteredHubIds()
    }
    
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
    
    func getDevice(deviceId: String) async -> Device? {
        return await hubManager.getDevice(deviceId: deviceId)
    }
    
    func getDevices(forHub hubId: String) async -> [Device] {
        return await hubManager.getDevices(forHub: hubId)
    }
    
    func getAllDevices() async -> [Device] {
        return await hubManager.getAllDevices()
    }
    
    func getRegisteredHubs() async -> [HubConfiguration] {
        return await hubManager.getAllConfigurations()
    }
    
    func getAllHubs() async -> [any HubProtocol] {
        return await hubManager.getAllHubs()
    }
    
    func controlDevice(deviceId: String, action: DeviceAction) async throws {
        try await hubManager.controlDevice(deviceId: deviceId, action: action)
    }
    
    func executeScene(sceneId: String, hubId: String) async throws {
        try await hubManager.executeScene(sceneId: sceneId, hubId: hubId)
    }
    
    func refreshHub(hubId: String) async throws {
        try await pollingService.pollNow(hubId: hubId)
    }
    
    func refreshAll() async {
        await pollingService.pollAllNow()
    }
    
    /// Refresh room mappings after all hubs have been registered
    func refreshRoomMappingsAfterRegistration() async {
        await roomMappingService.refreshRoomMappings()
    }
    
    var stateChangePublisher: AnyPublisher<StateChangeEvent, Never> {
        statePublisher.stateChangePublisher
    }
    
    func publisher(forHub hubId: String) -> AnyPublisher<StateChangeEvent, Never> {
        statePublisher.publisher(forHub: hubId)
    }
    
    func publisher(forDevice deviceId: String) -> AnyPublisher<StateChangeEvent, Never> {
        statePublisher.publisher(forDevice: deviceId)
    }
}

@MainActor
extension HubServiceCoordinator: @preconcurrency HubServiceProtocol {}
