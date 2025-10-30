import SwiftUI

struct AddCameraView: View {
    @Environment(\.dismiss) private var dismiss
    let cameraConfigService: CameraConfigServiceProtocol
    let onSave: (CameraConfig) -> Void

    @State private var cameraName = ""
    @State private var vmsType = VMSType.blueIris
    @State private var ipAddress = ""
    @State private var port = "2671"
    @State private var path = "/ui3.htm?t=live&group=Index"
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var toastMessage: ToastMessage?
    @State private var isSaving = false
    @State private var validationErrors: [String: String] = [:]

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.large) {
                // Header section with title
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("Add New Camera")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                identitySection
                connectionSection
            }
            .padding(.top, DesignSystem.Spacing.large)
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.bottom, DesignSystem.Spacing.large)
        }
        .background(Color(.systemGroupedBackground))
        .overlay(
            // Custom header with Cancel and Save buttons
            VStack {
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Cancel adding camera and return to camera management")

                    Spacer()

                    Text("Add New Camera")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    Button("Save") {
                        saveCamera()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValidConfiguration || isSaving)
                    .overlay(
                        Group {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    )
                    .accessibilityLabel("Save")
                    .accessibilityHint("Save camera configuration")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)

                Spacer()
            }
        )
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .interactiveDismissDisabled(isSaving)
        .overlay(
            ToastBannerOverlay(toastMessage: $toastMessage)
        )
        .keyboardHandling()
    }

    // MARK: - Sections

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Camera Name")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    TextField("e.g., Front Door, Backyard", text: $cameraName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(validationErrors["cameraName"] != nil ? Color.red : Color.clear, lineWidth: 1)
                        )
                        .accessibilityLabel("Camera Name")
                        .accessibilityHint("Enter a name for this camera")

                    if let error = validationErrors["cameraName"] {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
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
                    .pickerStyle(.menu)
                    .accessibilityLabel("Camera System Type")
                    .accessibilityHint("Select your camera system type")
                }

                Text("Select your camera system type. The app will configure connection settings appropriately.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(validationErrors["ipAddress"] != nil ? Color.red : Color.clear, lineWidth: 1)
                        )
                        .accessibilityLabel("IP Address")
                        .accessibilityHint("Enter the IP address of your camera server")

                    if let error = validationErrors["ipAddress"] {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("Port")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("Port", text: $port)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .keyboardType(.numberPad)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(validationErrors["port"] != nil ? Color.red : Color.clear, lineWidth: 1)
                        )
                        .accessibilityLabel("Port")
                        .accessibilityHint("Enter the port number for your camera server")

                    if let error = validationErrors["port"] {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(Color(.systemBackground))
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }


    // MARK: - Validation

    private var isValidConfiguration: Bool {
        return isCameraNameValid && isConnectionValid
    }

    private var isCameraNameValid: Bool {
        let trimmedName = cameraName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty
    }

    private var isConnectionValid: Bool {
        let trimmedIP = ipAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedIP.isEmpty || !isValidIPAddress(trimmedIP) {
            return false
        }
        if let portNum = Int(port), (portNum < 1 || portNum > 65535) {
            return false
        }
        return true
    }


    private func validateConfiguration() {
        validationErrors.removeAll()

        // Validate Camera Name
        let trimmedName = cameraName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            validationErrors["cameraName"] = "Camera name is required"
        }

        // Validate Connection
        if ipAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["ipAddress"] = "IP address is required"
        } else if !isValidIPAddress(ipAddress) {
            validationErrors["ipAddress"] = "Please enter a valid IP address (e.g., 192.168.1.1)"
        }

        if let port = Int(port), (port < 1 || port > 65535) {
            validationErrors["port"] = "Port must be between 1 and 65535"
        }
    }

    private func isValidIPAddress(_ ip: String) -> Bool {
        return IPValidator.isValidIPv4(ip)
    }

    private func saveCamera() {
        // Validate and show errors before attempting to save
        validateConfiguration()
        guard validationErrors.isEmpty else {
            return
        }

        isSaving = true
        HapticFeedback.buttonPress()

        Task {
            do {
                // Determine which camera slot is available (iris_one or iris_two)
                let existingCameras = cameraConfigService.getAllCameras()
                let irisOneExists = existingCameras.contains(where: { $0.id == "iris_one" })
                let irisTwoExists = existingCameras.contains(where: { $0.id == "iris_two" })

                let cameraId: String
                if !irisOneExists {
                    cameraId = "iris_one"
                } else if !irisTwoExists {
                    cameraId = "iris_two"
                } else {
                    // This shouldn't happen if the UI check works, but handle it gracefully
                    throw NSError(domain: "CameraConfig", code: 1, userInfo: [NSLocalizedDescriptionKey: "Maximum number of cameras already configured"])
                }

                let portInt = Int(port) ?? vmsType.defaultPort
                let config = CameraConfig(
                    id: cameraId,
                    name: cameraName,
                    vmsType: vmsType,
                    ipAddress: ipAddress,
                    port: portInt,
                    username: "",
                    path: path,
                    lastUpdated: Date()
                )

                // Call the onSave callback
                onSave(config)

                await MainActor.run {
                    isSaving = false
                    toastMessage = ToastMessage(title: "Camera added successfully", message: "\(cameraName) has been configured", type: .success)
                    HapticFeedback.success()

                    // Dismiss after a short delay to show the success message
                    Task {
                        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }

            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    toastMessage = ToastMessage(title: "Failed to add camera", message: error.localizedDescription, type: .error)
                    HapticFeedback.error()
                }
            }
        }
    }
}
