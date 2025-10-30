import SwiftUI

struct HubRowView: View {
    let configuration: HubConfiguration
    let isPrimary: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSetPrimary: () -> Void
    let onToggleAlarmHub: () -> Void
    
    var body: some View {
        HStack {
            // Left side: Hub name and status
            HStack {
                // Status indicator (green/red circle)
                Circle()
                    .fill(configuration.isEnabled ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(configuration.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isPrimary {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Right side: Buttons and toggle in one row
            HStack(spacing: 12) {
                // All buttons same size in one row - improved for better responsiveness
                if !isPrimary {
                    Button(action: {
                        DebugLogger.log("🔍 [HubRowView] Set Primary button tapped for \(configuration.name)", feature: .settings)
                        onSetPrimary()
                    }) {
                        Text("Set Primary")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .frame(minWidth: 80, minHeight: 40)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Set as Primary")
                    .accessibilityHint("Set this hub as the primary hub")
                }
                
                Button(action: {
                    DebugLogger.log("🔍 [HubRowView] Edit button tapped for \(configuration.name)", feature: .settings)
                    onEdit()
                }) {
                    Text("Edit")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .frame(minWidth: 70, minHeight: 40)
                .contentShape(Rectangle())
                .accessibilityLabel("Edit Hub")
                .accessibilityHint("Edit hub configuration")
                
                Button(action: {
                    DebugLogger.log("🔍 [HubRowView] Delete button tapped for \(configuration.name)", feature: .settings)
                    onDelete()
                }) {
                    Text("Delete")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .frame(minWidth: 70, minHeight: 40)
                .tint(.red)
                .contentShape(Rectangle())
                .accessibilityLabel("Delete Hub")
                .accessibilityHint("Delete this hub")
                
                // Toggle switch moved to the far right
                Toggle("", isOn: Binding(
                    get: { configuration.isEnabled },
                    set: { _ in onToggleAlarmHub() }
                ))
                .toggleStyle(SwitchToggleStyle())
                .frame(width: 50)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(isPrimary ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
    }
}

#Preview {
    HubRowView(
        configuration: HubConfiguration(
            hubId: "test-hub",
            hubType: .vera,
            name: "Test Hub",
            isEnabled: true,
            isAlarmHub: false,
            connection: HubConnection(
                type: .localIP,
                address: "192.168.1.100",
                port: 3480,
                useHTTPS: false
            ),
            credentials: HubCredentials(
                username: "test",
                password: "test",
                apiKey: nil,
                token: nil
            )
        ),
        isPrimary: false,
        onEdit: {},
        onDelete: {},
        onSetPrimary: {},
        onToggleAlarmHub: {}
    )
}
