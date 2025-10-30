import SwiftUI

// MARK: - Master PIN Entry View

struct MasterPINEntryView: View {
    let onVerify: (String) -> Void
    let onCancel: () -> Void
    let pinService: any PINManagementServiceProtocol
    
    @State private var pin = ""
    @State private var errorMessage: String?
    @State private var showErrorPopup = false
    @State private var popupMessage = ""
    
    var body: some View {
        NavigationView {
            StandardPINEntryView(
                icon: "lock.shield.fill",
                iconColor: .blue,
                title: "Enter Master PIN",
                subtitle: "6-digit PIN required",
                pin: $pin,
                errorMessage: $errorMessage,
                onDigit: { digit in
                    if pin.count < 6 {
                        pin += digit
                        errorMessage = nil // Clear error when user starts typing
                        if pin.count == 6 {
                            Task {
                                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                                await MainActor.run {
                                    handlePINVerification(pin)
                                }
                            }
                        }
                    }
                },
                onDelete: {
                    if !pin.isEmpty {
                        pin.removeLast()
                    }
                },
                onSubmit: {
                    if pin.count == 6 {
                        handlePINVerification(pin)
                    }
                },
                onCancel: onCancel,
                showCancelButton: false
            )
        }
        .overlay(
            PINErrorPopup(
                isPresented: $showErrorPopup,
                errorMessage: popupMessage,
                onDismiss: {
                    showErrorPopup = false
                    popupMessage = ""
                }
            )
        )
    }
    
    private func handlePINVerification(_ enteredPIN: String) {
        // Check if locked out first
        if pinService.isLockedOut() {
            let lockoutTime = pinService.getRemainingLockoutTime()
            showErrorPopup(message: "🔒 LOCKED OUT\nToo many failed attempts.\nTry again in \(lockoutTime)")
            pin = ""
            return
        }
        
        // Check PIN format
        guard enteredPIN.count == 6 && enteredPIN.allSatisfy({ $0.isNumber }) else {
            showErrorPopup(message: "❌ Invalid format\nPIN must be exactly 6 digits")
            pin = ""
            return
        }
        
        // Verify PIN
        if pinService.verifyMasterPIN(enteredPIN) {
            // Success - record successful attempt and proceed
            pinService.recordSuccessfulAttempt()
            onVerify(enteredPIN)
        } else {
            // Invalid PIN - record failed attempt
            pinService.recordFailedAttempt()
            
            // Show appropriate error message based on attempt count
            if pinService.isLockedOut() {
                let lockoutTime = pinService.getRemainingLockoutTime()
                showErrorPopup(message: "🔒 LOCKED OUT\nToo many failed attempts.\nTry again in \(lockoutTime)")
            } else {
                let attemptsInCurrentRound = pinService.getConsecutiveFailures() % 7
                let attemptsRemaining = 7 - attemptsInCurrentRound
                if attemptsRemaining > 1 {
                    showErrorPopup(message: "Invalid PIN. \(attemptsRemaining) attempts remaining.")
                } else if attemptsRemaining == 1 {
                    showErrorPopup(message: "Invalid PIN. 1 attempt remaining before lockout.")
                } else {
                    showErrorPopup(message: "Invalid PIN. Please try again.")
                }
            }
            pin = "" // Clear the PIN for retry
        }
    }
    
    private func showErrorPopup(message: String) {
        popupMessage = message
        showErrorPopup = true
        
        // Auto-dismiss after 3 seconds
        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3.0 seconds
            await MainActor.run {
                showErrorPopup = false
                popupMessage = ""
            }
        }
    }
}
