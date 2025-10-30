# Camera Views

This directory contains the SwiftUI user interface components for the camera surveillance system, providing an intuitive interface for live video monitoring, VMS selection, user-defined camera naming, and configuration management.

## 🎨 Core Views

### CameraTabView

Main camera interface with user-defined camera names and VMS support.

```swift
struct CameraTabView: View {
    @StateObject private var viewModel: CameraViewModel
    @State private var selectedTab = 0
    @State private var camera1Name: String = "Camera 1"
    @State private var camera2Name: String = "Camera 2"
    
    var body: some View {
        VStack {
            TabView(selection: $selectedTab) {
                CameraWebView(config: viewModel.camera1Config)
                    .tabItem {
                        Image(systemName: "camera.fill")
                        Text(camera1Name)
                    }
                    .tag(0)
                
                CameraWebView(config: viewModel.camera2Config)
                    .tabItem {
                        Image(systemName: "camera.fill")
                        Text(camera2Name)
                    }
                    .tag(1)
            }
            
            settingsButton
        }
        .sheet(isPresented: $viewModel.showSettings) {
            CameraSettingsView(viewModel: viewModel)
        }
        .onAppear {
            loadCameraNames()
        }
    }
}
```

**Key Features:**
- User-defined camera names in tab labels
- VMS-agnostic camera support
- Settings access with Master PIN protection
- Dynamic web view integration based on VMS type
- Error handling and loading states

### CameraWebView

Web view component for multi-VMS integration with secure credential handling.

```swift
struct CameraWebView: View {
    let config: CameraConfig?
    @StateObject private var webViewStore = WebViewStore()
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            if let config = config {
                WebView(webView: webViewStore.webView)
                    .onAppear {
                        loadCameraFeed(config: config)
                    }
                    .onDisappear {
                        pauseCameraFeed()
                    }
                    .refreshable {
                        await refreshCameraFeed()
                    }
            } else {
                placeholderView
            }
            
            if isLoading {
                loadingOverlay
            }
            
            if let errorMessage = errorMessage {
                errorOverlay(message: errorMessage)
            }
        }
    }
}
```

**Key Features:**
- WKWebView integration with Blue Iris
- Secure credential embedding
- Loading states and error handling
- Pull-to-refresh functionality
- Lifecycle management (pause/resume)

### CameraSettingsView

Configuration interface with Master PIN protection and form validation.

```swift
struct CameraSettingsView: View {
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var ipAddress = ""
    @State private var port = "2671"
    @State private var username = ""
    @State private var password = ""
    @State private var showMasterPINEntry = false
    @State private var isFormValid = false
    
    var body: some View {
        NavigationView {
            Form {
                configurationSection
                credentialsSection
                actionsSection
            }
            .navigationTitle("Camera Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showMasterPINEntry) {
            MasterPINEntryView { _ in
                showMasterPINEntry = false
            }
        }
        .onAppear {
            loadCurrentConfiguration()
        }
    }
}
```

**Key Features:**
- Master PIN protection for all settings
- Real-time form validation
- IP address and port configuration
- Username and password management
- Save/cancel functionality

## 🎨 UI Components

### Configuration Form

Input fields for camera configuration:

```swift
private var configurationSection: some View {
    Section("Camera Configuration") {
        HStack {
            Text("IP Address")
            Spacer()
            TextField("192.168.1.100", text: $ipAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numbersAndPunctuation)
                .onChange(of: ipAddress) { _ in
                    validateForm()
                }
        }
        
        HStack {
            Text("Port")
            Spacer()
            TextField("2671", text: $port)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .onChange(of: port) { _ in
                    validateForm()
                }
        }
        
        HStack {
            Text("Username")
            Spacer()
            TextField("admin", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: username) { _ in
                    validateForm()
                }
        }
    }
}
```

### Credentials Section

Password management with secure storage:

```swift
private var credentialsSection: some View {
    Section("Credentials") {
        HStack {
            Text("Password")
            Spacer()
            SecureField("Enter password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: password) { _ in
                    validateForm()
                }
        }
        
        if let config = viewModel.selectedCamera {
            HStack {
                Text("Status")
                Spacer()
                Text(hasCredentials(for: config) ? "Saved" : "Not Set")
                    .foregroundColor(hasCredentials(for: config) ? .green : .orange)
            }
        }
    }
}
```

### Action Buttons

Save and cancel functionality:

```swift
private var actionsSection: some View {
    Section {
        Button("Save Configuration") {
            saveConfiguration()
        }
        .disabled(!isFormValid)
        
        Button("Test Connection") {
            testConnection()
        }
        .disabled(!isFormValid)
        
        if let config = viewModel.selectedCamera {
            Button("Delete Configuration", role: .destructive) {
                deleteConfiguration(config)
            }
        }
    }
}
```

## 🔄 State Management

### Form Validation

Real-time validation of configuration inputs:

```swift
private func validateForm() {
    let ipValid = IPValidator.isValid(ipAddress)
    let portValid = Int(port).map { $0 > 0 && $0 <= 65535 } ?? false
    let usernameValid = !username.isEmpty
    let passwordValid = !password.isEmpty
    
    isFormValid = ipValid && portValid && usernameValid && passwordValid
}

private func loadCurrentConfiguration() {
    guard let config = viewModel.selectedCamera else { return }
    
    ipAddress = config.ipAddress
    port = String(config.port)
    username = config.username
    
    // Load password from secure storage
    if let credentials = viewModel.loadCredentials(for: config.id) {
        password = credentials.password
    }
}
```

