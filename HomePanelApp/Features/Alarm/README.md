# Alarm System

The alarm system is the core feature of the Home Panel App, providing secure control over Vera Hub alarm systems with advanced multi-PIN security and real-time state monitoring.

## 🚨 Overview

The alarm system provides real-time monitoring and control of Vera Hub alarm states with comprehensive security features including PIN protection, lockout system, and cross-device synchronization.

## 🏗️ Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    Alarm System Architecture                   │
├─────────────────────────────────────────────────────────────────┤
│  AlarmTabView  │  AlarmViewModel  │  UnifiedAlarmService      │
│  PINEntryView  │  PINManagement   │  AlarmLockoutService      │
└─────────────────┬─────────────────┬─────────────────┬───────────┘
                  │                 │                 │
┌─────────────────▼─────────────────▼─────────────────▼───────────┐
│                    Data Models                                │
├─────────────────────────────────────────────────────────────────┤
│  AlarmState  │  AlarmMode  │  PINData  │  MasterPINData       │
└─────────────────────────────────────────────────────────────────┘
```

### Modern Architecture Features

- **UnifiedAlarmService**: Unified alarm service integrating with hub architecture
- **HubServiceProtocol Integration**: Uses modern hub service protocol for multi-hub support
- **Shared LockoutManager**: Common lockout functionality across services
- **Protocol-Based Design**: Testable and modular service architecture
- **Reactive UI**: @Published properties for automatic UI updates
- **Actor-Based Concurrency**: Thread-safe operations with actor-based services

### State Management

The alarm system uses MVVM pattern with reactive state management:

```swift
@MainActor
class AlarmViewModel: ObservableObject {
    @Published var currentState: AlarmState = .unknown
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showPINEntry = false
    @Published var pendingMode: AlarmMode?
}
```

## 🔧 Core Features

### Alarm States

The system supports five alarm states:

| State | Description | Color | Icon |
|-------|-------------|-------|------|
| `disarmed` | System is disarmed | Green | `lock.open.fill` |
| `armedAway` | Armed for away mode | Red | `lock.shield.fill` |
| `armedStay` | Armed for stay mode | Orange | `house.fill` |
| `armedNightStay` | Armed for night-stay | Purple | `moon.fill` |
| `unknown` | State cannot be determined | Gray | `questionmark.circle.fill` |

### Alarm Modes

Four alarm modes can be set:

| Mode | Scene Name | Expected State | Button Color |
|------|------------|----------------|--------------|
| `away` | "Set Away Mode" | `armedAway` | Red |
| `stay` | "Set Stay Mode" | `armedStay` | Orange |
| `nightStay` | "Set Night-Stay Mode" | `armedNightStay` | Purple |
| `disarm` | "Set Disarm Mode" | `disarmed` | Green |

### Real-Time Monitoring

- **Auto-refresh**: State polls every 5 seconds
- **Visual feedback**: Dynamic background colors and icons
- **Loading states**: Progress indicators during operations
- **Error handling**: User-friendly error messages

## 🔐 Security Features

### Multi-PIN System

**Master PIN**:
- Required for PIN management
- Administrative functions
- Stored securely in Keychain

**User PINs**:
- Multiple PINs with names
- Family member access
- Individual usage tracking

**PIN Validation**:
- 6-digit requirement
- SHA-256 hashing with salt
- Secure verification methods

### Lockout Protection

**Advanced Lockout System**:
- 7 attempts trigger first lockout (7 minutes)
- Prime number delays: 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97 minutes
- Swings through 22 prime numbers like a pendulum - forward then backward (no artificial cap)
- Uses shared LockoutManager for base functionality
- Automatic expiration handling

**Prime Number Mathematical Easter Egg**:

The lockout system employs a sophisticated prime number sequence (7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97 minutes) that swings like a pendulum - forward then backward - as a subtle nod to the mathematical beauty and importance of prime numbers. This design provides both mathematical elegance and practical security benefits, mirroring the natural ebb and flow of the universe.

**Mathematical Significance**:
- **Fundamental Building Blocks**: Primes are the atoms of number theory, indivisible by design
- **Unique Properties**: Each prime has no divisors other than 1 and itself
- **Irregular Distribution**: Prime gaps follow no simple pattern, creating natural unpredictability
- **Mathematical Elegance**: Primes represent the purest form of mathematical randomness
- **Cryptographic Foundation**: Primes are the mathematical basis of modern cryptography

**User Experience Considerations**:
- **Reasonable Starting Point**: 7 minutes is manageable for legitimate users who make honest mistakes
- **Progressive Escalation**: Each step increases the burden on attackers while remaining accessible to users
- **Pendulum Motion**: Swings forward through primes (7→97), then backward (97→11), like the ebb and flow of the universe
- **Clear Feedback**: Users receive exact remaining time, reducing frustration and uncertainty

**Design Rationale**:
- **Mathematical Easter Egg**: Chosen as a subtle nod to the mathematical beauty and importance of prime numbers
- **Practical Benefits**: Prime numbers provide both mathematical elegance and practical security benefits
- **Pendulum Motion**: Swings through 22 prime numbers like a pendulum - 22 forward then 20 backward, creating a beautiful ebb and flow pattern
- **Optimal Balance**: Strikes the perfect balance between security hardening and user accessibility
- **Research-Based**: Industry research on optimal lockout timing informed this specific sequence selection

**Lockout States**:
- `isLockedOut()` - Check current lockout status
- `recordFailedAttempt()` - Increment failure count
- `recordSuccessfulAttempt()` - Reset failure count
- `resetLockout()` - Manual lockout reset


## 🎨 User Interface

### AlarmTabView

Main alarm interface with:

**Header Section**:
- Settings gear icon
- Lockout status indicator
- Current state display

**State Display**:
- Large icon with state-specific color
- State name with appropriate styling
- Loading indicator during operations
- Error message display

**Mode Buttons**:
- 2x2 grid layout
- Color-coded buttons
- SF Symbol icons
- Tap gestures for mode changes

**Footer**:
- Last updated timestamp
- Auto-refresh indicator

### PINEntryView

### Traffic Estimates

Real-time travel estimates for favorite destinations:

**Traffic Information Display**:
- Travel time estimates with current traffic conditions
- Distance to favorite destinations  
- Expected arrival times
- Formatted travel time (e.g., "25 min", "1h 15m")
- Distance in miles with one decimal precision

**Features**:
- Current location-based estimates
- Integration with iOS MapKit for traffic data
- Support for multiple favorite destinations
- Privacy-conscious location handling
- Permission-based access to location services

**Implementation**:
- `TrafficService`: Service for travel time estimates
- `DestinationStore`: Management of favorite destinations  
- `TrafficView`: SwiftUI component displaying traffic estimates
- `FavoriteDestination`: Model for stored destinations with coordinates


Real-time travel information for favorite destinations:

**Traffic Information Display**:
- Live ETA calculations using MapKit routing
- Real-time traffic conditions
- Distance to favorite destinations
- Expected arrival times
- Formatted travel time (e.g., "25 min", "1h 15m")
- Distance in miles with one decimal precision

**Features**:
- Location-based routing from current position
- Integration with iOS CoreLocation
- Automatic traffic data updates
- Support for multiple favorite destinations
- Privacy-conscious location handling
- Permission-based access

**Implementation**:
- `TrafficService`: Core service for routing and ETA calculations
- `DestinationStore`: Management of favorite destinations  
- `TrafficView`: SwiftUI component displaying traffic information
- `FavoriteDestination`: Model for stored destinations with coordinates


Secure PIN entry modal:

**PIN Display**:
- 6 dots showing entry progress
- Visual feedback for each digit
- Auto-submit when complete

**Keypad**:
- Phone-style 3x4 layout
- Number buttons with letters
- Delete and submit buttons
- Disabled state during lockout

**Error Handling**:
- Clear error messages
- Retry functionality
- Lockout status display

## 🔄 State Flow

### Alarm State Changes

```
User Tap → PIN Entry → PIN Validation → Service Call → State Update
    ↓           ↓            ↓              ↓            ↓
