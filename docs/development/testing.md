# Testing Strategy

This guide covers the comprehensive testing strategy for the Home Panel App, including unit tests, integration tests, and UI tests.

**Current Implementation**: Comprehensive testing framework with unit tests, integration tests, and UI tests covering all major features and edge cases.

## 🧪 Testing Overview

### Testing Pyramid

```
┌─────────────────────────────────────────────────────────────────┐
│                        UI Tests                                │
│                    (End-to-End)                                │
├─────────────────────────────────────────────────────────────────┤
│                    Integration Tests                           │
│                   (Service Integration)                        │
├─────────────────────────────────────────────────────────────────┤
│                      Unit Tests                                │
│                   (Individual Components)                      │
└─────────────────────────────────────────────────────────────────┘
```

### Test Coverage Goals

- **Unit Tests**: >80% code coverage
- **Integration Tests**: Critical paths covered
- **UI Tests**: Main user flows covered
- **Performance Tests**: Key operations profiled

## 🔧 Unit Testing

### Test Structure

**Test Target**: `HomePanelAppTests`

**Test Organization**:
```
HomePanelAppTests/
├── Models/
│   ├── AlarmStateTests.swift
│   ├── AlarmModeTests.swift
│   ├── PINDataTests.swift
│   └── AppConfigurationTests.swift
├── Services/
│   ├── UnifiedAlarmServiceTests.swift
│   ├── SceneServiceCoordinatorTests.swift
│   ├── PINManagementServiceTests.swift
│   ├── KeychainServiceTests.swift
│   └── AlarmLockoutServiceTests.swift
├── ViewModels/
│   └── AlarmViewModelTests.swift
└── Utilities/
    ├── PINHasherTests.swift
    └── VeraHubAlarmStateParserTests.swift
```

### Model Tests

**AlarmState Tests**:
```swift
import XCTest
@testable import HomePanelApp

class AlarmStateTests: XCTestCase {
    
    func testAlarmStateRawValues() {
        XCTAssertEqual(AlarmState.disarmed.rawValue, "Disarmed")
        XCTAssertEqual(AlarmState.armedAway.rawValue, "Armed Away")
        XCTAssertEqual(AlarmState.armedStay.rawValue, "Armed Stay")
        XCTAssertEqual(AlarmState.armedNightStay.rawValue, "Armed Night-Stay")
        XCTAssertEqual(AlarmState.unknown.rawValue, "Unknown")
    }
    
    func testAlarmStateColors() {
        XCTAssertEqual(AlarmState.disarmed.displayColor, .green)
        XCTAssertEqual(AlarmState.armedAway.displayColor, .red)
        XCTAssertEqual(AlarmState.armedStay.displayColor, .orange)
        XCTAssertEqual(AlarmState.armedNightStay.displayColor, .purple)
        XCTAssertEqual(AlarmState.unknown.displayColor, .gray)
    }
    
    func testAlarmStateIcons() {
        XCTAssertEqual(AlarmState.disarmed.iconName, "lock.open.fill")
        XCTAssertEqual(AlarmState.armedAway.iconName, "lock.shield.fill")
        XCTAssertEqual(AlarmState.armedStay.iconName, "house.fill")
        XCTAssertEqual(AlarmState.armedNightStay.iconName, "moon.fill")
        XCTAssertEqual(AlarmState.unknown.iconName, "questionmark.circle.fill")
    }
}
```

