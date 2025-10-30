import Foundation

// MARK: - Camera Service Coordinator

/// Coordinates camera operations across different VMS types
/// Routes requests to the appropriate VMS-specific adapter based on camera configuration
@MainActor
public class CameraServiceCoordinator: CameraServiceProtocol {

    // MARK: - Properties

    /// Cache of adapters by VMS type to avoid recreating them
    private var adapterCache: [VMSType: CameraServiceProtocol] = [:]

    // MARK: - Initialization

    public init() {
        // Coordinator doesn't need dependencies - adapters are created on demand
    }

    // MARK: - CameraServiceProtocol Implementation

    public func prepareConnection(
        config: CameraConfig,
        credentials: CameraCredentials
    ) async throws -> CameraConnection {
        let adapter = getAdapter(for: config.vmsType)

        // Validate configuration before preparing connection
        try adapter.validateConfiguration(config: config)

        // Delegate to appropriate adapter
        return try await adapter.prepareConnection(config: config, credentials: credentials)
    }

    public func validateConfiguration(config: CameraConfig) throws {
        let adapter = getAdapter(for: config.vmsType)
        try adapter.validateConfiguration(config: config)
    }

    public func getViewType(for config: CameraConfig) -> CameraViewType {
        let adapter = getAdapter(for: config.vmsType)
        return adapter.getViewType(for: config)
    }

    // MARK: - Private Methods

    /// Gets or creates the appropriate adapter for the VMS type
    /// Uses caching to avoid creating multiple adapter instances
    private func getAdapter(for vmsType: VMSType) -> CameraServiceProtocol {
        // Check cache first
        if let cachedAdapter = adapterCache[vmsType] {
            return cachedAdapter
        }

        // Create new adapter based on VMS type
        let adapter: CameraServiceProtocol

        switch vmsType {
        case .blueIris:
            // Blue Iris web-based VMS
            adapter = BlueIrisCameraAdapter()

        case .frigate:
            // Frigate NVR (future implementation)
            // For now, use generic web view adapter
            adapter = GenericWebViewAdapter()

        case .rtspGeneric:
            // Direct RTSP stream (future implementation)
            // For now, throw error
            adapter = UnsupportedVMSAdapter(vmsType: vmsType)

        case .mjpegGeneric:
            // Direct MJPEG stream (future implementation)
            // For now, throw error
            adapter = UnsupportedVMSAdapter(vmsType: vmsType)

        case .genericWebView:
            // Generic web view
            adapter = GenericWebViewAdapter()
        }

        // Cache the adapter
        adapterCache[vmsType] = adapter

        return adapter
    }
}

// MARK: - Placeholder Adapters

/// Temporary adapter for unsupported VMS types
/// This allows the app to compile while we implement each adapter incrementally
@MainActor
private class UnsupportedVMSAdapter: CameraServiceProtocol {
    let vmsType: VMSType

    init(vmsType: VMSType) {
        self.vmsType = vmsType
    }

    func prepareConnection(config: CameraConfig, credentials: CameraCredentials) async throws -> CameraConnection {
        throw CameraServiceError.unsupportedVMSType
    }

    func validateConfiguration(config: CameraConfig) throws {
        throw CameraServiceError.unsupportedVMSType
    }

    func getViewType(for config: CameraConfig) -> CameraViewType {
        return .webView
    }
}

/// Generic web view adapter for simple web-based cameras
@MainActor
private class GenericWebViewAdapter: CameraServiceProtocol {

    func prepareConnection(config: CameraConfig, credentials: CameraCredentials) async throws -> CameraConnection {
        // Build URL with embedded credentials
        let urlString = "http://\(config.username):\(credentials.password)@\(config.ipAddress):\(config.port)\(config.path)"

        guard let url = URL(string: urlString) else {
            throw CameraServiceError.invalidURL
        }

        return CameraConnection(
            viewType: .webView,
            connectionURL: url,
            additionalHeaders: nil,
            requiresJavaScript: false
        )
    }

    func validateConfiguration(config: CameraConfig) throws {
        guard config.port > 0 && config.port < 65536 else {
            throw CameraServiceError.invalidPort
        }
    }

    func getViewType(for config: CameraConfig) -> CameraViewType {
        return .webView
    }
}
