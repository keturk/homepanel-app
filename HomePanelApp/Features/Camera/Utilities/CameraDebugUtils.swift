import Foundation

// MARK: - Camera Debug Utilities

struct CameraDebugUtils {

    // MARK: - Debug Methods

    static func printCameraTabViewInit(cameraId: String, isConfigured: Bool, isLoadingWebView: Bool) {
        DebugLogger.log("CameraTabView (\(cameraId)) - Initialized with isConfigured: \(isConfigured), isLoadingWebView: \(isLoadingWebView)", feature: .camera)
    }

    static func printWebViewURL(cameraId: String, url: URL?) {
        DebugLogger.log("CameraTabView (\(cameraId)) - webViewURL: \(url?.absoluteString ?? "nil")", feature: .camera)
    }

    static func printCameraConfig(cameraId: String, username: String, isConfigured: Bool) {
        DebugLogger.log("CameraTabView (\(cameraId)) - username: \(username)", feature: .camera)
        DebugLogger.log("CameraTabView (\(cameraId)) - isConfigured: \(isConfigured)", feature: .camera)
    }

    static func printBuildURLAttempt(cameraId: String, url: URL?, urlString: String, username: String, isConfigured: Bool) {
        DebugLogger.log("CameraViewModel (\(cameraId)) - buildURLWithCredentials: \(url?.absoluteString ?? "nil")", feature: .camera)
        DebugLogger.log("CameraViewModel (\(cameraId)) - config.urlString: '\(urlString)'", feature: .camera)
        DebugLogger.log("CameraViewModel (\(cameraId)) - config.username: '\(username)'", feature: .camera)
        DebugLogger.log("CameraViewModel (\(cameraId)) - isConfigured: \(isConfigured)", feature: .camera)
    }

    static func printConfigurationSaved(cameraId: String, urlString: String, username: String) {
        DebugLogger.success("Configuration saved for \(cameraId): URL=\(urlString), Username=\(username)", feature: .camera)
    }

    static func printConfigurationSaveError(cameraId: String, error: Error) {
        DebugLogger.error("Failed to save configuration for \(cameraId): \(error.localizedDescription)", feature: .camera)
    }

    static func printConfigurationCleared(cameraId: String) {
        DebugLogger.log("Configuration cleared for \(cameraId)", feature: .camera)
    }

    static func printWebViewLoading(cameraId: String, isLoading: Bool) {
        if isLoading {
            DebugLogger.log("WebView (\(cameraId)) - Started loading", feature: .camera)
        } else {
            DebugLogger.success("WebView (\(cameraId)) - Finished loading", feature: .camera)
        }
    }

    static func printWebViewError(cameraId: String, error: Error) {
        DebugLogger.error("WebView (\(cameraId)) - Load error: \(error.localizedDescription)", feature: .camera)
    }

    static func printRefresh(cameraId: String) {
        DebugLogger.log("Camera (\(cameraId)) - Refreshing web view", feature: .camera)
    }
}
