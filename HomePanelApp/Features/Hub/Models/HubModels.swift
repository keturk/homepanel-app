import Foundation

// MARK: - Data Models

/// Universal device model
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

public enum DeviceCapability: String, Codable, Sendable {
    case switchable, dimmable, lockable, temperature, motion
}

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

public enum DeviceAction: Sendable {
    case turnOn
    case turnOff
    case setLevel(Int) // 0-100
    case lock
    case unlock
}

/// State change event
public struct StateChangeEvent: Sendable {
    let device: Device
    let oldState: DeviceState?
    let newState: DeviceState
    let timestamp: Date
}

// MARK: - Hub Configuration

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


// MARK: - Convenience Extensions

extension HubConfiguration {
    static let defaultPort = 3480
    static let defaultPollInterval = 5.0
    
    /// Create a Vera hub configuration with local IP
    static func veraHub(id: String, type: HubType, name: String, ipAddress: String, port: Int = defaultPort, isAlarmHub: Bool = false) -> HubConfiguration {
        let connection = HubConnection(
            type: .localIP,
            address: ipAddress,
            port: port,
            useHTTPS: false
        )
        return HubConfiguration(
            hubId: id,
            hubType: type,
            name: name,
            isEnabled: true,
            isAlarmHub: isAlarmHub,
            connection: connection
        )
    }
    
    /// Get connection URL for this hub
    var connectionURL: String {
        let scheme = connection.useHTTPS ? "https" : "http"
        let port = connection.port ?? HubConnection.defaultVeraPort
        return "\(scheme)://\(connection.address):\(port)"
    }
    
    /// Check if this is a Vera hub
    var isVeraHub: Bool {
        return hubType == .vera
    }
    
    /// Create a hub adapter for this configuration
    func createAdapter(session: URLSession = URLSession.shared) -> any HubProtocol {
        switch self.hubType {
        case .vera:
            return VeraHubAdapter(
                hubId: self.hubId,
                hubType: self.hubType,
                connection: self.connection,
                session: session
            )
        default:
            // For now, treat all other types as Vera adapters
            return VeraHubAdapter(
                hubId: self.hubId,
                hubType: self.hubType,
                connection: self.connection,
                session: session
            )
        }
    }
}

