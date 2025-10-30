# Alarm ViewModels

This directory contains the ViewModels that manage UI state and business logic for the alarm system, providing the bridge between SwiftUI views and alarm services.

## 🧠 Core ViewModels

### AlarmViewModel

Primary ViewModel for alarm state management and user interactions.

```swift
@MainActor
class AlarmViewModel: ObservableObject {
    @Published var currentState: AlarmState = .unknown
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showPINEntry = false
    @Published var pendingMode: AlarmMode?
    @Published var lastUpdated: Date?
    
    private let alarmService: AlarmServiceProtocol
    private let sceneService: SceneServiceProtocol
    private let pinService: PINManagementServiceProtocol
    private let lockoutService: AlarmLockoutServiceProtocol
}
```

**Key Responsibilities:**
- Alarm state polling and management
- PIN validation and mode changes
- Error handling and user feedback
- UI state coordination

## 🔄 State Management

### Published Properties

The ViewModel uses `@Published` properties for reactive UI updates:

```swift
@Published var currentState: AlarmState = .unknown
@Published var isLoading = false
@Published var errorMessage: String?
@Published var showPINEntry = false
@Published var pendingMode: AlarmMode?
@Published var lastUpdated: Date?
```

### State Polling

Automatic state refresh every 5 seconds:

```swift
func startPolling() {
    Timer.publish(every: 5.0, on: .main, in: .common)
        .autoconnect()
        .sink { [weak self] _ in
            Task { await self?.refreshState() }
        }
        .store(in: &cancellables)
}

func refreshState() async {
    guard !isLoading else { return }
    
    isLoading = true
    errorMessage = nil
    
    do {
        let newState = try await alarmService.fetchAlarmState()
        await MainActor.run {
            self.currentState = newState
            self.lastUpdated = Date()
            self.isLoading = false
        }
    } catch {
        await MainActor.run {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}
```

## 🔐 PIN Management

### PIN Validation Flow

Secure PIN validation with lockout protection:

```swift
func validatePIN(_ pin: String) -> Bool {
    guard !lockoutService.isLockedOut() else {
        errorMessage = "System is locked out. Please try again later."
        return false
    }
    
    let isValid = pinService.verifyPIN(pin)
    
    if isValid {
        lockoutService.recordSuccessfulAttempt()
        return true
    } else {
        lockoutService.recordFailedAttempt()
        errorMessage = "Invalid PIN. Please try again."
        return false
    }
}
```

### Mode Change Process

PIN-protected alarm mode changes:

```swift
func requestModeChange(_ mode: AlarmMode) {
    guard !lockoutService.isLockedOut() else {
        errorMessage = "System is locked out. Please try again later."
        return
    }
    
    pendingMode = mode
    showPINEntry = true
}

func executeModeChange() async {
    guard let mode = pendingMode else { return }
    
    isLoading = true
    errorMessage = nil
    
    do {
        let sceneMap = try await sceneService.fetchSceneList()
        try await alarmService.setAlarmMode(mode, sceneMap: sceneMap)
        
        // Refresh state to confirm change
        await refreshState()
        
        await MainActor.run {
            self.showPINEntry = false
            self.pendingMode = nil
            self.isLoading = false
        }
    } catch {
        await MainActor.run {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}
```

## 🎨 UI State Management

### Loading States

Visual feedback during operations:

```swift
var isRefreshing: Bool {
    isLoading && !showPINEntry
}

var isChangingMode: Bool {
    isLoading && showPINEntry
}

var canChangeMode: Bool {
    !isLoading && !lockoutService.isLockedOut()
}
```

### Error Handling

User-friendly error messages:

```swift
func handleError(_ error: Error) {
    switch error {
    case VeraHubError.networkError:
        errorMessage = "Unable to connect to Vera Hub. Please check your network connection."
    case VeraHubError.sceneNotFound:
        errorMessage = "Required scene not found on Vera Hub. Please check your configuration."
    case VeraHubError.deviceNotFound:
        errorMessage = "Alarm device not found. Please check your Vera Hub configuration."
    default:
        errorMessage = "An unexpected error occurred. Please try again."
    }
}
```

