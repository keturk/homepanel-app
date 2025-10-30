import Foundation

// MARK: - Blue Iris Camera Adapter

/// Adapter for Blue Iris video management system
/// Handles Blue Iris-specific connection setup and authentication
@MainActor
class BlueIrisCameraAdapter: CameraServiceProtocol {

    // MARK: - CameraServiceProtocol Implementation

    func prepareConnection(
        config: CameraConfig,
        credentials: CameraCredentials
    ) async throws -> CameraConnection {

        // Validate configuration first
        try validateConfiguration(config: config)

        // Blue Iris specific: build URL without embedded credentials
        // Format: http://ip:port/path
        let urlString = buildBlueIrisURL(config: config)

        guard let url = URL(string: urlString) else {
            DebugLogger.error("❌ Invalid Blue Iris URL: \(urlString)", feature: .camera)
            throw CameraServiceError.invalidURL
        }

        DebugLogger.log("✅ Prepared Blue Iris connection to \(config.ipAddress):\(config.port)", feature: .camera)

        return CameraConnection(
            viewType: .webView,
            connectionURL: url,
            additionalHeaders: nil,
            requiresJavaScript: true  // Blue Iris web UI requires JavaScript
        )
    }

    func validateConfiguration(config: CameraConfig) throws {
        // Validate port range
        guard config.port > 0 && config.port < 65536 else {
            DebugLogger.error("❌ Invalid Blue Iris port: \(config.port)", feature: .camera)
            throw CameraServiceError.invalidPort
        }

        // Validate path format (should start with /)
        guard config.path.hasPrefix("/") else {
            DebugLogger.error("❌ Invalid Blue Iris path: \(config.path)", feature: .camera)
            throw CameraServiceError.invalidPath
        }

        // Validate IP address is not empty
        guard !config.ipAddress.isEmpty else {
            throw CameraServiceError.configurationError("IP address is required")
        }

        DebugLogger.log("✅ Blue Iris configuration validated", feature: .camera)
    }

    func getViewType(for config: CameraConfig) -> CameraViewType {
        return .webView
    }

    // MARK: - Private Methods (Blue Iris Specific)

    /// Builds a Blue Iris URL without embedded credentials
    /// Format: http://ip:port/path
    private func buildBlueIrisURL(config: CameraConfig) -> String {
        return "http://\(config.ipAddress):\(config.port)\(config.path)"
    }
}

// MARK: - Character Set Extensions

private extension CharacterSet {
    /// Characters allowed in URL passwords
    static let urlPasswordAllowed: CharacterSet = {
        var allowed = CharacterSet.urlHostAllowed
        allowed.remove(charactersIn: "@:/?#[]")
        return allowed
    }()

    /// Characters allowed in URL usernames
    static let urlUserAllowed: CharacterSet = {
        var allowed = CharacterSet.urlHostAllowed
        allowed.remove(charactersIn: "@:/?#[]")
        return allowed
    }()
}