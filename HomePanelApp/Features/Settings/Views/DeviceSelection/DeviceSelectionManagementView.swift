import SwiftUI

struct DeviceSelectionManagementView: View {
    @ObservedObject var viewModel: AutomationViewModel
    @EnvironmentObject var settingsContext: SettingsContext
    @State private var showingDeviceSelection = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Configure Devices Button
                Button(action: {
                    showingDeviceSelection = true
                }) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.white)
                            .font(.title2)
                        Text("Configure Devices & Scenes")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .accessibilityLabel("Configure Devices & Scenes")
                .accessibilityHint("Tap to select and order devices and scenes")

                // Currently Selected Devices Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Selected Devices & Scenes (\(viewModel.appConfig.selectedDeviceNames.count))")
                        .font(.headline)
                        .padding(.horizontal, 20)

                    if viewModel.appConfig.selectedDeviceNames.isEmpty {
                        Text("No devices or scenes selected")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(Array(viewModel.appConfig.selectedDeviceNames.enumerated()), id: \.offset) { index, deviceName in
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 30, alignment: .leading)

                                    Text(deviceName)
                                        .font(.body)

                                    Spacer()

                                    // Show device type icon if we can find the device
                                    if let device = viewModel.devices.first(where: { $0.name == deviceName }) {
                                        Image(systemName: device.type.icon)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Info text
                Text("Devices and scenes will appear in the Automation tab in the order shown above.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            }
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .fullScreenCover(isPresented: $showingDeviceSelection) {
            DeviceSelectionSheet(viewModel: viewModel)
        }
    }
}