## 🔄 Lifecycle Management

### Initialization

Dependency injection and setup:

```swift
init(
    alarmService: AlarmServiceProtocol,
    sceneService: SceneServiceProtocol,
    pinService: PINManagementServiceProtocol,
    lockoutService: AlarmLockoutServiceProtocol
) {
    self.alarmService = alarmService
    self.sceneService = sceneService
    self.pinService = pinService
    self.lockoutService = lockoutService
    
    // Start polling on initialization
    startPolling()
}
```

### Cleanup

Proper resource cleanup:

```swift
deinit {
    cancellables.removeAll()
    stopPolling()
}

func stopPolling() {
    pollingTimer?.invalidate()
    pollingTimer = nil
}
```

## 🧪 Testing

### Unit Testing

Test ViewModel logic in isolation:

```swift
func testAlarmStateRefresh() async {
    let mockAlarmService = MockAlarmService()
    let viewModel = AlarmViewModel(
        alarmService: mockAlarmService,
        sceneService: MockSceneService(),
        pinService: MockPINManagementService(),
        lockoutService: MockAlarmLockoutService()
    )
    
    await viewModel.refreshState()
    
    XCTAssertEqual(viewModel.currentState, .armedAway)
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertNil(viewModel.errorMessage)
}

func testPINValidation() {
    let mockPINService = MockPINManagementService()
    let viewModel = AlarmViewModel(/* ... */)
    
    let isValid = viewModel.validatePIN("123456")
    XCTAssertTrue(isValid)
    
    let isInvalid = viewModel.validatePIN("654321")
    XCTAssertFalse(isInvalid)
}
```

### Integration Testing

Test ViewModel with real services:

```swift
func testModeChangeFlow() async {
    let viewModel = createAlarmViewModel()
    
    // Request mode change
    viewModel.requestModeChange(.away)
    XCTAssertTrue(viewModel.showPINEntry)
    XCTAssertEqual(viewModel.pendingMode, .away)
    
    // Validate PIN
    let isValid = viewModel.validatePIN("123456")
    XCTAssertTrue(isValid)
    
    // Execute mode change
    await viewModel.executeModeChange()
    XCTAssertFalse(viewModel.showPINEntry)
    XCTAssertNil(viewModel.pendingMode)
}
```

### Mock Services

Test with mock implementations:

```swift
class MockAlarmService: AlarmServiceProtocol {
    var mockState: AlarmState = .unknown
    var shouldThrowError = false
    
    func fetchAlarmState() async throws -> AlarmState {
        if shouldThrowError {
            throw VeraHubError.networkError(URLError(.notConnectedToInternet))
        }
        return mockState
    }
}
```

## 🚀 Performance

### Optimization Strategies

- **@MainActor**: Ensures UI updates on main thread
- **Async/Await**: Non-blocking network operations
- **State Caching**: Reduces unnecessary API calls
- **Error Recovery**: Automatic retry logic

### Memory Management

- **Weak References**: Prevents retain cycles
- **Cancellables**: Proper Combine subscription cleanup
- **Timer Management**: Automatic timer invalidation

## 📊 State Flow

### Alarm State Changes

```
User Tap → requestModeChange() → showPINEntry = true
    ↓
PIN Entry → validatePIN() → executeModeChange()
    ↓
Service Call → refreshState() → UI Update
```

### Error Handling

```
Error Occurred → handleError() → errorMessage = "User-friendly message"
    ↓
UI Update ← Error Display ← State Change
```

## 📁 Files

- **AlarmViewModel.swift** - Main alarm ViewModel

## 🔗 Navigation

- **[Alarm System](../README.md)** - Main alarm system documentation
- **[Models](../Models/README.md)** - Alarm data models
- **[Services](../Services/README.md)** - Alarm services and business logic
- **[Views](../Views/README.md)** - SwiftUI components

---

The Alarm ViewModels provide the business logic and state management that powers the alarm system's user interface and user interactions.
