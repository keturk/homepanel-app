import Foundation
import Combine

// MARK: - Service Protocol for DI

@MainActor
protocol HubServiceProtocol: AnyObject {
    var stateChangePublisher: AnyPublisher<StateChangeEvent, Never> { get }
    var isRunning: Bool { get }
    var registeredHubIds: [String] { get } // Added to expose registered hub IDs
    
    func start() async
    func stop() async
    func registerHub(_ hub: any HubProtocol, configuration: HubConfiguration) async
    func unregisterHub(hubId: String) async
    func updateHubConfiguration(hubId: String, newConfiguration: HubConfiguration) async // Added for updating hub configs
    
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
