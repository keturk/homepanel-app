import SwiftUI

// MARK: - PIN Display View

struct PINDisplayView: View {
    let pin: String
    let maxPINLength: Int
    let shakeOffset: CGFloat
    let fillColor: Color
    
    // Convenience initializer with default blue color (backward compatibility)
    init(pin: String, maxPINLength: Int, shakeOffset: CGFloat) {
        self.pin = pin
        self.maxPINLength = maxPINLength
        self.shakeOffset = shakeOffset
        self.fillColor = .blue
    }
    
    // Full initializer with configurable color
    init(pin: String, maxPINLength: Int, shakeOffset: CGFloat, fillColor: Color) {
        self.pin = pin
        self.maxPINLength = maxPINLength
        self.shakeOffset = shakeOffset
        self.fillColor = fillColor
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.pinDisplaySpacing) {
            ForEach(0..<maxPINLength, id: \.self) { index in
                Circle()
                    .fill(index < pin.count ? fillColor : Color.gray.opacity(DesignSystem.Opacity.pinDotInactive))
                    .frame(width: DesignSystem.FrameSize.pinDot, height: DesignSystem.FrameSize.pinDot)
                    .overlay(
                        Circle()
                            .stroke(fillColor.opacity(DesignSystem.Opacity.pinDotStroke), lineWidth: 1)
                    )
                    .scaleEffect(index < pin.count ? DesignSystem.Scale.pinDot : 1.0)
                    .animation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping), value: pin.count)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(Color(.systemGray6))
        )
        .offset(x: shakeOffset)
        .animation(.easeInOut(duration: DesignSystem.Animation.quick), value: shakeOffset)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("PIN entry field")
        .accessibilityValue("\(pin.count) of 6 digits entered")
        .accessibilityHint("Use the keypad below to enter your 6-digit PIN")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
        PINDisplayView(pin: "123", maxPINLength: 6, shakeOffset: 0)
        PINDisplayView(pin: "123456", maxPINLength: 6, shakeOffset: 0)
        PINDisplayView(pin: "12", maxPINLength: 6, shakeOffset: 10)
    }
    .padding()
    .background(Color(.systemBackground))
}
