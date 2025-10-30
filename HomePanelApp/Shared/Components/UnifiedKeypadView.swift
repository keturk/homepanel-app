import SwiftUI

// MARK: - Unified Keypad View
// Consolidated keypad component that replaces both PINKeypadView and PhoneKeypadView

struct UnifiedKeypadView: View {
    // Core callbacks
    let onDigit: (String) -> Void
    let onDelete: () -> Void
    let onSubmit: (() -> Void)?
    
    // Optional features
    let isLockedOut: Bool
    let showLetters: Bool
    
    // Initializer with sensible defaults
    init(
        onDigit: @escaping (String) -> Void,
        onDelete: @escaping () -> Void,
        onSubmit: (() -> Void)? = nil,
        isLockedOut: Bool = false,
        showLetters: Bool = true
    ) {
        self.onDigit = onDigit
        self.onDelete = onDelete
        self.onSubmit = onSubmit
        self.isLockedOut = isLockedOut
        self.showLetters = showLetters
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
            // Keypad Grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: DesignSystem.Grid.columns), 
                spacing: DesignSystem.Grid.spacing
            ) {
                // Row 1: 1, 2, 3
                KeypadButton(title: "1", letters: showLetters ? "" : "") {
                    onDigit("1")
                }
                KeypadButton(title: "2", letters: showLetters ? "ABC" : "") {
                    onDigit("2")
                }
                KeypadButton(title: "3", letters: showLetters ? "DEF" : "") {
                    onDigit("3")
                }
                
                // Row 2: 4, 5, 6
                KeypadButton(title: "4", letters: showLetters ? "GHI" : "") {
                    onDigit("4")
                }
                KeypadButton(title: "5", letters: showLetters ? "JKL" : "") {
                    onDigit("5")
                }
                KeypadButton(title: "6", letters: showLetters ? "MNO" : "") {
                    onDigit("6")
                }
                
                // Row 3: 7, 8, 9
                KeypadButton(title: "7", letters: showLetters ? "PQRS" : "") {
                    onDigit("7")
                }
                KeypadButton(title: "8", letters: showLetters ? "TUV" : "") {
                    onDigit("8")
                }
                KeypadButton(title: "9", letters: showLetters ? "WXYZ" : "") {
                    onDigit("9")
                }
                
                // Row 4: Delete, 0, Submit
                KeypadButton(title: "", icon: "delete.left") {
                    onDelete()
                }
                KeypadButton(title: "0", letters: "") {
                    onDigit("0")
                }
                KeypadButton(title: "", icon: "checkmark") {
                    DebugLogger.log("Checkmark button pressed", feature: .common)
                    onSubmit?()
                }
            }
            .padding()
            .disabled(isLockedOut)
            .opacity(isLockedOut ? DesignSystem.Opacity.disabled : 1.0)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("PIN keypad")
            .accessibilityHint("Use the keypad to enter your 6-digit PIN")
        }
    }
}

// MARK: - Convenience Initializers

extension UnifiedKeypadView {
    /// Creates a keypad for PIN entry with lockout support
    static func pinKeypad(
        onDigit: @escaping (String) -> Void,
        onDelete: @escaping () -> Void,
        onSubmit: @escaping () -> Void,
        isLockedOut: Bool = false
    ) -> UnifiedKeypadView {
        UnifiedKeypadView(
            onDigit: onDigit,
            onDelete: onDelete,
            onSubmit: onSubmit,
            isLockedOut: isLockedOut,
            showLetters: true
        )
    }
    
    /// Creates a simple keypad without submit functionality
    static func simpleKeypad(
        onDigit: @escaping (String) -> Void,
        onDelete: @escaping () -> Void,
        onSubmit: (() -> Void)? = nil,
        showLetters: Bool = true
    ) -> UnifiedKeypadView {
        UnifiedKeypadView(
            onDigit: onDigit,
            onDelete: onDelete,
            onSubmit: onSubmit,
            isLockedOut: false,
            showLetters: showLetters
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
        // PIN Keypad with lockout support
        UnifiedKeypadView.pinKeypad(
            onDigit: { digit in
                DebugLogger.log("Digit tapped: \(digit)", feature: .common)
            },
            onDelete: {
                DebugLogger.log("Delete tapped", feature: .common)
            },
            onSubmit: {
                DebugLogger.log("Submit tapped", feature: .common)
            },
            isLockedOut: false
        )

        Divider()

        // Simple keypad without letters
        UnifiedKeypadView.simpleKeypad(
            onDigit: { digit in
                DebugLogger.log("Digit tapped: \(digit)", feature: .common)
            },
            onDelete: {
                DebugLogger.log("Delete tapped", feature: .common)
            },
            showLetters: false
        )
    }
    .padding()
    .background(Color(.systemBackground))
}
