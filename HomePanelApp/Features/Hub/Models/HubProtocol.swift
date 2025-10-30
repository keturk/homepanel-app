import Foundation

// MARK: - Core Protocols

/// Abstract hub interface - any hub type must conform to this
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

/// Hub types for type-specific behavior
enum HubType: String, Codable, Sendable {
    case vera // All Vera hubs (Lite, Edge, Plus) use the same API
    case zigbee
    case zwave
    case homekit
    case future // For extensibility
}

// MARK: - Errors

// HubError is now defined in AppErrors.swift for unified error handling
