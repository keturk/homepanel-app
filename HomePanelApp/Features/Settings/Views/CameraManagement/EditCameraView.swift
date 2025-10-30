import SwiftUI

struct EditCameraView: View {
    @Environment(\.dismiss) private var dismiss
    let configuration: CameraConfig
    let cameraConfigService: CameraConfigServiceProtocol
    let onSave: (CameraConfig) -> Void

    @State private var cameraName: String
    @State private var vmsType: VMSType
    @State private var ipAddress: String
    @State private var port: String
    @State private var path: String
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var toastMessage: ToastMessage?
    @State private var isSaving = false

    init(configuration: CameraConfig, cameraConfigService: CameraConfigServiceProtocol, onSave: @escaping (CameraConfig) -> Void) {
        self.configuration = configuration
        self.cameraConfigService = cameraConfigService
        self.onSave = onSave

        _cameraName = State(initialValue: configuration.name)
        _vmsType = State(initialValue: configuration.vmsType)
        _ipAddress = State(initialValue: configuration.ipAddress)
        _port = State(initialValue: String(configuration.port))
        _path = State(initialValue: configuration.path)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Camera Identity") {
                    TextField("Camera Name", text: $cameraName)

                    Picker("Camera System Type", selection: $vmsType) {
                        ForEach(VMSType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("Connection") {
                    TextField("IP Address", text: $ipAddress)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }

            }
            .navigationTitle("Edit Camera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCamera()
                    }
                    .disabled(!isValidConfiguration || isSaving)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .interactiveDismissDisabled(isSaving)
        .overlay(
            ToastBannerOverlay(toastMessage: $toastMessage)
        )
    }

    private var isValidConfiguration: Bool {
        !cameraName.isEmpty && !ipAddress.isEmpty && !port.isEmpty
    }

    private func saveCamera() {
        isSaving = true
        HapticFeedback.buttonPress()

        Task {
            do {
                let portInt = Int(port) ?? vmsType.defaultPort
                let updatedConfig = CameraConfig(
                    id: configuration.id,
                    name: cameraName,
                    vmsType: vmsType,
                    ipAddress: ipAddress,
                    port: portInt,
                    username: "",
                    path: path,
                    lastUpdated: Date()
                )

                // Call the onSave callback
                onSave(updatedConfig)

                await MainActor.run {
                    isSaving = false
                    toastMessage = ToastMessage(title: "Camera updated successfully", message: "\(cameraName) has been updated", type: .success)
                    HapticFeedback.success()

                    Task {
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }

            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    toastMessage = ToastMessage(title: "Failed to update camera", message: error.localizedDescription, type: .error)
                    HapticFeedback.error()
                }
            }
        }
    }
}
