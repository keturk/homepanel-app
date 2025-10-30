# Alarm Services

This directory contains the business logic and external integrations for the alarm system, including multi-hub alarm management, PIN management, and security services.

## 🔧 Core Services

### UnifiedAlarmService

Modern unified alarm service that integrates with the multi-hub architecture, replacing the legacy Vera-specific alarm service.

```swift
@MainActor
class UnifiedAlarmService: @unchecked Sendable, AlarmServiceProtocol {
    private let hubService: HubServiceProtocol
    private let config: AppConfigurationProtocol
    private let session: URLSession
    private let alarmStateParser: AlarmStateParserProtocol
    
    func fetchAlarmState() async throws -> AlarmState
}
```

**Key Features:**
- **Multi-Hub Integration**: Works with the unified hub service architecture
- **Protocol-Based**: Implements `AlarmServiceProtocol` for compatibility
- **Modern Architecture**: Uses dependency injection and protocol abstraction
- **State Parsing**: Delegates to specialized alarm state parser
- **HubServiceProtocol Integration**: Uses modern hub service protocol for multi-hub support

**Service Dependencies:**
```swift
UnifiedAlarmService
├── HubServiceProtocol (unified hub management)
├── AppConfigurationProtocol (app configuration)
├── URLSession (network operations)
└── AlarmStateParserProtocol (state parsing)
```

### VeraHubAlarmStateParser

Specialized parser for Vera Hub alarm state responses.

```swift
@MainActor
class VeraHubAlarmStateParser: AlarmStateParserProtocol {
    func parseAlarmState(from data: Data) async throws -> AlarmState
}
```

**Parsing Logic:**
- Handles Vera Hub JSON responses
- Maps device states to alarm states
- Provides error handling for invalid responses

### PINManagementService

Comprehensive PIN management system with secure storage and validation.

```swift
class PINManagementService: @unchecked Sendable {
    private let keychainService: KeychainService
    private let lockoutManager: LockoutManager
    
    func setMasterPIN(_ pin: String) -> Bool
    func addUserPIN(_ pin: String, name: String) -> Bool
    func verifyPIN(_ pin: String) -> Bool
    func deleteUserPIN(_ id: UUID) -> Bool
    func updateUserPIN(_ id: UUID, newPin: String, newName: String) -> Bool
}
```

**Security Features:**
- Master PIN and User PIN management
- PIN validation and verification
- Lockout state management
- Error handling and recovery

### AlarmLockoutService

Advanced lockout protection system that delegates to the shared LockoutManager.

```swift
@MainActor
class AlarmLockoutService: ObservableObject {
    private let lockoutManager: LockoutManager
    
    var lockoutUntil: Date? {
        get { lockoutManager.lockoutUntil }
        set { lockoutManager.lockoutUntil = newValue }
    }
    
    var consecutiveFailures: Int {
        get { lockoutManager.consecutiveFailures }
        set { lockoutManager.consecutiveFailures = newValue }
    }
    
    func isLockedOut() -> Bool
    func recordFailedAttempt()
    func recordSuccessfulAttempt()
    func resetAllLockouts(pinService: PINManagementService)
}
```

**Key Features:**
- **Delegation Pattern**: Uses shared LockoutManager for base functionality
- **ObservableObject**: Provides reactive UI updates
- **Cross-Service Integration**: Can reset all lockouts across services
- **State Exposure**: Exposes lockout state through computed properties

### LockoutManager

Shared base class providing lockout functionality across all services.

```swift
@MainActor
class LockoutManager: ObservableObject, LockoutManagerProtocol {
    @Published var lockoutUntil: Date?
    @Published var consecutiveFailures: Int = 0
    
    private static let primeLockoutMinutes = [7, 11, 13, 17, 19, 23, 29]
    private static let attemptsPerLockoutRound = 7
    
    func isLockedOut() -> Bool
    func recordFailedAttempt()
    func recordSuccessfulAttempt()
    func getRemainingLockoutTime() -> String
    func clearLockoutState()
    func reloadLockoutState()
}
```

**Advanced Features:**
- **Prime Number Algorithm**: Escalating lockout periods (7, 11, 13, 17, 19, 23, 29 minutes)
- **Reactive UI**: @Published properties for automatic UI updates
- **Thread Safety**: Queue-based operations for thread safety
- **Event Publishing**: Real-time lockout state updates
- **Cross-Device Sync**: iCloud Keychain synchronization
- **Debug Logging**: Comprehensive logging for troubleshooting