**PINData Tests**:
```swift
class PINDataTests: XCTestCase {
    
    func testPINDataInitialization() {
        let pinData = PINData(pin: "123456", name: "Test User")
        
        XCTAssertEqual(pinData.name, "Test User")
        XCTAssertNotNil(pinData.id)
        XCTAssertNotNil(pinData.pinHash)
        XCTAssertNotNil(pinData.salt)
        XCTAssertNil(pinData.lastUsed)
    }
    
    func testPINVerification() {
        let pinData = PINData(pin: "123456", name: "Test User")
        
        XCTAssertTrue(pinData.verifyPIN("123456"))
        XCTAssertFalse(pinData.verifyPIN("654321"))
        XCTAssertFalse(pinData.verifyPIN("12345"))
        XCTAssertFalse(pinData.verifyPIN("1234567"))
    }
    
    func testPINDataCodable() throws {
        let pinData = PINData(pin: "123456", name: "Test User")
        
        let data = try JSONEncoder().encode(pinData)
        let decoded = try JSONDecoder().decode(PINData.self, from: data)
        
        XCTAssertEqual(pinData.name, decoded.name)
        XCTAssertEqual(pinData.pinHash, decoded.pinHash)
        XCTAssertEqual(pinData.salt, decoded.salt)
    }
}
```

### Service Tests

**AlarmService Tests**:
```swift
class AlarmServiceTests: XCTestCase {
    
    var mockAlarmService: MockAlarmService!
    var service: UnifiedAlarmService!
    
    override func setUp() {
        super.setUp()
        mockAlarmService = MockAlarmService()
        service = UnifiedAlarmService(hubService: mockHubService, config: mockConfig)
    }

**SceneService Tests**:
```swift
class SceneServiceTests: XCTestCase {
    
    var mockSceneService: MockSceneService!
    var service: SceneServiceCoordinator!
    
    override func setUp() {
        super.setUp()
        mockSceneService = MockSceneService()
        service = SceneServiceCoordinator(hubService: mockHubService, session: mockSession)
    }
    
    func testFetchAlarmState() async throws {
        // Given
        let expectedState = AlarmState.armedAway
        mockAlarmService.mockAlarmState = expectedState
        
        // When
        let result = try await service.fetchAlarmState()
        
        // Then
        XCTAssertEqual(result, expectedState)
    }
    
    func testFetchSceneList() async throws {
        // Given
        let expectedScenes = HubScopedSceneMap()
        expectedScenes["hub1"] = ["Set Away Mode": 1, "Set Stay Mode": 2]
        mockSceneService.mockSceneMap = expectedScenes
        
        // When
        let result = try await service.fetchSceneList(hubId: "hub1")
        
        // Then
        XCTAssertEqual(result, expectedScenes["hub1"])
    }
    
    func testSetAlarmMode() async throws {
        // Given
        let mode = AlarmMode.away
        let sceneMap = ["Set Away Mode": 1]
        let hubScopedMap = HubScopedSceneMap()
        hubScopedMap["hub1"] = sceneMap
        
        // When
        try await service.setAlarmMode(mode, hubScopedSceneMap: hubScopedMap, hubId: "hub1")
        
        // Then
        XCTAssertTrue(mockSceneService.setAlarmModeCalled)
        XCTAssertEqual(mockSceneService.lastMode, mode)
        XCTAssertEqual(mockSceneService.lastHubScopedMap, hubScopedMap)
    }
}

// MARK: - Mock Services

class MockAlarmService: AlarmServiceProtocol {
    var mockAlarmState: AlarmState = .unknown
    
    func fetchAlarmState() async throws -> AlarmState {
        return mockAlarmState
    }
}

class MockSceneService: SceneServiceProtocol {
    var mockSceneMap: HubScopedSceneMap = HubScopedSceneMap()
    var setAlarmModeCalled = false
    var lastMode: AlarmMode?
    var lastHubScopedMap: HubScopedSceneMap?
    
    func fetchSceneList(hubId: String) async throws -> HubScopedSceneMap {
        return mockSceneMap
    }
    
    func setAlarmMode(_ mode: AlarmMode, hubScopedSceneMap: HubScopedSceneMap, hubId: String) async throws {
        setAlarmModeCalled = true
        lastMode = mode
        lastHubScopedMap = hubScopedSceneMap
    }
}
```

**PINManagementService Tests**:
```swift
class PINManagementServiceTests: XCTestCase {
    
    var service: PINManagementService!
    
    override func setUp() {
        super.setUp()
        service = PINManagementService()
    }
    
