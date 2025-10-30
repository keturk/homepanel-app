import SwiftUI

struct DeviceCardView: View {
    let device: Device
    let isActionInProgress: Bool
    let onTap: () -> Void
    let roomMappingService: RoomMappingService

    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Don't allow interaction with placeholder or disconnected devices
            guard device.hubState != .placeholder && device.hubState != .disconnected else { return }

            // Immediate visual feedback
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }

            // Reset pressed state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }

            onTap()
        }) {
            VStack(spacing: DesignSystem.Spacing.small) {
                // Icon at the top
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 60, height: 60)

                    if isActionInProgress {
                        // Show loading spinner when action is in progress
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: iconColor))
                            .scaleEffect(1.5)
                    } else {
                        Image(systemName: iconName)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(iconColor)
                    }
                }
                
                // Device name and room below icon
                VStack(spacing: 2) {
                    Text(device.name)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Room label if available (only for devices, not scenes)
                    if device.type != .scene, let room = device.room, !room.isEmpty {
                        let roomName = roomMappingService.roomName(for: room, hubId: device.hubId)
                        Text(roomName)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                            .onAppear {
                                DebugLogger.log("DeviceCardView: Device '\(device.name)' has room '\(room)' -> '\(roomName)' (hub: \(device.hubId))", feature: .automation)
                            }
                    }
                }
                
                // Status indicator
                DeviceStatusIndicator(status: statusIndicatorType)
                
                // Brightness bar for dimmers
                if device.type == .dimmer, device.state.isOn == true, let level = device.state.level {
                    BrightnessBar(level: level)
                        .frame(height: 4)
                }
            }
            .padding(DesignSystem.Spacing.large)
            .frame(maxWidth: .infinity, minHeight: 200)
            .aspectRatio(1.0, contentMode: .fit)
            .background(enhancedBackgroundColor)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(enhancedBorderColor, lineWidth: 2)
            )
            .shadow(
                color: .black.opacity(0.15),
                radius: isPressed ? 2 : 8,
                x: 0,
                y: isPressed ? 1 : 4
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isActionInProgress || device.hubState == .placeholder || device.hubState == .disconnected)
    }
    
    // MARK: - Computed Properties
    private var iconName: String {
        if device.type == .scene {
            return "sparkles"
        }
        return device.type.icon
    }
    
    private var iconColor: Color {
        // Placeholder devices have orange color, disconnected devices have red color
        switch device.hubState {
        case .placeholder:
            return Color.orange
        case .disconnected:
            return Color.red
        case .connected:
        
            if device.type == .scene {
                return Color.blue
            }
            
            switch device.type {
        case .light, .lightSwitch, .dimmer:
            return device.state.isOn == true ? Color.yellow : Color.gray
        case .sensor:
            return device.state.tripped == true ? Color.green : Color.gray
        case .lock:
            return device.state.locked == true ? Color.red : Color.green
        case .thermostat:
            return Color.blue
            case .scene:
                return Color.blue
            }
        }
    }
    
    
    private var iconBackgroundColor: Color {
        switch device.hubState {
        case .placeholder:
            return Color.orange.opacity(0.2)
        case .disconnected:
            return Color.red.opacity(0.2)
        case .connected:
            if device.type == .scene {
                return Color.purple.opacity(0.3)
            }
            return device.state.isOn == true ? iconColor.opacity(0.2) : Color.gray.opacity(0.1)
        }
    }
    
    private var enhancedBackgroundColor: Color {
        switch device.hubState {
        case .placeholder:
            return Color.orange.opacity(0.15)
        case .disconnected:
            return Color.red.opacity(0.15)
        case .connected:
            if device.type == .scene {
                return Color.purple.opacity(0.2)
            }
            return device.state.isOn == true ? Color.yellow.opacity(0.15) : Color.gray.opacity(0.2)
        }
    }
    
    private var enhancedBorderColor: Color {
        switch device.hubState {
        case .placeholder:
            return Color.orange.opacity(0.6)
        case .disconnected:
            return Color.red.opacity(0.6)
        case .connected:
            if device.type == .scene {
                return Color.purple.opacity(0.6)
            }
            return device.state.isOn == true ? Color.yellow.opacity(0.6) : Color.gray.opacity(0.5)
        }
    }
    
    private var statusIndicatorType: DeviceStatusIndicator.Status {
        switch device.hubState {
        case .placeholder:
            return .placeholder
        case .disconnected:
            return .disconnected
        case .connected:
            if isActionInProgress {
                return .executing
            } else if device.type == .scene {
                return .normal("Tap to activate")
            } else {
                return .normal("")
            }
        }
    }
    
}

// MARK: - Brightness Bar
struct BrightnessBar: View {
    let level: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.3))
                
                // Fill
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.yellow.opacity(0.8))
                    .frame(width: geometry.size.width * CGFloat(level) / 100.0)
            }
        }
    }
}
