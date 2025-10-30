import Foundation
import SwiftUI
@preconcurrency import Combine

// MARK: - Alarm View Model

@MainActor
class AlarmViewModel: ObservableObject {
    // MARK: - Constants

    /// Duration for countdown timer (in seconds)
    /// Note: Scenes like "Set Away", "Set Stay", "Set Night-Stay" first disarm (0s),
    /// wait 2 seconds, then switch to intended mode. We add extra time for hub processing.
    private static let countdownDuration: Int = 5
    
    /// Delay for clearing wrong PIN trigger (in seconds)
    private static let wrongPINClearDelay: Double = 0.1
    
    /// Timer interval for countdown updates (in seconds)
    private static let countdownTimerInterval: Double = 1.0
    
    // MARK: - Published Properties
    
    @Published var currentState: AlarmState = .unknown
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showPINEntry = false
    @Published var pendingMode: AlarmMode?
    @Published var triggerWrongPIN = false
    @Published var lastUpdated: Date = Date()
    @Published var pinErrorMessage: String?
    @Published var countdownSeconds: Int = 0
    @Published var isCountdownActive: Bool = false
    
    // MARK: - Private Properties
    
    private let sceneService: SceneServiceProtocol
    private let alarmService: VeraHubAlarmServiceProtocol
    private let config: AppConfigurationProtocol
    private let pinService: any PINManagementServiceProtocol
    private let lockoutService: AlarmLockoutService
    private var refreshCancellable: AnyCancellable?
    private var refreshTask: Task<Void, Never>?
    private var countdownCancellable: AnyCancellable?
    private var lockoutEventSubscription: AnyCancellable?
    private var stateChangeSubscription: AnyCancellable?
    
    // MARK: - Initialization
    
