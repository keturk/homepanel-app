import SwiftUI
import UniformTypeIdentifiers

struct BackupRestoreView: View {
    @ObservedObject var config: AppConfiguration
    @ObservedObject var pinService: PINManagementService
    let cameraConfigService: CameraConfigService
    @ObservedObject var hubConfigStore: HubConfigurationStore
    @ObservedObject var destinationStore: DestinationStore
    @EnvironmentObject var settingsContext: SettingsContext
    
    @StateObject private var backupService = SettingsBackupService()
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var exportURL: URL?
    @State private var toastMessage: ToastMessage?
    @State private var showingImportAlert = false
    @State private var importURL: URL?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up.on.square.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Backup & Restore")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Export your settings to a file, or import from a previous backup. This allows you to restore your configuration after reinstalling the app.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                Divider()
                
                // Export Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Export Settings")
                        .font(.headline)
                    
                    Text("Create a backup file containing all your settings, including hub configurations, camera settings, PINs, scene mappings, and favorite destinations.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        HapticFeedback.buttonPress()
                        Task {
                            await exportSettings()
                        }
                    }) {
                        HStack {
                            if backupService.isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text(backupService.isExporting ? "Exporting..." : "Export Settings")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(backupService.isExporting)
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                .cornerRadius(12)
                
                // Import Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Import Settings")
                        .font(.headline)
                    
                    Text("Restore your settings from a previously exported backup file. This will replace your current settings.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        HapticFeedback.buttonPress()
                        showingImportPicker = true
                    }) {
                        HStack {
                            if backupService.isImporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                            }
                            Text(backupService.isImporting ? "Importing..." : "Import Settings")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(backupService.isImporting)
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                .cornerRadius(12)
                
                // Warning
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Important")
                            .font(.headline)
                        Text("Importing will replace all current settings. Make sure to export a backup first if you want to keep your current configuration.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
        .overlay(
            ToastBannerOverlay(toastMessage: $toastMessage)
        )
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importURL = url
                    showingImportAlert = true
                }
            case .failure(let error):
                toastMessage = ToastMessage(
                    title: "Import Failed",
                    message: error.localizedDescription,
                    type: .error
                )
                HapticFeedback.error()
            }
        }
        .alert("Import Settings", isPresented: $showingImportAlert) {
            Button("Import", role: .destructive) {
                if let url = importURL {
                    Task {
                        await importSettings(from: url)
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                importURL = nil
            }
        } message: {
            Text("This will replace all your current settings with the settings from the backup file. This action cannot be undone.")
        }
    }
    
    // MARK: - Export
    
    private func exportSettings() async {
        do {
            let url = try await backupService.exportAllSettings(
                hubConfigStore: hubConfigStore,
                cameraConfigService: cameraConfigService,
                pinService: pinService,
                appConfig: config,
                destinationStore: destinationStore
            )
            
            await MainActor.run {
                exportURL = url
                showingExportSheet = true
                toastMessage = ToastMessage(
                    title: "Export Successful",
                    message: "Settings exported successfully. Share the file to save it.",
                    type: .success
                )
                HapticFeedback.success()
            }
        } catch {
            await MainActor.run {
                toastMessage = ToastMessage(
                    title: "Export Failed",
                    message: error.localizedDescription,
                    type: .error
                )
                HapticFeedback.error()
            }
        }
    }
    
    // MARK: - Import
    
    private func importSettings(from url: URL) async {
        do {
            // Need to access the URL's security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            try await backupService.importSettings(
                from: url,
                hubConfigStore: hubConfigStore,
                cameraConfigService: cameraConfigService,
                pinService: pinService,
                appConfig: config,
                destinationStore: destinationStore
            )
            
            await MainActor.run {
                toastMessage = ToastMessage(
                    title: "Import Successful",
                    message: "All settings have been restored from the backup file.",
                    type: .success
                )
                HapticFeedback.success()
                importURL = nil
            }
        } catch {
            await MainActor.run {
                toastMessage = ToastMessage(
                    title: "Import Failed",
                    message: error.localizedDescription,
                    type: .error
                )
                HapticFeedback.error()
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

