import SwiftUI

// MARK: - PIN Entry Header View

struct PINEntryHeaderView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    // Convenience initializer for alarm mode (backward compatibility)
    init(mode: String) {
        self.icon = "lock.shield.fill"
        self.iconColor = .blue
        self.title = "Enter PIN to \(mode)"
        self.subtitle = "6-digit PIN required"
    }
    
    // Full initializer for custom configuration
    init(icon: String, iconColor: Color, title: String, subtitle: String) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.formSpacing) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.FontSize.regular))
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, DesignSystem.Layout.topPadding)
    }
}

// MARK: - Preview

#Preview {
    PINEntryHeaderView(mode: "Away")
        .padding()
        .background(Color(.systemBackground))
}
