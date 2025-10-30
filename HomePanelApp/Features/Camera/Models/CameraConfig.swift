import Foundation

// MARK: - Video Management System Types

/// Types of video management systems and camera protocols supported
public enum VMSType: String, Codable, CaseIterable, Sendable {
    case blueIris = "Blue Iris"
    case frigate = "Frigate NVR"
    case rtspGeneric = "RTSP Camera"
    case mjpegGeneric = "MJPEG Camera"
    case genericWebView = "Generic Web View"

    /// Display name for UI
    var displayName: String {
        return self.rawValue
    }

    /// Whether this VMS type requires a web view
    var requiresWebView: Bool {
        switch self {
        case .blueIris, .frigate, .genericWebView:
            return true
        case .rtspGeneric, .mjpegGeneric:
            return false
        }
    }

    /// Whether this VMS type requires JavaScript enabled
    var requiresJavaScript: Bool {
        switch self {
        case .blueIris, .frigate:
            return true
        case .rtspGeneric, .mjpegGeneric, .genericWebView:
            return false
        }
    }

    /// Default port for this VMS type
    var defaultPort: Int {
        switch self {
        case .blueIris:
            return 2671  // Blue Iris default web port
        case .frigate:
            return 5000  // Frigate default port
        case .rtspGeneric:
            return 554  // RTSP standard port
        case .mjpegGeneric:
            return 80  // HTTP default
        case .genericWebView:
            return 80  // HTTP default
        }
    }
}

// MARK: - Camera Configuration

/// Configuration for a camera/VMS connection
public struct CameraConfig: Codable, Identifiable {
    public let id: String
    public let name: String           // User-defined name (e.g., "Front Door", "Backyard")
    public let vmsType: VMSType       // Type of VMS/camera system
    public let ipAddress: String
    public let port: Int
    public let username: String
    public let path: String
    public let lastUpdated: Date

    // MARK: - Initialization

    public init(
        id: String,
        name: String,
        vmsType: VMSType,
        ipAddress: String,
        port: Int,
        username: String,
        path: String,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.vmsType = vmsType
        self.ipAddress = ipAddress
        self.port = port
        self.username = username
        self.path = path
        self.lastUpdated = lastUpdated
    }

    // MARK: - URL Building

    /// Builds a basic URL for the camera (without credentials)
    /// Actual URL construction should be handled by VMS-specific adapters
    public func buildBaseURL() -> URL? {
        let urlString = "http://\(ipAddress):\(port)\(path)"
        return URL(string: urlString)
    }

    
    // MARK: - Computed Properties
    
    /// Returns true if IP address, port, and username are configured
    var isConfigured: Bool {
        !ipAddress.isEmpty && port > 0 && (vmsType == .blueIris || !username.isEmpty)
    }
    
    
    // MARK: - Default Configurations
    
    /// Creates default configuration for Camera 1
    static func camera1() -> CameraConfig {
        CameraConfig(
            id: "camera1",
            name: "Camera 1",
            vmsType: .blueIris,
            ipAddress: "",
            port: 2671,  // Blue Iris default web port
            username: "",
            path: "/ui3.htm?t=live&group=Index"
        )
    }
    
    /// Creates default configuration for Camera 2
    static func camera2() -> CameraConfig {
        CameraConfig(
            id: "camera2",
            name: "Camera 2",
            vmsType: .blueIris,
            ipAddress: "",
            port: 2671,  // Blue Iris default web port
            username: "",
            path: "/ui3.htm?t=live&group=Index"
        )
    }
    
    
    // MARK: - Validation
    
    /// Validates that the IP address is valid
    var isValidIPAddress: Bool {
        let components = ipAddress.split(separator: ".")
        guard components.count == 4 else { return false }
        return components.allSatisfy { component in
            guard let number = Int(component) else { return false }
            return number >= 0 && number <= 255
        }
    }
    
    /// Validates that the port is valid
    var isValidPort: Bool {
        return port > 0 && port <= 65535
    }
    
    /// Validates that the URL is valid
    var isValidURL: Bool {
        buildBaseURL() != nil
    }
    
    /// Returns true if the configuration is valid for saving
    var isValidForSaving: Bool {
        isValidIPAddress && isValidPort && (vmsType != .blueIris || !username.isEmpty)
    }
}