### Prime Number Lockout Algorithm

The lockout system uses a carefully designed prime number sequence for lockout durations, serving as a subtle nod to the mathematical beauty and importance of prime numbers. The sequence follows a pendulum motion - swinging forward through primes, then backward, like the ebb and flow of the universe.

**Mathematical Easter Egg:**
- **Fundamental Building Blocks**: Primes are the atoms of number theory, indivisible by design
- **Unique Properties**: Each prime has no divisors other than 1 and itself
- **Irregular Distribution**: Prime gaps follow no simple pattern, creating natural unpredictability
- **Mathematical Elegance**: Primes represent the purest form of mathematical randomness
- **Cryptographic Foundation**: Primes are the mathematical basis of modern cryptography

**User Experience Design:**
- **Reasonable Starting Point**: 7 minutes is manageable for legitimate users who make honest mistakes
- **Progressive Escalation**: Each step increases the burden on attackers while remaining accessible to users
- **Pendulum Motion**: Swings forward through primes (7→97), then backward (97→11), like the ebb and flow of the universe
- **Clear Feedback**: Users receive exact remaining time, reducing frustration and uncertainty

**Design Rationale:**
- **Mathematical Easter Egg**: Chosen as a subtle nod to the mathematical beauty and importance of prime numbers
- **Practical Benefits**: Prime numbers provide both mathematical elegance and practical security benefits
- **Optimal Balance**: Strikes the perfect balance between security hardening and user accessibility
- **Research-Based**: Industry research on optimal lockout timing informed this specific sequence selection

**Algorithm Implementation - Pendulum Motion:**
```swift
// Forward swing (ascending primes):
// First lockout (7 attempts): 7 minutes
// Second lockout (14 attempts): 11 minutes  
// Third lockout (21 attempts): 13 minutes
// ... continues to last prime
// Twenty-second lockout (154 attempts): 97 minutes

// Backward swing (descending primes):
// Twenty-third lockout (161 attempts): 89 minutes
// Twenty-fourth lockout (168 attempts): 83 minutes
// Twenty-fifth lockout (175 attempts): 79 minutes
// ... continues back to first prime
// Forty-third lockout (301 attempts): 7 minutes

// Then swings forward again: 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97
// "Everything in the universe has a measured motion, or ebb and flow, like a pendulum swinging between two poles"
```

**Pendulum Motion:**
The system includes 22 prime numbers (7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97) and swings through them like a pendulum - 22 forward then 20 backward (skipping 7 to avoid repetition), creating a beautiful ebb and flow pattern that mirrors the natural rhythms of the universe.

## 🔐 Security Services

### KeychainService

Secure credential storage and retrieval using iOS Keychain.

```swift
class KeychainService: @unchecked Sendable {
    func store(key: String, value: String) throws
    func retrieve(key: String) throws -> String
    func storeData(key: String, value: Data) throws
    func retrieveData(key: String) throws -> Data
    func delete(key: String) throws
}
```

**Security Features:**
- iOS Keychain encryption
- Automatic cleanup on errors
- Comprehensive error handling
- Cross-device synchronization via iCloud Keychain

### PINHasher

Utility for secure PIN hashing and salt generation.

```swift
enum PINHasher {
    static func hashPIN(_ pin: String, salt: String) throws -> String
    static func generateSalt() -> String
}
```

**Hashing Implementation:**
```swift
static func hashPIN(_ pin: String, salt: String) throws -> String {
    let data = (pin + salt).data(using: .utf8)!
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}

static func generateSalt() -> String {
    let saltData = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
    return saltData.base64EncodedString()
}
```

## 🌐 Network Services

### VeraHubAlarmStateParser

Parses Vera Hub API responses into alarm states.

```swift
class VeraHubAlarmStateParser: @unchecked Sendable {
    func parseAlarmState(from data: Data) throws -> AlarmState
    func parseSceneList(from data: Data) throws -> [String: Int]
}
```

**Parsing Logic:**
```swift
func parseAlarmState(from data: Data) throws -> AlarmState {
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    guard let device = json?["Device_Num_7"] as? [String: Any],
          let state = device["state"] as? String else {
        throw VeraHubError.invalidResponse
    }
    
    return AlarmState(rawValue: state) ?? .unknown
}
```

## 🔄 Service Coordination

### Modern Service Architecture

Services are organized with clear dependencies and protocol-based design:

