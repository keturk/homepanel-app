import Foundation

// MARK: - Camera Service Protocol

/// Generic protocol for camera/VMS operations across all system types
/// This protocol abstracts camera management away from specific VMS implementations
@MainActor
public protocol CameraServiceProtocol: Sendable {

    /// Prepares a connection to the camera system
    /// - Parameters:
    ///   - config: The camera configuration
    ///   - credentials: The camera credentials
    /// - Returns: A CameraConnection with all details needed to display the stream
    /// - Throws: CameraServiceError if preparation fails
    func prepareConnection(
        config: CameraConfig,
        credentials: CameraCredentials
    ) async throws -> CameraConnection

    /// Validates that a camera configuration is valid for this VMS type
    /// - Parameter config: The configuration to validate
    /// - Throws: CameraServiceError if validation fails
    func validateConfiguration(config: CameraConfig) throws

    /// Returns the view type needed for this camera system
    /// - Parameter config: The camera configuration
    /// - Returns: The type of view to use (webView, rtspStream, etc.)
    func getViewType(for config: CameraConfig) -> CameraViewType
}

// MARK: - Camera Service Errors

/// Errors that can occur during camera service operations
public enum CameraServiceError: LocalizedError {
    case invalidURL
    case invalidPort
    case invalidPath
    case missingCredentials
    case unsupportedVMSType
    case connectionFailed(String)
    case configurationError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The camera URL is invalid"
        case .invalidPort:
            return "The camera port is invalid"
        case .invalidPath:
            return "The camera path is invalid"
        case .missingCredentials:
            return "Camera credentials are missing"
        case .unsupportedVMSType:
            return "This camera system type is not yet supported"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }
}
