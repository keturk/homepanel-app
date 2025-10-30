import Foundation

// MARK: - Hub-Scoped ID Utilities

/// Utility for creating and managing hub-scoped identifiers
/// This ensures unique IDs across multiple Vera hubs by prefixing with hub ID
public struct HubScopedID {
    
    /// Creates a hub-scoped device ID
    /// - Parameters:
    ///   - hubId: The hub identifier
    ///   - deviceId: The original device ID from Vera API
    /// - Returns: A unique device ID scoped to the hub (e.g., "hub_[HUB_ID]_device_123")
    public static func deviceID(hubId: String, deviceId: String) -> String {
        return "hub_\(hubId)_device_\(deviceId)"
    }
    
    /// Creates a hub-scoped room ID
    /// - Parameters:
    ///   - hubId: The hub identifier
    ///   - roomId: The original room ID from Vera API
    /// - Returns: A unique room ID scoped to the hub (e.g., "hub_[HUB_ID]_room_5")
    public static func roomID(hubId: String, roomId: String) -> String {
        return "hub_\(hubId)_room_\(roomId)"
    }
    
    /// Creates a hub-scoped scene ID
    /// - Parameters:
    ///   - hubId: The hub identifier
    ///   - sceneId: The original scene ID from Vera API
    /// - Returns: A unique scene ID scoped to the hub (e.g., "hub_[HUB_ID]_scene_3")
    public static func sceneID(hubId: String, sceneId: Int) -> String {
        return "hub_\(hubId)_scene_\(sceneId)"
    }
    
    /// Extracts the original device ID from a hub-scoped device ID
    /// - Parameter scopedID: The hub-scoped device ID
    /// - Returns: The original device ID, or nil if invalid format
    public static func extractDeviceID(from scopedID: String) -> String? {
        let components = scopedID.components(separatedBy: "_")
        guard components.count >= 4, components[0] == "hub", components[2] == "device" else {
            return nil
        }
        return components.dropFirst(3).joined(separator: "_")
    }
    
    /// Extracts the original room ID from a hub-scoped room ID
    /// - Parameter scopedID: The hub-scoped room ID
    /// - Returns: The original room ID, or nil if invalid format
    public static func extractRoomID(from scopedID: String) -> String? {
        let components = scopedID.components(separatedBy: "_")
        guard components.count >= 4, components[0] == "hub", components[2] == "room" else {
            return nil
        }
        return components.dropFirst(3).joined(separator: "_")
    }
    
    /// Extracts the original scene ID from a hub-scoped scene ID
    /// - Parameter scopedID: The hub-scoped scene ID
    /// - Returns: The original scene ID, or nil if invalid format
    public static func extractSceneID(from scopedID: String) -> Int? {
        let components = scopedID.components(separatedBy: "_")
        guard components.count >= 4, components[0] == "hub", components[2] == "scene" else {
            return nil
        }
        return Int(components[3])
    }
    
    /// Extracts the hub ID from a hub-scoped ID
    /// - Parameter scopedID: The hub-scoped ID
    /// - Returns: The hub ID, or nil if invalid format
    public static func extractHubID(from scopedID: String) -> String? {
        let components = scopedID.components(separatedBy: "_")
        guard components.count >= 4, components[0] == "hub" else {
            return nil
        }

        // Find the LAST type marker (device, room, or scene) that has at least one component after it
        // This handles cases where the hub ID or entity ID itself contains these words
        // Examples:
        // - "hub_living_room_hub_room_5" -> hub ID is "living_room_hub"
        // - "hub_hub1_room_living_room" -> hub ID is "hub1"
        var typeIndex = -1
        for (index, component) in components.enumerated() where index < components.count - 1 {
            if component == "device" || component == "room" || component == "scene" {
                typeIndex = index
                // Don't break - continue to find the LAST occurrence before the final component
            }
        }

        guard typeIndex > 1 else {
            return nil
        }

        // Hub ID is everything between index 1 and the type marker
        return components[1..<typeIndex].joined(separator: "_")
    }
    
    /// Checks if an ID is hub-scoped
    /// - Parameter id: The ID to check
    /// - Returns: True if the ID is hub-scoped, false otherwise
    public static func isHubScoped(_ id: String) -> Bool {
        return id.hasPrefix("hub_")
    }
}

// MARK: - Hub-Scoped Scene Map

/// Hub-scoped scene mapping that stores scene names mapped to hub-scoped scene IDs
public struct HubScopedSceneMap: Codable {
    private var sceneMaps: [String: [String: String]] = [:] // hubId -> [sceneName: hubScopedSceneID]
    
    /// Add a scene mapping for a specific hub
    /// - Parameters:
    ///   - hubId: The hub identifier
    ///   - sceneName: The scene name
    ///   - sceneId: The original scene ID from Vera API
    public mutating func addScene(hubId: String, sceneName: String, sceneId: Int) {
        if sceneMaps[hubId] == nil {
            sceneMaps[hubId] = [:]
        }
        sceneMaps[hubId]?[sceneName] = HubScopedID.sceneID(hubId: hubId, sceneId: sceneId)
    }
    
    /// Get the hub-scoped scene ID for a scene name in a specific hub
    /// - Parameters:
    ///   - sceneName: The scene name
    ///   - hubId: The hub identifier
    /// - Returns: The hub-scoped scene ID, or nil if not found
    public func getSceneID(sceneName: String, hubId: String) -> String? {
        return sceneMaps[hubId]?[sceneName]
    }
    
    /// Get all scene mappings for a specific hub
    /// - Parameter hubId: The hub identifier
    /// - Returns: Dictionary of scene names to hub-scoped scene IDs
    public func getScenes(forHub hubId: String) -> [String: String] {
        return sceneMaps[hubId] ?? [:]
    }
    
    /// Get all hub IDs that have scene mappings
    /// - Returns: Array of hub IDs
    public func getAllHubIds() -> [String] {
        return Array(sceneMaps.keys)
    }
    
    /// Clear all scene mappings for a specific hub
    /// - Parameter hubId: The hub identifier
    public mutating func clearScenes(forHub hubId: String) {
        sceneMaps.removeValue(forKey: hubId)
    }
    
    /// Clear all scene mappings
    public mutating func clearAll() {
        sceneMaps.removeAll()
    }
}
