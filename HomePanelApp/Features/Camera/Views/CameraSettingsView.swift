import SwiftUI

// MARK: - Camera Settings View

struct CameraSettingsView: View {
    // MARK: - Constants
    
    /// Default Blue Iris UI path for camera access
    private static let defaultBlueIrisPath = "/ui3.htm?t=live&group=Index"
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsContext: SettingsContext
    
    @State private var cameraName: String
    @State private var vmsType: VMSType
    @State private var ipAddress: String
    @State private var port: String
    @State private var username: String
    @State private var password: String = ""
    
    init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
        _cameraName = State(initialValue: viewModel.config.name)
        _vmsType = State(initialValue: viewModel.config.vmsType)
        _ipAddress = State(initialValue: viewModel.config.ipAddress)
        _port = State(initialValue: String(viewModel.config.port))
        _username = State(initialValue: viewModel.config.username)
        _password = State(initialValue: viewModel.getSavedPassword())
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.large) {
                identitySection
                connectionSection
            }
            .padding(.top, DesignSystem.Spacing.large)
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.bottom, DesignSystem.Spacing.large)
        }
        .background(Color(.systemGroupedBackground))
        .keyboardAware()
        .overlay(
            ToastBannerOverlay(toastMessage: $settingsContext.toastMessage)
        )
        .interactiveDismissDisabled() // Make it modal - prevent accidental dismissal
        .keyboardHandling()
        .onAppear {
            // Initialize original values for change tracking
            settingsContext.setOriginalValue("camera_name", value: cameraName)
            settingsContext.setOriginalValue("camera_vmsType", value: vmsType.rawValue)
            settingsContext.setOriginalValue("camera_ip", value: ipAddress)
            settingsContext.setOriginalValue("camera_port", value: port)
            settingsContext.setOriginalValue("camera_username", value: username)
            settingsContext.setOriginalValue("camera_password", value: password)

            // Set save handler
            settingsContext.setSaveHandler {
                guard self.isValid else {
                    throw SettingsError.validationFailed("Please check all fields are valid")
                }
                await self.viewModel.saveConfiguration(
                    name: self.cameraName,
                    vmsType: self.vmsType,
                    ipAddress: self.ipAddress,
                    port: self.port,
                    path: CameraSettingsView.defaultBlueIrisPath,
                    username: "",
                    password: ""
                )
            }

            // Set save complete callback to refresh camera tabs
            settingsContext.setSaveCompleteCallback {
                // This will be called after successful save
                // The callback will be set by the parent view
            }
        }
    }
    
    // MARK: - Sections
    
    private var identitySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Camera Identity")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                Text("Camera Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("e.g., Front Door, Backyard", text: $cameraName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .onChange(of: cameraName) { _, newValue in
                        settingsContext.registerValue("camera_name", value: newValue)
                    }
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                Text("Camera System Type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Type", selection: $vmsType) {
                    ForEach(VMSType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: vmsType) { _, newValue in
                    settingsContext.registerValue("camera_vmsType", value: newValue.rawValue)
                }
            }
            
            Text("Select your camera system type. The app will configure connection settings appropriately.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(DesignSystem.Spacing.medium)
        .background(Color(.systemBackground))
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Camera Connection")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("IP Address")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter IP Address", text: $ipAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .keyboardType(.numbersAndPunctuation)
                        .textContentType(.URL)
                        .onChange(of: ipAddress) { _, newValue in
                            settingsContext.registerValue("camera_ip", value: newValue)
                        }
                        .accessibilityLabel("IP Address")
                        .accessibilityHint("Enter the IP address of your Blue Iris camera server")
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("Port")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter Port", text: $port)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .keyboardType(.numberPad)
                        .textContentType(.URL)
                        .onChange(of: port) { _, newValue in
                            settingsContext.registerValue("camera_port", value: newValue)
                        }
                        .accessibilityLabel("Port")
                        .accessibilityHint("Enter the port number for your Blue Iris server")
                }
            }
            
            Text("Example: IP: 192.168.1.100, Port: 2671")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(DesignSystem.Spacing.medium)
        .background(Color(.systemBackground))
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    
    
    // MARK: - Buttons
    
    private var cancelButton: some View {
        Button("Cancel") {
            dismiss()
        }
    }
    
    private var saveButton: some View {
        Button("Save") {
            Task {
                await viewModel.saveConfiguration(
                    name: cameraName,
                    vmsType: vmsType,
                    ipAddress: ipAddress,
                    port: port,
                    path: CameraSettingsView.defaultBlueIrisPath,
                    username: "",
                    password: ""
                )
                dismiss()
            }
        }
        .disabled(!isValid)
        .fontWeight(.semibold)
    }
    
    // MARK: - Validation
    
    private var isValid: Bool {
        !ipAddress.isEmpty && 
        !port.isEmpty && 
        isValidIPAddress(ipAddress) &&
        isValidPort(port)
    }
    
    private func isValidIPAddress(_ ip: String) -> Bool {
        return IPValidator.isValidIPv4(ip)
    }
    
    private func isValidPort(_ port: String) -> Bool {
        return IPValidator.isValidPort(port)
    }
}