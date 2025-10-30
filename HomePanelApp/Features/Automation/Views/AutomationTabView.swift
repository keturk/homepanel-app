import SwiftUI

struct AutomationTabView: View {
    @StateObject private var viewModel: AutomationViewModel
    
    // 4-column grid layout for landscape mode (4 tiles per row)
    private let columns = [
        GridItem(.flexible(), spacing: DesignSystem.Spacing.medium),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.medium),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.medium),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.medium)
    ]
    
    init(dependencyContainer: DependencyContainer, pinService: any PINManagementServiceProtocol) {
        self._viewModel = StateObject(wrappedValue: dependencyContainer.createAutomationViewModel())
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content
                if viewModel.isLoading && viewModel.devices.isEmpty {
                    loadingView
                } else if viewModel.devices.isEmpty {
                    emptyStateView
                } else {
                    deviceGridView
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    errorMessageView(errorMessage)
                }
            }
        }
        .onAppear {
            DebugLogger.log("AutomationTabView appeared", feature: .automation)
            Task {
                // Refresh room mappings first
                await viewModel.roomMappingService.refreshRoomMappings()
                await viewModel.loadDevices()
                
                // If no devices found after initial load, wait a bit and try again
                if viewModel.devices.isEmpty {
                    DebugLogger.log("📊 AutomationTabView: No devices found, waiting and retrying...", feature: .automation)
                    try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                    await viewModel.loadDevices()
                }
            }
        }
        .onDisappear {
            DebugLogger.log("AutomationTabView disappeared", feature: .automation)
        }
        .onReceive(NotificationCenter.default.publisher(for: .deviceSelectionChanged)) { _ in
            DebugLogger.log("AutomationTabView received deviceSelectionChanged notification", feature: .automation)
            Task {
                await viewModel.loadDevices()
            }
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Spacer()
            
            Image(systemName: "house.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Devices Configured")
                .font(.system(size: DesignSystem.FontSize.extraLarge, weight: .bold))
                .foregroundColor(.white)
            
            Text("Tap the Settings button to configure\ndevices and scenes to display")
                .font(.system(size: DesignSystem.FontSize.medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.massive)
    }
    
    private var deviceGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.medium) {
                ForEach(viewModel.devices) { device in
                        DeviceCardView(
                            device: device,
                            isActionInProgress: viewModel.deviceActionInProgress.contains(device.id),
                            onTap: {
                                Task {
                                    if device.type == .scene {
                                        await viewModel.executeScene(device)
                                    } else {
                                        await viewModel.toggleDevice(device)
                                    }
                                }
                            },
                            roomMappingService: viewModel.roomMappingService
                        )
                }
            }
            .padding(DesignSystem.Spacing.large)
        }
    }
    
    private func errorMessageView(_ message: String) -> some View {
        Text(message)
            .font(.system(size: DesignSystem.FontSize.small))
            .foregroundColor(.red)
            .padding(DesignSystem.Spacing.medium)
            .background(Color.red.opacity(0.2))
            .cornerRadius(DesignSystem.CornerRadius.small)
            .padding(DesignSystem.Spacing.medium)
    }
    
    
    // MARK: - Helper Methods
}
