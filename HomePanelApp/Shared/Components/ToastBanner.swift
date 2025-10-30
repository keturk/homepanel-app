import SwiftUI

// MARK: - Toast Message Types

enum ToastType {
    case success
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return DesignSystem.Colors.success
        case .error: return DesignSystem.Colors.error
        case .warning: return DesignSystem.Colors.warning
        case .info: return .blue
        }
    }
}

struct ToastMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String?
    let type: ToastType
    let duration: TimeInterval
    
    init(title: String, message: String? = nil, type: ToastType, duration: TimeInterval = 3.0) {
        self.title = title
        self.message = message
        self.type = type
        self.duration = duration
    }
}

// MARK: - Toast Banner Component

struct ToastBanner: View {
    let message: ToastMessage
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    @State private var offset: CGFloat = -100
    
    var body: some View {
        if isVisible {
            VStack {
                HStack(spacing: DesignSystem.Spacing.medium) {
                    Image(systemName: message.type.icon)
                        .font(.system(size: DesignSystem.FontSize.iconSize))
                        .foregroundColor(message.type.color)
                        .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                        Text(message.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        if let messageText = message.message {
                            Text(messageText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: DesignSystem.FontSize.nano))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Dismiss notification")
                    .accessibilityHint("Tap to dismiss this notification")
                }
                .padding(DesignSystem.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(Color(.systemBackground))
                        .shadow(
                            color: .black.opacity(DesignSystem.Opacity.shadow),
                            radius: DesignSystem.Shadow.radius,
                            x: DesignSystem.Shadow.xOffset,
                            y: DesignSystem.Shadow.yOffset
                        )
                )
                .padding(.horizontal, DesignSystem.Spacing.large)
                .offset(y: offset)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .onTapGesture {
                    onDismiss()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(message.title). \(message.message ?? "")")
                .accessibilityHint("Tap to dismiss")
                .accessibilityAddTraits(.isButton)
                
                Spacer()
            }
            .onAppear {
                withAnimation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping)) {
                    isVisible = true
                    offset = 0
                }
                
                // Auto-dismiss after duration
                Task {
                    try await Task.sleep(nanoseconds: UInt64(message.duration * 1_000_000_000))
                    await MainActor.run {
                        dismissToast()
                    }
                }
            }
        }
    }
    
    private func dismissToast() {
        withAnimation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping)) {
            isVisible = false
            offset = -100
        }
        
        // Call onDismiss after animation completes
        Task {
            try await Task.sleep(nanoseconds: UInt64(DesignSystem.Animation.standard * 1_000_000_000))
            await MainActor.run {
                onDismiss()
            }
        }
    }
}

// MARK: - Toast Banner Overlay

struct ToastBannerOverlay: View {
    @Binding var toastMessage: ToastMessage?
    
    var body: some View {
        if let message = toastMessage {
            ToastBanner(message: message) {
                toastMessage = nil
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ToastBanner(
            message: ToastMessage(
                title: "Success!",
                message: "Settings saved successfully",
                type: .success
            )
        ) { }
        
        ToastBanner(
            message: ToastMessage(
                title: "Error",
                message: "Failed to save settings. Please try again.",
                type: .error
            )
        ) { }
        
        ToastBanner(
            message: ToastMessage(
                title: "Warning",
                message: "This action cannot be undone",
                type: .warning
            )
        ) { }
        
        ToastBanner(
            message: ToastMessage(
                title: "Info",
                message: "Settings will be applied after restart",
                type: .info
            )
        ) { }
    }
    .background(Color.gray.opacity(0.1))
}