    func testSetMasterPIN() {
        // Given
        let pin = "123456"
        
        // When
        let result = service.setMasterPIN(pin)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertNotNil(service.masterPINData)
    }
    
    func testAddUserPIN() {
        // Given
        let pin = "654321"
        let name = "Test User"
        
        // When
        let result = service.addUserPIN(pin, name: name)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(service.userPINs.count, 1)
        XCTAssertEqual(service.userPINs.first?.name, name)
    }
    
    func testVerifyPIN() {
        // Given
        let pin = "123456"
        service.setMasterPIN(pin)
        
        // When
        let result = service.verifyPIN(pin)
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testVerifyInvalidPIN() {
        // Given
        let pin = "123456"
        service.setMasterPIN(pin)
        
        // When
        let result = service.verifyPIN("654321")
        
        // Then
        XCTAssertFalse(result)
    }
}
```

### ViewModel Tests

**AlarmViewModel Tests**:
```swift
@MainActor
class AlarmViewModelTests: XCTestCase {
    
    var viewModel: AlarmViewModel!
    var mockConfig: MockAppConfiguration!
    var mockSceneService: MockSceneService!
    var mockAlarmService: MockAlarmService!
    
    override func setUp() {
        super.setUp()
        mockConfig = MockAppConfiguration()
        mockSceneService = MockSceneService()
        mockAlarmService = MockAlarmService()
        
        viewModel = AlarmViewModel(
            config: mockConfig,
            sceneService: mockSceneService,
            alarmService: mockAlarmService
        )
    }
    
    func testInitialState() {
        XCTAssertEqual(viewModel.currentState, .unknown)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showPINEntry)
        XCTAssertNil(viewModel.pendingMode)
    }
    
    func testRefreshState() async {
        // Given
        let expectedState = AlarmState.armedAway
        mockAlarmService.mockAlarmState = expectedState
        
        // When
        await viewModel.refreshState()
        
        // Then
        XCTAssertEqual(viewModel.currentState, expectedState)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testChangeMode() {
        // Given
        let mode = AlarmMode.away
        
        // When
        viewModel.changeMode(mode)
        
        // Then
        XCTAssertTrue(viewModel.showPINEntry)
        XCTAssertEqual(viewModel.pendingMode, mode)
    }
}
```

## 🔗 Integration Testing

### Vera Hub Integration Tests

**Real API Testing**:
```swift
class VeraHubIntegrationTests: XCTestCase {
    
    var alarmService: UnifiedAlarmService!
    var sceneService: SceneServiceCoordinator!
    var config: AppConfiguration!
    
    override func setUp() {
        super.setUp()
        config = AppConfiguration()
        config.veraHubIP = "192.168.1.100" // Test Vera Hub IP
        let hubService = HubServiceCoordinator()
        alarmService = UnifiedAlarmService(hubService: hubService, config: config)
        sceneService = SceneServiceCoordinator(hubService: hubService, session: URLSession.shared)
    }
    
    func testRealVeraHubConnection() async throws {
        // Test with real Vera Hub
        let scenes = try await sceneService.fetchSceneList(hubId: "test-hub")
        XCTAssertFalse(scenes.isEmpty)
    }
    
    func testRealAlarmStateFetching() async throws {
        let alarmState = try await alarmService.fetchAlarmState()
        XCTAssertNotEqual(alarmState, .unknown)
    }
    
    func testRealSceneExecution() async throws {
        let scenes = try await sceneService.fetchSceneList(hubId: "test-hub")
        guard let sceneId = scenes["Set Away Mode"] else {
            XCTFail("Set Away Mode scene not found")
            return
        }
        
        // This test should be run carefully as it changes alarm state
        // let hubScopedMap = HubScopedSceneMap()
        // hubScopedMap["test-hub"] = scenes
        // try await sceneService.setAlarmMode(.away, hubScopedSceneMap: hubScopedMap, hubId: "test-hub")
    }
}
```

### Network Error Testing

**Network Error Scenarios**:
```swift
class NetworkErrorTests: XCTestCase {
    
