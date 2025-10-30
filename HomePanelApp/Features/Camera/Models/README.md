# Camera Models

This directory contains the data models for camera configuration, VMS types, and credential management, providing secure storage structures for multi-VMS camera integration through the adapter pattern.

## 📊 Data Models

### CameraConfig

Configuration structure for camera settings and connection parameters.

```swift
public struct CameraConfig: Codable, Identifiable {
    public let id: String
    public let name: String           // User-defined name
    public let vmsType: VMSType       // VMS system type
    public let ipAddress: String
    public let port: Int
    public let username: String
    public let path: String
    public let lastUpdated: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        vmsType: VMSType,
        ipAddress: String,
        port: Int,
        username: String = "",
        path: String = "",
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
}
```

**Properties:**
- `id`: Unique identifier for the camera configuration
- `name`: User-defined camera name (e.g., "Front Door", "Backyard") - legacy "Iris One"/"Iris Two" naming deprecated
- `vmsType`: Type of VMS system (Blue Iris, Frigate, RTSP, etc.)
- `ipAddress`: VMS server IP address
- `port`: VMS web port (varies by VMS type)
- `username`: VMS login username
- `path`: VMS-specific path for optimal viewing
- `lastUpdated`: Timestamp of last configuration update

**Usage:**
```swift
let config = CameraConfig(
    name: "Front Door",
    vmsType: .blueIris,
    ipAddress: "192.168.1.100",
    port: 81,
    username: "admin"
)
```

### CameraCredentials

Secure credential storage for camera authentication.

```swift
public struct CameraCredentials: Codable {
    public let cameraId: String
    public let password: String
    public let lastUpdated: Date
    
    public init(cameraId: String, password: String) {
        self.cameraId = cameraId
        self.password = password
        self.lastUpdated = Date()
    }
}
```

**Security Features:**
- Password stored securely in iOS Keychain
- Camera ID association for multi-camera support
- Last updated timestamp for credential management
- Automatic encryption/decryption

**Usage:**
```swift
let credentials = CameraCredentials(
    cameraId: "iris-one",
    password: "secret123"
)
```

### VMSType

Enumeration of supported Video Management System types.

```swift
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
            return 81  // Blue Iris default web port
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
```

**Properties:**
- `displayName`: User-friendly name for UI display
- `requiresWebView`: Whether this VMS type uses web view
- `requiresJavaScript`: Whether JavaScript is required
- `defaultPort`: Default port for this VMS type

### CameraConnection

Result of preparing a camera connection with all necessary details.

```swift
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

    /// Whether this connection is ready to use
    public var isValid: Bool {
        return errorMessage == nil
    }

    /// Whether this connection uses a web view
    public var usesWebView: Bool {
        return viewType == .webView
    }
}
```

### CameraViewType

Types of views needed to display different camera systems.

```swift
public enum CameraViewType: Sendable {
    case webView      // For web-based VMS (Blue Iris, Frigate, etc.)
    case rtspStream   // For direct RTSP streams
    case mjpegStream  // For MJPEG streams
    case native       // For native iOS camera protocols (future)
}
```

## 🔐 Security Models

### Credential Management

Secure storage and retrieval of camera credentials:

```swift
extension CameraCredentials {
    var keychainKey: String {
        "camera_credentials_\(cameraId)"
    }
    
    func store() throws {
        let data = try JSONEncoder().encode(self)
        try KeychainService.shared.storeData(key: keychainKey, value: data)
    }
    
    static func load(for cameraId: String) throws -> CameraCredentials? {
        let data = try KeychainService.shared.retrieveData(key: "camera_credentials_\(cameraId)")
        return try JSONDecoder().decode(CameraCredentials.self, from: data)
    }
}
```

### URL Building

URL construction is handled by VMS-specific adapters through the `CameraServiceProtocol`:

```swift
// Use CameraServiceCoordinator for URL building
let cameraService = CameraServiceCoordinator()
let connection = try await cameraService.prepareConnection(
    config: cameraConfig, 
    credentials: credentials
)

// Access the built URL
let url = connection.connectionURL
```

**Note**: Direct URL building methods are deprecated. Use the adapter pattern for VMS-specific URL construction.

## 🎨 UI Integration

### Configuration Display

User-friendly configuration representation:

```swift
extension CameraConfig {
    var displayName: String {
        "Camera \(id.prefix(8))"
    }
    
    var connectionString: String {
        "\(ipAddress):\(port)"
    }
    
    var isConfigured: Bool {
        !ipAddress.isEmpty && port > 0
    }
}
```

### Validation

