import SwiftUI

struct AddHubView: View {
    @Environment(\.dismiss) private var dismiss
    let hubConfigStore: HubConfigurationStore
    let onSave: (HubConfiguration) -> Void

    @State private var hubName = ""
    @State private var selectedHubType = HubType.vera
    @State private var connectionType = HubConnection.ConnectionType.localIP
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
    @State private var pollInterval = 5.0
    @State private var isEnabled = true
    @State private var isAlarmHub = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var toastMessage: ToastMessage?
    @State private var isSaving = false
    @State private var validationErrors: [String: String] = [:]
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed header with Cancel and Save buttons
            HStack {
                Button("Cancel") {
                    DebugLogger.log("🔍 [AddHubView] Cancel button tapped", feature: .settings)
                    dismiss()
                }
                .buttonStyle(.bordered)
                .disabled(false)
                .accessibilityLabel("Cancel")
                .accessibilityHint("Cancel adding hub and return to hub management")

                Spacer()

                Text("Add Automation Hub")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("Save") {
                    DebugLogger.log("🔍 [AddHubView] Save button tapped", feature: .settings)
                    saveHub()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidConfiguration || isSaving)
                .overlay(
                    Group {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                )
                .accessibilityLabel("Save")
                .accessibilityHint("Save hub configuration")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)

            // Scrollable content
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    hubInformationSection
                    connectionSection
                    credentialsSection
                    settingsSection
                }
                .padding(.top, DesignSystem.Spacing.large)
                .padding(.horizontal, DesignSystem.Spacing.large)
                .padding(.bottom, 200) // Large bottom padding to ensure all content is scrollable
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .interactiveDismissDisabled(isSaving) // Only prevent dismissal when saving
        .overlay(
            ToastBannerOverlay(toastMessage: $toastMessage)
        )
        .keyboardHandling()
    }
    
    // MARK: - Sections
    
    private var hubInformationSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Hub Information")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("Hub Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter Hub Name", text: $hubName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(validationErrors["hubName"] != nil ? Color.red : Color.clear, lineWidth: 1)
                        )
                        .accessibilityLabel("Hub Name")
                        .accessibilityHint("Enter a name for this hub")
                    
                    if let error = validationErrors["hubName"] {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("Hub Type")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Hub Type", selection: $selectedHubType) {
                        ForEach([HubType.vera, .zigbee, .zwave, .homekit, .future], id: \.self) { type in
                            Text(hubTypeDisplayName(type)).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Hub Type")
                    .accessibilityHint("Select the type of hub you're adding")
                }
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(Color(.systemBackground))
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Connection")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("Connection Type")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Connection Type", selection: $connectionType) {
                        ForEach(HubConnection.ConnectionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                switch connectionType {
                case .localIP:
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text("IP Address")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter IP Address", text: $ipAddress)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numbersAndPunctuation)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(validationErrors["ipAddress"] != nil ? Color.red : Color.clear, lineWidth: 1)
                                )
                                .accessibilityLabel("IP Address")
                                .accessibilityHint("Enter the IP address of your hub")
                            
                            if let error = validationErrors["ipAddress"] {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text("Port")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter Port", text: $port)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(validationErrors["port"] != nil ? Color.red : Color.clear, lineWidth: 1)
                                )
                                .accessibilityLabel("Port")
                                .accessibilityHint("Enter the port number for your hub")
                            
                            if let error = validationErrors["port"] {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                case .remoteURL:
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text("URL")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter URL", text: $url)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.URL)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(validationErrors["url"] != nil ? Color.red : Color.clear, lineWidth: 1)
                                )
                                .accessibilityLabel("URL")
                                .accessibilityHint("Enter the URL of your hub")
                            
                            if let error = validationErrors["url"] {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text("Port (optional)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter Port", text: $port)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .accessibilityLabel("Port (optional)")
                                .accessibilityHint("Enter the port number if needed")
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(Color(.systemBackground))
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var credentialsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Credentials (Optional)")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: DesignSystem.Spacing.medium) {
                Toggle("Has Credentials", isOn: $hasCredentials)
                    .toggleStyle(SwitchToggleStyle())
                
                if hasCredentials {
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text("Username")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter Username", text: $username)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .accessibilityLabel("Username")
                                .accessibilityHint("Enter the username for hub authentication")
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            SecureField("Enter Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .accessibilityLabel("Password")
                                .accessibilityHint("Enter the password for hub authentication")
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text("API Key")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter API Key", text: $apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .accessibilityLabel("API Key")
                                .accessibilityHint("Enter the API key for hub authentication")
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text("Token")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter Token", text: $token)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .accessibilityLabel("Token")
                                .accessibilityHint("Enter the token for hub authentication")
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(Color(.systemBackground))
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Settings")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    HStack {
                        Text("Poll Interval")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(pollInterval)) seconds")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $pollInterval, in: 1...60, step: 1)
                        .accessibilityLabel("Poll Interval")
                        .accessibilityHint("Adjust the polling interval for this hub")
                }
                
                Toggle("Enabled", isOn: $isEnabled)
                    .toggleStyle(SwitchToggleStyle())
                    .accessibilityLabel("Enabled")
                    .accessibilityHint("Enable or disable this hub")
                
                Toggle("Alarm Hub", isOn: $isAlarmHub)
                    .toggleStyle(SwitchToggleStyle())
                    .accessibilityLabel("Alarm Hub")
                    .accessibilityHint("Set this hub as the primary alarm hub")
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(Color(.systemBackground))
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var isValidConfiguration: Bool {
        // Check validation without modifying state
        return isHubNameValid && isConnectionValid
    }

    private var isHubNameValid: Bool {
        let trimmedName = hubName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            return false
        }
        // Check for duplicate hub names
        let hubId = generateHubId(from: trimmedName)
        return !hubConfigStore.configurations.contains(where: { $0.hubId == hubId })
    }

    private var isConnectionValid: Bool {
        switch connectionType {
        case .localIP:
            let trimmedIP = ipAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedIP.isEmpty || !isValidIPAddress(trimmedIP) {
                return false
            }
            if let portNum = Int(port), (portNum < 1 || portNum > 65535) {
                return false
            }
            return true
        case .remoteURL:
            let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmedURL.isEmpty && isValidURL(trimmedURL)
        }
    }

    private func validateConfiguration() {
        validationErrors.removeAll()

        // Validate Hub Name
        let trimmedName = hubName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            validationErrors["hubName"] = "Hub name is required"
        } else {
            // Check for duplicate hub names
            let hubId = generateHubId(from: trimmedName)
            if hubConfigStore.configurations.contains(where: { $0.hubId == hubId }) {
                validationErrors["hubName"] = "A hub with this name already exists"
            }
        }

        // Validate Connection based on type
        switch connectionType {
        case .localIP:
            if ipAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationErrors["ipAddress"] = "IP address is required"
            } else if !isValidIPAddress(ipAddress) {
                validationErrors["ipAddress"] = "Please enter a valid IP address (e.g., 192.168.1.1)"
            }
            
            if let port = Int(port), (port < 1 || port > 65535) {
                validationErrors["port"] = "Port must be between 1 and 65535"
            }
            
        case .remoteURL:
            if url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationErrors["url"] = "URL is required"
            } else if !isValidURL(url) {
                validationErrors["url"] = "Please enter a valid URL (e.g., https://example.com)"
            }
        }
    }
    
    private func isValidIPAddress(_ ip: String) -> Bool {
        let components = ip.split(separator: ".")
        guard components.count == 4 else { return false }
        
        for component in components {
            guard let num = Int(component), num >= 0 && num <= 255 else { return false }
        }
        return true
    }
    
    private func isValidURL(_ url: String) -> Bool {
        guard let url = URL(string: url) else { return false }
        return url.scheme == "http" || url.scheme == "https"
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
        // Validate and show errors before attempting to save
        validateConfiguration()
        guard validationErrors.isEmpty else {
            return
        }

        isSaving = true
        HapticFeedback.buttonPress()

        Task {
            do {
                let hubId = generateHubId()
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
                
                let config = HubConfiguration(
                    hubId: hubId,
                    hubType: selectedHubType,
                    name: hubName,
                    isEnabled: isEnabled,
                    isAlarmHub: isAlarmHub,
                    connection: connection,
                    pollInterval: pollInterval
                )
                
                DebugLogger.log("🔍 [AddHubView] Calling onSave with config: \(config.name) (\(config.hubId))", feature: .settings)
                onSave(config)
                
                await MainActor.run {
                    isSaving = false
                    toastMessage = ToastMessage(title: "Hub added successfully", message: "\(hubName) has been configured", type: .success)
                    HapticFeedback.success()
                    
                    // Dismiss after a short delay to show the success message
                    Task {
                        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    toastMessage = ToastMessage(title: "Failed to add hub", message: error.localizedDescription, type: .error)
                    HapticFeedback.error()
                }
            }
        }
    }
    
    private func generateHubId(from name: String) -> String {
        // Generate a consistent hubId based on the hub name
        // Remove leading/trailing whitespace and convert to lowercase
        let sanitized = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            // Remove any characters that aren't alphanumeric or hyphens
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-")).inverted)
            .joined()
        return sanitized
    }

    private func generateHubId() -> String {
        return generateHubId(from: hubName)
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
    AddHubView(hubConfigStore: HubConfigurationStore()) { _ in }
}
