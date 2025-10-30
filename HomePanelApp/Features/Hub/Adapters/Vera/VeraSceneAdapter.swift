import Foundation

// MARK: - Vera Scene Adapter

/// Adapter for Vera Hub scene operations
/// Handles Vera-specific API calls and response parsing
@MainActor
class VeraSceneAdapter: SceneServiceProtocol {

    // MARK: - Properties

    private let hubService: HubServiceProtocol
    private let session: URLSession

    // MARK: - Initialization

    init(hubService: HubServiceProtocol, session: URLSession) {
        self.hubService = hubService
        self.session = session
    }

    // MARK: - SceneServiceProtocol Implementation

    func fetchSceneList(hubId: String) async throws -> HubScopedSceneMap {
        DebugLogger.log("🔍 [VeraSceneAdapter] Starting scene list fetch for hub: \(hubId)", feature: .alarm)
        
        // Get the hub configuration from hub service
        let registeredHubs = await hubService.getRegisteredHubs()
        DebugLogger.log("🔍 [VeraSceneAdapter] Found \(registeredHubs.count) registered hubs", feature: .alarm)
        
        guard let hub = registeredHubs.first(where: { $0.hubId == hubId }) else {
            DebugLogger.error("❌ [VeraSceneAdapter] Hub not found: \(hubId)", feature: .alarm)
            throw HubError.hubNotFound(hubId)
        }

        DebugLogger.log("🔍 [VeraSceneAdapter] Found hub: \(hub.hubId) at \(hub.connection.address)", feature: .alarm)

        // Vera-specific: Use the sdata endpoint on port 3480 for better performance
        let port = hub.connection.port ?? 3480 // Default Vera port
        let sdataURL = "http://\(hub.connection.address):\(port)/data_request?id=sdata"
        DebugLogger.log("🔍 [VeraSceneAdapter] Constructed sdata URL: \(sdataURL)", feature: .alarm)

        let sceneMap = try await fetchScenesFromURL(sdataURL, hubId: hubId)
        
        let sceneCount = sceneMap.getScenes(forHub: hubId).count
        DebugLogger.log("✅ [VeraSceneAdapter] Successfully fetched \(sceneCount) scenes for hub \(hubId)", feature: .alarm)

        return sceneMap
    }

    func setAlarmMode(_ mode: AlarmMode, hubScopedSceneMap: HubScopedSceneMap, hubId: String) async throws {
        // Get the scene ID for this mode using the scene name
        let sceneName = mode.sceneName
        guard let sceneId = hubScopedSceneMap.getSceneID(sceneName: sceneName, hubId: hubId) else {
            DebugLogger.error("❌ No scene mapped for alarm mode: \(mode) (scene name: \(sceneName))", feature: .alarm)
            throw HubError.sceneNotFound(sceneName)
        }

        DebugLogger.log("🎬 Executing Vera scene \(sceneId) for mode: \(mode)", feature: .alarm)

        // Use hub service to execute the scene
        try await hubService.executeScene(sceneId: sceneId, hubId: hubId)

        DebugLogger.log("✅ Successfully executed Vera scene for mode: \(mode)", feature: .alarm)
    }

    // MARK: - Private Methods (Vera-specific)

