import SwiftUI

// MARK: - Add PIN View

struct AddPINView: View {
    let onAdd: (String, String) -> Void
    let onCancel: () -> Void
    let isUsernameAvailable: (String) -> Bool
    
    @State private var currentPIN = ""
    @State private var confirmPIN = ""
    @State private var pinName = ""
    @State private var step = 1 // 1: Enter Name & PIN, 2: Confirm PIN
    @State private var errorMessage: String? = nil
    @State private var isUsernameValid = true
    @State private var usernameValidationMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 30) {
            if step == 1 {
                // Name Entry using standardized template
                StandardPINEntryView(
                    icon: "plus.circle.fill",
                    iconColor: .green,
                    title: "Add New PIN",
                    subtitle: "Enter a name and 6-digit PIN",
                    pin: $currentPIN,
                    errorMessage: $errorMessage,
                    onDigit: { digit in
                        handleDigitEntry(digit)
                    },
                    onDelete: {
                        if !currentPIN.isEmpty {
                            currentPIN.removeLast()
                        }
                    },
                    onSubmit: {
                        handlePINComplete()
                    },
                    onCancel: onCancel,
                    isLockedOut: !isUsernameValid,
                    lockoutMessage: isUsernameValid ? nil : "Please enter a valid username first",
                    customContent: {
                        AnyView(
                            VStack(spacing: 8) {
                                TextField("PIN Name (e.g., John, Guest, etc.)", text: $pinName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal, 40)
                                    .onChange(of: pinName) { _, newValue in
                                        validateUsername(newValue)
                                    }
                                    .onSubmit {
                                        // Focus will move to PIN entry automatically
                                    }
                                    .keyboardHandling()
                                    .accessibilityLabel("PIN Name")
                                    .accessibilityHint("Enter a name for this PIN")

                                // Username validation feedback
                                if let validationMessage = usernameValidationMessage {
                                    Text(validationMessage)
                                        .font(.caption)
                                        .foregroundColor(isUsernameValid ? .green : .red)
                                        .padding(.horizontal, 40)
                                }
                            }
                        )
                    }
                )
            } else {
                // Confirm PIN using standardized layout
                StandardPINEntryView(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    title: "Confirm PIN",
                    subtitle: "Re-enter the PIN to confirm",
                    pin: $confirmPIN,
                    errorMessage: $errorMessage,
                    onDigit: { digit in
                        handleDigitEntry(digit)
                    },
                    onDelete: {
                        if !confirmPIN.isEmpty {
                            confirmPIN.removeLast()
                        }
                    },
                    onSubmit: {
                        handlePINComplete()
                    },
                    onCancel: onCancel
                )
            }

            Spacer()
        }
        .padding()
    }
    
    // MARK: - Private Methods
    
    private func handleDigitEntry(_ digit: String) {
        if step == 1 {
            // Only allow PIN entry if username is valid
            guard isUsernameValid else { 
                HapticFeedback.formError()
                return 
            }
            
            if currentPIN.count < 6 {
                currentPIN += digit
                HapticFeedback.pinEntry()
                if currentPIN.count == 6 {
                    // Validate name and PIN before proceeding
                    let trimmedName = pinName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedName.isEmpty {
                        errorMessage = "Please enter a name for this PIN."
                        currentPIN = ""
                        HapticFeedback.formError()
                        return
                    }
                    
                    // Double-check username validity before proceeding
                    if !isUsernameAvailable(trimmedName) {
                        errorMessage = "Username already exists. Please choose a different name."
                        currentPIN = ""
                        HapticFeedback.formError()
                        return
                    }
                    
                    Task {
                        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                        await MainActor.run {
                            step = 2
                            errorMessage = nil // Clear any previous error
                        }
                    }
                }
            }
        } else if step == 2 {
            if confirmPIN.count < 6 {
                confirmPIN += digit
                HapticFeedback.pinEntry()
                if confirmPIN.count == 6 {
                    Task {
                        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                        await MainActor.run {
                            handlePINComplete()
                        }
                    }
                }
            }
        }
    }
    
    private func handlePINComplete() {
        if step == 1 {
            // This should not happen as we handle it in handleDigitEntry
            // But keeping for safety
            let trimmedName = pinName.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedName.isEmpty {
                errorMessage = "Please enter a name for this PIN."
                return
            }
            
            
            if currentPIN.count == 6 {
                step = 2
                errorMessage = nil
            }
        } else if step == 2 {
            if confirmPIN.count == 6 {
                if currentPIN == confirmPIN {
                    let trimmedName = pinName.trimmingCharacters(in: .whitespacesAndNewlines)
                    HapticFeedback.pinSuccess()
                    onAdd(currentPIN, trimmedName)
                } else {
                    // PINs don't match - clear confirmation PIN but stay on step 2
                    confirmPIN = ""
                    errorMessage = "PINs don't match. Please re-enter the confirmation PIN."
                    HapticFeedback.pinError()
                }
            }
        }
    }
    
    private func validateUsername(_ username: String) {
        let trimmedName = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            isUsernameValid = true
            usernameValidationMessage = nil
        } else if isUsernameAvailable(trimmedName) {
            isUsernameValid = true
            usernameValidationMessage = "✓ Username available"
        } else {
            isUsernameValid = false
            usernameValidationMessage = "✗ Username already exists"
        }
    }
}
