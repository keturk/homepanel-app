import Foundation

// MARK: - Debug Logger Feature Flags

/// Centralized debug logging system with feature-based toggles
/// This allows you to enable/disable debug logs for specific features
enum DebugLogger {

    // MARK: - Feature Type

    enum Feature {
        case alarm
        case camera
        case common
        case settings
        case automation
        case hubService

        /// Check if logging is enabled for this feature
        var isEnabled: Bool {
            switch self {
            case .alarm: return FeatureFlags.alarm
            case .camera: return FeatureFlags.camera
            case .common: return FeatureFlags.common
            case .settings: return FeatureFlags.settings
            case .automation: return FeatureFlags.automation
            case .hubService: return FeatureFlags.hubService
            }
        }
    }

    // MARK: - Feature Flags Configuration

    /// Enable/disable debug logs for each feature
    /// Set to `true` to see debug statements, `false` to hide them
    enum FeatureFlags {
        static let alarm: Bool = false        // Alarm feature debug logs
        static let camera: Bool = false      // Camera feature debug logs (Iris One & Two)
        static let common: Bool = false       // Common/shared functionality (traffic, location, master PIN, etc.)
        static let settings: Bool = false     // Settings feature debug logs (destination management)
        static let automation: Bool = false  // Automation feature debug logs
        static let hubService: Bool = false  // Hub service debug logs (polling, state changes, etc.)
    }

    // MARK: - Logging Methods

    /// Generate timestamp for log messages
    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }

    /// Log a debug message for a specific feature
    /// - Parameters:
    ///   - message: The message to log
    ///   - feature: Which feature this log belongs to
    ///   - file: Source file (automatically captured)
    ///   - line: Source line (automatically captured)
    static func log(_ message: String,
                   feature: Feature,
                   file: String = #file,
                   line: Int = #line) {
        #if DEBUG
        guard feature.isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("🔍 [\(timestamp())] [\(fileName):\(line)] \(message)")
        #endif
    }

    /// Log a success message for a specific feature
    static func success(_ message: String,
                       feature: Feature,
                       file: String = #file,
                       line: Int = #line) {
        #if DEBUG
        guard feature.isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("✅ [\(timestamp())] [\(fileName):\(line)] \(message)")
        #endif
    }

    /// Log an error message for a specific feature
    static func error(_ message: String,
                     feature: Feature,
                     file: String = #file,
                     line: Int = #line) {
        #if DEBUG
        guard feature.isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("❌ [\(timestamp())] [\(fileName):\(line)] \(message)")
        #endif
    }

    /// Log a warning message for a specific feature
    static func warning(_ message: String,
                       feature: Feature,
                       file: String = #file,
                       line: Int = #line) {
        #if DEBUG
        guard feature.isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("⚠️ [\(timestamp())] [\(fileName):\(line)] \(message)")
        #endif
    }

    /// Log a lockout message for a specific feature
    static func lockout(_ message: String,
                       feature: Feature,
                       file: String = #file,
                       line: Int = #line) {
        #if DEBUG
        guard feature.isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("🔒 [\(timestamp())] [\(fileName):\(line)] \(message)")
        #endif
    }

    /// Log a timer/countdown message for a specific feature
    static func timer(_ message: String,
                     feature: Feature,
                     file: String = #file,
                     line: Int = #line) {
        #if DEBUG
        guard feature.isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("⏰ [\(timestamp())] [\(fileName):\(line)] \(message)")
        #endif
    }

    /// Log a state change message for a specific feature
    static func stateChange(_ message: String,
                           feature: Feature,
                           file: String = #file,
                           line: Int = #line) {
        #if DEBUG
        guard feature.isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("🔄 [\(timestamp())] [\(fileName):\(line)] \(message)")
        #endif
    }
}

// MARK: - Usage Examples
/*

 // To use the debug logger in your code:

 // Basic log
 DebugLogger.log("Camera view initialized", feature: .camera)

 // Success log
 DebugLogger.success("PIN verification successful", feature: .alarm)

 // Error log
 DebugLogger.error("Failed to load camera feed", feature: .camera)

 // Warning log
 DebugLogger.warning("Scene map is empty", feature: .alarm)

 // Common functionality (like master PIN entry)
 DebugLogger.log("Master PIN entered", feature: .common)

 // To disable debug logs for a specific feature:
 // Go to the FeatureFlags enum above and set the feature to false
 // For example: static let camera: Bool = false

 */
