import SwiftUI

// MARK: - Design System
// Centralized constants for consistent UI design across the app

struct DesignSystem {
    
    // MARK: - Colors
    
    struct Colors {
        static let primary = Color.orange
        static let secondary = Color.gray
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let background = Color(.systemBackground)
        static let cardBackground = Color(.secondarySystemBackground)
    }
    
    // MARK: - Font Sizes
    
    struct FontSize {
        // System font sizes
        static let extraLarge: CGFloat = 80
        static let large: CGFloat = 60
        static let medium: CGFloat = 50
        static let regular: CGFloat = 40
        static let small: CGFloat = 36
        static let extraSmall: CGFloat = 30
        static let tiny: CGFloat = 24
        static let micro: CGFloat = 20
        static let nano: CGFloat = 18
        static let pico: CGFloat = 16
        
        // Semantic font sizes
        static let warningTitle: CGFloat = 36
        static let warningSubtitle: CGFloat = 24
        static let warningDescription: CGFloat = 18
        static let instructionText: CGFloat = 16
        static let iconSize: CGFloat = 30
        static let largeIconSize: CGFloat = 50
        static let extraLargeIconSize: CGFloat = 60
        static let hugeIconSize: CGFloat = 80
        
        // Date/Time display font sizes
        static let dateTimeLarge: CGFloat = 48
        static let dateTimeMedium: CGFloat = 36
        static let dateTimeSmall: CGFloat = 28
        static let timeDisplay: CGFloat = 44
        static let dateDisplay: CGFloat = 32
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        // Base spacing units
        static let nano: CGFloat = 2
        static let micro: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 10
        static let regular: CGFloat = 12
        static let large: CGFloat = 15
        static let extraLarge: CGFloat = 20
        static let huge: CGFloat = 30
        static let massive: CGFloat = 40
        
        // Semantic spacing
        static let keypadSpacing: CGFloat = 15
        static let buttonSpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 20
        static let headerSpacing: CGFloat = 10
        static let statusSpacing: CGFloat = 15
        static let warningSpacing: CGFloat = 30
        static let gridSpacing: CGFloat = 15
        static let pinDisplaySpacing: CGFloat = 15
        static let formSpacing: CGFloat = 8
        static let rowSpacing: CGFloat = 4
        static let countdownSpacing: CGFloat = 4
        static let lastUpdatedSpacing: CGFloat = 2
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        // Base corner radius values
        static let nano: CGFloat = 8
        static let small: CGFloat = 10
        static let medium: CGFloat = 12
        static let large: CGFloat = 15
        static let extraLarge: CGFloat = 35
        
        // Semantic corner radius
        static let button: CGFloat = 15
        static let keypadButton: CGFloat = 35
        static let card: CGFloat = 12
        static let popup: CGFloat = 15
        static let statusCard: CGFloat = 15
        static let pinRow: CGFloat = 8
        static let formField: CGFloat = 10
        static let lockoutCard: CGFloat = 12
        static let placeholderCard: CGFloat = 15
    }
    
    // MARK: - Frame Sizes
    
    struct FrameSize {
        // Button sizes
        static let keypadButton: CGFloat = 70
        static let modeButtonHeight: CGFloat = 100
        static let pinDot: CGFloat = 20
        static let iconFrame: CGFloat = 30
        
        // Layout sizes
        static let statusCardHeight: CGFloat = 30
        static let warningPadding: CGFloat = 40
        static let formPadding: CGFloat = 30
        static let popupPadding: CGFloat = 20
        static let headerPadding: CGFloat = 20
        static let sectionPadding: CGFloat = 4
    }
    
    // MARK: - Opacity Values
    
    struct Opacity {
        // Base opacity values
        static let veryLight: Double = 0.1
        static let light: Double = 0.2
        static let medium: Double = 0.3
        static let semiTransparent: Double = 0.5
        static let disabled: Double = 0.5
        static let pressed: Double = 0.6
        static let overlay: Double = 0.8
        static let background: Double = 0.9
        
        // Semantic opacity values
        static let shadow: Double = 0.1
        static let cardBackground: Double = 0.2
        static let errorBackground: Double = 0.1
        static let warningBackground: Double = 0.1
        static let pinDotInactive: Double = 0.3
        static let pinDotStroke: Double = 0.5
        static let buttonShadow: Double = 0.1
        static let buttonGradientStart: Double = 0.8
        static let buttonGradientEnd: Double = 0.9
        static let buttonOverlay: Double = 0.3
        static let modalOverlay: Double = 0.8
        static let modalBackground: Double = 0.9
        static let stateBackground: Double = 0.3
        static let previewBackground: Double = 0.1
    }
    
    // MARK: - Shadow Values
    
    struct Shadow {
        static let radius: CGFloat = 5
        static let pressedRadius: CGFloat = 2
        static let offset: CGFloat = 2
        static let pressedOffset: CGFloat = 1
        static let xOffset: CGFloat = 0
        static let yOffset: CGFloat = 2
        static let pressedYOffset: CGFloat = 1
    }
    
