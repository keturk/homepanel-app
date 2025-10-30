import Foundation
import Combine

// MARK: - Scene Service Protocol

/// Generic protocol for scene operations across all hub types
/// This protocol abstracts scene management away from specific hub implementations
@MainActor
public protocol SceneServiceProtocol: Sendable {
    /// Fetches the list of available scenes from a specific hub
    /// - Parameter hubId: The unique identifier of the hub
    /// - Returns: A HubScopedSceneMap containing scene mappings for the hub
    /// - Throws: HubError if the hub is not found or network errors occur
    func fetchSceneList(hubId: String) async throws -> HubScopedSceneMap

    /// Sets the alarm mode by executing the appropriate scene
    /// - Parameters:
    ///   - mode: The alarm mode to set (armedAway, armedStay, etc.)
    ///   - hubScopedSceneMap: The scene mapping for the hub
    ///   - hubId: The unique identifier of the hub
    /// - Throws: HubError if scene execution fails
    func setAlarmMode(_ mode: AlarmMode, hubScopedSceneMap: HubScopedSceneMap, hubId: String) async throws
}
