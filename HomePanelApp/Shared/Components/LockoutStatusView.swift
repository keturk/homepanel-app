import SwiftUI

// MARK: - Lockout Status View

struct LockoutStatusView: View {
    let isLockedOut: Bool
    let remainingLockoutTime: String
    
    // Convenience initializer for alarm system (backward compatibility)
    init(isLockedOut: Bool, remainingLockoutTime: String) {
        self.isLockedOut = isLockedOut
        self.remainingLockoutTime = remainingLockoutTime
    }
    
    // Full initializer for custom lockout message
    init(isLockedOut: Bool, lockoutMessage: String) {
        self.isLockedOut = isLockedOut
        self.remainingLockoutTime = lockoutMessage
    }
    
    var body: some View {
        if isLockedOut {
            VStack(spacing: DesignSystem.Spacing.headerSpacing) {
                Image(systemName: "lock.fill")
                    .font(.system(size: DesignSystem.FontSize.regular))
                    .foregroundColor(.red)
                
                Text("Too many failed attempts")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Text(remainingLockoutTime)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.red.opacity(DesignSystem.Opacity.errorBackground))
            .cornerRadius(DesignSystem.CornerRadius.lockoutCard)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
        LockoutStatusView(isLockedOut: false, remainingLockoutTime: "0 minutes")
        LockoutStatusView(isLockedOut: true, remainingLockoutTime: "5 minutes")
    }
    .padding()
    .background(Color(.systemBackground))
}
