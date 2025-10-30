import SwiftUI
import Combine

// MARK: - Alarm State Model

public enum AlarmState: String, Codable, CaseIterable {
    case disarmed = "Disarmed"
    case armedAway = "Armed Away"
    case armedStay = "Armed Stay"
    case armedNightStay = "Armed Night-Stay"
    case unknown = "Unknown"
    
    public var backgroundColor: Color {
        switch self {
        case .disarmed:
            return Color.green.opacity(DesignSystem.Opacity.stateBackground)
        case .armedAway:
            return Color.red.opacity(DesignSystem.Opacity.stateBackground)
        case .armedStay:
            return Color.orange.opacity(DesignSystem.Opacity.stateBackground)
        case .armedNightStay:
            return Color.purple.opacity(DesignSystem.Opacity.stateBackground)
        case .unknown:
            return Color.gray.opacity(DesignSystem.Opacity.stateBackground)
        }
    }
    
    public var iconName: String {
        switch self {
        case .disarmed:
            return "lock.open.fill"
        case .armedAway:
            return "lock.shield.fill"
        case .armedStay:
            return "house.fill"
        case .armedNightStay:
            return "moon.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
    
    public var displayColor: Color {
        switch self {
        case .disarmed:
            return .green
        case .armedAway:
            return .red
        case .armedStay:
            return .orange
        case .armedNightStay:
            return .purple
        case .unknown:
            return .gray
        }
    }
}

// MARK: - Lockout Event Types

/// Represents different types of lockout events that can occur in the system
public enum LockoutEvent {
    case lockoutsReset
    case lockoutStateChanged
    case lockoutCleared
    case lockoutExpired
}

// MARK: - Lockout Event Publisher

/// A centralized publisher for lockout events using Combine
@MainActor
public class LockoutEventPublisher: ObservableObject {
    public static let shared = LockoutEventPublisher()
    
    private let subject = PassthroughSubject<LockoutEvent, Never>()
    
    private init() {}
    
    /// Publishes a lockout event to all subscribers
    public func publish(_ event: LockoutEvent) {
        subject.send(event)
        DebugLogger.log("Published lockout event: \(event)", feature: .alarm)
    }
    
    /// Returns a publisher for subscribing to lockout events
    public var publisher: AnyPublisher<LockoutEvent, Never> {
        subject.eraseToAnyPublisher()
    }
    
    /// Convenience method to publish a lockouts reset event
    public func publishLockoutsReset() {
        publish(.lockoutsReset)
    }
    
    /// Convenience method to publish a lockout state change event
    public func publishLockoutStateChanged() {
        publish(.lockoutStateChanged)
    }
    
    /// Convenience method to publish a lockout cleared event
    public func publishLockoutCleared() {
        publish(.lockoutCleared)
    }
    
    /// Convenience method to publish a lockout expired event
    public func publishLockoutExpired() {
        publish(.lockoutExpired)
    }
}
