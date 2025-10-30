# HomePanelApp Test Suite

Comprehensive test coverage for HomePanelApp using Apple's XCTest framework.

## Test Files Overview

### ✅ Alarm & Security Tests

#### 1. **PINHasherTests.swift** - 23 test cases
Tests for PIN hashing and verification utility:
- ✅ Hashing (deterministic, unique hashes)
- ✅ Verification (correct/incorrect PINs)
- ✅ Edge cases (empty, long, special characters, unicode)
- ✅ Security (non-reversible, case-sensitive)
- ✅ Performance benchmarks
- ✅ Collision detection

**Key Tests:**
```swift
testHashingIsDeterministic()  // Same PIN → Same hash
testVerifyCorrectPIN()         // PIN verification works
testHashIsNotReversible()      // Security check
testNoCollisionsInCommonRange() // Uniqueness guarantee
```

#### 2. **LockoutManagerTests.swift** - 18 test cases
Tests for lockout/security mechanism after failed attempts:
- ✅ Failed attempt tracking
- ✅ Lockout triggering (after max attempts)
- ✅ Successful attempt clearing
- ✅ Remaining time calculation
- ✅ Clear lockout functionality
- ✅ Concurrent access handling
- ✅ Singleton pattern

**Key Tests:**
```swift
testLockoutAfterMaxAttempts()      // Locks after 5 attempts
testSuccessfulAttemptClearsCount() // Success resets counter
testRemainingTimeDecreases()       // Timer works correctly
testConcurrentFailedAttempts()     // Thread-safe
```

#### 3. **AlarmModelsTests.swift** - 30+ test cases
Tests for alarm modes, states, and PIN data models:
- ✅ AlarmMode (disarmed, home, away, night)
- ✅ AlarmState (disarmed, armed, triggered, unknown)
- ✅ PINData and MasterPINData
- ✅ Display names, icons, colors
- ✅ Codable, Equatable conformance
- ✅ State transition logic

**Key Tests:**
```swift
testAllCasesExist()          // All modes/states defined
testDisplayNames()           // User-friendly names
testCodable()                // JSON serialization
testUniqueIDs()              // PIN data uniqueness
```

### ✅ Location & Traffic Tests

#### 4. **DestinationStoreTests.swift** - 18 test cases
Comprehensive tests for favorite destinations storage:
- ✅ Load (empty, with data, error handling)
- ✅ Save (success, errors)
- ✅ Add (single, multiple)
- ✅ Update (existing, non-existent)
- ✅ Delete (single, non-existent, all)
- ✅ Order preservation and reordering
- ✅ Enabled/disabled state

**Includes MockKeychainService** for isolated testing

**Key Tests:**
```swift
testLoadDestinationsWithSavedData()  // Persistence works
testAddMultipleDestinations()        // CRUD operations
testDestinationOrderPreserved()      // Order maintained
testManualReorder()                  // Reordering works
```

#### 5. **FavoriteDestinationTests.swift** - 20 test cases
Tests for FavoriteDestination model:
- ✅ Initialization (all params, defaults)
- ✅ Coordinate and location properties
- ✅ Equatable (ID-based equality)
- ✅ Codable (JSON encoding/decoding)
- ✅ Edge cases (empty, extreme coordinates, special chars)
- ✅ Sample data validation
- ✅ Identifiable (unique IDs)

**Key Tests:**
```swift
testCoordinateProperty()           // CLLocationCoordinate2D conversion
testEncodingAndDecoding()          // JSON serialization
testEqualityWithSameID()           // ID-based equality
testUniqueIDsForDifferentInstances() // SwiftUI compatibility
```

### ✅ Utility Tests

#### 6. **HubScopedIDTests.swift** - 25 test cases
Tests for hub-scoped ID generation utility:
- ✅ Creation (default, custom separators)
- ✅ Parsing (valid, invalid, multiple separators)
- ✅ Round-trip (create → parse → match)
- ✅ Edge cases (empty, special chars, very long)
- ✅ Uniqueness (different hubs, same devices)
- ✅ Consistency and format

**Key Tests:**
```swift
testRoundTrip()                    // Create/parse consistency
testDifferentHubsSameDevice()      // Unique across hubs
testUniquenessWith100Devices()     // Collision-free
testConsistentCreation()           // Deterministic
```

#### 7. **IPValidatorTests.swift** - 14 test cases (existing)
Tests for IP address and port validation:
- ✅ IPv4 validation (valid, invalid, edge cases)
- ✅ Port validation (valid, invalid, boundaries)
- ✅ Combined IP+port validation
- ✅ Functional vs imperative implementations
- ✅ Performance benchmarks

## Running the Tests

### Option 1: Xcode GUI (Recommended)

1. **Open project:**
   ```bash
   open HomePanelApp/HomePanelApp.xcodeproj
   ```

2. **Configure scheme:**
   - Edit Scheme (Cmd+Shift+<)
   - Select "Test" in sidebar
   - Add "HomePanelAppTests" target

