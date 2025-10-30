import SwiftUI

struct HubManagementView: View {
    @ObservedObject var config: AppConfiguration
    @ObservedObject var hubConfigStore: HubConfigurationStore
    let hubService: HubServiceProtocol
    @State private var showingAddHub = false
    @State private var editingHub: HubConfiguration?
    @State private var hubToDelete: HubConfiguration?
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Add New Hub Button
                Button(action: {
                    DebugLogger.log("🔍 [HubManagementView] Add New Hub button tapped", feature: .settings)
                    showingAddHub = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                        Text("Add New Hub")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .accessibilityLabel("Add New Hub")
                .accessibilityHint("Tap to add a new automation hub")

                // Primary Hub Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Primary Hub")
                        .font(.headline)
                        .padding(.horizontal, 20)

                    if let primaryHubId = config.primaryHubId,
                       let primaryHub = hubConfigStore.getHub(hubId: primaryHubId) {
                        PrimaryHubRowView(
                            configuration: primaryHub,
                            isSelected: true,
                            onSelect: { _ in }
                        )
                        .padding(.horizontal, 20)
                    } else {
                        Text("No primary hub selected")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.horizontal, 20)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // All Hubs Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("All Hubs (\(hubConfigStore.configurations.count))")
                        .font(.headline)
                        .padding(.horizontal, 20)

                    if hubConfigStore.configurations.isEmpty {
                        Text("No hubs configured")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.horizontal, 20)
                    } else {
                        ForEach(hubConfigStore.configurations) { hubConfig in
                            HubRowView(
                                configuration: hubConfig,
                                isPrimary: hubConfig.hubId == config.primaryHubId,
                                onEdit: {
                                    DebugLogger.log("🔍 [HubManagementView] Edit callback triggered for \(hubConfig.name)", feature: .settings)
                                    editingHub = hubConfig
                                },
                                onDelete: {
                                    hubToDelete = hubConfig
                                    showingDeleteAlert = true
                                },
                                onSetPrimary: {
                                    config.primaryHubId = hubConfig.hubId
                                },
                                onToggleAlarmHub: {
                                    Task {
                                        try await hubConfigStore.toggleHubEnabled(hubId: hubConfig.hubId)
                                    }
                                }
                            )
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .fullScreenCover(isPresented: $showingAddHub) {
            AddHubView(hubConfigStore: hubConfigStore) { newConfig in
                Task {
                    // Save to hub configuration store
                    try await hubConfigStore.addHub(newConfig)

                    // Register with HubService if enabled
                    if newConfig.isEnabled {
                        DebugLogger.log("🔍 [HubManagementView] Registering newly added hub '\(newConfig.name)' with HubService", feature: .settings)
                        let adapter = newConfig.createAdapter()
                        await hubService.registerHub(adapter, configuration: newConfig)

                        // Refresh room mappings after adding the hub
                        await hubService.refreshRoomMappingsAfterRegistration()
                        DebugLogger.success("Hub '\(newConfig.name)' registered successfully", feature: .settings)
                    } else {
                        DebugLogger.log("🔍 [HubManagementView] Hub '\(newConfig.name)' is disabled, skipping registration", feature: .settings)
                    }
                }
            }
        }
        .fullScreenCover(item: $editingHub) { config in
            EditHubView(configuration: config) { updatedConfig in
                Task {
                    // Check if hub was enabled/disabled
                    let wasEnabled = config.isEnabled
                    let nowEnabled = updatedConfig.isEnabled

                    // Update the configuration store
                    try await hubConfigStore.updateHub(updatedConfig)

                    // Handle hub registration changes
                    if wasEnabled && !nowEnabled {
                        // Hub was disabled - unregister it
                        DebugLogger.log("🔍 [HubManagementView] Hub '\(updatedConfig.name)' was disabled, unregistering from HubService", feature: .settings)
                        await hubService.unregisterHub(hubId: updatedConfig.hubId)
                    } else if !wasEnabled && nowEnabled {
                        // Hub was enabled - register it
                        DebugLogger.log("🔍 [HubManagementView] Hub '\(updatedConfig.name)' was enabled, registering with HubService", feature: .settings)
                        let adapter = updatedConfig.createAdapter()
                        await hubService.registerHub(adapter, configuration: updatedConfig)
                        await hubService.refreshRoomMappingsAfterRegistration()
                    } else if nowEnabled {
                        // Hub was already enabled - update the configuration
                        DebugLogger.log("🔍 [HubManagementView] Hub '\(updatedConfig.name)' configuration updated, refreshing HubService", feature: .settings)
                        await hubService.updateHubConfiguration(hubId: updatedConfig.hubId, newConfiguration: updatedConfig)
                    }
                }
            }
        }
        .alert("Delete Hub", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let hub = hubToDelete {
                    Task {
                        // Unregister from HubService first
                        DebugLogger.log("🔍 [HubManagementView] Unregistering hub '\(hub.name)' from HubService", feature: .settings)
                        await hubService.unregisterHub(hubId: hub.hubId)

                        // Then remove from configuration store
                        try await hubConfigStore.removeHub(hubId: hub.hubId)
                        DebugLogger.success("Hub '\(hub.name)' deleted successfully", feature: .settings)
                    }
                }
            }
        } message: {
            if let hub = hubToDelete {
                Text("Are you sure you want to delete '\(hub.name)'? This action cannot be undone.")
            }
        }
        .onAppear {
            config.autoSelectPrimaryHub(from: hubConfigStore.configurations)

            DebugLogger.log("🔍 [HubManagementView] onAppear - hubConfigStore.configurations.count: \(hubConfigStore.configurations.count)", feature: .settings)
            for (index, config) in hubConfigStore.configurations.enumerated() {
                DebugLogger.log("🔍 [HubManagementView] Hub \(index): \(config.name) (\(config.hubId)) - enabled: \(config.isEnabled)", feature: .settings)
            }
        }
    }
}
