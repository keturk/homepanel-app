import Foundation

// MARK: - Camera View Types

/// Types of views needed to display different camera systems
public enum CameraViewType: Sendable {
    case webView      // For web-based VMS (Blue Iris, Frigate, etc.)
    case rtspStream   // For direct RTSP streams
    case mjpegStream  // For MJPEG streams
    case native       // For native iOS camera protocols (future)
}

// MARK: - Camera Connection

/// Result of preparing a camera connection
/// Contains all information needed to display the camera stream
public struct CameraConnection: Sendable {
    /// The type of view required to display this camera
    public let viewType: CameraViewType

    /// The URL to connect to
    public let connectionURL: URL

    /// Additional HTTP headers to include (e.g., authentication tokens)
    public let additionalHeaders: [String: String]?

    /// Whether JavaScript should be enabled (for web views)
    public let requiresJavaScript: Bool

    /// Optional error message if connection preparation failed
    public let errorMessage: String?

    // MARK: - Initialization

    public init(
        viewType: CameraViewType,
        connectionURL: URL,
        additionalHeaders: [String: String]? = nil,
        requiresJavaScript: Bool = false,
        errorMessage: String? = nil
    ) {
        self.viewType = viewType
        self.connectionURL = connectionURL
        self.additionalHeaders = additionalHeaders
        self.requiresJavaScript = requiresJavaScript
        self.errorMessage = errorMessage
    }

    // MARK: - Convenience Properties

    /// Whether this connection is ready to use
    public var isValid: Bool {
        return errorMessage == nil
    }

    /// Whether this connection uses a web view
    public var usesWebView: Bool {
        return viewType == .webView
    }
}