    // MARK: - Animation Durations
    
    struct Animation {
        static let quick: Double = 0.1
        static let standard: Double = 0.2
        static let slow: Double = 0.3
        static let verySlow: Double = 0.5
        static let springResponse: Double = 0.3
        static let springDamping: Double = 0.6
    }
    
    // MARK: - Scale Effects
    
    struct Scale {
        static let pressed: CGFloat = 0.9
        static let pressedMode: CGFloat = 0.95
        static let pinDot: CGFloat = 1.1
        static let progressView: CGFloat = 1.2
        static let warningIcon: CGFloat = 1.2
    }
    
    // MARK: - Grid Configuration
    
    struct Grid {
        static let columns: Int = 3
        static let modeColumns: Int = 2
        static let spacing: CGFloat = 15
    }
    
    // MARK: - PIN Configuration
    
    struct PIN {
        static let maxLength: Int = 6
        static let displaySpacing: CGFloat = 15
        static let dotSize: CGFloat = 20
        static let shakeOffset: CGFloat = 10
    }
    
    // MARK: - Layout Constants
    
    struct Layout {
        static let maxWidth: CGFloat = .infinity
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 30
        static let bottomPadding: CGFloat = 20
        static let topPadding: CGFloat = 20
    }
    
    // MARK: - Tab Bar Constants
    
    struct TabBar {
        static let height: CGFloat = 120
        static let iconSize: CGFloat = 32
        static let fontSize: CGFloat = 18
        static let fontWeight: Font.Weight = .bold
        static let topPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 32
        static let itemSpacing: CGFloat = 6
        static let cornerRadius: CGFloat = 20
        static let backgroundColor: Color = Color(.systemBackground)
        static let selectedColor: Color = .blue
        static let unselectedColor: Color = .secondary
    }
    
    // MARK: - Settings Icon Constants
    
    struct SettingsIcon {
        static let size: CGFloat = 30
        static let frameSize: CGFloat = 44
        static let iconSize: CGFloat = 20
        static let fontWeight: Font.Weight = .medium
        static let cornerRadius: CGFloat = 22
        static let backgroundOpacity: Double = 0.6
        static let shadowOpacity: Double = 0.3
        static let shadowRadius: CGFloat = 4
        static let shadowOffset: CGFloat = 2
        static let padding: CGFloat = 15
    }
}

// MARK: - Button Styles

extension DesignSystem {
    
    // MARK: - Primary Button Style
    struct PrimaryButtonStyle: ButtonStyle {
        let color: Color
        let isDisabled: Bool
        
        init(color: Color = .blue, isDisabled: Bool = false) {
            self.color = color
            self.isDisabled = isDisabled
        }
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(buttonBackground(isPressed: configuration.isPressed))
                .cornerRadius(CornerRadius.button)
                .scaleEffect(configuration.isPressed ? Scale.pressed : 1.0)
                .shadow(
                    color: color.opacity(Opacity.buttonShadow),
                    radius: configuration.isPressed ? Shadow.pressedRadius : Shadow.radius,
                    x: Shadow.xOffset,
                    y: configuration.isPressed ? Shadow.pressedYOffset : Shadow.yOffset
                )
                .opacity(isDisabled ? Opacity.disabled : 1.0)
                .animation(.easeInOut(duration: Animation.quick), value: configuration.isPressed)
        }
        
