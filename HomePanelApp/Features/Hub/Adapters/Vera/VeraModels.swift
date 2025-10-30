import Foundation

// MARK: - Vera Hub API Response Models

// MARK: - Scene List Response
public struct VeraUserDataResponse: Codable {
    internal let sections: [VeraSection]?
    internal let scenes: [VeraScene]?
    internal let categoryFilter: [VeraCategoryFilter]?
    
    // Custom initializer to extract scenes from the response
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        sections = try container.decodeIfPresent([VeraSection].self, forKey: .sections)
        scenes = try container.decodeIfPresent([VeraScene].self, forKey: .scenes)
        categoryFilter = try container.decodeIfPresent([VeraCategoryFilter].self, forKey: .categoryFilter)
    }
    
    // Computed property to get all scenes (from top level or sections)
    var allScenes: [VeraScene]? {
        var foundScenes: [VeraScene] = []
        
        // First, try to get scenes from the top level
        if let topLevelScenes = scenes {
            foundScenes.append(contentsOf: topLevelScenes)
        }
        
        // Then, try to get scenes from sections
        if let sections = sections {
            for section in sections {
                // Check if this section is actually a scene (has id and name)
                if let id = section.id, let name = section.name {
                    // Can't use initializer directly since we have custom init(from:)
                    // Parse sections as scenes if they have scene-like properties
                    // These will be parsed by the decoder when fetched from API
                }
                // Check for nested scenes
                if let sectionScenes = section.scenes {
                    foundScenes.append(contentsOf: sectionScenes)
                }
            }
        }
        
        return foundScenes.isEmpty ? nil : foundScenes
    }
    
    enum CodingKeys: String, CodingKey {
        case sections, scenes
        case categoryFilter = "category_filter"
    }
}

public struct VeraScene: Codable {
    let id: Int
    let name: String?  // Optional because status endpoint may not include name
    let room: Int?
    let active: Bool?  // Changed from Int to Bool - status endpoint returns bool
    let state: Int?    // Scene state (e.g., -1, 4, etc.)
    let comment: String? // Scene comment/description

    enum CodingKeys: String, CodingKey {
        case id, name, room, active, state, comment
    }

    // Custom decoder to handle type variations across different endpoints
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        room = try container.decodeIfPresent(Int.self, forKey: .room)
        state = try container.decodeIfPresent(Int.self, forKey: .state)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)

        // Handle active as either Bool or Int
        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: .active) {
            active = boolValue
        } else if let intValue = try? container.decodeIfPresent(Int.self, forKey: .active) {
            active = intValue != 0
        } else {
            active = nil
        }
    }
}

public struct VeraSection: Codable {
    let deviceType: String?
    let name: String?
    let id: Int?
    let scenes: [VeraScene]?
    let tabs: [VeraTab]?
    
    // Custom initializer to handle the actual JSON structure
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        deviceType = try container.decodeIfPresent(String.self, forKey: .deviceType)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        tabs = try container.decodeIfPresent([VeraTab].self, forKey: .tabs)
        
        // Try to decode as a scene if it has scene properties
        if container.contains(.id) && container.contains(.name) {
            // This section is actually a scene
            scenes = nil
        } else {
            // This section contains scenes
            scenes = try container.decodeIfPresent([VeraScene].self, forKey: .scenes)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case name, id, scenes
        case deviceType = "DeviceType"
        case tabs = "Tabs"
    }
}

public struct VeraTab: Codable {
    let label: VeraLabel?
    let position: String?
    let tabType: String?
    let function: String?
    let permission: String?
    
    enum CodingKeys: String, CodingKey {
        case label = "Label"
        case position = "Position"
        case tabType = "TabType"
        case function = "Function"
        case permission = "Permission"
    }
}

public struct VeraLabel: Codable {
    let langTag: String?
    let text: String?
    
    enum CodingKeys: String, CodingKey {
        case text
        case langTag = "lang_tag"
    }
}

public struct VeraCategoryFilter: Codable {
    let id: Int
    let categories: [String]?
    let label: VeraLabel?
    
    enum CodingKeys: String, CodingKey {
        case id, categories
        case label = "Label"
    }
}

// MARK: - Device Status Response
/// Response from /data_request?id=status endpoint
/// This endpoint returns an array of devices, not a dictionary with Device_Num_X keys
public struct VeraStatusResponse: Codable {
    let devices: [VeraDevice]?
    let scenes: [VeraScene]?
    let startup: AnyCodable?  // Changed from String - can be dict {"tasks": []} or string
    let dataVersion: Int?  // Changed from String - API returns Int
    let timestamp: Int?

    enum CodingKeys: String, CodingKey {
        case devices, scenes, startup, timestamp
        case dataVersion = "DataVersion"
    }
}


public struct VeraDevice: Codable {
    let id: Int?
    let name: String?
    let states: [VeraDeviceState]?
    let armed: String?
    let state: String?
    let status: Int?
    let value: String?
    let armMode: String?
    let jobs: [AnyCodable]?
    let pendingJobs: Int?
    let tooltip: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, states, armed, state, status, value, jobs, tooltip
        case armMode = "ArmMode"
        case pendingJobs = "PendingJobs"
    }
}

public struct VeraDeviceState: Codable {
    let id: Int?
    let service: String
    let variable: String
    let value: AnyCodable
    
    enum CodingKeys: String, CodingKey {
        case id, service, variable, value
    }
}


// MARK: - SData Response (Optimized for Polling)
/// Response from /data_request?id=sdata endpoint
/// This is an abbreviated, optimized response designed for UI polling
public struct VeraSDataResponse: Codable {
    let devices: [VeraSDataDevice]?
    let scenes: [VeraScene]?
    let rooms: [VeraRoom]?
    let sections: [VeraSection]?
    let categories: [VeraCategory]?
    let dataVersion: Int?
    let loadTime: Int?
    let full: Int?
    let version: String?
    let model: String?
    let temperature: String?
    let skin: String?
    let serialNumber: String?
    let fwd1: String?
    let fwd2: String?
    let ir: Int?
    let irtx: String?
    let mode: Int?
    let state: Int?
    let comment: String?

    enum CodingKeys: String, CodingKey {
        case devices, scenes, rooms, sections, categories, full, version, model, temperature, skin, ir, irtx, mode, state, comment
        case dataVersion = "dataversion"
        case loadTime = "loadtime"
        case serialNumber = "serial_number"
        case fwd1, fwd2
    }
}

/// Simplified device model from sdata endpoint
public struct VeraSDataDevice: Codable {
    let id: Int
    let name: String
    let altId: String?
    let category: Int
    let subcategory: Int?
    let room: Int?
    let parent: Int?
    let status: String?  // Can be "1", "0", or other values
    let state: Int?
    let configured: String?
    let comment: String?
    let level: String?
    let temperature: String?
    let locked: String?
    let tripped: String?

    enum CodingKeys: String, CodingKey {
        case id, name, category, subcategory, room, parent, status, state, configured, comment
        case level, temperature, locked, tripped
        case altId = "altid"
    }
}

// MARK: - Room Data Response
public struct VeraRoomsResponse: Codable {
    let rooms: [VeraRoom]?

    enum CodingKeys: String, CodingKey {
        case rooms
    }
}

public struct VeraRoom: Codable, Sendable {
    let id: Int
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id, name
    }
}

public struct VeraCategory: Codable, Sendable {
    let id: Int
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
    }
}

// MARK: - AnyCodable Helper
public struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}
