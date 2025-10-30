import Foundation
import Combine

// MARK: - State Publisher

/// Combine-based event publisher for state changes
class StatePublisher: ObservableObject, @unchecked Sendable {
    private let stateChangeSubject = PassthroughSubject<StateChangeEvent, Never>()
    
    var stateChangePublisher: AnyPublisher<StateChangeEvent, Never> {
        stateChangeSubject.eraseToAnyPublisher()
    }
    
    func publish(_ event: StateChangeEvent) {
        stateChangeSubject.send(event)
    }
    
    // Convenience: Filter by hub
    func publisher(forHub hubId: String) -> AnyPublisher<StateChangeEvent, Never> {
        stateChangePublisher
            .filter { $0.device.hubId == hubId }
            .eraseToAnyPublisher()
    }
    
    // Convenience: Filter by device
    func publisher(forDevice deviceId: String) -> AnyPublisher<StateChangeEvent, Never> {
        stateChangePublisher
            .filter { $0.device.id == deviceId }
            .eraseToAnyPublisher()
    }
    
    // Convenience: Filter by device type
    func publisher(forDeviceType deviceType: DeviceType) -> AnyPublisher<StateChangeEvent, Never> {
        stateChangePublisher
            .filter { $0.device.type == deviceType }
            .eraseToAnyPublisher()
    }
    
    // Convenience: Filter by capability
    func publisher(forCapability capability: DeviceCapability) -> AnyPublisher<StateChangeEvent, Never> {
        stateChangePublisher
            .filter { $0.device.capabilities.contains(capability) }
            .eraseToAnyPublisher()
    }
}