Input validation for configuration parameters:

```swift
extension CameraConfig {
    var isValid: Bool {
        return IPValidator.isValid(ipAddress) &&
               port > 0 && port <= 65535 &&
               !username.isEmpty
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        
        if !IPValidator.isValid(ipAddress) {
            errors.append("Invalid IP address format")
        }
        
        if port <= 0 || port > 65535 {
            errors.append("Port must be between 1 and 65535")
        }
        
        if username.isEmpty {
            errors.append("Username is required")
        }
        
        return errors
    }
}
```

## 🔄 State Management

### Configuration Updates

Track configuration changes and updates:

```swift
extension CameraConfig {
    mutating func update(
        ipAddress: String? = nil,
        port: Int? = nil,
        username: String? = nil
    ) {
        if let ipAddress = ipAddress {
            self.ipAddress = ipAddress
        }
        if let port = port {
            self.port = port
        }
        if let username = username {
            self.username = username
        }
        self.lastUpdated = Date()
    }
}
```

### Credential Updates

Secure credential update handling:

```swift
extension CameraCredentials {
    mutating func updatePassword(_ newPassword: String) {
        self.password = newPassword
        self.lastUpdated = Date()
    }
    
    var isExpired: Bool {
        let expirationTime: TimeInterval = 30 * 24 * 60 * 60 // 30 days
        return Date().timeIntervalSince(lastUpdated) > expirationTime
    }
}
```

## 🧪 Testing

### Model Testing

Test data model functionality:

```swift
func testCameraConfigCreation() {
    let config = CameraConfig(
        ipAddress: "192.168.1.100",
        port: 2671,
        username: "admin"
    )
    
    XCTAssertEqual(config.ipAddress, "192.168.1.100")
    XCTAssertEqual(config.port, 2671)
    XCTAssertEqual(config.username, "admin")
    XCTAssertTrue(config.isValid)
}

func testCameraCredentialsSecurity() {
    let credentials = CameraCredentials(
        cameraId: "iris-one",
        password: "secret123"
    )
    
    XCTAssertEqual(credentials.cameraId, "iris-one")
    XCTAssertEqual(credentials.password, "secret123")
    XCTAssertFalse(credentials.isExpired)
}
```

### Validation Testing

Test input validation:

```swift
func testIPValidation() {
    let validConfig = CameraConfig(ipAddress: "192.168.1.100", port: 2671, username: "admin")
    XCTAssertTrue(validConfig.isValid)
    
    let invalidConfig = CameraConfig(ipAddress: "invalid-ip", port: 2671, username: "admin")
    XCTAssertFalse(invalidConfig.isValid)
    XCTAssertTrue(invalidConfig.validationErrors.contains("Invalid IP address format"))
}

func testPortValidation() {
    let validConfig = CameraConfig(ipAddress: "192.168.1.100", port: 2671, username: "admin")
    XCTAssertTrue(validConfig.isValid)
    
    let invalidConfig = CameraConfig(ipAddress: "192.168.1.100", port: 70000, username: "admin")
    XCTAssertFalse(invalidConfig.isValid)
    XCTAssertTrue(invalidConfig.validationErrors.contains("Port must be between 1 and 65535"))
}
```

### URL Building Testing

Test URL construction:

```swift
func testURLBuilding() {
    let config = CameraConfig(
        ipAddress: "192.168.1.100",
        port: 2671,
        username: "admin"
    )
    
    let credentials = CameraCredentials(
        cameraId: "camera1",
        password: "secret123"
    )
    
    // Use adapter pattern for URL building
    let cameraService = CameraServiceCoordinator()
    Task {
        do {
            let connection = try await cameraService.prepareConnection(
                config: config, 
                credentials: credentials
            )
            XCTAssertNotNil(connection.connectionURL)
            XCTAssertTrue(connection.connectionURL.absoluteString.contains("192.168.1.100"))
        } catch {
            XCTFail("URL building failed: \(error)")
        }
    }
}
```

## 📁 Files

- **CameraConfig.swift** - Camera configuration data structure with VMS support
- **CameraCredentials.swift** - Secure credential storage structure
- **CameraConnection.swift** - Camera connection result model

## 🔗 Navigation

- **[Camera System](../README.md)** - Main camera system documentation
- **[Services](../Services/README.md)** - Camera configuration and credential management
- **[ViewModels](../ViewModels/README.md)** - Camera state and configuration logic
- **[Views](../Views/README.md)** - Camera interface and settings components

---

These models provide the foundation for camera configuration management and secure credential storage in the camera surveillance system.