UI Update ← Modal Close ← Success/Error ← API Response ← UI Refresh
```

### PIN Verification Flow

```
PIN Entry → Hash Generation → Keychain Lookup → Verification → Success/Error
     ↓             ↓              ↓              ↓            ↓
UI Update ← Hash Comparison ← PIN Retrieval ← Salt Lookup ← UI Feedback
```

### Lockout Flow

```
Failed Attempt → Counter Increment → Lockout Check → Lockout Period → UI Update
       ↓               ↓                ↓              ↓            ↓
Error Message ← Attempt Count ← Prime Number ← Timer Start ← Lockout Display
```

## 🌐 Vera Hub Integration

### API Endpoints

**Scene List**:
```
GET http://{IP}:3480/data_request?id=user_data
```

**Scene Execution**:
```
GET http://{IP}:3480/data_request?id=lu_action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=RunScene&SceneNum={ID}
```

**Alarm State**:
```
GET http://{IP}:3480/data_request?id=status&DeviceNum=7&output_format=json
```

### Scene Mapping

Dynamic scene ID mapping:
- Fetches scene list at startup
- Maps scene names to IDs
- Handles scene not found errors
- Caches mapping for performance

### Error Handling

Comprehensive error management:
- Network connectivity issues
- Invalid scene IDs
- Device not found errors
- JSON parsing errors
- Timeout handling

## 🧪 Testing

### Unit Testing

Test individual components:

```swift
func testAlarmStateParsing() {
    let data = mockVeraHubResponse.data(using: .utf8)!
    let state = try! parseAlarmState(from: data)
    XCTAssertEqual(state, .armedAway)
}

