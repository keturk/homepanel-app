import Foundation

// MARK: - Polling Service Actor

/// Background polling coordinator
actor PollingService {
    private let hubManager: HubManager
    private var pollingTasks: [String: Task<Void, Never>] = [:]
    private var isRunning = false
    
    init(hubManager: HubManager) {
        self.hubManager = hubManager
    }
    
    func startPolling() {
        guard !isRunning else {
            DebugLogger.log("Already running, skipping start", feature: .hubService)
            return
        }
        DebugLogger.log("Starting polling service", feature: .hubService)
        isRunning = true

        // Start polling tasks for each hub
        Task {
            let hubIds = await hubManager.getRegisteredHubIds()
            DebugLogger.log("Found \(hubIds.count) registered hubs: \(hubIds)", feature: .hubService)
            for hubId in hubIds {
                await startPolling(forHub: hubId)
            }
        }
    }
    
    func startPolling(forHub hubId: String) async {
        DebugLogger.log("Starting polling for hub: \(hubId)", feature: .hubService)
        // Cancel existing task if any
        pollingTasks[hubId]?.cancel()

        guard let config = await hubManager.getConfiguration(forHub: hubId) else {
            DebugLogger.error("No configuration found for hub: \(hubId)", feature: .hubService)
            return
        }

        let task = Task {
            while !Task.isCancelled {
                do {
                    DebugLogger.log("PollingService: About to poll hub \(hubId)", feature: .hubService)
                    try await hubManager.pollHub(hubId: hubId)
                    DebugLogger.log("PollingService: Successfully polled hub \(hubId)", feature: .hubService)
                } catch {
                    DebugLogger.error("Polling error for hub \(hubId): \(error)", feature: .hubService)
                }

                // Wait for poll interval
                try? await Task.sleep(for: .seconds(config.pollInterval))
            }
        }

        pollingTasks[hubId] = task
    }
    
    func stopPolling(forHub hubId: String) {
        pollingTasks[hubId]?.cancel()
        pollingTasks.removeValue(forKey: hubId)
    }
    
    func stopAllPolling() {
        pollingTasks.values.forEach { $0.cancel() }
        pollingTasks.removeAll()
        isRunning = false
    }
    
    func pollNow(hubId: String) async throws {
        try await hubManager.pollHub(hubId: hubId)
    }
    
    func pollAllNow() async {
        await hubManager.pollAllHubs()
    }
    
    func isPolling(hubId: String) -> Bool {
        return pollingTasks[hubId] != nil && !pollingTasks[hubId]!.isCancelled
    }
    
    func getPollingHubIds() -> [String] {
        return Array(pollingTasks.keys)
    }
}
