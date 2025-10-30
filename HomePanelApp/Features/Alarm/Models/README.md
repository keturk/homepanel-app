# Alarm Models

This directory contains the data models and business entities for the alarm system, including alarm states, modes, and PIN data structures.

## 📊 Data Models

### AlarmState

Represents the current state of the Vera Hub alarm system.

```swift
public enum AlarmState: String, CaseIterable, Codable {
    case disarmed = "0"
    case armedAway = "1"
    case armedStay = "2"
    case armedNightStay = "3"
    case unknown = "unknown"
}
```

**Properties:**
- `rawValue`: String representation from Vera Hub API
- `backgroundColor`: SwiftUI color for UI display
- `iconName`: SF Symbol name for state icon
- `displayName`: Human-readable state name

**Usage:**
```swift
let currentState = AlarmState.armedAway
print(currentState.displayName) // "Armed Away"
print(currentState.backgroundColor) // Color.red
```

### AlarmMode

Represents alarm mode operations and their expected outcomes.

```swift
public enum AlarmMode: String, CaseIterable, Codable {
    case away = "away"
    case stay = "stay"
    case nightStay = "nightStay"
    case disarm = "disarm"
}
```

**Properties:**
- `sceneName`: Vera Hub scene name for mode change
- `expectedState`: Target alarm state after execution
- `buttonColor`: SwiftUI color for mode button
- `iconName`: SF Symbol name for mode icon

**Usage:**
```swift
let mode = AlarmMode.away
print(mode.sceneName) // "Set Away Mode"
print(mode.expectedState) // .armedAway
```

### PINData

Secure storage structure for user PIN information.

```swift
public struct PINData: Codable, Identifiable {
    public let id: UUID
    public let pinHash: String  // SHA-256 hash of the PIN
    public let salt: String     // Random salt used for hashing
    public let name: String
    public let createdAt: Date
    public var lastUsed: Date?
}
```

**Security Features:**
- PIN never stored in plain text
- SHA-256 hashing with random salt
- Unique identifier for management
- Creation and usage timestamps

**Verification Method:**
```swift
func verifyPIN(_ pin: String) -> Bool {
    return PINHasher.hashPIN(pin, salt: self.salt) == self.pinHash
}
```

### MasterPINData

Secure storage structure for master PIN information.

```swift
public struct MasterPINData: Codable {
    public let pinHash: String  // SHA-256 hash
    public let salt: String     // Random salt
    public var lastUsed: Date?
}
```

**Features:**
- Same security model as PINData
- Tracks last used timestamp
- Required for administrative functions
- Cross-device synchronization

## 🔐 Security Models

### PIN Validation

All PIN models implement secure validation:

```swift
// PINData initialization with secure hashing
public init(pin: String, name: String = "") throws {
    self.id = UUID()
    let salt = PINHasher.generateSalt()
    self.pinHash = try PINHasher.hashPIN(pin, salt: salt)
    self.salt = salt
    self.name = name
    self.createdAt = Date()
    self.lastUsed = nil
}
```

### Hashing Implementation

PIN hashing uses SHA-256 with random salt:

```swift
func hashPIN(_ pin: String, salt: String) -> String {
    let data = (pin + salt).data(using: .utf8)!
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}
```

## 🎨 UI Integration

### Color Coding

Alarm states and modes use consistent color coding:

```swift
extension AlarmState {
    var backgroundColor: Color {
        switch self {
        case .disarmed: return .green
        case .armedAway: return .red
        case .armedStay: return .orange
        case .armedNightStay: return .purple
        case .unknown: return .gray
        }
    }
}
```

### Icon Mapping

SF Symbols provide consistent visual representation:

```swift
extension AlarmState {
    var iconName: String {
        switch self {
        case .disarmed: return "lock.open.fill"
        case .armedAway: return "lock.shield.fill"
        case .armedStay: return "house.fill"
        case .armedNightStay: return "moon.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}
```

## 🔄 State Transitions

### Valid State Changes

The alarm system supports specific state transitions:

```
disarmed ←→ armedAway
disarmed ←→ armedStay
disarmed ←→ armedNightStay
armedAway ←→ armedStay
armedAway ←→ armedNightStay
armedStay ←→ armedNightStay
```

### Mode to State Mapping

Each alarm mode targets a specific state:

| Mode | Target State | Scene Name |
|------|-------------|------------|
| `away` | `armedAway` | "Set Away Mode" |
| `stay` | `armedStay` | "Set Stay Mode" |
| `nightStay` | `armedNightStay` | "Set Night-Stay Mode" |
| `disarm` | `disarmed` | "Set Disarm Mode" |

## 🧪 Testing

### Model Testing

Test data model functionality:

```swift
func testAlarmStateProperties() {
    let state = AlarmState.armedAway
    XCTAssertEqual(state.rawValue, "1")
    XCTAssertEqual(state.displayName, "Armed Away")
    XCTAssertEqual(state.backgroundColor, Color.red)
}

func testPINDataSecurity() {
    let pinData = try! PINData(pin: "123456", name: "Test")
    XCTAssertTrue(pinData.verifyPIN("123456"))
    XCTAssertFalse(pinData.verifyPIN("654321"))
    XCTAssertNotEqual(pinData.pinHash, "123456") // Never plain text
}
```

### State Transition Testing

Test valid state changes:

```swift
func testValidStateTransitions() {
    let validTransitions = [
        (AlarmState.disarmed, AlarmState.armedAway),
        (AlarmState.armedAway, AlarmState.disarmed),
        (AlarmState.armedStay, AlarmState.armedNightStay)
    ]
    
    for (from, to) in validTransitions {
        XCTAssertTrue(isValidTransition(from: from, to: to))
    }
}
```

## 📁 Files

- **AlarmState.swift** - Alarm state enumeration and properties
- **AlarmMode.swift** - Alarm mode enumeration and properties
- **PINData.swift** - User PIN data structure
- **MasterPINData.swift** - Master PIN data structure

## 🔗 Navigation

- **[Alarm System](../README.md)** - Main alarm system documentation
- **[Services](../Services/README.md)** - Alarm services and business logic
- **[ViewModels](../ViewModels/README.md)** - UI state management
- **[Views](../Views/README.md)** - SwiftUI components

---

These models provide the foundation for the alarm system's data management, security, and user interface integration.
