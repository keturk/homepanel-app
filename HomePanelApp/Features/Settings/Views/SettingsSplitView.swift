import SwiftUI

struct SettingsSplitView: View {
    @ObservedObject var config: AppConfiguration
    @ObservedObject var pinService: PINManagementService
    let cameraConfigService: CameraConfigService
    @StateObject var automationViewModel: AutomationViewModel
    @StateObject var settingsContext = SettingsContext()
    @ObservedObject var hubConfigStore: HubConfigurationStore
    @ObservedObject var destinationStore: DestinationStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSetting: SettingsMenuItem? = .pinManagement
    @State private var leftPaneWidth: CGFloat = 300 // Default 1/3 of screen
    @State private var showingSaveDiscardDialog = false
    @State private var pendingNavigation: (() -> Void)? = nil
    @State private var isDragging = false
    @State private var isHovering = false
    @State private var dragStartWidth: CGFloat = 0

    // Constants
    private let userDefaultsKey = "settingsSplitViewLeftPaneWidth"
    private let minimumLeftPaneWidth: CGFloat = 200
    private let minimumRightPaneWidth: CGFloat = 200
    private let dividerHitboxWidth: CGFloat = 20

    init(config: AppConfiguration, pinService: PINManagementService, cameraConfigService: CameraConfigService, dependencyContainer: DependencyContainer) {
        self.config = config
        self.pinService = pinService
        self.cameraConfigService = cameraConfigService
        self._hubConfigStore = ObservedObject(wrappedValue: dependencyContainer.getHubConfigStore())
        self._automationViewModel = StateObject(wrappedValue: dependencyContainer.createAutomationViewModel())
        self._destinationStore = ObservedObject(wrappedValue: dependencyContainer.getDestinationStore())
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left Pane - Settings List
                leftPane
                    .frame(width: leftPaneWidth)
                    .background(Color(UIColor.systemGroupedBackground))
                
                // Resizable Divider
                resizableDivider
                
                // Right Pane - Selected Setting Detail
                rightPane
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemBackground))
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Load saved width or set to 1/3 of screen
            let screenWidth = UIScreen.main.bounds.width
            let savedWidth = UserDefaults.standard.double(forKey: userDefaultsKey)
            
            if savedWidth > 0 {
                // Ensure saved width is within bounds
                let maxWidth = screenWidth - minimumRightPaneWidth
                leftPaneWidth = max(minimumLeftPaneWidth, min(savedWidth, maxWidth))
            } else {
                leftPaneWidth = screenWidth / 3
            }
        }
        .alert("Unsaved Changes", isPresented: $showingSaveDiscardDialog) {
            Button("Save", role: .none) {
                Task {
                    await settingsContext.save()
                    pendingNavigation?()
                    pendingNavigation = nil
                }
            }
            Button("Discard", role: .destructive) {
                settingsContext.discard()
                pendingNavigation?()
                pendingNavigation = nil
            }
            Button("Cancel", role: .cancel) {
                pendingNavigation = nil
            }
        } message: {
            Text("You have unsaved changes. What would you like to do?")
        }
    }
    
    // MARK: - Resizable Divider
    
    private var resizableDivider: some View {
        GeometryReader { geometry in
            ZStack {
                // Background for the divider area
                Rectangle()
                    .fill(Color.gray.opacity(isHovering || isDragging ? 0.1 : 0.05))
                    .frame(width: dividerHitboxWidth)
                
                // Visual divider line
                Rectangle()
                    .fill(Color.gray.opacity(isDragging ? 0.8 : 0.4))
                    .frame(width: 3)
                    .opacity(isHovering || isDragging ? 1.0 : 0.8)
                
                // Drag handle area (invisible but wider for easier interaction)
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: dividerHitboxWidth)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        isHovering = hovering
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: dividerHitboxWidth)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        dragStartWidth = leftPaneWidth
                    }
                    
                    let screenWidth = UIScreen.main.bounds.width
                    let newWidth = dragStartWidth + value.translation.width
                    let maxWidth = screenWidth - minimumRightPaneWidth
                    
                    // Apply constraints
                    leftPaneWidth = max(minimumLeftPaneWidth, min(newWidth, maxWidth))
                }
                .onEnded { _ in
                    isDragging = false
                    
                    // Save the new width to UserDefaults
                    UserDefaults.standard.set(leftPaneWidth, forKey: userDefaultsKey)
                }
        )
        .animation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping), value: leftPaneWidth)
    }
    
    // MARK: - Left Pane (Settings List)
    
    private var leftPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            
            Divider()
            
            // Settings List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(SettingsMenuItem.allCases, id: \.self) { item in
                        SettingsRowView(
                            item: item,
                            isSelected: selectedSetting == item,
                            onTap: {
                                if settingsContext.hasUnsavedChanges && selectedSetting != item {
                                    showingSaveDiscardDialog = true
                                    pendingNavigation = {
                                        selectedSetting = item
                                    }
                                    HapticFeedback.warning()
                                } else {
                                    selectedSetting = item
                                    HapticFeedback.navigation()
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Right Pane (Selected Setting Detail)
    
    private var rightPane: some View {
        VStack(spacing: 0) {
            // Toolbar for Save/Discard buttons - Fixed at top
            if settingsContext.hasUnsavedChanges {
                settingsToolbar
            }
            
            // Content - Scrollable to handle keyboard
            ScrollView {
                Group {
                    if let selectedSetting = selectedSetting {
                        selectedSetting.detailView(
                            config: config,
                            pinService: pinService,
                            cameraConfigService: cameraConfigService,
                            automationViewModel: automationViewModel,
                            settingsContext: settingsContext,
                            hubConfigStore: hubConfigStore,
                            destinationStore: destinationStore
                        )
                    } else {
                        // Default view when no setting is selected
                        VStack {
                            Image(systemName: "gear")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("Select a setting from the list")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .overlay(
                    ToastBannerOverlay(toastMessage: $settingsContext.toastMessage)
                )
            }
        }
    }
    
    private var settingsToolbar: some View {
        HStack {
            Spacer()
            
            Button("Discard") {
                settingsContext.discard()
                HapticFeedback.buttonPress()
            }
            .buttonStyle(.bordered)
            .disabled(settingsContext.isSaving)
            .controlSize(.large)
            
            Button("Save") {
                HapticFeedback.buttonPress()
                Task {
                    await settingsContext.save()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(settingsContext.isSaving)
            .controlSize(.large)
            .overlay(
                Group {
                    if settingsContext.isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(UIColor.systemGroupedBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .bottom
        )
        .zIndex(1) // Ensure toolbar stays above content
    }
}

// MARK: - Settings Item Enum

enum SettingsMenuItem: String, CaseIterable {
    case pinManagement = "Alarm Users"
    case cameraSettings = "Cameras"
    case devicesAndScenes = "Devices & Scenes"
    case hubManagement = "Automation Hubs"
    case favoriteDestinations = "Favorite Destinations"
    case backupRestore = "Backup & Restore"
    case resetLockouts = "Reset Lockouts"
    case clearAllSettings = "Clear All Settings"

    var icon: String {
        switch self {
        case .pinManagement: return "key.fill"
        case .cameraSettings: return "video.fill"
        case .devicesAndScenes: return "lightbulb.fill"
        case .hubManagement: return "network"
        case .favoriteDestinations: return "location.fill"
        case .backupRestore: return "square.and.arrow.up.on.square.fill"
        case .resetLockouts: return "lock.open"
        case .clearAllSettings: return "exclamationmark.triangle.fill"
        }
    }
    
    @MainActor
    @ViewBuilder
    func detailView(
        config: AppConfiguration,
        pinService: any PINManagementServiceProtocol,
        cameraConfigService: CameraConfigService,
        automationViewModel: AutomationViewModel,
        settingsContext: SettingsContext,
        hubConfigStore: HubConfigurationStore,
        destinationStore: DestinationStore
    ) -> some View {
        switch self {
        case .pinManagement:
            PINManagementView(pinService: pinService as! PINManagementService)
                .environmentObject(settingsContext)
        case .cameraSettings:
            CameraManagementView(cameraConfigService: cameraConfigService)
                .environmentObject(settingsContext)
        case .devicesAndScenes:
            DeviceSelectionManagementView(viewModel: automationViewModel)
                .environmentObject(settingsContext)
        case .hubManagement:
            HubManagementView(config: config, hubConfigStore: hubConfigStore, hubService: automationViewModel.hubService)
        case .favoriteDestinations:
            DestinationManagementView(destinationStore: destinationStore)
        case .backupRestore:
            BackupRestoreView(
                config: config,
                pinService: pinService as! PINManagementService,
                cameraConfigService: cameraConfigService,
                hubConfigStore: hubConfigStore,
                destinationStore: destinationStore
            )
            .environmentObject(settingsContext)
        case .resetLockouts:
            ResetLockoutsView(pinService: pinService as! PINManagementService)
        case .clearAllSettings:
            ClearAllSettingsView(config: config, pinService: pinService as! PINManagementService, hubConfigStore: hubConfigStore)
        }
    }
}

// MARK: - Settings Row View

struct SettingsRowView: View {
    let item: SettingsMenuItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .blue : .primary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                isSelected ? Color.blue.opacity(0.1) : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Placeholder Views

struct ResetLockoutsView: View {
    @ObservedObject var pinService: PINManagementService
    @State private var showingAlert = false
    @State private var toastMessage: ToastMessage?
    @State private var isResetting = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.open")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Reset Lockouts")
                .font(.title)
                .fontWeight(.bold)
            
            Text("This will clear all PIN attempt counters and lockout timers for all users.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Reset All Lockouts") {
                showingAlert = true
                HapticFeedback.destructive()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isResetting)
            .overlay(
                Group {
                    if isResetting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            )
        }
        .padding()
        .overlay(
            ToastBannerOverlay(toastMessage: $toastMessage)
        )
        .alert("Reset Lockouts", isPresented: $showingAlert) {
            Button("Reset", role: .destructive) {
                isResetting = true
                HapticFeedback.destructive()
                
                Task {
                    let lockoutService = AlarmLockoutService()
                    lockoutService.resetAllLockouts(pinService: pinService)
                    
                    await MainActor.run {
                        isResetting = false
                        toastMessage = ToastMessage(title: "Lockouts reset successfully", message: "All PIN attempt counters and lockout timers have been cleared", type: .success)
                        HapticFeedback.success()
                    }
                }
            }
            Button("Cancel", role: .cancel) { 
                HapticFeedback.buttonPress()
            }
        } message: {
            Text("This will clear all PIN attempt counters and lockout timers. This action cannot be undone.")
        }
    }
}

struct ClearAllSettingsView: View {
    @ObservedObject var config: AppConfiguration
    @ObservedObject var pinService: PINManagementService
    let hubConfigStore: HubConfigurationStore
    @State private var showingAlert = false
    @State private var toastMessage: ToastMessage?
    @State private var isClearing = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Clear All Settings")
                .font(.title)
                .fontWeight(.bold)
            
            Text("This will clear all settings and reset the Master PIN to 123456. This action cannot be undone.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Clear All Settings") {
                showingAlert = true
                HapticFeedback.destructive()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isClearing)
            .overlay(
                Group {
                    if isClearing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            )
        }
        .padding()
        .overlay(
            ToastBannerOverlay(toastMessage: $toastMessage)
        )
        .alert("Clear All Settings", isPresented: $showingAlert) {
            Button("Clear", role: .destructive) {
                isClearing = true
                HapticFeedback.destructive()
                
                Task {
                    await clearAllSettings()
                    
                    await MainActor.run {
                        isClearing = false
                        toastMessage = ToastMessage(title: "Settings cleared successfully", message: "All settings have been cleared and Master PIN reset to 123456", type: .success)
                        HapticFeedback.success()
                    }
                }
            }
            Button("Cancel", role: .cancel) { 
                HapticFeedback.buttonPress()
            }
        } message: {
            Text("This will clear all settings and reset the Master PIN to 123456. This action cannot be undone.")
        }
    }
    
    private func clearAllSettings() async {
        // 1. Clear AppConfiguration settings
        config.resetToDefaults()
        
        // 2. Clear all user PINs and reset Master PIN
        await clearAllPINs()
        
        // 3. Clear camera settings
        await clearCameraSettings()
        
        // 4. Clear device & scenes settings
        await clearDeviceSettings()
        
        // 5. Clear hub configurations
        await clearHubConfigurations()
    }
    
    private func clearAllPINs() async {
        // Clear all user PINs
        let allPINs = pinService.getAllPINs()
        for pinData in allPINs {
            _ = pinService.removeUserPIN(pinData.id)
        }
        
        // Reset Master PIN to 123456
        _ = pinService.setMasterPIN("123456")
        
        // Clear lockout state
        pinService.clearLockoutState()
    }
    
    private func clearCameraSettings() async {
        // Clear camera configurations from Keychain (both config and passwords)
        let keychainService = KeychainService.shared
        try? keychainService.delete(key: "camera_config_iris_one")
        try? keychainService.delete(key: "camera_config_iris_two")
        try? keychainService.deleteCameraPassword(for: "iris_one")
        try? keychainService.deleteCameraPassword(for: "iris_two")
    }
    
    private func clearDeviceSettings() async {
        // Clear selected device names
        DebugLogger.log("🔍 [ClearAllSettings] Clearing device settings - before: \(config.selectedDeviceNames)", feature: .settings)
        config.updateSelectedDeviceNames([])
        DebugLogger.log("🔍 [ClearAllSettings] Clearing device settings - after: \(config.selectedDeviceNames)", feature: .settings)
    }
    
    private func clearHubConfigurations() async {
        // Clear all hub configurations using HubConfigurationStore
        DebugLogger.log("🔍 [ClearAllSettings] Clearing hub configurations", feature: .settings)
        do {
            try await hubConfigStore.clearAllConfigurations()
            DebugLogger.log("🔍 [ClearAllSettings] Hub configurations cleared via HubConfigurationStore", feature: .settings)
        } catch {
            DebugLogger.log("❌ [ClearAllSettings] Failed to clear hub configurations: \(error)", feature: .settings)
        }
    }
}

