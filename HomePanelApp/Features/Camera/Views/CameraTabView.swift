import SwiftUI

// MARK: - Camera Tab View

struct CameraTabView: View {
    @StateObject private var viewModel: CameraViewModel
    
    init(cameraId: String, configService: CameraConfigServiceProtocol, pinService: any PINManagementServiceProtocol) {
        _viewModel = StateObject(
            wrappedValue: CameraViewModel(
                cameraId: cameraId,
                configService: configService,
                pinService: pinService
            )
        )
    }
    
    var body: some View {
        ZStack {
            if viewModel.isConfigured {
                cameraWebView
            } else {
                notConfiguredView
            }
            
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showPINEntry) {
            pinEntrySheet
                // PIN entry should allow dismissal (authentication, not data entry)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var cameraWebView: some View {
        CameraWebView(url: viewModel.webViewURL) { url in
            viewModel.handleURLChange(url)
        }
        .id(viewModel.webViewKey)
        .refreshable {
            viewModel.refresh()
        }
    }
    
    private var notConfiguredView: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Image(systemName: "video.slash")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.secondary)
            
            Text("Not Configured")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Tap the settings icon to configure this Blue Iris connection")
                .font(.body)
                .foregroundColor(DesignSystem.Colors.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.extraLarge)
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
        }
    }
    
    
    private var pinEntrySheet: some View {
        PINEntryView(
            mode: "Enter Master PIN",
            onSubmit: { pin in
                Task {
                    await viewModel.verifyPIN(pin)
                }
            },
            onCancel: {
                viewModel.showPINEntry = false
            },
            onWrongPIN: nil,
            triggerWrongPIN: false,
            pinService: viewModel.pinService,
            isLockedOut: false,
            remainingLockoutTime: "",
            onShowError: nil,
            pinErrorMessage: .constant(nil)
        )
    }
    
}