    /// Fetches and parses scenes from Vera's user_data endpoint
    private func fetchScenesFromURL(_ urlString: String, hubId: String) async throws -> HubScopedSceneMap {
        DebugLogger.log("🔍 [VeraSceneAdapter] Starting HTTP request to: \(urlString)", feature: .alarm)
        
        guard let url = URL(string: urlString) else {
            DebugLogger.error("❌ [VeraSceneAdapter] Invalid Vera URL: \(urlString)", feature: .alarm)
            throw HubError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        DebugLogger.log("🔍 [VeraSceneAdapter] Received \(data.count) bytes of data", feature: .alarm)

        guard let httpResponse = response as? HTTPURLResponse else {
            DebugLogger.error("❌ [VeraSceneAdapter] Invalid HTTP response from Vera hub", feature: .alarm)
            throw HubError.invalidResponse
        }

        DebugLogger.log("🔍 [VeraSceneAdapter] HTTP status code: \(httpResponse.statusCode)", feature: .alarm)
        
        guard httpResponse.statusCode == 200 else {
            DebugLogger.error("❌ [VeraSceneAdapter] Vera hub returned status code: \(httpResponse.statusCode)", feature: .alarm)
            throw HubError.serverError(httpResponse.statusCode)
        }

        // Parse Vera's JSON response
        DebugLogger.log("🔍 [VeraSceneAdapter] Starting JSON parsing for hub: \(hubId)", feature: .alarm)
        let sceneMap = try parseVeraScenes(from: data, hubId: hubId)

        let sceneCount = sceneMap.getScenes(forHub: hubId).count
        DebugLogger.log("✅ [VeraSceneAdapter] Successfully fetched \(sceneCount) scene mappings from Vera hub", feature: .alarm)

        return sceneMap
    }

    /// Parses Vera's sdata JSON response into scene mappings
    /// sdata endpoint has a simpler structure with scenes directly in the scenes array
    private func parseVeraScenes(from data: Data, hubId: String) throws -> HubScopedSceneMap {
        DebugLogger.log("🔍 [VeraSceneAdapter] Starting JSON parsing for hub: \(hubId)", feature: .alarm)
        let decoder = JSONDecoder()
        
        // Debug: Log the raw JSON data for troubleshooting
        if let jsonString = String(data: data, encoding: .utf8) {
            DebugLogger.log("🔍 [VeraSceneAdapter] Raw sdata JSON (first 500 chars): \(String(jsonString.prefix(500)))", feature: .alarm)
        }
        
        let response: VeraSDataResponse
        do {
            DebugLogger.log("🔍 [VeraSceneAdapter] Attempting to decode VeraSDataResponse", feature: .alarm)
            response = try decoder.decode(VeraSDataResponse.self, from: data)
            DebugLogger.log("✅ [VeraSceneAdapter] Successfully decoded VeraSDataResponse", feature: .alarm)
        } catch {
            DebugLogger.error("❌ [VeraSceneAdapter] JSON parsing failed: \(error.localizedDescription)", feature: .alarm)
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .typeMismatch(let type, let context):
                    DebugLogger.error("❌ [VeraSceneAdapter] Type mismatch: expected \(type), path: \(context.codingPath)", feature: .alarm)
                case .valueNotFound(let type, let context):
                    DebugLogger.error("❌ [VeraSceneAdapter] Value not found: \(type), path: \(context.codingPath)", feature: .alarm)
                case .keyNotFound(let key, let context):
                    DebugLogger.error("❌ [VeraSceneAdapter] Key not found: \(key), path: \(context.codingPath)", feature: .alarm)
                case .dataCorrupted(let context):
                    DebugLogger.error("❌ [VeraSceneAdapter] Data corrupted: \(context.debugDescription), path: \(context.codingPath)", feature: .alarm)
                @unknown default:
                    DebugLogger.error("❌ [VeraSceneAdapter] Unknown decoding error: \(decodingError)", feature: .alarm)
                }
            }
            throw error
        }

        // Log response structure for debugging
        DebugLogger.log("🔍 [VeraSceneAdapter] Response structure - devices: \(response.devices?.count ?? 0), scenes: \(response.scenes?.count ?? 0), rooms: \(response.rooms?.count ?? 0)", feature: .alarm)

        guard let scenes = response.scenes, !scenes.isEmpty else {
            DebugLogger.error("❌ [VeraSceneAdapter] No scenes found in Vera sdata response", feature: .alarm)
            throw HubError.invalidJSON // Using existing error since noScenesFound doesn't exist
        }

        DebugLogger.log("🔍 [VeraSceneAdapter] Found \(scenes.count) scenes from Vera sdata response", feature: .alarm)

        // Create hub-scoped scene map and add all found scenes
        var sceneMap = HubScopedSceneMap()
        var addedScenes = 0

        // Add all scenes to the map
        for scene in scenes {
            if let sceneName = scene.name {
                sceneMap.addScene(hubId: hubId, sceneName: sceneName, sceneId: scene.id)
                addedScenes += 1
                DebugLogger.log("✅ [VeraSceneAdapter] Added Vera scene '\(sceneName)' (ID: \(scene.id)) to scene map", feature: .alarm)
            } else {
                DebugLogger.log("⚠️ [VeraSceneAdapter] Skipping scene with ID \(scene.id) - no name", feature: .alarm)
            }
        }

        DebugLogger.log("🔍 [VeraSceneAdapter] Successfully added \(addedScenes) scenes to scene map", feature: .alarm)

        if sceneMap.getScenes(forHub: hubId).isEmpty {
            DebugLogger.error("❌ [VeraSceneAdapter] No scenes found in Vera sdata response after processing", feature: .alarm)
            throw HubError.invalidJSON // Using existing error since noScenesFound doesn't exist
        }

        return sceneMap
    }
}

// Note: All referenced types exist in the same module (HomePanelApp):
// - SceneServiceProtocol: HomePanelApp/Features/Hub/Services/SceneServiceProtocol.swift
// - HubServiceProtocol: HomePanelApp/Features/Hub/Services/HubServiceProtocol.swift
// - HubScopedSceneMap: HomePanelApp/Shared/Utilities/HubScopedID.swift
// - AlarmMode: HomePanelApp/Features/Alarm/Models/AlarmMode.swift
// - HubConfiguration: HomePanelApp/Features/Hub/Models/HubModels.swift
// - HubError: HomePanelApp/Core/Errors/AppErrors.swift
// - DebugLogger: HomePanelApp/Shared/Utilities/Debug/DebugLogger.swift
// - VeraSDataResponse: HomePanelApp/Features/Hub/Adapters/Vera/VeraModels.swift
// No additional imports needed beyond Foundation