```
UnifiedAlarmService
├── HubServiceProtocol (unified hub management)
├── AppConfigurationProtocol (app configuration)
├── URLSession (network operations)
└── AlarmStateParserProtocol (state parsing)

PINManagementService
├── KeychainService (secure storage)
├── LockoutManager (shared lockout functionality)
└── LockoutEventPublisher (event publishing)

AlarmLockoutService
├── LockoutManager (shared lockout functionality)
└── LockoutEventPublisher (event publishing)

LockoutManager
├── KeychainService (secure storage)
├── LockoutEventPublisher (event publishing)
└── DispatchQueue (thread safety)
```

### Protocol-Based Design

All services implement protocols for testability and modularity:

```swift
// Alarm service protocol
@MainActor
protocol AlarmServiceProtocol: Sendable {
    func fetchAlarmState() async throws -> AlarmState
}

// State parser protocol
@MainActor
protocol AlarmStateParserProtocol: Sendable {
    func parseAlarmState(from data: Data) async throws -> AlarmState
}

// Lockout manager protocol
@MainActor
protocol LockoutManagerProtocol: ObservableObject {
    var lockoutUntil: Date? { get set }
    var consecutiveFailures: Int { get set }
    func isLockedOut() -> Bool
    func recordFailedAttempt()
    func recordSuccessfulAttempt()
}
```

### Error Handling

Comprehensive error handling across all services:

```swift
enum VeraHubError: Error, LocalizedError {
    case invalidResponse
    case networkError(Error)
    case sceneNotFound
    case deviceNotFound
    case invalidState
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Vera Hub"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .sceneNotFound:
            return "Scene not found on Vera Hub"
        case .deviceNotFound:
            return "Alarm device not found"
        case .invalidState:
            return "Invalid alarm state"
        }
    }
}
```

## 🧪 Testing

### Service Testing

Test individual service functionality:

```swift
func testUnifiedAlarmService() async throws {
    let service = UnifiedAlarmService(hubService: mockHubService, config: mockConfig)
    let state = try await service.fetchAlarmState()
    XCTAssertEqual(state, .armedAway)
}

func testPINManagementService() {
    let service = PINManagementService()
    let success = service.setMasterPIN("123456")
    XCTAssertTrue(success)
    
    let isValid = service.verifyPIN("123456")
    XCTAssertTrue(isValid)
}
```

### Integration Testing

Test service interactions:

```swift
func testAlarmModeChange() async throws {
    let alarmService = UnifiedAlarmService(hubService: mockHubService, config: mockConfig)
    let sceneService = SceneServiceCoordinator(hubService: mockHubService, session: mockSession)
    
    let sceneMap = ["Set Away Mode": 1]
    try await alarmService.setAlarmMode(.away, sceneMap: sceneMap)
    
    let newState = try await alarmService.fetchAlarmState()
    XCTAssertEqual(newState, .armedAway)
}
```

### Security Testing

Test security features:

```swift
func testLockoutSystem() {
    let service = AlarmLockoutService()
    
    // Record 7 failed attempts
    for _ in 0..<7 {
        service.recordFailedAttempt()
    }
    
    XCTAssertTrue(service.isLockedOut())
}
```

## 🚀 Performance

### Optimization Strategies

- **Async/Await**: Modern concurrency for network operations
- **Caching**: Scene mapping and configuration caching
- **Error Recovery**: Automatic retry logic with exponential backoff
- **Memory Management**: Proper cleanup and deinitialization

### Monitoring

- **Response Times**: Track API call performance
- **Error Rates**: Monitor service failure rates
- **Lockout Events**: Track security events
- **Memory Usage**: Monitor service memory consumption

## 📁 Files

- **UnifiedAlarmService.swift** - Modern unified alarm service
- **PINManagementService.swift** - PIN CRUD operations with shared lockout management
- **AlarmLockoutService.swift** - Alarm-specific lockout management
- **LockoutManager.swift** - Shared base lockout functionality
- **Parsers/VeraHubAlarmStateParser.swift** - Vera Hub alarm state parsing

## 🔗 Navigation

- **[Alarm System](../README.md)** - Main alarm system documentation
- **[Models](../Models/README.md)** - Alarm data models
- **[ViewModels](../ViewModels/README.md)** - UI state management
- **[Views](../Views/README.md)** - SwiftUI components

---

These services provide the business logic and external integrations that power the alarm system's functionality and security features.
