import SwiftUI
import Combine

// MARK: - Alarm Tab View

struct AlarmTabView: View {
    @ObservedObject var config: AppConfiguration
    @ObservedObject var viewModel: AlarmViewModel
    @ObservedObject var trafficService: TrafficService
    @ObservedObject var destinationStore: DestinationStore
    @State private var timeUpdateTimer: Timer?
    @State private var timeUpdateTrigger: Int = 0

    init(config: AppConfiguration, viewModel: AlarmViewModel, trafficService: TrafficService, destinationStore: DestinationStore) {
        self.config = config
        self.viewModel = viewModel
        self.trafficService = trafficService
        self.destinationStore = destinationStore
    }
    
    var body: some View {
        ZStack {
            // Dynamic background based on current state
            currentState.backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: currentState)
            
            VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                // Header
                headerView
                
                // Three-Column Header
                threeColumnHeader
                
                // Mode Buttons Grid
                modeButtonsGrid

                // Traffic Information
                TrafficView(trafficService: trafficService, destinationStore: destinationStore)

                Spacer()

            }
            .padding(.top, 1) // Ensure safe area is respected at top

            // Wrong PIN Warning Overlay
            if viewModel.triggerWrongPIN {
                wrongPINWarningOverlay
            }
        }
                .sheet(isPresented: $viewModel.showPINEntry) {
                    PINEntryView(
                        mode: viewModel.pendingMode?.rawValue ?? "",
                        onSubmit: { pin in
                            viewModel.verifyPIN(pin)
                        },
                        onCancel: {
                            viewModel.cancelPINEntry()
                        },
                        onWrongPIN: {
                            // This is handled internally by the PINEntryView
                        },
                        triggerWrongPIN: viewModel.triggerWrongPIN,
                        pinService: config.pinService,
                        isLockedOut: viewModel.isLockedOut,
                        remainingLockoutTime: viewModel.remainingLockoutTime,
                        onShowError: { message in
                            // This will be handled by the PINEntryView's internal popup
                        },
                        pinErrorMessage: $viewModel.pinErrorMessage
                    )
                    // PIN entry should allow dismissal (authentication, not data entry)
                }
        .onTapGesture {
            // Clear error when tapping anywhere
            if viewModel.errorMessage != nil {
                viewModel.errorMessage = nil
            }
        }
        .onAppear {
            startTimeUpdateTimer()
        }
        .onDisappear {
            stopTimeUpdateTimer()
        }
        // Note: No need for onAppear refresh - initial fetch happens automatically in init
        // and all subsequent updates come via state change subscription
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: DesignSystem.Spacing.headerSpacing) {
            
            HStack {
                Spacer()
            }
        }
        .padding()
    }
    
    
    private var threeColumnHeader: some View {
        HStack(spacing: DesignSystem.Spacing.sectionSpacing) {
            // Left Column - Date (separate box)
            dateColumn
            
            // Middle Column - Alarm Status (separate box)
            statusColumn
            
            // Right Column - Time (separate box)
            timeColumn
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
    
    private var dateColumn: some View {
        VStack(spacing: DesignSystem.Spacing.countdownSpacing) {
            Text(currentDate.dayOfWeek)
                .font(.system(size: DesignSystem.FontSize.dateTimeSmall, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(currentDate.monthDay)
                .font(.system(size: DesignSystem.FontSize.dateDisplay, weight: .bold))
                .foregroundColor(.primary)
            
            Text(currentDate.year)
                .font(.system(size: DesignSystem.FontSize.dateTimeSmall, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120) // Fixed minimum height
        .padding(.vertical, DesignSystem.FrameSize.statusCardHeight)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.statusCard)
                .fill(Color.white.opacity(DesignSystem.Opacity.cardBackground))
                .shadow(color: .black.opacity(DesignSystem.Opacity.shadow), radius: DesignSystem.Shadow.radius, x: DesignSystem.Shadow.xOffset, y: DesignSystem.Shadow.yOffset)
        )
    }
    
    private var statusColumn: some View {
        VStack(spacing: DesignSystem.Spacing.statusSpacing) {
            // State Icon
            Image(systemName: currentState.iconName)
                .font(.system(size: DesignSystem.FontSize.extraLargeIconSize))
                .foregroundColor(currentState.displayColor)
                .symbolEffect(.bounce, value: currentState)
            
            // Status Text - Show concise status or current state
            Text(statusText)
                .font(.system(size: DesignSystem.FontSize.dateTimeMedium, weight: .semibold))
                .foregroundColor(statusColor)
                .multilineTextAlignment(.center)
            
            // Loading Indicator
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: statusColor))
                    .scaleEffect(DesignSystem.Scale.progressView)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120) // Fixed minimum height
        .padding(.vertical, DesignSystem.FrameSize.statusCardHeight)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.statusCard)
                .fill(Color.white.opacity(DesignSystem.Opacity.cardBackground))
                .shadow(color: .black.opacity(DesignSystem.Opacity.shadow), radius: DesignSystem.Shadow.radius, x: DesignSystem.Shadow.xOffset, y: DesignSystem.Shadow.yOffset)
        )
    }
    
    private var timeColumn: some View {
        VStack(spacing: DesignSystem.Spacing.countdownSpacing) {
            Text(currentTime.timeString)
                .font(.system(size: DesignSystem.FontSize.timeDisplay, weight: .bold))
                .foregroundColor(.primary)
            
            Text(currentTime.ampmString)
                .font(.system(size: DesignSystem.FontSize.dateTimeSmall, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120) // Fixed minimum height
        .padding(.vertical, DesignSystem.FrameSize.statusCardHeight)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.statusCard)
                .fill(Color.white.opacity(DesignSystem.Opacity.cardBackground))
                .shadow(color: .black.opacity(DesignSystem.Opacity.shadow), radius: DesignSystem.Shadow.radius, x: DesignSystem.Shadow.xOffset, y: DesignSystem.Shadow.yOffset)
        )
    }
    
    // MARK: - Status Text Logic
    
    private var statusText: String {
        if let error = viewModel.errorMessage {
            // Show concise error messages
            if error.contains("Failed to fetch") {
                return "Connection Error"
            } else if error.contains("Failed to change") {
                return "Change Failed"
            } else if error.contains("No scenes found") {
                return "Configuration Error"
            } else if error == "Refreshing" {
                return "Refreshing"
            } else {
                return "Error"
            }
        } else if viewModel.isLoading {
            return "Refreshing"
        } else {
            return currentState.rawValue
        }
    }
    
    private var statusColor: Color {
        if viewModel.errorMessage != nil {
            return .red
        } else if viewModel.isLoading {
            return currentState.displayColor
        } else {
            return currentState.displayColor
        }
    }
    
    private var modeButtonsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Grid.spacing) {
            ForEach(AlarmMode.allCases, id: \.self) { mode in
                ModeButton(
                    title: mode.rawValue,
                    icon: mode.iconName,
                    color: mode.buttonColor,
                    isDisabled: viewModel.isLoading
                ) {
                    viewModel.changeMode(mode)
                }
            }
        }
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Alarm mode selection")
        .accessibilityHint("Select an alarm mode by tapping one of the buttons")
    }
    
    
    // MARK: - Wrong PIN Warning Overlay
    
    private var wrongPINWarningOverlay: some View {
        ZStack {
            // Full screen dark background
            Color.black.opacity(DesignSystem.Opacity.modalBackground)
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss warning by tapping anywhere
                    viewModel.triggerWrongPIN = false
                }
            
            VStack(spacing: DesignSystem.Spacing.warningSpacing) {
                // Warning Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: DesignSystem.FontSize.extraLarge))
                    .foregroundColor(.red)
                    .scaleEffect(DesignSystem.Scale.warningIcon)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: viewModel.triggerWrongPIN)
                
                // Warning Text
                VStack(spacing: DesignSystem.Spacing.statusSpacing) {
                    Text("⚠️ WRONG PIN ⚠️")
                        .font(.system(size: DesignSystem.FontSize.warningTitle, weight: .bold))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    
                    Text("ACCESS DENIED")
                        .font(.system(size: DesignSystem.FontSize.tiny, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("This PIN will trigger security measures")
                        .font(.system(size: DesignSystem.FontSize.nano, weight: .medium))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Layout.horizontalPadding)
                }
                
                
                // Instructions
                Text("Tap anywhere to dismiss")
                    .font(.system(size: DesignSystem.FontSize.pico, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(DesignSystem.FrameSize.warningPadding)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: viewModel.triggerWrongPIN)
    }
    
    // MARK: - Helper Methods
    
    private func startTimeUpdateTimer() {
        stopTimeUpdateTimer()
        
        // Update time every minute
        timeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            // Force UI update by triggering a state change
            // This will cause the view to recompute currentTime
            DispatchQueue.main.async {
                self.timeUpdateTrigger += 1
            }
        }
    }
    
    private func stopTimeUpdateTimer() {
        timeUpdateTimer?.invalidate()
        timeUpdateTimer = nil
    }
    
    // MARK: - Computed Properties
    
    private var currentState: AlarmState {
        viewModel.currentState
    }
    
    private var currentDate: (dayOfWeek: String, monthDay: String, year: String) {
        let now = Date()
        let formatter = DateFormatter()
        
        // Use timeUpdateTrigger to force recomputation
        _ = timeUpdateTrigger
        
        formatter.dateFormat = "EEEE"
        let dayOfWeek = formatter.string(from: now)
        
        formatter.dateFormat = "MMM d"
        let monthDay = formatter.string(from: now)
        
        formatter.dateFormat = "yyyy"
        let year = formatter.string(from: now)
        
        return (dayOfWeek, monthDay, year)
    }
    
    private var currentTime: (timeString: String, ampmString: String) {
        let now = Date()
        let formatter = DateFormatter()
        
        // Use timeUpdateTrigger to force recomputation
        _ = timeUpdateTrigger
        
        formatter.dateFormat = "h:mm"
        let timeString = formatter.string(from: now)
        
        formatter.dateFormat = "a"
        let ampmString = formatter.string(from: now)
        
        return (timeString, ampmString)
    }
}

// MARK: - Preview

#Preview {
    let pinService = DependencyContainer.shared.getPINManagementService() as! PINManagementService
    let config = DependencyContainer.shared.getConfig() as! AppConfiguration
    let dependencyContainer = DependencyContainer.shared
    let viewModel = dependencyContainer.createAlarmViewModel()
    let trafficService = dependencyContainer.getTrafficService()
    let destinationStore = dependencyContainer.getDestinationStore()
    AlarmTabView(
        config: config,
        viewModel: viewModel,
        trafficService: trafficService,
        destinationStore: destinationStore
    )
}
