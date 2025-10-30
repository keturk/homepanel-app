import SwiftUI

// MARK: - Traffic View

struct TrafficView: View {
    @ObservedObject var trafficService: TrafficService
    @ObservedObject var destinationStore: DestinationStore

    @State private var trafficInfos: [TrafficInfo] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var refreshTimer: Timer?
    @State private var lastRefreshTime: Date?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
            trafficCard
        }
        .padding(.horizontal)
        .task {
            await loadDestinationsAndTraffic()
            startAutoRefresh()
        }
        .onChange(of: destinationStore.destinations) {
            Task {
                await refreshTrafficInfo()
            }
        }
        .onDisappear {
            stopAutoRefresh()
        }
    }

    // MARK: - Traffic Card

    private var trafficCard: some View {
        ZStack {
            VStack(spacing: DesignSystem.Spacing.statusSpacing) {
                if isLoading && trafficInfos.isEmpty {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if trafficInfos.isEmpty {
                    emptyStateView
                } else {
                    trafficContentView
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding(.vertical, DesignSystem.FrameSize.statusCardHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.statusCard)
                    .fill(Color.white.opacity(DesignSystem.Opacity.cardBackground))
                    .shadow(
                        color: .black.opacity(DesignSystem.Opacity.shadow),
                        radius: DesignSystem.Shadow.radius,
                        x: DesignSystem.Shadow.xOffset,
                        y: DesignSystem.Shadow.yOffset
                    )
            )

            // Refresh button positioned at bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()

                    Button(action: {
                        Task {
                            await refreshTrafficInfo()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                    }
                    .padding(.trailing, 12)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    // MARK: - Traffic Content View

    private var trafficContentView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(trafficInfos) { info in
                    VStack(spacing: 8) {
                        // Icon and Name
                        HStack(spacing: 8) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)

                            Text(info.destinationName)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }

                        // ETA (large and prominent)
                        Text(info.formattedETA)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.green)

                        // Distance
                        Text(info.formattedDistance)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .frame(minWidth: 200)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    // Divider between destinations
                    if info.id != trafficInfos.last?.id {
                        Divider()
                            .frame(height: 80)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.regular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "car.circle")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No destinations configured")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.secondary)

            Text("Add destinations in Settings")
                .font(.system(size: 18))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.statusSpacing) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                .scaleEffect(DesignSystem.Scale.progressView)

            Text("Loading traffic info...")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text(message)
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.regular)
        }
    }

    // MARK: - Helper Methods

    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 {
            return "\(seconds)s ago"
        } else {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        }
    }

    // MARK: - Data Loading

    private func loadDestinationsAndTraffic() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load destinations
            let _ = try await destinationStore.loadDestinations()

            // Fetch traffic info
            await refreshTrafficInfo()
        } catch {
            DebugLogger.error("❌ [TrafficView] Failed to load destinations: \(error)", feature: .common)
            errorMessage = "Failed to load destinations"
        }

        isLoading = false
    }

    private func refreshTrafficInfo() async {
        let destinations = destinationStore.destinations
        DebugLogger.log("🔄 [TrafficView] Refreshing traffic info for \(destinations.count) destinations", feature: .common)

        guard !destinations.isEmpty else {
            DebugLogger.log("⚠️ [TrafficView] No destinations to fetch traffic for", feature: .common)
            trafficInfos = []
            return
        }

        let enabledCount = destinations.filter { $0.isEnabled }.count
        DebugLogger.log("✅ [TrafficView] \(enabledCount) destinations are enabled", feature: .common)

        trafficInfos = await trafficService.fetchTrafficInfo(for: destinations)
        lastRefreshTime = Date()

        DebugLogger.log("📊 [TrafficView] Received \(trafficInfos.count) traffic infos", feature: .common)

        if trafficInfos.isEmpty && !destinations.isEmpty {
            errorMessage = "Enable location services to see traffic info"
            DebugLogger.log("⚠️ [TrafficView] No traffic infos returned - location services may be disabled", feature: .common)
        } else {
            errorMessage = nil
        }
    }

    // MARK: - Auto Refresh

    private func startAutoRefresh() {
        // Refresh every 5 minutes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                await refreshTrafficInfo()
            }
        }

        DebugLogger.log("🔄 [TrafficView] Started auto-refresh (5 minutes)", feature: .common)
    }

    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        DebugLogger.log("⏹️ [TrafficView] Stopped auto-refresh", feature: .common)
    }
}

// MARK: - Preview

#Preview {
    let trafficService = TrafficService()
    let destinationStore = DependencyContainer.shared.getDestinationStore()

    TrafficView(trafficService: trafficService, destinationStore: destinationStore)
        .padding()
        .background(Color.gray.opacity(DesignSystem.Opacity.previewBackground))
}
