import Foundation
import Combine

// MARK: - Settings Error

enum SettingsError: Error, LocalizedError {
    case validationFailed(String)
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return message
        case .saveFailed(let message):
            return message
        }
    }
}

// MARK: - Settings Context for unified save/cancel strategy

@MainActor
class SettingsContext: ObservableObject {
    @Published var hasUnsavedChanges = false
    @Published var isSaving = false
    @Published var lastError: Error?
    @Published var toastMessage: ToastMessage?
    
    private var originalValues: [String: Any] = [:]
    private var currentValues: [String: Any] = [:]
    private var saveHandler: (() async throws -> Void)?
    private var onSaveComplete: (() -> Void)?
    
    // MARK: - Change Tracking
    
    func registerValue<T>(_ key: String, value: T) {
        currentValues[key] = value
        updateChangeStatus()
    }
    
    func setOriginalValue<T>(_ key: String, value: T) {
        originalValues[key] = value
        currentValues[key] = value
        updateChangeStatus()
    }
    
    private func updateChangeStatus() {
        hasUnsavedChanges = !areValuesEqual()
    }
    
    private func areValuesEqual() -> Bool {
        for (key, currentValue) in currentValues {
            guard let originalValue = originalValues[key] else {
                return false
            }
            
            // Simple comparison - in a real app you'd want more sophisticated comparison
            if String(describing: currentValue) != String(describing: originalValue) {
                return false
            }
        }
        return true
    }
    
    // MARK: - Save/Cancel Actions
    
    func setSaveHandler(_ handler: @escaping () async throws -> Void) {
        saveHandler = handler
    }
    
    func setSaveCompleteCallback(_ callback: @escaping () -> Void) {
        onSaveComplete = callback
    }
    
    func save() async {
        isSaving = true
        lastError = nil
        clearToast()
        defer { isSaving = false }
        
        do {
            if let handler = saveHandler {
                try await handler()
            }
            // Update original values after successful save
            originalValues = currentValues
            hasUnsavedChanges = false
            
            // Show success toast and haptic feedback
            showToast("Settings saved successfully", type: .success)
            HapticFeedback.settingsSuccess()
            
            // Call save complete callback
            onSaveComplete?()
        } catch {
            lastError = error
            // Keep hasUnsavedChanges = true on error
            
            // Show error toast and haptic feedback
            showToast("Failed to save settings", message: error.localizedDescription, type: .error)
            HapticFeedback.settingsError()
        }
    }
    
    func cancel() {
        // Reset current values to original values
        currentValues = originalValues
        hasUnsavedChanges = false
    }
    
    func discard() {
        // Same as cancel - reset to original values
        currentValues = originalValues
        hasUnsavedChanges = false
    }
    
    func reset() {
        originalValues.removeAll()
        currentValues.removeAll()
        hasUnsavedChanges = false
        saveHandler = nil
        lastError = nil
        clearToast()
    }
    
    // MARK: - Toast Management
    
    func showToast(_ title: String, message: String? = nil, type: ToastType) {
        toastMessage = ToastMessage(title: title, message: message, type: type)
    }
    
    func clearToast() {
        toastMessage = nil
    }
}

// MARK: - Settings Scope

enum SettingsScope {
    case global      // Applies to all iPads under same account
    case device      // iPad-specific
    
    var icon: String {
        switch self {
        case .global: return "globe"
        case .device: return "ipad"
        }
    }
    
    var description: String {
        switch self {
        case .global: return "Global (all iPads)"
        case .device: return "This iPad only"
        }
    }
}

// MARK: - Settings Item

struct SettingsItem {
    let key: String
    let title: String
    let scope: SettingsScope
    let value: Any
}
