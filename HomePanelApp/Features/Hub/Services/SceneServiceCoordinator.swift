import Foundation

// MARK: - Scene Service Coordinator

/// Coordinates scene operations across different hub types
/// Routes requests to the appropriate hub-specific adapter based on hub type
@MainActor
public class SceneServiceCoordinator: SceneServiceProtocol {

    // MARK: - Properties

    private let hubService: HubServiceProtocol
    private let session: URLSession

    /// Cache of adapters by hub type to avoid recreating them
    private var adapterCache: [HubType: SceneServiceProtocol] = [:]

    // MARK: - Initialization

    init(hubService: HubServiceProtocol, session: URLSession) {
        self.hubService = hubService
        self.session = session
    }

    // MARK: - Public Methods

    public func fetchSceneList(hubId: String) async throws -> HubScopedSceneMap {
        let hub = try await getHub(hubId)
        let adapter = getAdapter(for: hub.hubType)
        return try await adapter.fetchSceneList(hubId: hubId)
    }

    public func setAlarmMode(_ mode: AlarmMode, hubScopedSceneMap: HubScopedSceneMap, hubId: String) async throws {
        let hub = try await getHub(hubId)
        let adapter = getAdapter(for: hub.hubType)
        try await adapter.setAlarmMode(mode, hubScopedSceneMap: hubScopedSceneMap, hubId: hubId)
    }

    // MARK: - Private Methods

    /// Retrieves hub configuration from hub service
    private func getHub(_ hubId: String) async throws -> HubConfiguration {
        let registeredHubs = await hubService.getRegisteredHubs()
        guard let hub = registeredHubs.first(where: { $0.hubId == hubId }) else {
            throw HubError.hubNotFound(hubId)
        }
        return hub
    }

    /// Gets or creates the appropriate adapter for the hub type
    /// Uses caching to avoid creating multiple adapter instances
    private func getAdapter(for hubType: HubType) -> SceneServiceProtocol {
        // Check cache first
        if let cachedAdapter = adapterCache[hubType] {
            return cachedAdapter
        }

        // Create new adapter based on hub type
        let adapter: SceneServiceProtocol

        switch hubType {
        case .vera:
            // For Vera hubs, use the Vera-specific adapter
            // This will be created in Task 3
            adapter = VeraSceneAdapter(hubService: hubService, session: session)

        // Future hub types can be added here:
        // case .zigbee:
        //     adapter = ZigbeeSceneAdapter(hubService: hubService, session: session)
        // case .zwave:
        //     adapter = ZwaveSceneAdapter(hubService: hubService, session: session)
        // case .homekit:
        //     adapter = HomeKitSceneAdapter(hubService: hubService, session: session)
        case .zigbee, .zwave, .homekit, .future:
            // For now, treat all other types as Vera adapters until specific adapters are created
            adapter = VeraSceneAdapter(hubService: hubService, session: session)
        }

        // Cache the adapter
        adapterCache[hubType] = adapter

        return adapter
    }
}

// Note: All referenced types exist in the same module (HomePanelApp):
// - HubServiceProtocol: HomePanelApp/Features/Hub/Services/HubServiceProtocol.swift
// - HubScopedSceneMap: HomePanelApp/Shared/Utilities/HubScopedID.swift
// - AlarmMode: HomePanelApp/Features/Alarm/Models/AlarmMode.swift
// - HubConfiguration: HomePanelApp/Features/Hub/Models/HubModels.swift
// - HubType: HomePanelApp/Features/Hub/Models/HubProtocol.swift
// - HubError: HomePanelApp/Core/Errors/AppErrors.swift
// No additional imports needed beyond Foundation
