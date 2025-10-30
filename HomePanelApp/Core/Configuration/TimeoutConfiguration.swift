import Foundation

/// Centralized timeout configuration for network operations
///
/// All timeout values used throughout the app are defined here for easy management
/// and consistency. Adjust these values to tune network timeout behavior globally.
enum TimeoutConfiguration {
    /// Quick reachability checks (e.g., hub ping, connection test)
    /// Used in: BaseHubAdapter.isReachable
    static let reachabilityCheck: TimeInterval = 3.0

    /// Standard room mapping operations
    /// Used in: RoomMappingService
    static let roomMapping: TimeInterval = 15.0

    /// Quick automation room mapping
    /// Used in: AutomationViewModel
    static let automationRoomMapping: TimeInterval = 10.0

    /// Standard API requests (hub commands, device operations, scene execution)
    /// Used in: BaseHubAdapter.makeRequest, general hub operations
    static let standardRequest: TimeInterval = 30.0

    /// Long-running resource downloads and file transfers
    /// Used in: URLSession configuration for resource downloads
    static let resourceDownload: TimeInterval = 60.0
}
