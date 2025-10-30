import SwiftUI

struct UnifiedCameraSettingsView: View {
    @ObservedObject var irisOneViewModel: CameraViewModel
    @ObservedObject var irisTwoViewModel: CameraViewModel
    @EnvironmentObject var settingsContext: SettingsContext
    @State private var selectedCamera: CameraType = .irisOne
    @StateObject private var irisOneContext = SettingsContext()
    @StateObject private var irisTwoContext = SettingsContext()
    @State private var pendingCameraSwitch: CameraType?
    @State private var showingSwitchCameraDialog = false
    
    enum CameraType: String, CaseIterable {
        case irisOne = "Iris One"
        case irisTwo = "Iris Two"
    }
    
    init(cameraConfigService: CameraConfigService, pinService: any PINManagementServiceProtocol) {
        self._irisOneViewModel = ObservedObject(wrappedValue: CameraViewModel(cameraId: "iris_one", configService: cameraConfigService, pinService: pinService))
        self._irisTwoViewModel = ObservedObject(wrappedValue: CameraViewModel(cameraId: "iris_two", configService: cameraConfigService, pinService: pinService))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Camera Selection
            Picker("Camera", selection: Binding(
                get: { selectedCamera },
                set: { newCamera in
                    if currentCameraContext.hasUnsavedChanges {
                        pendingCameraSwitch = newCamera
                        showingSwitchCameraDialog = true
                    } else {
                        selectedCamera = newCamera
                        HapticFeedback.selection()
                    }
                }
            )) {
                ForEach(CameraType.allCases, id: \.self) { camera in
                    Text(camera.rawValue).tag(camera)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .accessibilityLabel("Camera Selection")
            .accessibilityHint("Choose which camera to configure")
            
            Divider()
            
            // Camera Settings Content
            if selectedCamera == .irisOne {
                CameraSettingsView(viewModel: irisOneViewModel)
                    .environmentObject(irisOneContext)
            } else {
                CameraSettingsView(viewModel: irisTwoViewModel)
                    .environmentObject(irisTwoContext)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay(
            ToastBannerOverlay(toastMessage: selectedCamera == .irisOne ? $irisOneContext.toastMessage : $irisTwoContext.toastMessage)
        )
        .alert("Unsaved Changes", isPresented: $showingSwitchCameraDialog) {
            Button("Save", role: .none) {
                Task {
                    await currentCameraContext.save()
                    if let pending = pendingCameraSwitch {
                        selectedCamera = pending
                        pendingCameraSwitch = nil
                        HapticFeedback.selection()
                    }
                }
            }
            Button("Discard", role: .destructive) {
                currentCameraContext.discard()
                if let pending = pendingCameraSwitch {
                    selectedCamera = pending
                    pendingCameraSwitch = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pendingCameraSwitch = nil
            }
        } message: {
            Text("You have unsaved changes. What would you like to do?")
        }
    }
    
    private var currentCameraContext: SettingsContext {
        selectedCamera == .irisOne ? irisOneContext : irisTwoContext
    }
    
    private var hasAnyUnsavedChanges: Bool {
        irisOneContext.hasUnsavedChanges || irisTwoContext.hasUnsavedChanges
    }
}
