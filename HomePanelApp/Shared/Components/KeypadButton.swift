import SwiftUI

// MARK: - Keypad Button Component

struct KeypadButton: View {
    let title: String
    var icon: String?
    var letters: String?
    let action: () -> Void
    
    init(title: String, icon: String? = nil, letters: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.letters = letters
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action()
        }) {
            VStack(spacing: DesignSystem.Spacing.nano) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .fontWeight(.medium)
                } else {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let letters = letters {
                        Text(letters)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.keypad())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Computed Properties
    
    private var accessibilityLabel: String {
        if let icon = icon {
            switch icon {
            case "delete.left":
                return "Delete"
            case "checkmark":
                return "Submit"
            default:
                return "Button"
            }
        } else {
            return "Number \(title)"
        }
    }
    
    private var accessibilityHint: String {
        if let icon = icon {
            switch icon {
            case "delete.left":
                return "Tap to delete the last entered digit"
            case "checkmark":
                return "Tap to submit the PIN"
            default:
                return "Tap to activate"
            }
        } else {
            return "Tap to enter number \(title)"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
        // Phone-style keypad preview
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: DesignSystem.Grid.columns), spacing: DesignSystem.Grid.spacing) {
            // Row 1: 1, 2, 3
            KeypadButton(title: "1", letters: "") { }
            KeypadButton(title: "2", letters: "ABC") { }
            KeypadButton(title: "3", letters: "DEF") { }
            
            // Row 2: 4, 5, 6
            KeypadButton(title: "4", letters: "GHI") { }
            KeypadButton(title: "5", letters: "JKL") { }
            KeypadButton(title: "6", letters: "MNO") { }
            
            // Row 3: 7, 8, 9
            KeypadButton(title: "7", letters: "PQRS") { }
            KeypadButton(title: "8", letters: "TUV") { }
            KeypadButton(title: "9", letters: "WXYZ") { }
            
            // Row 4: Delete, 0, Submit
            KeypadButton(title: "", icon: "delete.left") { }
            KeypadButton(title: "0", letters: "") { }
            KeypadButton(title: "", icon: "checkmark") { }
        }
    }
    .padding()
    .background(Color(.systemBackground))
}