        private func buttonBackground(isPressed: Bool) -> some View {
            RoundedRectangle(cornerRadius: CornerRadius.button)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            color.opacity(Opacity.buttonGradientStart),
                            color.opacity(Opacity.buttonGradientEnd)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.button)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(Opacity.buttonOverlay),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }
    
    // MARK: - Secondary Button Style
    struct SecondaryButtonStyle: ButtonStyle {
        let isDisabled: Bool
        
        init(isDisabled: Bool = false) {
            self.isDisabled = isDisabled
        }
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(buttonBackground(isPressed: configuration.isPressed))
                .cornerRadius(CornerRadius.button)
                .scaleEffect(configuration.isPressed ? Scale.pressed : 1.0)
                .shadow(
                    color: .black.opacity(Opacity.buttonShadow),
                    radius: configuration.isPressed ? Shadow.pressedRadius : Shadow.radius,
                    x: Shadow.xOffset,
                    y: configuration.isPressed ? Shadow.pressedYOffset : Shadow.yOffset
                )
                .opacity(isDisabled ? Opacity.disabled : 1.0)
                .animation(.easeInOut(duration: Animation.quick), value: configuration.isPressed)
        }
        
        private func buttonBackground(isPressed: Bool) -> some View {
            RoundedRectangle(cornerRadius: CornerRadius.button)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemGray6),
                            Color(.systemGray5)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.button)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(Opacity.overlay),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }
    
    // MARK: - Destructive Button Style
    struct DestructiveButtonStyle: ButtonStyle {
        let isDisabled: Bool
        
        init(isDisabled: Bool = false) {
            self.isDisabled = isDisabled
        }
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(buttonBackground(isPressed: configuration.isPressed))
                .cornerRadius(CornerRadius.button)
                .scaleEffect(configuration.isPressed ? Scale.pressed : 1.0)
                .shadow(
                    color: .red.opacity(Opacity.buttonShadow),
                    radius: configuration.isPressed ? Shadow.pressedRadius : Shadow.radius,
                    x: Shadow.xOffset,
                    y: configuration.isPressed ? Shadow.pressedYOffset : Shadow.yOffset
                )
                .opacity(isDisabled ? Opacity.disabled : 1.0)
                .animation(.easeInOut(duration: Animation.quick), value: configuration.isPressed)
        }
        
        private func buttonBackground(isPressed: Bool) -> some View {
            RoundedRectangle(cornerRadius: CornerRadius.button)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.red.opacity(Opacity.buttonGradientStart),
                            Color.red.opacity(Opacity.buttonGradientEnd)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.button)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(Opacity.buttonOverlay),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }
    
    // MARK: - Keypad Button Style
    struct KeypadButtonStyle: ButtonStyle {
        let isDisabled: Bool
        
        init(isDisabled: Bool = false) {
            self.isDisabled = isDisabled
        }
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .frame(width: FrameSize.keypadButton, height: FrameSize.keypadButton)
                .background(buttonBackground(isPressed: configuration.isPressed))
                .foregroundColor(.primary)
                .cornerRadius(CornerRadius.keypadButton)
                .scaleEffect(configuration.isPressed ? Scale.pressed : 1.0)
                .shadow(
                    color: .black.opacity(Opacity.buttonShadow),
                    radius: configuration.isPressed ? Shadow.pressedRadius : Shadow.radius,
                    x: Shadow.xOffset,
                    y: configuration.isPressed ? Shadow.pressedYOffset : Shadow.yOffset
                )
                .opacity(isDisabled ? Opacity.disabled : 1.0)
                .animation(.easeInOut(duration: Animation.quick), value: configuration.isPressed)
        }
        
        private func buttonBackground(isPressed: Bool) -> some View {
            RoundedRectangle(cornerRadius: CornerRadius.keypadButton)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemGray6),
                            Color(.systemGray5)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.keypadButton)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(Opacity.overlay),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }
    
    // MARK: - Mode Button Style
    struct ModeButtonStyle: ButtonStyle {
        let color: Color
        let isDisabled: Bool
        
        init(color: Color, isDisabled: Bool = false) {
            self.color = color
            self.isDisabled = isDisabled
        }
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .frame(maxWidth: .infinity)
                .frame(height: FrameSize.modeButtonHeight)
                .background(buttonBackground(isPressed: configuration.isPressed))
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.button)
                .scaleEffect(configuration.isPressed ? Scale.pressedMode : 1.0)
                .shadow(
                    color: color.opacity(Opacity.buttonOverlay),
                    radius: configuration.isPressed ? Shadow.pressedRadius : Shadow.radius,
                    x: Shadow.xOffset,
                    y: configuration.isPressed ? Shadow.pressedYOffset : Shadow.yOffset
                )
                .opacity(isDisabled ? Opacity.pressed : 1.0)
                .animation(.easeInOut(duration: Animation.quick), value: configuration.isPressed)
        }
        
        private func buttonBackground(isPressed: Bool) -> some View {
            RoundedRectangle(cornerRadius: CornerRadius.button)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            color.opacity(Opacity.buttonGradientStart),
                            color.opacity(Opacity.buttonGradientEnd)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.button)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(Opacity.buttonOverlay),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }
}

// MARK: - Button Style Extensions

extension ButtonStyle where Self == DesignSystem.PrimaryButtonStyle {
    static func primary(color: Color = .blue, isDisabled: Bool = false) -> DesignSystem.PrimaryButtonStyle {
        DesignSystem.PrimaryButtonStyle(color: color, isDisabled: isDisabled)
    }
}

extension ButtonStyle where Self == DesignSystem.SecondaryButtonStyle {
    static func secondary(isDisabled: Bool = false) -> DesignSystem.SecondaryButtonStyle {
        DesignSystem.SecondaryButtonStyle(isDisabled: isDisabled)
    }
}

extension ButtonStyle where Self == DesignSystem.DestructiveButtonStyle {
    static func destructive(isDisabled: Bool = false) -> DesignSystem.DestructiveButtonStyle {
        DesignSystem.DestructiveButtonStyle(isDisabled: isDisabled)
    }
}

extension ButtonStyle where Self == DesignSystem.KeypadButtonStyle {
    static func keypad(isDisabled: Bool = false) -> DesignSystem.KeypadButtonStyle {
        DesignSystem.KeypadButtonStyle(isDisabled: isDisabled)
    }
}

extension ButtonStyle where Self == DesignSystem.ModeButtonStyle {
    static func mode(color: Color, isDisabled: Bool = false) -> DesignSystem.ModeButtonStyle {
        DesignSystem.ModeButtonStyle(color: color, isDisabled: isDisabled)
    }
}

