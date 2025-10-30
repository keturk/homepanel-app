import SwiftUI

// MARK: - Mode Button Component

struct ModeButton: View {
    let title: String
    let icon: String
    let color: Color
    let isDisabled: Bool
    let action: () -> Void
    
    init(title: String, icon: String, color: Color, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            action()
        }) {
            VStack(spacing: DesignSystem.Spacing.buttonSpacing) {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.FontSize.iconSize, weight: .medium))
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
        .buttonStyle(.mode(color: color, isDisabled: isDisabled))
        .accessibilityLabel("\(title) mode")
        .accessibilityHint("Tap to set alarm to \(title) mode")
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(isDisabled ? [] : [.isButton])
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Computed Properties
}

// MARK: - Preview

#Preview {
    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
        HStack(spacing: DesignSystem.Spacing.statusSpacing) {
            ModeButton(title: "Away", icon: "airplane", color: .red) {
                DebugLogger.log("Away tapped", feature: .alarm)
            }

            ModeButton(title: "Stay", icon: "house", color: .orange) {
                DebugLogger.log("Stay tapped", feature: .alarm)
            }
        }

        HStack(spacing: DesignSystem.Spacing.statusSpacing) {
            ModeButton(title: "Night-Stay", icon: "moon.stars", color: .purple) {
                DebugLogger.log("Night-Stay tapped", feature: .alarm)
            }

            ModeButton(title: "Disarm", icon: "lock.open", color: .green, isDisabled: true) {
                DebugLogger.log("Disarm tapped", feature: .alarm)
            }
        }
    }
    .padding()
    .background(Color.gray.opacity(DesignSystem.Opacity.previewBackground))
}
