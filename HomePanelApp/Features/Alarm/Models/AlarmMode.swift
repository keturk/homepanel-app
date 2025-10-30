import Foundation
import SwiftUI

// MARK: - Alarm Mode Model

/// Enumeration representing the different alarm system modes available in the application.
/// Each mode corresponds to a specific security state and has associated UI elements and behaviors.
public enum AlarmMode: String, CaseIterable {
    case away = "Away"
    case stay = "Stay"
    case nightStay = "Night-Stay"
    case disarm = "Disarm"
    
    /// The scene name used by the Vera Hub system for this alarm mode.
    /// - Returns: A string containing the scene name that matches the Vera Hub configuration
    public var sceneName: String {
        // Scene names that match the Vera Hub scene names
        switch self {
        case .away: return "Set Away Mode"
        case .disarm: return "Set Disarm Mode"
        case .nightStay: return "Set Night-Stay Mode"
        case .stay: return "Set Stay Mode"
        }
    }
    
    /// The expected alarm state that corresponds to this mode.
    /// - Returns: An AlarmState value representing the security state for this mode
    public var expectedState: AlarmState {
        switch self {
        case .away: return .armedAway
        case .stay: return .armedStay
        case .nightStay: return .armedNightStay
        case .disarm: return .disarmed
        }
    }
    
    /// The SF Symbol name for the icon representing this alarm mode.
    /// - Returns: A string containing the SF Symbol name for UI display
    public var iconName: String {
        switch self {
        case .away: return "airplane"
        case .stay: return "house"
        case .nightStay: return "moon.stars"
        case .disarm: return "lock.open"
        }
    }
    
    /// The color used for UI elements representing this alarm mode.
    /// - Returns: A SwiftUI Color value for consistent visual representation
    public var buttonColor: Color {
        switch self {
        case .away: return .red
        case .stay: return .orange
        case .nightStay: return .purple
        case .disarm: return .green
        }
    }
}