### Error Handling

User-friendly error display:

```swift
private func handleError(_ error: Error) {
    switch error {
    case CameraError.invalidConfiguration:
        errorMessage = "Invalid configuration. Please check your inputs."
    case CameraError.credentialsNotFound:
        errorMessage = "Credentials not found. Please enter your password."
    case CameraError.keychainError:
        errorMessage = "Failed to save credentials securely."
    default:
        errorMessage = "An unexpected error occurred. Please try again."
    }
}
```

## 🎨 Design System Integration

### Loading States

Visual feedback during operations:

```swift
private var loadingOverlay: some View {
    VStack {
        ProgressView()
            .scaleEffect(1.2)
        Text("Loading camera feed...")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.3))
}
```

### Error States

Clear error messaging:

```swift
private func errorOverlay(message: String) -> some View {
    VStack(spacing: DesignSystem.Spacing.buttonSpacing) {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.largeTitle)
            .foregroundColor(.red)
        
        Text(message)
            .font(.headline)
            .multilineTextAlignment(.center)
        
        Button("Retry") {
            if let config = config {
                loadCameraFeed(config: config)
            }
        }
        .buttonStyle(.borderedProminent)
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(DesignSystem.CornerRadius.card)
    .shadow(radius: 10)
}
```

### Placeholder States

Empty state handling:

```swift
private var placeholderView: some View {
    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
        Image(systemName: "camera.fill")
            .font(.system(size: 60))
            .foregroundColor(.gray)
        
        Text("No Camera Configured")
            .font(.title2)
            .fontWeight(.semibold)
        
        Text("Tap the settings button to configure your camera")
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        
        Button("Open Settings") {
            // Open settings
        }
        .buttonStyle(.borderedProminent)
    }
    .padding()
}
```

## 🧪 Testing

### UI Testing

Test user interactions and visual feedback:

```swift
func testCameraSettingsForm() {
    let app = XCUIApplication()
    app.launch()
    
    // Navigate to camera tab
    app.tabBars.buttons["Camera"].tap()
    
    // Open settings
    app.buttons["Settings"].tap()
    
    // Enter Master PIN
    app.buttons["1"].tap()
    app.buttons["2"].tap()
    // ... continue with PIN entry
    
    // Fill configuration form
    app.textFields["IP Address"].tap()
    app.textFields["IP Address"].typeText("192.168.1.100")
    
    app.textFields["Port"].tap()
    app.textFields["Port"].typeText("2671")
    
    app.textFields["Username"].tap()
    app.textFields["Username"].typeText("admin")
    
    app.secureFields["Enter password"].tap()
    app.secureFields["Enter password"].typeText("password123")
    
    // Save configuration
    app.buttons["Save Configuration"].tap()
    
    // Verify success
    XCTAssertTrue(app.staticTexts["Configuration saved"].exists)
}

func testCameraWebView() {
    let app = XCUIApplication()
    app.launch()
    
    // Navigate to camera tab
    app.tabBars.buttons["Camera"].tap()
    
    // Verify web view is loaded
    let webView = app.webViews.firstMatch
    XCTAssertTrue(webView.exists)
    
    // Test pull-to-refresh
    webView.swipeDown()
    XCTAssertTrue(webView.exists) // Should still be there after refresh
}
```

### Accessibility Testing

Test accessibility features:

```swift
func testAccessibility() {
    let app = XCUIApplication()
    app.launch()
    
    // Test camera tab accessibility
    let cameraTab = app.tabBars.buttons["Camera"]
    XCTAssertTrue(cameraTab.isAccessibilityElement)
    XCTAssertEqual(cameraTab.label, "Camera")
    
    // Test settings button accessibility
    let settingsButton = app.buttons["Settings"]
    XCTAssertTrue(settingsButton.isAccessibilityElement)
    XCTAssertTrue(settingsButton.accessibilityHint.contains("Tap to open camera settings"))
}
```

## 🚀 Performance

### Optimization Strategies

- **Web View Lifecycle**: Automatic pause/resume for off-screen cameras
- **Form Validation**: Efficient real-time validation
- **Memory Management**: Proper web view cleanup
- **State Caching**: Minimize unnecessary updates

### Responsive Design

Adapt to different screen sizes:

```swift
private var webViewHeight: CGFloat {
    UIDevice.current.userInterfaceIdiom == .pad ? 600 : 400
}

private var formColumns: Int {
    UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1
}
```

## 📁 Files

- **CameraTabView.swift** - Main camera interface
- **CameraWebView.swift** - Web view component for Blue Iris
- **CameraSettingsView.swift** - Configuration interface

## 🔗 Navigation

- **[Camera System](../README.md)** - Main camera system documentation
- **[Models](../Models/README.md)** - Camera data models
- **[Services](../Services/README.md)** - Camera services and business logic
- **[ViewModels](../ViewModels/README.md)** - UI state management

---

These SwiftUI views provide an intuitive, secure, and responsive user interface for the camera surveillance system's live monitoring and configuration management.
