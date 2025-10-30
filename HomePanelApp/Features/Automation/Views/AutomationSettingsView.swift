import SwiftUI
import Combine

struct AutomationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AutomationViewModel
    @EnvironmentObject var settingsContext: SettingsContext
    
    @State private var deviceNamesText = ""
    @State private var isLoading = false
    @State private var toastMessage: ToastMessage?
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Device Names Configuration Section - Full Height
            deviceNamesSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black)
        .overlay(
            ToastBannerOverlay(toastMessage: $toastMessage)
        )
        .keyboardHandling()
        .onAppear {
            loadDeviceNames()
            // Initialize original values for change tracking
            settingsContext.setOriginalValue("automation_devices", value: deviceNamesText)

            // Set save handler
            settingsContext.setSaveHandler {
                self.saveDeviceNames()
            }
        }
    }
    
    // MARK: - Device Names Section
    
    private var deviceNamesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Text("Enter device and scene names separated by commas. These will appear on the Automation tab for this iPad in the order they are entered.")
                .font(.system(size: DesignSystem.FontSize.pico))
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, DesignSystem.Spacing.medium)
            
            // TextEditor that fills remaining space
            TextEditor(text: $deviceNamesText)
                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
                .padding(DesignSystem.Spacing.medium)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(DesignSystem.CornerRadius.medium)
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .stroke(isTextFieldFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: isTextFieldFocused ? 2 : 1)
                )
                .focused($isTextFieldFocused)
                .onChange(of: deviceNamesText) { _, newValue in
                    settingsContext.registerValue("automation_devices", value: newValue)
                }
                .accessibilityLabel("Device Names")
                .accessibilityHint("Enter device and scene names separated by commas")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(DesignSystem.Spacing.medium)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(DesignSystem.CornerRadius.large)
    }
    

    // MARK: - Helper Methods

    private func loadDeviceNames() {
        deviceNamesText = viewModel.appConfig.selectedDeviceNames.joined(separator: ", ")
    }

    private func saveDeviceNames() {
        let deviceNames = deviceNamesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        DebugLogger.log("Saving device names: \(deviceNames)", feature: .automation)
        viewModel.appConfig.updateSelectedDeviceNames(deviceNames)
        DebugLogger.log("After saving, selectedDeviceNames: \(viewModel.appConfig.selectedDeviceNames)", feature: .automation)

        // Refresh the automation view
        Task {
            await viewModel.loadDevices()
        }
        
        // Show success toast and haptic feedback
        toastMessage = ToastMessage(title: "Device names saved successfully", message: "\(deviceNames.count) devices configured", type: .success)
        HapticFeedback.settingsSuccess()
        
        // Reset settings context after successful save
        settingsContext.reset()
    }
}
