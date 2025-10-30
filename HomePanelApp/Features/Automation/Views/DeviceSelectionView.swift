import SwiftUI

struct DeviceSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let allDevices: [Device]
    let selectedDeviceNames: [String]
    let onSelectionChanged: ([String]) -> Void
    
    @State private var currentSelection: [String]
    @State private var searchText = ""
    
    init(allDevices: [Device], selectedDeviceNames: [String], onSelectionChanged: @escaping ([String]) -> Void) {
        self.allDevices = allDevices
        self.selectedDeviceNames = selectedDeviceNames
        self.onSelectionChanged = onSelectionChanged
        self._currentSelection = State(initialValue: selectedDeviceNames)
    }
    
    var filteredDevices: [Device] {
        if searchText.isEmpty {
            return allDevices.sorted { $0.name < $1.name }
        } else {
            return allDevices
                .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name < $1.name }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText)
                    .padding()
                
                // Device list
                List {
                    ForEach(filteredDevices, id: \.id) { device in
                        DeviceSelectionRow(
                            device: device,
                            isSelected: currentSelection.contains(device.name),
                            onToggle: { isSelected in
                                if isSelected {
                                    if !currentSelection.contains(device.name) {
                                        currentSelection.append(device.name)
                                    }
                                } else {
                                    currentSelection.removeAll { $0 == device.name }
                                }
                            }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
            .background(Color.black)
            .navigationTitle("Select Devices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSelectionChanged(currentSelection)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DeviceSelectionRow: View {
    let device: Device
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                onToggle(!isSelected)
            }) {
                HStack {
                    Image(systemName: device.type.icon)
                        .foregroundColor(device.state.isOn == true ? .yellow : .gray)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(device.type.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let room = device.room {
                            Text(room)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    if device.type == .scene {
                        Text("Scene")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    } else if let isOn = device.state.isOn {
                        Text(isOn ? "ON" : "OFF")
                            .font(.caption)
                            .foregroundColor(isOn ? .green : .gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((isOn ? Color.green : Color.gray).opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title2)
        }
        .padding(.vertical, 4)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search devices...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}

#Preview {
    let sampleDevices = [
        Device(
            id: "1",
            hubId: "hub1",
            name: "Living Room Light",
            type: .light,
            room: "Living Room",
            state: DeviceState(deviceId: "1", hubId: "hub1", isOn: true, level: nil, temperature: nil, locked: nil, tripped: nil, lastUpdate: Date()),
            capabilities: [.switchable]
        ),
        Device(
            id: "2",
            hubId: "hub1",
            name: "Kitchen Switch",
            type: .lightSwitch,
            room: "Kitchen",
            state: DeviceState(deviceId: "2", hubId: "hub1", isOn: false, level: nil, temperature: nil, locked: nil, tripped: nil, lastUpdate: Date()),
            capabilities: [.switchable]
        )
    ]
    
    DeviceSelectionView(
        allDevices: sampleDevices,
        selectedDeviceNames: ["Living Room Light"],
        onSelectionChanged: { _ in }
    )
}
