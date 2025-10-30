import SwiftUI

// MARK: - PIN Entry View

struct PINEntryView: View {
    let mode: String
    let onSubmit: (String) -> Void
    let onCancel: () -> Void
    let onWrongPIN: (() -> Void)?
    let triggerWrongPIN: Bool
    let pinService: any PINManagementServiceProtocol
    let isLockedOut: Bool
    let remainingLockoutTime: String
    let onShowError: ((String) -> Void)?
    @Binding var pinErrorMessage: String?
    
    @State private var pin = ""
    @State private var shakeOffset: CGFloat = 0
    @State private var showErrorPopup = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Constants
    
    /// Maximum length for PIN input
    private let maxPINLength = 6
    
    /// Animation duration for smooth UI transitions
    private static let animationDuration: Double = 0.1
    
    /// Delay before auto-submitting PIN when complete
    private static let autoSubmitDelay: Double = 0.2
    
    /// Duration for error popup auto-dismiss
    private static let errorPopupDismissDelay: Double = 3.0
    
    /// Delay for shake animation completion
    private static let shakeAnimationDelay: Double = 0.3
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                PINEntryHeaderView(mode: mode)
                
                // PIN Display
                PINDisplayView(
                    pin: pin,
                    maxPINLength: maxPINLength,
                    shakeOffset: shakeOffset
                )
                
                // Lockout Status
                LockoutStatusView(
                    isLockedOut: isLockedOut,
                    remainingLockoutTime: remainingLockoutTime
                )
                
                // Keypad
                UnifiedKeypadView.pinKeypad(
                    onDigit: addDigit,
                    onDelete: deleteDigit,
                    onSubmit: submitPIN,
                    isLockedOut: isLockedOut
                )
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: triggerWrongPIN) { _, newValue in
            if newValue {
                handleWrongPINTrigger()
            }
        }
        .onChange(of: pinErrorMessage) { _, newValue in
            if let errorMessage = newValue {
                showErrorPopup(message: errorMessage)
                // Clear the PIN input when there's an error
                pin = ""
                // Clear the error message after showing popup
                Task {
                    try await Task.sleep(nanoseconds: UInt64(Self.animationDuration * 1_000_000_000))
                    await MainActor.run {
                        self.pinErrorMessage = nil
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .overlay(
            PINErrorPopup(
                isPresented: $showErrorPopup,
                errorMessage: errorMessage,
                onDismiss: {
                    showErrorPopup = false
                    errorMessage = ""
                }
            )
        )
    }
    
    // MARK: - View Components
    // Note: View components have been extracted to separate files:
    // - PINEntryHeaderView
    // - PINDisplayView  
    // - LockoutStatusView
    // - UnifiedKeypadView
    // - PINErrorPopup
    
    // MARK: - Actions
    
    private func addDigit(_ digit: String) {
        guard pin.count < maxPINLength else { return }
        
        withAnimation(.easeInOut(duration: Self.animationDuration)) {
            pin += digit
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Auto-submit when PIN is complete (but not if locked out)
        if pin.count == maxPINLength && !isLockedOut {
            Task {
                try await Task.sleep(nanoseconds: UInt64(Self.autoSubmitDelay * 1_000_000_000))
                await MainActor.run {
                    submitPIN()
                }
            }
        }
    }
    
    private func deleteDigit() {
        guard !pin.isEmpty else { return }
        
        _ = withAnimation(.easeInOut(duration: Self.animationDuration)) {
            pin.removeLast()
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func submitPIN() {
        guard pin.count == maxPINLength else { return }
        
        // Haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        onSubmit(pin)
        // Don't dismiss here - let the parent handle it based on success/failure
    }
    
    func handleWrongPINTrigger() {
        DebugLogger.log("handleWrongPINTrigger called", feature: .alarm)
        shakePIN()
    }
    
    
    func showErrorPopup(message: String) {
        errorMessage = message
        showErrorPopup = true
        
        // Auto-dismiss after configured delay
        Task {
            try await Task.sleep(nanoseconds: UInt64(Self.errorPopupDismissDelay * 1_000_000_000))
            await MainActor.run {
                showErrorPopup = false
                errorMessage = ""
            }
        }
    }
    
    
    private func shakePIN() {
        withAnimation(.easeInOut(duration: Self.animationDuration).repeatCount(3, autoreverses: true)) {
            shakeOffset = 10
        }
        
        Task {
            try await Task.sleep(nanoseconds: UInt64(Self.shakeAnimationDelay * 1_000_000_000))
            await MainActor.run {
                withAnimation(.easeInOut(duration: Self.animationDuration)) {
                    shakeOffset = 0
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var pinErrorMessage: String? = nil
    
    return PINEntryView(
        mode: "Away",
        onSubmit: { pin in
            DebugLogger.log("PIN submitted", feature: .alarm)
        },
        onCancel: {
            DebugLogger.log("PIN entry cancelled", feature: .alarm)
        },
        onWrongPIN: {
            DebugLogger.log("Wrong PIN entered", feature: .alarm)
        },
        triggerWrongPIN: false,
        pinService: DependencyContainer.shared.getPINManagementService() as! PINManagementService,
        isLockedOut: false,
        remainingLockoutTime: "0 minutes",
        onShowError: { message in
            DebugLogger.error("Error: \(message)", feature: .alarm)
        },
        pinErrorMessage: $pinErrorMessage
    )
}
