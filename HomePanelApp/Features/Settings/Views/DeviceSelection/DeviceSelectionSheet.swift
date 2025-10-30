import SwiftUI

// MARK: - Notification Names

extension Notification.Name {
    static let deviceSelectionChanged = Notification.Name("deviceSelectionChanged")
}

struct DeviceSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: AutomationViewModel

    @State private var selectedDeviceNames: Set<String> = []
    @State private var orderedDeviceNames: [String] = []
    @State private var allDevices: [Device] = []
    @State private var hubConfigurations: [HubConfiguration] = []
    @State private var expandedHubs: Set<String> = []
    @State private var expandedRooms: Set<String> = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var toastMessage: ToastMessage?
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Text("Select Devices & Scenes")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("Save") {
                    saveSelection()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
                .overlay(
                    Group {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)

            if isLoading {
                ProgressView("Loading devices...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 0) {
                    // Left: Device Selection
                    deviceSelectionPane
                        .frame(maxWidth: .infinity)

                    Divider()

                    // Right: Selected & Ordered
                    selectedDevicesPane
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: horizontalSizeClass == .regular ? 1600 : .infinity)
        .overlay(
            ToastBannerOverlay(toastMessage: $toastMessage)
        )
        .task {
            await loadDevices()
        }
    }

    // MARK: - Device Selection Pane

    private var deviceSelectionPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Available Devices & Scenes")
                .font(.title3)
                .fontWeight(.semibold)
                .padding()

            // Search box
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundColor(.secondary)
                TextField("Filter by name...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title3)
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(filteredHubConfigurations) { hub in
                        hubSection(hub: hub)
                    }
                }
                .padding()
            }
            .frame(maxHeight: .infinity)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var filteredHubConfigurations: [HubConfiguration] {
        let filteredHubs: [HubConfiguration]
        
        if searchText.isEmpty {
            filteredHubs = hubConfigurations
        } else {
            // Filter hubs that have matching devices/scenes
            filteredHubs = hubConfigurations.filter { hub in
                let hubDevices = allDevices.filter { $0.hubId == hub.hubId }
                return hubDevices.contains { device in
                    device.name.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        // Sort hubs alphabetically by name
        return filteredHubs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func hubSection(hub: HubConfiguration) -> some View {
        let hubDevices = allDevices.filter { $0.hubId == hub.hubId }

        // Filter devices by search text
        let filteredDevices: [Device]
        if searchText.isEmpty {
            filteredDevices = hubDevices
        } else {
            filteredDevices = hubDevices.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        // Debug: Log hub device counts
        let hubDevicesCount = hubDevices.filter { $0.type != .scene }.count
        let hubScenesCount = hubDevices.filter { $0.type == .scene }.count
        DebugLogger.log("🔍 [DeviceSelectionSheet] Hub '\(hub.name)': \(hubDevicesCount) devices, \(hubScenesCount) scenes", feature: .automation)

        // Don't show hub if no devices match
        guard !filteredDevices.isEmpty else {
            return AnyView(EmptyView())
        }

        // Group devices and scenes by room
        let devices = filteredDevices.filter { $0.type != .scene }
        let scenes = filteredDevices.filter { $0.type == .scene }
        
        // Debug: Log filtered counts
        DebugLogger.log("🔍 [DeviceSelectionSheet] After filtering: \(devices.count) devices, \(scenes.count) scenes", feature: .automation)
        
        let devicesByRoom = Dictionary(grouping: devices) { getRoomName(for: $0, hubId: hub.hubId) }
        let scenesByRoom = Dictionary(grouping: scenes) { getRoomName(for: $0, hubId: hub.hubId) }
        
        // Debug: Log room assignments
        DebugLogger.log("🔍 [DeviceSelectionSheet] Room assignments for hub '\(hub.name)':", feature: .automation)
        for (roomName, roomDevices) in devicesByRoom {
            DebugLogger.log("🔍 [DeviceSelectionSheet] Room '\(roomName)': \(roomDevices.count) devices", feature: .automation)
        }
        for (roomName, roomScenes) in scenesByRoom {
            DebugLogger.log("🔍 [DeviceSelectionSheet] Room '\(roomName)': \(roomScenes.count) scenes", feature: .automation)
        }
        
        // Get all room names and sort alphabetically
        let allRoomNames = Set(devicesByRoom.keys).union(Set(scenesByRoom.keys)).sorted()
        DebugLogger.log("🔍 [DeviceSelectionSheet] All room names: \(allRoomNames)", feature: .automation)
        let isExpanded = expandedHubs.contains(hub.hubId)

        return AnyView(VStack(alignment: .leading, spacing: 8) {
            // Hub Header
            Button(action: {
                withAnimation {
                    if isExpanded {
                        expandedHubs.remove(hub.hubId)
                    } else {
                        expandedHubs.insert(hub.hubId)
                    }
                }
            }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Image(systemName: "network")
                        .font(.title3)
                        .foregroundColor(.blue)

                    Text(hub.name)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()

                    Text("\(filteredDevices.count) items")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    // Rooms (Devices first, then Scenes)
                    ForEach(allRoomNames, id: \.self) { roomName in
                        roomSectionWithScenes(
                            roomName: roomName, 
                            devices: devicesByRoom[roomName] ?? [], 
                            scenes: scenesByRoom[roomName] ?? [], 
                            hubId: hub.hubId
                        )
                    }
                }
                .padding(.leading, 20)
            }
        })
    }

    private func roomSectionWithScenes(roomName: String, devices: [Device], scenes: [Device], hubId: String) -> some View {
        let roomKey = "\(hubId)_\(roomName)"
        let isExpanded = expandedRooms.contains(roomKey)
        
        // Sort devices and scenes alphabetically
        let sortedDevices = devices.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let sortedScenes = scenes.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        let totalItems = devices.count + scenes.count

        return VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                withAnimation {
                    if isExpanded {
                        expandedRooms.remove(roomKey)
                    } else {
                        expandedRooms.insert(roomKey)
                    }
                }
            }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Image(systemName: "door.left.hand.closed")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text(roomName)
                        .font(.title3)

                    Spacer()

                    Text("\(totalItems)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color(.systemBackground).opacity(0.5))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    // Devices first (sorted alphabetically)
                    ForEach(sortedDevices) { device in
                        deviceRow(device: device)
                    }
                    
                    // Scenes second (sorted alphabetically)
                    ForEach(sortedScenes) { scene in
                        deviceRow(device: scene)
                    }
                }
                .padding(.leading, 16)
            }
        }
    }

    private func roomSection(roomName: String, devices: [Device], hubId: String) -> some View {
        let roomKey = "\(hubId)_\(roomName)"
        let isExpanded = expandedRooms.contains(roomKey)
        
        // Sort devices alphabetically
        let sortedDevices = devices.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        return VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                withAnimation {
                    if isExpanded {
                        expandedRooms.remove(roomKey)
                    } else {
                        expandedRooms.insert(roomKey)
                    }
                }
            }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Image(systemName: "door.left.hand.closed")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text(roomName)
                        .font(.title3)

                    Spacer()

                    Text("\(devices.count)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color(.systemBackground).opacity(0.5))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(sortedDevices) { device in
                        deviceRow(device: device)
                    }
                }
                .padding(.leading, 16)
            }
        }
    }


    private func deviceRow(device: Device) -> some View {
        Button(action: {
            toggleDeviceSelection(device)
        }) {
            HStack {
                Image(systemName: selectedDeviceNames.contains(device.name) ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(selectedDeviceNames.contains(device.name) ? .blue : .secondary)

                Image(systemName: device.type.icon)
                    .font(.title3)
                    .foregroundColor(.secondary)

                Text(device.name)
                    .font(.title3)

                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(selectedDeviceNames.contains(device.name) ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selected Devices Pane

    private var selectedDevicesPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Selected Order (\(orderedDeviceNames.count))")
                .font(.title3)
                .fontWeight(.semibold)
                .padding()

            Divider()

            if orderedDeviceNames.isEmpty {
                VStack {
                    Image(systemName: "checkmark.square")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Select devices from the left")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(orderedDeviceNames, id: \.self) { deviceName in
                        HStack {
                            Image(systemName: "line.3.horizontal")
                                .font(.title3)
                                .foregroundColor(.secondary)

                            if let device = allDevices.first(where: { $0.name == deviceName }) {
                                Image(systemName: device.type.icon)
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }

                            Text(deviceName)
                                .font(.title3)

                            Spacer()

                            Button(action: {
                                removeDevice(deviceName)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove { from, to in
                        orderedDeviceNames.move(fromOffsets: from, toOffset: to)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Actions

    private func toggleDeviceSelection(_ device: Device) {
        if selectedDeviceNames.contains(device.name) {
            selectedDeviceNames.remove(device.name)
            orderedDeviceNames.removeAll { $0 == device.name }
        } else {
            selectedDeviceNames.insert(device.name)
            orderedDeviceNames.append(device.name)
        }
        HapticFeedback.selection()
    }

    private func removeDevice(_ deviceName: String) {
        selectedDeviceNames.remove(deviceName)
        orderedDeviceNames.removeAll { $0 == deviceName }
        HapticFeedback.selection()
    }

    private func loadDevices() async {
        isLoading = true

        // Get all devices and hubs
        allDevices = await viewModel.hubService.getAllDevices()
        hubConfigurations = await viewModel.hubService.getRegisteredHubs()

        // Debug: Log device and scene counts
        let devices = allDevices.filter { $0.type != .scene }
        let scenes = allDevices.filter { $0.type == .scene }
        DebugLogger.log("🔍 [DeviceSelectionSheet] Loaded \(allDevices.count) total items: \(devices.count) devices, \(scenes.count) scenes", feature: .automation)
        
        // Log scenes for debugging
        for scene in scenes {
            DebugLogger.log("🔍 [DeviceSelectionSheet] Scene: '\(scene.name)' (hub: \(scene.hubId), room: \(scene.room ?? "nil"))", feature: .automation)
        }

        // Initialize selection from current config
        selectedDeviceNames = Set(viewModel.appConfig.selectedDeviceNames)
        orderedDeviceNames = viewModel.appConfig.selectedDeviceNames

        isLoading = false
    }

    private func saveSelection() {
        isSaving = true
        HapticFeedback.buttonPress()

        // Update app configuration
        viewModel.appConfig.updateSelectedDeviceNames(orderedDeviceNames)

        // Reload devices in the automation view
        Task { @MainActor in
            await viewModel.loadDevices()

            // Force a UI refresh
            viewModel.objectWillChange.send()

            // Post notification for other views to refresh
            NotificationCenter.default.post(name: .deviceSelectionChanged, object: nil)

            isSaving = false
            toastMessage = ToastMessage(
                title: "Devices saved successfully",
                message: "\(orderedDeviceNames.count) devices configured",
                type: .success
            )
            HapticFeedback.success()

            try? await Task.sleep(nanoseconds: 1_000_000_000)
            dismiss()
        }
    }

    // MARK: - Helper Methods

    private func getRoomName(for device: Device, hubId: String) -> String {
        guard let roomId = device.room else {
            DebugLogger.log("🔍 [DeviceSelectionSheet] Device '\(device.name)' (type: \(device.type)) has no room, assigning to 'No Room'", feature: .automation)
            return "No Room"
        }
        let roomName = viewModel.roomMappingService.roomName(for: roomId, hubId: hubId)
        DebugLogger.log("🔍 [DeviceSelectionSheet] Device '\(device.name)' (type: \(device.type)) assigned to room: '\(roomName)' (roomId: \(roomId))", feature: .automation)
        return roomName
    }
}