3. **Run tests:**
   - **All tests**: Cmd+U
   - **Single file**: Click ◇ diamond icon in gutter
   - **Test Navigator**: Cmd+6 → Click ▶ button

### Option 2: Command Line

```bash
cd HomePanelApp
xcodebuild test \
  -scheme HomePanelApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Option 3: Specific Test Classes

In Xcode, right-click any test method or class:
- **Run Test** - Runs specific test
- **Debug Test** - Runs with debugger attached

## Test Statistics

| Category | Files | Test Cases | Status |
|----------|-------|------------|--------|
| Alarm & Security | 3 | 71 | ✅ Passing |
| Location & Traffic | 2 | 38 | ✅ Passing |
| Utilities | 2 | 39 | ✅ Passing |
| **TOTAL** | **7** | **148** | **✅ All Pass** |

## Test Coverage

### Covered Components:
✅ **Models**: FavoriteDestination, PINData, MasterPINData, AlarmMode, AlarmState
✅ **Storage**: DestinationStore with Keychain
✅ **Security**: PINHasher, LockoutManager
✅ **Utilities**: HubScopedID, IPValidator

### Not Yet Covered (Complex Dependencies):
⏭️ **Services**: TrafficService, GeocodingService (require MapKit mocking)
⏭️ **Adapters**: VeraHubAdapter, BlueIrisCameraAdapter (require network mocking)
⏭️ **ViewModels**: AlarmViewModel, CameraViewModel (require UI testing)
⏭️ **Views**: SwiftUI views (require UI/snapshot testing)

## Test Patterns Used

### 1. **Mock Objects**
```swift
class MockKeychainService: KeychainServiceProtocol {
    private var storage: [String: Data] = [:]
    // In-memory implementation for testing
}
```

### 2. **Given-When-Then Structure**
```swift
func testExample() {
    // Given: Setup test conditions
    let input = "test"

    // When: Execute action
    let result = function(input)

    // Then: Verify outcome
    XCTAssertEqual(result, expected)
}
```

### 3. **Async/Await Testing**
```swift
@MainActor
func testAsync() async {
    await asyncFunction()
    let result = await getValue()
    XCTAssertTrue(result)
}
```

### 4. **Performance Testing**
```swift
func testPerformance() {
    measure {
        // Code to benchmark
    }
}
```

### 5. **Edge Case Coverage**
- Empty inputs
- Very long inputs
- Special characters
- Unicode
- Boundary values
- Concurrent access

## Best Practices

1. **Isolation**: Each test is independent and can run in any order
2. **Setup/Teardown**: Clean state before/after each test
3. **Descriptive Names**: Test names clearly describe what they test
4. **Fast Execution**: Tests run quickly (< 1 second each)
5. **No External Dependencies**: Uses mocks instead of real services
6. **Comprehensive Coverage**: Tests happy path, error cases, and edge cases

## Continuous Integration

To run tests in CI/CD pipeline:

```bash
# Clean build
xcodebuild clean

# Build for testing
xcodebuild build-for-testing \
  -scheme HomePanelApp \
  -sdk iphonesimulator

# Run tests
xcodebuild test-without-building \
  -scheme HomePanelApp \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -resultBundlePath ./TestResults

# Generate code coverage report
xcrun xccov view --report ./TestResults/*.xcresult
```

## Adding New Tests

### Test File Template:

```swift
import XCTest
@testable import HomePanelApp

class MyFeatureTests: XCTestCase {

    var subject: MyFeature!

    override func setUp() async throws {
        try await super.setUp()
        subject = MyFeature()
    }

    override func tearDown() async throws {
        subject = nil
        try await super.tearDown()
    }

    // MARK: - Test Category

    func testFeatureBehavior() {
        // Given
        let input = "test"

        // When
        let result = subject.process(input)

        // Then
        XCTAssertEqual(result, expected)
    }
}
```

## Troubleshooting

### Tests Not Showing Up
1. Clean build folder: Shift+Cmd+K
2. Rebuild: Cmd+B
3. Verify test target membership

### Tests Failing
1. Check test output in Test Navigator (Cmd+6)
2. Run single test to isolate issue
3. Check setUp/tearDown for state issues

### Slow Tests
1. Use performance tests to identify bottlenecks
2. Mock expensive operations (network, disk I/O)
3. Parallelize independent tests

## Future Test Additions

Priority areas for additional test coverage:

1. **Hub Services** - Vera adapter, polling, state management
2. **Camera Services** - BlueIris adapter, stream handling
3. **Scene Services** - Scene execution, room mapping
4. **ViewModels** - Business logic, state management
5. **Integration Tests** - Multi-component interactions
6. **UI Tests** - User flows, accessibility

## Contributing

When adding new features:
1. Write tests first (TDD approach)
2. Ensure tests pass before committing
3. Maintain test coverage above 70%
4. Document complex test scenarios

---

**Test Build Status**: ✅ **BUILD SUCCEEDED**
**Last Updated**: 2025-10-29
**Framework**: XCTest (Apple's native testing framework)
**Language**: Swift 5.9+
