import SwiftUI
import Foundation
import Combine

// MARK: - Tab Enum

enum Tab: String, Hashable, CaseIterable {
    case alarm = "Alarm"
    case irisOne = "Iris One"
    case irisTwo = "Iris Two"
    case automation = "Automation"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .alarm: return "shield.fill"
        case .irisOne: return "video.fill"
        case .irisTwo: return "video.fill"
        case .automation: return "house.fill"
        case .settings: return "gear"
        }
    }
    
    var tag: Int {
        switch self {
        case .alarm: return 0
        case .irisOne: return 1
        case .irisTwo: return 2
        case .automation: return 3
        case .settings: return 4
        }
    }
}

// MARK: - Main App Entry Point

@main
struct HomePanelApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @StateObject private var config: AppConfiguration
    @StateObject private var alarmViewModel: AlarmViewModel
    @State private var selectedTab: Tab = .alarm
    @State private var showingMasterPINForSettings = false
    @State private var masterPINVerifiedForSettings = false
    @State private var showingUnsavedChangesDialog = false
    @State private var pendingTabSwitch: Tab? = nil
    @State private var settingsContext: SettingsContext?
    @State private var settingsLastAccessTime: Date? = nil
    @State private var settingsInactivityCancellable: AnyCancellable? = nil
    
    // Cache the tab views to prevent recreation
    @State private var alarmTabView: AlarmTabView?
    @State private var irisOneTabView: CameraTabView?
    @State private var irisTwoTabView: CameraTabView?
    @State private var automationTabView: AutomationTabView?
    @State private var settingsTabView: SettingsSplitView?
    @State private var cameraTabRefreshKey: UUID = UUID()
    @State private var dependencyContainer: DependencyContainer?
    
    // Dynamic camera names
    @State private var cameraOneName: String = "Camera 1"
    @State private var cameraTwoName: String = "Camera 2"
    
    init() {
        // Use the shared dependency container which has a single PINManagementService instance
        let dependencyContainer = DependencyContainer.shared
        let config = dependencyContainer.getConfig()

        // Create hub service and set it in the container to ensure same instance
        let hubService = dependencyContainer.getHubService()
        dependencyContainer.setHubService(hubService)

        // Load existing hubs and set primary hub BEFORE creating AlarmViewModel
        let hubConfigStore = dependencyContainer.getHubConfigStore()
        let existingHubs = hubConfigStore.getAllHubs()
        (config as! AppConfiguration).autoSelectPrimaryHub(from: existingHubs)
        DebugLogger.log("Primary hub set to: \(config.primaryHubId ?? "nil") before AlarmViewModel creation", feature: .hubService)

        DebugLogger.log("🔍 Creating StateObjects...", feature: .hubService)
        _config = StateObject(wrappedValue: config as! AppConfiguration)
        DebugLogger.log("✅ Config StateObject created", feature: .hubService)

        DebugLogger.log("🔍 Creating AlarmViewModel...", feature: .hubService)
        let alarmVM = dependencyContainer.createAlarmViewModel()
        DebugLogger.log("✅ AlarmViewModel instance created", feature: .hubService)
        _alarmViewModel = StateObject(wrappedValue: alarmVM)
        DebugLogger.log("✅ AlarmViewModel StateObject wrapped", feature: .hubService)
        _dependencyContainer = State(initialValue: dependencyContainer)

        // Initialize hub service
        Task {
            await Self.initializeHubService(dependencyContainer)
        }
    }
    
    private static func initializeHubService(_ container: DependencyContainer) async {
        DebugLogger.log("Initializing hub service...", feature: .hubService)
        let hubService = container.getHubService()
        let hubConfigStore = container.getHubConfigStore()
        let appConfig = container.getConfig() as? AppConfiguration

        // Load existing hubs from storage (if any)
        let existingHubs = hubConfigStore.getAllHubs()
        DebugLogger.log("Found \(existingHubs.count) existing hubs", feature: .hubService)

        // Auto-select primary hub if needed
        if let appConfig = appConfig {
            await MainActor.run {
                appConfig.autoSelectPrimaryHub(from: existingHubs)
            }
        }

        // Register all configured hubs with timeout handling
        for config in existingHubs {
            if config.isEnabled {
                DebugLogger.log("Registering hub: \(config.name) (\(config.hubId))", feature: .hubService)
                let adapter = config.createAdapter()
                
                // Register hub with timeout to prevent hanging
                do {
                    try await withTimeout(seconds: TimeoutConfiguration.automationRoomMapping) {
                        await hubService.registerHub(adapter, configuration: config)
                    }
                    DebugLogger.log("✅ Successfully registered hub: \(config.name)", feature: .hubService)
                } catch {
                    DebugLogger.log("⚠️ Failed to register hub \(config.name): \(error.localizedDescription)", feature: .hubService)
                    // Continue with other hubs even if one fails
                }
            } else {
                DebugLogger.log("Skipping disabled hub: \(config.name)", feature: .hubService)
            }
        }

        // Refresh room mappings once after all hubs are registered (with timeout)
        DebugLogger.log("Refreshing room mappings after hub registration...", feature: .hubService)
        do {
            try await withTimeout(seconds: TimeoutConfiguration.roomMapping) {
                await hubService.refreshRoomMappingsAfterRegistration()
            }
            DebugLogger.log("✅ Room mappings refreshed successfully", feature: .hubService)
        } catch {
            DebugLogger.log("⚠️ Failed to refresh room mappings: \(error.localizedDescription)", feature: .hubService)
            // Continue anyway - fallback room mappings will be used
        }

        // Start the hub service
        DebugLogger.log("Starting hub service...", feature: .hubService)
        await hubService.start()
        DebugLogger.success("Hub service initialization complete", feature: .hubService)
    }
    
    /// Timeout wrapper for async operations
    /// Uses a result enum to prevent cancellation errors from propagating
    private static func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: TimeoutResult<T>.self) { group in
            // Add the actual operation - capture its result or error
            group.addTask {
                do {
                    let result = try await operation()
                    return .completed(result)
                } catch {
                    return .failed(error)
                }
            }

            // Add the timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return .timedOut
            }

            // Wait for the first result
            guard let firstResult = try await group.next() else {
                throw TimeoutError()
            }

            // Cancel remaining tasks (won't affect already-completed operation)
            group.cancelAll()

            // Process the result
            switch firstResult {
            case .completed(let value):
                return value
            case .failed(let error):
                throw error
            case .timedOut:
                throw TimeoutError()
            }
        }
    }

    /// Internal result type for timeout wrapper
    private enum TimeoutResult<T: Sendable>: Sendable {
        case completed(T)
        case failed(Error)
        case timedOut
    }
    
    
    var body: some View {
        ZStack {
            // Main content - keep all views in memory to prevent web view recreation
            Group {
                // Alarm Tab
                if let alarmTab = alarmTabView {
                    alarmTab
                        .environmentObject(DependencyContainer.shared.getPINManagementService() as! PINManagementService)
                        .opacity(selectedTab == .alarm ? 1 : 0)
                        .allowsHitTesting(selectedTab == .alarm)
                }
                
                // Iris One Tab
                if let irisOneTab = irisOneTabView {
                    irisOneTab
                        .opacity(selectedTab == .irisOne ? 1 : 0)
                        .allowsHitTesting(selectedTab == .irisOne)
                        .id(cameraTabRefreshKey) // Force refresh when key changes
                }
                
                // Iris Two Tab
                if let irisTwoTab = irisTwoTabView {
                    irisTwoTab
                        .opacity(selectedTab == .irisTwo ? 1 : 0)
                        .allowsHitTesting(selectedTab == .irisTwo)
                        .id(cameraTabRefreshKey) // Force refresh when key changes
                }
                
                // Automation Tab
                if let automationTab = automationTabView {
                    automationTab
                        .opacity(selectedTab == .automation ? 1 : 0)
                        .allowsHitTesting(selectedTab == .automation)
                }
                
                // Settings Tab - only show if Master PIN verified
                if masterPINVerifiedForSettings {
                    if selectedTab == .settings {
                        if let settingsTab = settingsTabView {
                            settingsTab
                                .opacity(1)
                                .allowsHitTesting(true)
                                .onAppear {
                                    startSettingsInactivityTimer()
                                }
                                .onTapGesture {
                                    resetSettingsInactivityTimer()
                                }
                                .onChange(of: settingsContext?.hasUnsavedChanges) { _, hasChanges in
                                    // Reset timer when user is actively making changes
                                    if hasChanges == true {
                                        resetSettingsInactivityTimer()
                                    }
                                }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                customTabBar
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showingMasterPINForSettings) {
            MasterPINEntryView(
                onVerify: { _ in
                    showingMasterPINForSettings = false
                    masterPINVerifiedForSettings = true
                    selectedTab = .settings
                },
                onCancel: {
                    showingMasterPINForSettings = false
                },
                pinService: DependencyContainer.shared.getPINManagementService()
            )
        }
        .alert("Unsaved Changes", isPresented: $showingUnsavedChangesDialog) {
            Button("Save", role: .none) {
                Task {
                    if let context = settingsContext {
                        await context.save()
                    }
                    if let pending = pendingTabSwitch {
                        selectedTab = pending
                        pendingTabSwitch = nil
                    }
                }
            }
            Button("Discard", role: .destructive) {
                settingsContext?.discard()
                if let pending = pendingTabSwitch {
                    selectedTab = pending
                    pendingTabSwitch = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pendingTabSwitch = nil
            }
        } message: {
            Text("You have unsaved changes. What would you like to do?")
        }
        .onAppear {
            // Initialize tab views only once to prevent recreation
            if alarmTabView == nil {
                alarmTabView = AlarmTabView(
                    config: config,
                    viewModel: alarmViewModel,
                    trafficService: DependencyContainer.shared.getTrafficService(),
                    destinationStore: DependencyContainer.shared.getDestinationStore()
                )
            }

            // Listen for camera configuration changes
            NotificationCenter.default.addObserver(
                forName: .cameraConfigurationChanged,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    loadCameraNames()
                    refreshCameraTabs()
                }
            }
            if irisOneTabView == nil, let container = dependencyContainer {
                irisOneTabView = CameraTabView(
                    cameraId: "iris_one",
                    configService: container.cameraConfigService,
                    pinService: container.getPINManagementService()
                )
            }
            if irisTwoTabView == nil, let container = dependencyContainer {
                irisTwoTabView = CameraTabView(
                    cameraId: "iris_two",
                    configService: container.cameraConfigService,
                    pinService: container.getPINManagementService()
                )
            }
            
            // Load camera names after camera tabs are initialized
            loadCameraNames()
            
            if automationTabView == nil, let container = dependencyContainer {
                automationTabView = AutomationTabView(
                    dependencyContainer: container,
                    pinService: container.getPINManagementService()
                )
            }
            if settingsTabView == nil, let container = dependencyContainer {
                let settingsView = SettingsSplitView(
                    config: config,
                    pinService: container.getPINManagementService() as! PINManagementService,
                    cameraConfigService: container.cameraConfigService as! CameraConfigService,
                    dependencyContainer: container
                )
                settingsTabView = settingsView
                // Access the settingsContext from the created view
                settingsContext = settingsView.settingsContext
            }
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabButton(
                    icon: tab.icon,
                    title: tabTitle(for: tab),
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                }
            }
        }
        .padding(.horizontal, DesignSystem.Layout.horizontalPadding)
        .padding(.top, DesignSystem.TabBar.topPadding)
        .padding(.bottom, DesignSystem.TabBar.bottomPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.TabBar.cornerRadius)
                .fill(alarmViewModel.currentState.backgroundColor)
                .shadow(
                    color: .black.opacity(DesignSystem.Opacity.shadow),
                    radius: 10,
                    x: 0,
                    y: -5
                )
        )
        .background(alarmViewModel.currentState.backgroundColor)
        .animation(.easeInOut(duration: 0.3), value: alarmViewModel.currentState)
    }
    
    private func tabButton(
        icon: String,
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            // Check if trying to access Settings tab - always require Master PIN
            if title == "Settings" {
                // Always require Master PIN authentication when switching to Settings
                masterPINVerifiedForSettings = false
                showingMasterPINForSettings = true
            } else if selectedTab == .settings && title != "Settings" {
                // Check for unsaved changes when leaving Settings tab
                if let context = settingsContext, context.hasUnsavedChanges {
                    pendingTabSwitch = Tab.allCases.first { $0.rawValue == title }
                    showingUnsavedChangesDialog = true
                } else {
                    // Clear settings authentication when leaving
                    masterPINVerifiedForSettings = false
                    settingsInactivityCancellable?.cancel()
                    settingsInactivityCancellable = nil
                    withAnimation(.easeInOut(duration: DesignSystem.Animation.standard)) {
                        action()
                    }
                }
            } else {
                withAnimation(.easeInOut(duration: DesignSystem.Animation.standard)) {
                    action()
                }
            }
        }) {
            VStack(spacing: DesignSystem.TabBar.itemSpacing) {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.TabBar.iconSize, weight: .bold))
                    .foregroundColor(isSelected ? DesignSystem.TabBar.selectedColor : DesignSystem.TabBar.unselectedColor)
                
                Text(title)
                    .font(.system(size: DesignSystem.TabBar.fontSize, weight: DesignSystem.TabBar.fontWeight))
                    .foregroundColor(isSelected ? DesignSystem.TabBar.selectedColor : DesignSystem.TabBar.unselectedColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.TabBar.height - DesignSystem.TabBar.topPadding - DesignSystem.TabBar.bottomPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint("Tap to switch to \(title) tab")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
    
    // MARK: - Settings Inactivity Timer
    
    private func startSettingsInactivityTimer() {
        settingsLastAccessTime = Date()
        settingsInactivityCancellable?.cancel()
        settingsInactivityCancellable = Timer.publish(every: 180, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [self] _ in
                selectedTab = .alarm
                masterPINVerifiedForSettings = false
                settingsInactivityCancellable = nil
            }
    }
    
    private func resetSettingsInactivityTimer() {
        settingsLastAccessTime = Date()
        settingsInactivityCancellable?.cancel()
        settingsInactivityCancellable = Timer.publish(every: 180, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [self] _ in
                selectedTab = .alarm
                masterPINVerifiedForSettings = false
                settingsInactivityCancellable = nil
            }
    }
    
    // MARK: - Camera Names Management
    
    private func loadCameraNames() {
        guard let container = dependencyContainer else { return }
        let configService = container.cameraConfigService
        
        if let config1 = configService.getConfiguration(for: "iris_one") {
            cameraOneName = config1.name
        }
        
        if let config2 = configService.getConfiguration(for: "iris_two") {
            cameraTwoName = config2.name
        }
    }
    
    private func tabTitle(for tab: Tab) -> String {
        switch tab {
        case .irisOne:
            return cameraOneName
        case .irisTwo:
            return cameraTwoName
        default:
            return tab.rawValue
        }
    }
    
    // MARK: - Camera Tab Refresh
    
    private func refreshCameraTabs() {
        // Force recreation of camera tabs by clearing them and updating the refresh key
        irisOneTabView = nil
        irisTwoTabView = nil
        cameraTabRefreshKey = UUID()
        
        // Always create camera tabs - they will show "Not Configured" if no config exists
        if let container = dependencyContainer {
            // Always create iris_one tab
            irisOneTabView = CameraTabView(
                cameraId: "iris_one",
                configService: container.cameraConfigService,
                pinService: container.getPINManagementService()
            )
            
            // Always create iris_two tab
            irisTwoTabView = CameraTabView(
                cameraId: "iris_two",
                configService: container.cameraConfigService,
                pinService: container.getPINManagementService()
            )
        }
    }
}


// MARK: - Preview

#Preview {
    ContentView()
}