    init(config: AppConfigurationProtocol,
         sceneService: SceneServiceProtocol,
         alarmService: VeraHubAlarmServiceProtocol,
         pinService: any PINManagementServiceProtocol,
         lockoutService: AlarmLockoutService = AlarmLockoutService()) {
        self.config = config
        self.sceneService = sceneService
        self.alarmService = alarmService
        self.pinService = pinService
        self.lockoutService = lockoutService

        // Debug: Print current configuration
        AlarmDebugUtils.printConfiguration(config: config)

        // Clear any old lockout state from previous version
        let consecutiveFailures = lockoutService.getConsecutiveFailures()
        if consecutiveFailures > 0 && consecutiveFailures < 7 {
            DebugLogger.log("Detected old lockout state with \(consecutiveFailures) attempts - clearing for new behavior", feature: .alarm)
            lockoutService.clearLockoutState()
        }

        // Note: Don't fetch scene list at startup - hubs might not be registered yet
        // Scene list will be fetched when first state change arrives

        // Subscribe to real-time state changes from the alarm service
        // This will automatically update UI when device cache is populated
        subscribeToStateChanges()

        // Subscribe to lockout events using the new publisher
        lockoutEventSubscription = LockoutEventPublisher.shared.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .lockoutsReset:
                    self?.lockoutService.reloadLockoutState()
                case .lockoutStateChanged, .lockoutCleared, .lockoutExpired:
                    // These events are handled by the lockout service itself
                    break
                }
            }
    }
    
    
    deinit {
        // Cancel Combine subscriptions
        refreshCancellable?.cancel()
        countdownCancellable?.cancel()
        stateChangeSubscription?.cancel()

        // Cancel any pending refresh task
        refreshTask?.cancel()
        refreshTask = nil

        // Cancel lockout event subscription
        lockoutEventSubscription?.cancel()
        lockoutEventSubscription = nil

        DebugLogger.log("AlarmViewModel deallocated - automatic cleanup", feature: .alarm)
    }
    
    // MARK: - Public Methods
    
    func changeMode(_ mode: AlarmMode) {
        // Check if we're locked out
        if lockoutService.isLockedOut() {
            DebugLogger.lockout("Cannot change mode - locked out until \(lockoutService.getRemainingLockoutTime())", feature: .alarm)
            return
        }
        
        // Check if primary hub is configured
        guard let primaryHubId = config.primaryHubId else {
            errorMessage = "No primary hub configured. Please configure a primary hub in settings."
            return
        }
        
        // Check if scene map is available for the primary hub
        let primaryHubScenes = config.hubScopedSceneMap.getScenes(forHub: primaryHubId)
        DebugLogger.log("🔍 [AlarmViewModel] Checking scene availability for hub \(primaryHubId): \(primaryHubScenes.count) scenes", feature: .alarm)
        
        if primaryHubScenes.isEmpty {
            DebugLogger.log("🔍 [AlarmViewModel] No scenes available, attempting to fetch scenes for mode: \(mode)", feature: .alarm)
            // Try to fetch scenes before showing error
            Task {
                await fetchSceneList()
                
                // Check again after fetching
                let updatedScenes = config.hubScopedSceneMap.getScenes(forHub: primaryHubId)
                DebugLogger.log("🔍 [AlarmViewModel] After fetch attempt: \(updatedScenes.count) scenes available", feature: .alarm)
                
                if updatedScenes.isEmpty {
                    DebugLogger.error("❌ [AlarmViewModel] Still no scenes available after fetch attempt", feature: .alarm)
                    await MainActor.run {
                        errorMessage = "No scenes found on primary hub. Alarm mode changes may not work properly."
                    }
                } else {
                    DebugLogger.log("✅ [AlarmViewModel] Scenes now available, proceeding with PIN entry for mode: \(mode)", feature: .alarm)
                    // Scenes are now available, proceed with PIN entry
                    await MainActor.run {
                        pendingMode = mode
                        showPINEntry = true
                    }
                }
            }
            return
        }
        
        DebugLogger.log("✅ [AlarmViewModel] Scenes available, proceeding with PIN entry for mode: \(mode)", feature: .alarm)
        
        pendingMode = mode
        showPINEntry = true
    }
    
    func verifyPIN(_ pin: String) {
        guard let mode = pendingMode else { return }
        
        // Verify PIN using the PIN management service
        let isValid = pinService.verifyAnyPIN(pin)
        
        AlarmDebugUtils.printPINVerificationResult(success: isValid, mode: mode)
        
        if isValid {
            // PIN is valid, proceed with mode change
            lockoutService.recordSuccessfulAttempt()
            
            // Close PIN entry immediately and show feedback
            showPINEntry = false
            pendingMode = nil
            
            // Show immediate feedback that PIN was accepted
            Task { @MainActor in
                isLoading = true
                errorMessage = "Refreshing"
            }
            
            Task {
                await performModeChange(mode)
                
                // Start 5-second countdown timer (no immediate refresh)
                await MainActor.run {
                    startCountdownTimer()
                }
            }
        } else {
            // PIN is invalid, record failed attempt and show error
            lockoutService.recordFailedAttempt()
            triggerWrongPIN = true
            
            // Show appropriate error message based on attempt count
            if lockoutService.isLockedOut() {
                let lockoutTime = lockoutService.getRemainingLockoutTime()
                pinErrorMessage = "🔒 LOCKED OUT\nToo many failed attempts.\nTry again in \(lockoutTime)"
            } else {
                let attemptsInCurrentRound = lockoutService.getConsecutiveFailures() % 7
                let attemptsRemaining = 7 - attemptsInCurrentRound
                if attemptsRemaining > 1 {
                    pinErrorMessage = "Invalid PIN. \(attemptsRemaining) attempts remaining."
                } else if attemptsRemaining == 1 {
                    pinErrorMessage = "Invalid PIN. 1 attempt remaining before lockout."
                } else {
                    pinErrorMessage = "Invalid PIN. Please try again."
                }
            }
            
            // Clear the wrong PIN trigger after a short delay
            Task {
                try await Task.sleep(nanoseconds: UInt64(Self.wrongPINClearDelay * 1_000_000_000))
                await MainActor.run {
                    self.triggerWrongPIN = false
                }
            }
        }
    }
    
    func cancelPINEntry() {
        showPINEntry = false
        pendingMode = nil
        pinErrorMessage = nil
    }
    
    func startCountdownTimer() {
        stopCountdownTimer()

        countdownSeconds = Self.countdownDuration
        isCountdownActive = true

        countdownCancellable = Timer.publish(every: Self.countdownTimerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }

                if self.countdownSeconds > 1 {
                    self.countdownSeconds -= 1
                } else {
                    // Countdown finished - state will update automatically via subscription
                    self.stopCountdownTimer()
                    DebugLogger.log("Countdown complete - waiting for state change event", feature: .alarm)
                }
            }

        DebugLogger.timer("Countdown timer started - \(Self.countdownDuration) seconds", feature: .alarm)
    }

    func stopCountdownTimer() {
        countdownCancellable?.cancel()
        countdownCancellable = nil
        isCountdownActive = false
        countdownSeconds = 0

        DebugLogger.timer("Countdown timer stopped", feature: .alarm)
    }
    
    // MARK: - Computed Properties
    
    var isLockedOut: Bool {
        return lockoutService.isLockedOut()
    }
    
    var remainingLockoutTime: String {
        return lockoutService.getRemainingLockoutTime()
    }
    
    // MARK: - Private Methods

    private func performModeChange(_ mode: AlarmMode) async {
        guard let primaryHubId = config.primaryHubId else {
            await MainActor.run {
                errorMessage = "No primary hub configured"
                isLoading = false
            }
            return
        }
        
        AlarmDebugUtils.printModeChangeAttempt(mode: mode, sceneMap: config.hubScopedSceneMap.getScenes(forHub: primaryHubId))

        do {
            try await sceneService.setAlarmMode(mode, hubScopedSceneMap: config.hubScopedSceneMap, hubId: primaryHubId)
            AlarmDebugUtils.printModeChangeSuccess(mode: mode)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to change mode: \(error.localizedDescription)"
                isLoading = false
            }
            AlarmDebugUtils.printModeChangeError(mode: mode, error: error)
        }
    }
    
    private func fetchSceneList() async {
        DebugLogger.log("🔍 [AlarmViewModel] Starting scene list fetch", feature: .alarm)
        
        guard let primaryHubId = config.primaryHubId else {
            DebugLogger.error("❌ [AlarmViewModel] No primary hub configured", feature: .alarm)
            await MainActor.run {
                errorMessage = "No primary hub configured. Please configure a primary hub in settings."
            }
            return
        }
        
        DebugLogger.log("🔍 [AlarmViewModel] Fetching scenes for primary hub: \(primaryHubId)", feature: .alarm)
        
        do {
            let hubScopedSceneMap = try await sceneService.fetchSceneList(hubId: primaryHubId)
            DebugLogger.log("✅ [AlarmViewModel] Successfully fetched scene map from service", feature: .alarm)
            
            await MainActor.run {
                DebugLogger.log("🔍 [AlarmViewModel] Starting scene map merge process", feature: .alarm)
                
                // Merge the new scene map with existing hub-scoped scene map
                var mergedSceneMap = config.hubScopedSceneMap
                let allHubIds = hubScopedSceneMap.getAllHubIds()
                DebugLogger.log("🔍 [AlarmViewModel] Merging scenes from \(allHubIds.count) hubs", feature: .alarm)
                
                for hubId in allHubIds {
                    let scenes = hubScopedSceneMap.getScenes(forHub: hubId)
                    DebugLogger.log("🔍 [AlarmViewModel] Processing \(scenes.count) scenes for hub: \(hubId)", feature: .alarm)
                    
                    for (sceneName, hubScopedSceneId) in scenes {
                        if let originalSceneId = HubScopedID.extractSceneID(from: hubScopedSceneId) {
                            mergedSceneMap.addScene(hubId: hubId, sceneName: sceneName, sceneId: originalSceneId)
                            DebugLogger.log("✅ [AlarmViewModel] Added scene '\(sceneName)' (ID: \(originalSceneId)) for hub \(hubId)", feature: .alarm)
                        } else {
                            DebugLogger.warning("⚠️ [AlarmViewModel] Failed to extract scene ID from: \(hubScopedSceneId)", feature: .alarm)
                        }
                    }
                }
                
                config.updateSceneMap(mergedSceneMap)
                DebugLogger.log("✅ [AlarmViewModel] Scene map updated successfully", feature: .alarm)
                
                // Clear any previous error if scene fetching succeeds
                let primaryHubScenes = config.hubScopedSceneMap.getScenes(forHub: primaryHubId)
                if !primaryHubScenes.isEmpty {
                    errorMessage = nil
                    DebugLogger.log("✅ [AlarmViewModel] Cleared error message - scenes available", feature: .alarm)
                }
            }
            
            AlarmDebugUtils.printSceneMapStatus(sceneMap: config.hubScopedSceneMap.getScenes(forHub: primaryHubId))
            
            // If scene map is empty, show a warning but don't treat it as an error
            let primaryHubScenes = config.hubScopedSceneMap.getScenes(forHub: primaryHubId)
            if primaryHubScenes.isEmpty {
                DebugLogger.warning("⚠️ [AlarmViewModel] Scene map is empty for primary hub - alarm mode changes will fail", feature: .alarm)
                await MainActor.run {
                    errorMessage = "No scenes found on primary hub. Alarm mode changes may not work properly."
                }
            } else {
                DebugLogger.log("✅ [AlarmViewModel] Scene map populated with \(primaryHubScenes.count) scenes", feature: .alarm)
                // Clear any previous error if we successfully loaded scenes
                await MainActor.run {
                    errorMessage = nil
                }
            }
        } catch {
            DebugLogger.error("❌ [AlarmViewModel] Scene fetching failed: \(error.localizedDescription)", feature: .alarm)
            
            // If hub not found, it might still be registering - don't show error yet
            // The next refresh will retry
            if case HubError.hubNotFound = error {
                DebugLogger.log("🔍 [AlarmViewModel] Hub not registered yet, will retry on next refresh", feature: .alarm)
            } else {
                await MainActor.run {
                    errorMessage = "Failed to load scene configuration: \(error.localizedDescription)"
                }
                AlarmDebugUtils.printErrorState(error: "Failed to load scene configuration: \(error.localizedDescription)")
            }
        }
    }
    
    private func subscribeToStateChanges() {
        // Set loading state while waiting for first state change
        isLoading = true
        
        stateChangeSubscription = alarmService.subscribeToStateChanges()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (newState: AlarmState) in
                guard let self = self else { return }

                // Update state on first event (unknown -> actual state) or when state changes
                if self.currentState == .unknown {
                    DebugLogger.success("Initial alarm state loaded from subscription: \(newState)", feature: .alarm)
                    self.currentState = newState
                    self.lastUpdated = Date()
                    self.isLoading = false
                    
                    // Fetch scene list on first state change (when hub is ready)
                    Task {
                        await self.fetchSceneList()
                    }
                } else if self.currentState != newState {
                    DebugLogger.log("Real-time alarm state update: \(self.currentState) -> \(newState)", feature: .alarm)
                    self.currentState = newState
                    self.lastUpdated = Date()
                    self.isLoading = false
                }

                // Clear temporary error messages
                if self.errorMessage == "Refreshing" {
                    self.errorMessage = nil
                }
            }

        DebugLogger.log("Subscribed to real-time alarm state changes - waiting for first event...", feature: .alarm)
        
        // Add timeout to prevent infinite loading state
        // If no state change is received within 10 seconds, reset loading state
        Task {
            try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            await MainActor.run {
                if self.isLoading && self.currentState == .unknown {
                    DebugLogger.warning("No initial alarm state received within 10 seconds - resetting loading state", feature: .alarm)
                    self.isLoading = false
                    self.errorMessage = "Unable to connect to alarm system"
                }
            }
        }
    }

    // MARK: - Lockout Management

    func resetAllLockouts(pinService: any PINManagementServiceProtocol) {
        lockoutService.resetAllLockouts(pinService: pinService)
    }
}

// MARK: - Lockout Event Handling
// Note: Lockout events are now handled through the LockoutEventPublisher
