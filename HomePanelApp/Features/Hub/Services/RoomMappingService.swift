import Foundation
import Combine

// MARK: - Room Mapping Service

/// Service for mapping room IDs to room names from Vera Hub
@MainActor
class RoomMappingService: ObservableObject {
    @Published private(set) var roomMaps: [String: [String: String]] = [:] // hubId -> [roomId: roomName]
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: Error?
    
    private let hubService: HubServiceProtocol
    
    init(hubService: HubServiceProtocol) {
        self.hubService = hubService
    }
    
    /// Fetch and cache room mappings from Vera Hub with timeout and fallback
    func refreshRoomMappings() async {
        isLoading = true
        lastError = nil
        
        do {
            // Get the hub service coordinator to access Vera Hub adapter
            if let coordinator = hubService as? HubServiceCoordinator {
                // Get all available hubs and fetch room mappings from each
                let hubs = await coordinator.getAllHubs()
                DebugLogger.log("RoomMappingService: Found \(hubs.count) hubs for room mapping: \(hubs.map { $0.hubId })", feature: .automation)
                var newRoomMaps: [String: [String: String]] = [:]
                
                for hub in hubs {
                    DebugLogger.log("RoomMappingService: Processing hub '\(hub.hubId)' of type '\(type(of: hub))'", feature: .automation)
                    
                    // Cast to VeraHubAdapter to access fetchRooms method
                    if let veraAdapter = hub as? VeraHubAdapter {
                        do {
                            // Use timeout wrapper to prevent indefinite hanging
                            let rooms = try await withTimeout(seconds: TimeoutConfiguration.roomMapping) {
                                try await veraAdapter.fetchRooms()
                            }
                            DebugLogger.log("RoomMappingService: Fetched \(rooms.count) rooms from hub \(hub.hubId)", feature: .automation)
                            
                            // Build room mapping dictionary for this hub using hub-scoped room IDs
                            var hubRoomMap: [String: String] = [:]
                            for room in rooms {
                                let hubScopedRoomId = HubScopedID.roomID(hubId: hub.hubId, roomId: String(room.id))
                                hubRoomMap[hubScopedRoomId] = room.name
                            }
                            
                            newRoomMaps[hub.hubId] = hubRoomMap
                            DebugLogger.log("RoomMappingService: Loaded \(rooms.count) rooms from hub \(hub.hubId). Room mappings: \(hubRoomMap)", feature: .automation)
                        } catch {
                            DebugLogger.log("RoomMappingService: Failed to load rooms from hub \(hub.hubId): \(error.localizedDescription)", feature: .automation)
                            
                            // Provide fallback room mappings to prevent camera UI issues
                            let fallbackRooms = createFallbackRoomMappings(for: hub.hubId)
                            newRoomMaps[hub.hubId] = fallbackRooms
                            DebugLogger.log("RoomMappingService: Using fallback room mappings for hub \(hub.hubId): \(fallbackRooms)", feature: .automation)
                        }
                    } else {
                        DebugLogger.log("RoomMappingService: Hub '\(hub.hubId)' is not a VeraHubAdapter, skipping", feature: .automation)
                    }
                }
                
                await MainActor.run {
                    self.roomMaps = newRoomMaps
                    self.isLoading = false
                }
                
                DebugLogger.log("RoomMappingService: Loaded room mappings for \(newRoomMaps.count) hubs", feature: .automation)
            } else {
                throw RoomMappingError.invalidHubService
            }
        } catch {
            await MainActor.run {
                self.lastError = error
                self.isLoading = false
            }
            DebugLogger.log("RoomMappingService: Failed to load rooms: \(error.localizedDescription)", feature: .automation)
        }
    }
    
    /// Create fallback room mappings when network requests fail
    private func createFallbackRoomMappings(for hubId: String) -> [String: String] {
        // Provide basic room mappings to prevent camera UI from breaking
        let fallbackRooms = [
            "1": "House",
            "2": "Living Room", 
            "3": "Kitchen",
            "4": "Master Bedroom",
            "5": "Guest Room",
            "6": "Study",
            "7": "Garage",
            "8": "Basement",
            "9": "Attic"
        ]
        
        var hubScopedMappings: [String: String] = [:]
        for (roomId, roomName) in fallbackRooms {
            let hubScopedRoomId = HubScopedID.roomID(hubId: hubId, roomId: roomId)
            hubScopedMappings[hubScopedRoomId] = roomName
        }
        
        return hubScopedMappings
    }
    
    
    /// Get room name for a given room ID and hub ID
    func roomName(for roomId: String, hubId: String) -> String {
        guard let hubRoomMap = roomMaps[hubId] else {
            DebugLogger.log("RoomMappingService: No room mappings found for hub '\(hubId)'", feature: .automation)
            return "Unknown Room"
        }
        
        // Check if roomId is already hub-scoped
        let lookupRoomId: String
        if HubScopedID.isHubScoped(roomId) {
            // Room ID is already hub-scoped, use it directly
            lookupRoomId = roomId
        } else {
            // Convert room ID to hub-scoped ID for lookup
            lookupRoomId = HubScopedID.roomID(hubId: hubId, roomId: roomId)
        }
        
        let roomName = hubRoomMap[lookupRoomId] ?? "Unknown Room"
        
        if roomName == "Unknown Room" {
            DebugLogger.log("RoomMappingService: No mapping found for room ID '\(roomId)' in hub '\(hubId)'", feature: .automation)
        }
        return roomName
    }
    
    /// Check if room mapping is available for a room ID in a specific hub
    func hasRoomMapping(for roomId: String, hubId: String) -> Bool {
        // Check if roomId is already hub-scoped
        let lookupRoomId: String
        if HubScopedID.isHubScoped(roomId) {
            // Room ID is already hub-scoped, use it directly
            lookupRoomId = roomId
        } else {
            // Convert room ID to hub-scoped ID for lookup
            lookupRoomId = HubScopedID.roomID(hubId: hubId, roomId: roomId)
        }
        return roomMaps[hubId]?[lookupRoomId] != nil
    }
}

// MARK: - Room Mapping Errors

enum RoomMappingError: Error, LocalizedError {
    case invalidHubType
    case noHubsAvailable
    case invalidHubService
    case roomNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidHubType:
            return "Invalid hub type - expected VeraHubAdapter"
        case .noHubsAvailable:
            return "No hubs available for room mapping"
        case .invalidHubService:
            return "Invalid hub service type"
        case .roomNotFound(let roomId):
            return "Room with ID '\(roomId)' not found"
        }
    }
}