func testPINVerification() {
    let pinData = PINData(pin: "123456", name: "Test")
    XCTAssertTrue(pinData.verifyPIN("123456"))
    XCTAssertFalse(pinData.verifyPIN("654321"))
}
```

### Integration Testing

Test service interactions:

```swift
func testAlarmModeChange() async throws {
    let viewModel = createAlarmViewModel()
    await viewModel.setAlarmMode(.away)
    XCTAssertEqual(viewModel.currentState, .armedAway)
}
```

### UI Testing

Test user interactions:

```swift
func testPINEntry() {
    let app = XCUIApplication()
    app.buttons["Away"].tap()
    app.buttons["1"].tap()
    app.buttons["2"].tap()
    // ... continue with PIN entry
}
```

## 🔧 Configuration

### Settings

**Vera Hub IP**: Configurable IP address
**Alarm Device ID**: Hardcoded device ID (7)
**Refresh Interval**: 5-second auto-refresh
**Scene Mapping**: Dynamic from Vera Hub

### PIN Management

**Master PIN Setup**: Required for first use
**User PIN Management**: Add/remove/edit PINs
**Lockout Reset**: Administrative function
**Secure Storage**: Keychain-based credential management

## 🚀 Performance

### Optimization

- **Lazy Loading**: Services initialized on demand
- **State Caching**: Reduces API calls
- **Error Recovery**: Automatic retry logic
- **Memory Management**: Proper cleanup

### Monitoring

- **State Polling**: Efficient 5-second intervals
- **Error Tracking**: Comprehensive logging
- **Performance Metrics**: Response time monitoring
- **Memory Usage**: Stream management

## 🔮 Future Enhancements

### Planned Features

- **Push Notifications**: Alarm event notifications
- **Widgets**: Home screen widgets
- **Apple Watch**: Companion app
- **Voice Control**: Siri integration

### Technical Improvements

- **Offline Mode**: Local state caching
- **Batch Operations**: Multiple state changes
- **Advanced Analytics**: Usage statistics
- **Custom Scenes**: User-defined scenes

## 📁 File Structure

- **[Models](Models/README.md)** - Alarm states, modes, and PIN data structures
- **[Services](Services/README.md)** - Vera Hub integration and security services
- **[ViewModels](ViewModels/README.md)** - Business logic and state management
- **[Views](Views/README.md)** - SwiftUI user interface components

## 🔗 Navigation

- **[Features Overview](../README.md)** - All app features
- **[Main App Architecture](../../README.md)** - Overall app architecture
- **[Core Infrastructure](../../Core/README.md)** - Shared infrastructure
- **[Shared Components](../../Shared/README.md)** - Reusable components

---

The alarm system provides a comprehensive, secure, and user-friendly interface for controlling Vera Hub alarm systems with advanced security features and real-time monitoring.
