import SwiftUI

struct CameraManagementView: View {
    @ObservedObject var cameraConfigService: CameraConfigService
    @State private var showingAddCamera = false
    @State private var editingCamera: CameraConfig?
    @State private var cameraToDelete: String?
    @State private var showingDeleteAlert = false
    @State private var showingCameraLimitAlert = false

    private let maxCameras = 2

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Add New Camera Button
                Button(action: {
                    if configuredCameras.count >= maxCameras {
                        showingCameraLimitAlert = true
                        HapticFeedback.warning()
                    } else {
                        showingAddCamera = true
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                        Text("Add New Camera")
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
                .accessibilityLabel("Add New Camera")
                .accessibilityHint("Tap to add a new camera")

                // All Cameras Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configured Cameras (\(configuredCameras.count))")
                        .font(.headline)
                        .padding(.horizontal, 20)

                    if configuredCameras.isEmpty {
                        Text("No cameras configured")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.horizontal, 20)
                    } else {
                        ForEach(configuredCameras) { camera in
                            CameraRowView(
                                configuration: camera,
                                onEdit: {
                                    editingCamera = camera
                                },
                                onDelete: {
                                    cameraToDelete = camera.id
                                    showingDeleteAlert = true
                                }
                            )
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .fullScreenCover(isPresented: $showingAddCamera) {
            AddCameraView(cameraConfigService: cameraConfigService) { newConfig in
                Task {
                    try cameraConfigService.saveConfiguration(newConfig)
                    NotificationCenter.default.post(name: .cameraConfigurationChanged, object: nil)
                }
            }
        }
        .fullScreenCover(item: $editingCamera) { camera in
            EditCameraView(
                configuration: camera,
                cameraConfigService: cameraConfigService,
                onSave: { updatedConfig in
                    Task {
                        try cameraConfigService.saveConfiguration(updatedConfig)
                        NotificationCenter.default.post(name: .cameraConfigurationChanged, object: nil)
                    }
                }
            )
        }
        .alert("Delete Camera", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let cameraId = cameraToDelete {
                    Task {
                        do {
                            DebugLogger.log("Attempting to delete camera: \(cameraId)", feature: .camera)
                            try cameraConfigService.deleteConfiguration(for: cameraId)
                            DebugLogger.success("Camera deleted successfully", feature: .camera)
                            NotificationCenter.default.post(name: .cameraConfigurationChanged, object: nil)
                        } catch {
                            DebugLogger.error("Failed to delete camera: \(error)", feature: .camera)
                        }
                    }
                }
            }
        } message: {
            if let cameraId = cameraToDelete,
               let camera = configuredCameras.first(where: { $0.id == cameraId }) {
                Text("Are you sure you want to delete '\(camera.name)'? This action cannot be undone.")
            }
        }
        .alert("Camera Limit Reached", isPresented: $showingCameraLimitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can only configure up to \(maxCameras) cameras. Please delete an existing camera before adding a new one.")
        }
    }

    private var configuredCameras: [CameraConfig] {
        // Get all configured cameras from the service
        return cameraConfigService.cameras.filter { $0.isConfigured }
    }
}

// MARK: - Camera Row View

struct CameraRowView: View {
    let configuration: CameraConfig
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Camera Name with Action Buttons
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(configuration.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(configuration.vmsType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Action Buttons inline with name
                HStack(spacing: 12) {
                    Button(action: onEdit) {
                        Text("Edit")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .frame(minWidth: 70, minHeight: 40)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Edit Camera")
                    .accessibilityHint("Edit camera configuration")

                    Button(action: onDelete) {
                        Text("Delete")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .frame(minWidth: 70, minHeight: 40)
                    .tint(.red)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Delete Camera")
                    .accessibilityHint("Delete this camera")
                }
            }

        }
        .padding()
    }
}
