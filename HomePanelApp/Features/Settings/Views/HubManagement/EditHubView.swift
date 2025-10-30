import SwiftUI

struct EditHubView: View {
    @Environment(\.dismiss) private var dismiss
    let configuration: HubConfiguration
    let onSave: (HubConfiguration) -> Void
    
    @State private var hubName: String
    @State private var selectedHubType: HubType
    @State private var connectionType: HubConnection.ConnectionType
    @State private var ipAddress = ""
    @State private var port = "3480"
    @State private var url = ""
    @State private var customConnection = ""
    @State private var customPort = ""
    @State private var hasCredentials = false
    @State private var username = ""
    @State private var password = ""
    @State private var apiKey = ""
    @State private var token = ""
    @State private var pollInterval: Double
    @State private var isEnabled: Bool
    @State private var showingError = false
    @State private var errorMessage = ""
    
    
    init(configuration: HubConfiguration, onSave: @escaping (HubConfiguration) -> Void) {
        self.configuration = configuration
        self.onSave = onSave
        
        _hubName = State(initialValue: configuration.name)
        _selectedHubType = State(initialValue: configuration.hubType)
        _pollInterval = State(initialValue: configuration.pollInterval)
        _isEnabled = State(initialValue: configuration.isEnabled)
        
        // Determine connection type and populate fields
        switch configuration.connection.type {
        case .localIP:
            _connectionType = State(initialValue: .localIP)
            _ipAddress = State(initialValue: configuration.connection.address)
            _port = State(initialValue: String(configuration.connection.port ?? HubConnection.defaultVeraPort))
        case .remoteURL:
            _connectionType = State(initialValue: .remoteURL)
            _url = State(initialValue: configuration.connection.address)
            _port = State(initialValue: configuration.connection.port.map(String.init) ?? "")
        }
        
        // Set credentials if available
        if let credentials = configuration.connection.credentials {
            _hasCredentials = State(initialValue: true)
            _username = State(initialValue: credentials.username ?? "")
            _password = State(initialValue: credentials.password ?? "")
            _apiKey = State(initialValue: credentials.apiKey ?? "")
            _token = State(initialValue: credentials.token ?? "")
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Hub Information") {
                    TextField("Hub Name", text: $hubName)

                    Picker("Hub Type", selection: $selectedHubType) {
                        ForEach([HubType.vera, .zigbee, .zwave, .homekit, .future], id: \.self) { type in
                            Text(hubTypeDisplayName(type)).tag(type)
                        }
                    }
                }

                Section("Connection") {
                    Picker("Connection Type", selection: $connectionType) {
                        ForEach(HubConnection.ConnectionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch connectionType {
                    case .localIP:
                        TextField("IP Address", text: $ipAddress)
                            .keyboardType(.numbersAndPunctuation)
                        TextField("Port", text: $port)
                            .keyboardType(.numberPad)
                    case .remoteURL:
                        TextField("URL", text: $url)
                            .keyboardType(.URL)
                        TextField("Port (optional)", text: $port)
                            .keyboardType(.numberPad)
                    }
                }

                Section("Credentials (Optional)") {
                    Toggle("Has Credentials", isOn: $hasCredentials)

                    if hasCredentials {
                        TextField("Username", text: $username)
                        SecureField("Password", text: $password)
                        TextField("API Key", text: $apiKey)
                        TextField("Token", text: $token)
                    }
                }

                Section("Settings") {
                    HStack {
                        Text("Poll Interval")
                        Spacer()
                        Text("\(Int(pollInterval)) seconds")
                    }
                    Slider(value: $pollInterval, in: 1...60, step: 1)

                    Toggle("Enabled", isOn: $isEnabled)
                }
            }
            .navigationTitle("Edit Hub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveHub()
                    }
                    .disabled(!isValidConfiguration)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .keyboardHandling()
        }
        .interactiveDismissDisabled() // Prevent accidental dismissal
    }
    
    private var isValidConfiguration: Bool {
        !hubName.isEmpty && !connectionString.isEmpty
    }
    
    private var connectionString: String {
        switch connectionType {
        case .localIP:
            return ipAddress
        case .remoteURL:
            return url
        }
    }
    
    private var connectionPort: Int? {
        return Int(port)
    }
    
    private var credentials: HubCredentials? {
        guard hasCredentials else { return nil }
        
        return HubCredentials(
            username: username.isEmpty ? nil : username,
            password: password.isEmpty ? nil : password,
            apiKey: apiKey.isEmpty ? nil : apiKey,
            token: token.isEmpty ? nil : token
        )
    }
    
    private func saveHub() {
        do {
            let connection: HubConnection
            
            switch connectionType {
            case .localIP:
                guard !ipAddress.isEmpty else {
                    throw HubError.invalidConnectionString
                }
                connection = HubConnection(
                    type: .localIP,
                    address: ipAddress,
                    port: connectionPort ?? 3480,
                    useHTTPS: false
                )
            case .remoteURL:
                guard !url.isEmpty else {
                    throw HubError.invalidConnectionString
                }
                connection = HubConnection(
                    type: .remoteURL,
                    address: url,
                    port: connectionPort,
                    useHTTPS: true
                )
            }
            
            let updatedConfig = HubConfiguration(
                hubId: configuration.hubId,
                hubType: selectedHubType,
                name: hubName,
                isEnabled: isEnabled,
                connection: connection,
                pollInterval: pollInterval
            )
            
            onSave(updatedConfig)
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func hubTypeDisplayName(_ type: HubType) -> String {
        switch type {
        case .vera:
            return "Vera Hub (Lite/Edge/Plus)"
        case .zigbee:
            return "Zigbee Hub"
        case .zwave:
            return "Z-Wave Hub"
        case .homekit:
            return "HomeKit Hub"
        case .future:
            return "Custom Hub"
        }
    }
}

#Preview {
    let config = HubConfiguration.veraHub(
        id: "test-hub",
        type: .vera,
        name: "Test Hub",
        ipAddress: "192.168.1.100"
    )
    return EditHubView(configuration: config) { _ in }
}