    func testNetworkTimeout() async {
        let config = AppConfiguration()
        config.veraHubIP = "192.168.1.999" // Invalid IP
        let hubService = HubServiceCoordinator()
        let service = SceneServiceCoordinator(hubService: hubService, session: URLSession.shared)
        
        do {
            _ = try await service.fetchSceneList(hubId: "test-hub")
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is HubError)
        }
    }
    
    func testInvalidResponse() async {
        // Test with mock service that returns invalid data
        let mockService = MockSceneService()
        mockService.shouldReturnInvalidData = true
        
        do {
            _ = try await mockService.fetchSceneList(hubId: "test-hub")
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is HubError)
        }
    }
}
```

## 🎨 UI Testing

### UI Test Structure

**Test Target**: `HomePanelAppUITests`

**Test Organization**:
```
HomePanelAppUITests/
├── AlarmTabTests.swift
├── SettingsTests.swift
├── PINEntryTests.swift
└── ErrorHandlingTests.swift
```

### Alarm Tab Tests

**Basic UI Tests**:
```swift
class AlarmTabTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testAlarmTabDisplay() {
        // Test that alarm tab is displayed
        XCTAssertTrue(app.buttons["Away"].exists)
        XCTAssertTrue(app.buttons["Stay"].exists)
        XCTAssertTrue(app.buttons["Night-Stay"].exists)
        XCTAssertTrue(app.buttons["Disarm"].exists)
    }
    
    func testModeButtonTaps() {
        // Test mode button interactions
        app.buttons["Away"].tap()
        XCTAssertTrue(app.sheets["PIN Entry"].exists)
        
        app.buttons["Cancel"].tap()
        XCTAssertFalse(app.sheets["PIN Entry"].exists)
    }
    
    func testSettingsAccess() {
        // Test settings access
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }
}
```

**PIN Entry Tests**:
```swift
class PINEntryTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testPINEntryDisplay() {
        // Open PIN entry
        app.buttons["Away"].tap()
        
        // Test PIN entry elements
        XCTAssertTrue(app.staticTexts["Enter PIN to Away"].exists)
        XCTAssertTrue(app.buttons["1"].exists)
        XCTAssertTrue(app.buttons["2"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
    }
    
    func testPINEntryInput() {
        // Open PIN entry
        app.buttons["Away"].tap()
        
        // Enter PIN
        app.buttons["1"].tap()
        app.buttons["2"].tap()
        app.buttons["3"].tap()
        app.buttons["4"].tap()
        app.buttons["5"].tap()
        app.buttons["6"].tap()
        
        // PIN should auto-submit
        XCTAssertFalse(app.sheets["PIN Entry"].exists)
    }
    
    func testPINEntryCancel() {
        // Open PIN entry
        app.buttons["Away"].tap()
        
        // Cancel PIN entry
        app.buttons["Cancel"].tap()
        
        // PIN entry should be dismissed
        XCTAssertFalse(app.sheets["PIN Entry"].exists)
    }
}
```

### Settings Tests

**Settings Navigation**:
```swift
class SettingsTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testSettingsNavigation() {
        // Open settings
        app.buttons["Settings"].tap()
        
        // Test settings elements
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        XCTAssertTrue(app.textFields["Vera Hub IP"].exists)
        XCTAssertTrue(app.buttons["PIN Management"].exists)
    }
    
    func testVeraHubIPConfiguration() {
        // Open settings
        app.buttons["Settings"].tap()
        
        // Test IP configuration
        let ipField = app.textFields["Vera Hub IP"]
        ipField.tap()
        ipField.clearText()
        ipField.typeText("192.168.1.100")
        
        // Navigate back
        app.buttons["Done"].tap()
    }
    
    func testPINManagementAccess() {
        // Open settings
        app.buttons["Settings"].tap()
        
        // Open PIN management
        app.buttons["PIN Management"].tap()
        
        // Test PIN management elements
        XCTAssertTrue(app.navigationBars["PIN Management"].exists)
    }
}
```

## 📊 Performance Testing

### Memory Testing

**Memory Usage Tests**:
```swift
class MemoryTests: XCTestCase {
    
