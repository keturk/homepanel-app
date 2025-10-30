import SwiftUI

// MARK: - Standard PIN Entry View

struct StandardPINEntryView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var pin: String
    @Binding var errorMessage: String?
    let onDigit: (String) -> Void
    let onDelete: () -> Void
    let onSubmit: () -> Void
    let onCancel: () -> Void
    let isLockedOut: Bool
    let lockoutMessage: String?
    let customContent: (() -> AnyView)?
    let showCancelButton: Bool
    
    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        pin: Binding<String>,
        errorMessage: Binding<String?>,
        onDigit: @escaping (String) -> Void,
        onDelete: @escaping () -> Void,
        onSubmit: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        isLockedOut: Bool = false,
        lockoutMessage: String? = nil,
        customContent: (() -> AnyView)? = nil,
        showCancelButton: Bool = true
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self._pin = pin
        self._errorMessage = errorMessage
        self.onDigit = onDigit
        self.onDelete = onDelete
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self.isLockedOut = isLockedOut
        self.lockoutMessage = lockoutMessage
        self.customContent = customContent
        self.showCancelButton = showCancelButton
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.warningSpacing) {
            // Header - use existing component
            PINEntryHeaderView(
                icon: icon,
                iconColor: iconColor,
                title: title,
                subtitle: subtitle
            )
            
            // Custom content (for name fields, etc.)
            if let customContent = customContent {
                customContent()
            }
            
            // Lockout status - use existing component
            LockoutStatusView(
                isLockedOut: isLockedOut,
                lockoutMessage: lockoutMessage ?? "Try again in: 0 minutes"
            )
            
            if !isLockedOut {
                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // PIN Display - use existing component
                PINDisplayView(
                    pin: pin,
                    maxPINLength: 6,
                    shakeOffset: 0,
                    fillColor: iconColor
                )
                
                // Keypad
                UnifiedKeypadView.simpleKeypad(
                    onDigit: onDigit,
                    onDelete: onDelete,
                    onSubmit: onSubmit
                )
            }
            
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showCancelButton {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Tap to cancel PIN entry and return to previous screen")
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
    }
}
