import UIKit

// MARK: - Haptic Feedback Utility

/// Centralized haptic feedback utility for consistent user experience
@MainActor
class HapticFeedback {
    
    // MARK: - Semantic Feedback Methods
    
    /// Success haptic feedback for positive actions
    static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Error haptic feedback for failed actions
    static func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    /// Warning haptic feedback for cautionary actions
    static func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    // MARK: - Impact Feedback Methods
    
    /// Light impact feedback for subtle interactions
    static func light() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Medium impact feedback for standard interactions
    static func medium() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Heavy impact feedback for strong interactions
    static func heavy() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Selection Feedback
    
    /// Selection feedback for picker and segmented control changes
    static func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Contextual Feedback Methods
    
    /// Feedback for button presses
    static func buttonPress() {
        light()
    }
    
    /// Feedback for successful form submissions
    static func formSuccess() {
        success()
    }
    
    /// Feedback for form validation errors
    static func formError() {
        error()
    }
    
    /// Feedback for destructive actions
    static func destructive() {
        warning()
    }
    
    /// Feedback for navigation actions
    static func navigation() {
        light()
    }
    
    /// Feedback for toggle switches
    static func toggle() {
        light()
    }
    
    /// Feedback for slider adjustments
    static func slider() {
        light()
    }
    
    /// Feedback for keyboard interactions
    static func keyboard() {
        light()
    }
    
    /// Feedback for PIN entry
    static func pinEntry() {
        light()
    }
    
    /// Feedback for successful PIN entry
    static func pinSuccess() {
        success()
    }
    
    /// Feedback for failed PIN entry
    static func pinError() {
        error()
    }
    
    /// Feedback for camera operations
    static func camera() {
        medium()
    }
    
    /// Feedback for hub operations
    static func hub() {
        medium()
    }
    
    /// Feedback for settings changes
    static func settings() {
        light()
    }
    
    /// Feedback for successful settings save
    static func settingsSuccess() {
        success()
    }
    
    /// Feedback for settings save errors
    static func settingsError() {
        error()
    }
}
