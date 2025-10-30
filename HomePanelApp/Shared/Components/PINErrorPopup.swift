import SwiftUI

// MARK: - PIN Error Popup

struct PINErrorPopup: View {
    @Binding var isPresented: Bool
    let errorMessage: String
    let onDismiss: () -> Void
    
    var body: some View {
        Group {
            if isPresented {
                ZStack {
                    Color.black.opacity(DesignSystem.Opacity.overlay)
                        .ignoresSafeArea()
                    
                    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: DesignSystem.FontSize.medium))
                            .foregroundColor(.red)
                        
                        Text("Invalid PIN")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        
                        Text(errorMessage)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .lineLimit(nil)
                    }
                    .padding(DesignSystem.FrameSize.formPadding)
                    .background(Color.black.opacity(DesignSystem.Opacity.modalBackground))
                    .cornerRadius(DesignSystem.CornerRadius.popup)
                    .padding(DesignSystem.FrameSize.popupPadding)
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: DesignSystem.Animation.slow), value: isPresented)
                .onTapGesture {
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isPresented = true
    
    return ZStack {
        Color.blue.ignoresSafeArea()
        
        PINErrorPopup(
            isPresented: $isPresented,
            errorMessage: "The PIN you entered is incorrect. Please try again.",
            onDismiss: {
                isPresented = false
            }
        )
    }
}