    func testMemoryUsage() {
        // Test memory usage during normal operation
        let config = AppConfiguration()
        let viewModel = AlarmViewModel(config: config)
        
        // Simulate normal usage
        for _ in 0..<100 {
            viewModel.refreshState()
        }
        
        // Check memory usage
        let memoryUsage = getMemoryUsage()
        XCTAssertLessThan(memoryUsage, 100 * 1024 * 1024) // 100MB limit
    }
    
    func testMemoryLeaks() {
        // Test for memory leaks
        weak var weakViewModel: AlarmViewModel?
        
        autoreleasepool {
            let config = AppConfiguration()
            let viewModel = AlarmViewModel(config: config)
            weakViewModel = viewModel
            
            // Simulate usage
            viewModel.refreshState()
        }
        
        // ViewModel should be deallocated
        XCTAssertNil(weakViewModel)
    }
}
```

### Performance Benchmarks

**Performance Tests**:
```swift
class PerformanceTests: XCTestCase {
    
    func testAlarmStateFetchingPerformance() {
        let config = AppConfiguration()
        let service = UnifiedAlarmService(hubService: hubService, config: config)
        
        measure {
            let expectation = self.expectation(description: "Alarm state fetched")
            
            Task {
                do {
                    _ = try await service.fetchAlarmState()
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to fetch alarm state: \(error)")
                }
            }
            
            waitForExpectations(timeout: 5.0)
        }
    }
    
    func testPINVerificationPerformance() {
        let pinData = PINData(pin: "123456", name: "Test")
        
        measure {
            for _ in 0..<1000 {
                _ = pinData.verifyPIN("123456")
            }
        }
    }
}
```

## 🔧 Test Configuration

### Test Environment Setup

**Test Configuration**:
```swift
class TestConfiguration {
    static let shared = TestConfiguration()
    
    let testVeraHubIP = "192.168.1.100"
    let testPIN = "123456"
    let testTimeout: TimeInterval = 5.0
    
    private init() {}
}
```

**Mock Data**:
```swift
class MockData {
    static let testScenes = [
        "Set Away Mode": 1,
        "Set Stay Mode": 2,
        "Set Night-Stay Mode": 3,
        "Set Disarm Mode": 4
    ]
    
    static let testAlarmState = AlarmState.armedAway
    static let testPINData = PINData(pin: "123456", name: "Test User")
}
```

### Test Utilities

**Test Helpers**:
```swift
extension XCTestCase {
    
    func waitForAsync<T>(_ asyncBlock: @escaping () async throws -> T) throws -> T {
        var result: Result<T, Error>?
        let expectation = expectation(description: "Async operation")
        
        Task {
            do {
                let value = try await asyncBlock()
                result = .success(value)
            } catch {
                result = .failure(error)
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        return try result!.get()
    }
    
    func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}
```

## 📈 Test Reporting

### Code Coverage

**Coverage Goals**:
- Overall: >80%
- Critical paths: >90%
- Services: >85%
- ViewModels: >80%
- Models: >95%

**Coverage Reporting**:
```bash
# Generate coverage report
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' test -enableCodeCoverage YES

# View coverage report
xcrun xccov view --report DerivedData/Logs/Test/*.xcresult
```

### Test Results

**Test Reporting**:
- JUnit XML output
- HTML coverage reports
- Performance metrics
- Memory usage reports

## 🔧 Continuous Integration

### GitHub Actions

**CI Configuration**:
```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Select Xcode Version
      run: sudo xcode-select -s /Applications/Xcode_26.0.1.app
    
    - name: Run Tests
      run: |
        xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' test -enableCodeCoverage YES
    
    - name: Upload Coverage
      uses: codecov/codecov-action@v3
```

---

This testing strategy provides comprehensive coverage for the Home Panel App, ensuring reliability, performance, and maintainability. Follow the testing guidelines and run tests regularly to maintain code quality.
