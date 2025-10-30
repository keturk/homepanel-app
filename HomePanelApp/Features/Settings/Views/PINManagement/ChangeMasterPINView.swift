import SwiftUI

// MARK: - Change Master PIN View

struct ChangeMasterPINView: View {
    let pinService: any PINManagementServiceProtocol
    let onChange: (String, String) -> Void
    let onCancel: () -> Void
    
    @State private var currentPIN = ""
    @State private var originalPIN = "" // Store the original PIN from step 1
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var step = 1 // 1: current, 2: new, 3: confirm
    @State private var errorMessage: String? = nil
    @State private var lockoutTimer: Timer?
    
    var body: some View {
        NavigationView {
            StandardPINEntryView(
                icon: pinService.isLockedOut() ? "lock.fill" : "key.fill",
                iconColor: pinService.isLockedOut() ? .red : .orange,
                title: pinService.isLockedOut() ? "Master PIN Change Locked" : stepTitle,
                subtitle: pinService.isLockedOut() ? "" : stepDescription,
                pin: $currentPIN,
                errorMessage: $errorMessage,
                onDigit: { digit in
                    if !pinService.isLockedOut() && currentPIN.count < 6 {
                        currentPIN += digit
                        errorMessage = nil // Clear error when user starts typing
                        if currentPIN.count == 6 {
                            Task {
                                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                                await MainActor.run {
                                    handlePINComplete()
                                }
                            }
                        }
                    }
                },
                onDelete: {
                    if !pinService.isLockedOut() && !currentPIN.isEmpty {
                        currentPIN.removeLast()
                    }
                },
                onSubmit: {
                    if !pinService.isLockedOut() {
                        DebugLogger.log("onSubmit callback called, currentPIN.count = \(currentPIN.count)", feature: .common)
                        if currentPIN.count == 6 {
                            DebugLogger.log("Calling handlePINComplete()", feature: .common)
                            handlePINComplete()
                        } else {
                            DebugLogger.log("PIN count is not 6, not calling handlePINComplete()", feature: .common)
                        }
                    }
                },
                onCancel: onCancel,
                isLockedOut: pinService.isLockedOut(),
                lockoutMessage: pinService.isLockedOut() ? "Try again in: \(pinService.getRemainingLockoutTime())" : nil
            )
            .onAppear {
                startLockoutTimer()
            }
            .onDisappear {
                stopLockoutTimer()
            }
        }
    }
    
    private var stepTitle: String {
        switch step {
        case 1: return "Enter Current PIN"
        case 2: return "Enter New PIN"
        case 3: return "Confirm New PIN"
        default: return ""
        }
    }
    
    private var stepDescription: String {
        switch step {
        case 1: return "Enter your current master PIN"
        case 2: return "Enter a new 6-digit master PIN"
        case 3: return "Confirm your new master PIN"
        default: return ""
        }
    }
    
    private var pinColor: Color {
        switch step {
        case 1: return .blue
        case 2: return .green
        case 3: return .orange
        default: return .blue
        }
    }
    
    private func handlePINComplete() {
        switch step {
        case 1:
            // Check if already locked out
            if pinService.isLockedOut() {
                errorMessage = "Master PIN change is locked. Try again in \(pinService.getRemainingLockoutTime())"
                return
            }
            
            // Verify current PIN before proceeding
            if pinService.verifyMasterPIN(currentPIN) {
                // Success - record successful attempt and proceed
                pinService.recordSuccessfulAttempt()
                originalPIN = currentPIN
                step = 2
                currentPIN = ""
                errorMessage = nil // Clear any previous error
            } else {
                // Invalid PIN - record failed attempt
                pinService.recordFailedAttempt()
                DebugLogger.log("Invalid current PIN entered", feature: .common)
                currentPIN = ""
                
                if pinService.isLockedOut() {
                    errorMessage = "Too many failed attempts. Try again in \(pinService.getRemainingLockoutTime())"
                } else {
                    errorMessage = "Incorrect Master PIN. Please try again."
                }
            }
        case 2:
            
            // Check if new PIN is the same as current Master PIN
            if currentPIN == originalPIN {
                errorMessage = "New PIN must be different from current Master PIN. Please choose a different PIN."
                currentPIN = ""
                return
            }
            
            // Store new PIN and move to step 3
            newPIN = currentPIN
            step = 3
            currentPIN = ""
        case 3:
            // Confirm new PIN - compare currentPIN (confirmation) with newPIN
            DebugLogger.log("PIN confirmation - checking PINs match", feature: .common)
            if newPIN == currentPIN {
                DebugLogger.log("PINs match, calling onChange", feature: .common)
                // Call onChange with original PIN and new PIN
                onChange(originalPIN, newPIN)
            } else {
                DebugLogger.log("PINs don't match, clearing confirmation PIN but staying on step 3", feature: .common)
                // PINs don't match - clear confirmation PIN but stay on step 3
                currentPIN = ""
                errorMessage = "PINs don't match. Please re-enter the confirmation PIN."
            }
        default:
            break
        }
    }
    
    private func startLockoutTimer() {
        lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Force UI update when lockout status changes
            Task { @MainActor in
                if !pinService.isLockedOut() {
                    stopLockoutTimer()
                }
            }
        }
    }
    
    private func stopLockoutTimer() {
        lockoutTimer?.invalidate()
        lockoutTimer = nil
    }
}
