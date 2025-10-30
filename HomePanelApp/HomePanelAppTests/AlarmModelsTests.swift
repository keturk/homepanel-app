import XCTest
@testable import HomePanelApp

// MARK: - Alarm Mode Tests

class AlarmModeTests: XCTestCase {

    // MARK: - Enum Cases Tests

    func testAllCasesExist() {
        // When accessing all cases
        let allCases = AlarmMode.allCases

        // Then should have expected modes
        XCTAssertTrue(allCases.contains(.disarm), "Should have disarm mode")
        XCTAssertTrue(allCases.contains(.stay), "Should have stay mode")
        XCTAssertTrue(allCases.contains(.away), "Should have away mode")
        XCTAssertTrue(allCases.contains(.nightStay), "Should have nightStay mode")
    }

    func testAlarmModeCaseCount() {
        // When counting cases
        let count = AlarmMode.allCases.count

        // Then should have 4 modes
        XCTAssertEqual(count, 4, "Should have exactly 4 alarm modes")
    }

    // MARK: - Raw Value Tests

    func testRawValues() {
        // Then each mode should have a raw value
        XCTAssertEqual(AlarmMode.disarm.rawValue, "Disarm")
        XCTAssertEqual(AlarmMode.stay.rawValue, "Stay")
        XCTAssertEqual(AlarmMode.away.rawValue, "Away")
        XCTAssertEqual(AlarmMode.nightStay.rawValue, "Night-Stay")
    }

    func testUniqueRawValues() {
        // When getting all raw values
        let rawValues = AlarmMode.allCases.map { $0.rawValue }
        let uniqueRawValues = Set(rawValues)

        // Then all should be unique
        XCTAssertEqual(rawValues.count, uniqueRawValues.count, "All raw values should be unique")
    }

    // MARK: - Scene Name Tests

    func testSceneNames() {
        // Then each mode should have a scene name
        XCTAssertEqual(AlarmMode.disarm.sceneName, "Set Disarm Mode")
        XCTAssertEqual(AlarmMode.stay.sceneName, "Set Stay Mode")
        XCTAssertEqual(AlarmMode.away.sceneName, "Set Away Mode")
        XCTAssertEqual(AlarmMode.nightStay.sceneName, "Set Night-Stay Mode")
    }

    func testSceneNamesAreUnique() {
        // When getting all scene names
        let sceneNames = AlarmMode.allCases.map { $0.sceneName }
        let uniqueSceneNames = Set(sceneNames)

        // Then all should be unique
        XCTAssertEqual(sceneNames.count, uniqueSceneNames.count, "All scene names should be unique")
    }

    // MARK: - Expected State Tests

    func testExpectedStates() {
        // Then each mode should map to correct alarm state
        XCTAssertEqual(AlarmMode.disarm.expectedState, .disarmed)
        XCTAssertEqual(AlarmMode.stay.expectedState, .armedStay)
        XCTAssertEqual(AlarmMode.away.expectedState, .armedAway)
        XCTAssertEqual(AlarmMode.nightStay.expectedState, .armedNightStay)
    }

    // MARK: - Icon Tests

    func testIconNames() {
        // Then each mode should have an icon
        XCTAssertEqual(AlarmMode.disarm.iconName, "lock.open")
        XCTAssertEqual(AlarmMode.stay.iconName, "house")
        XCTAssertEqual(AlarmMode.away.iconName, "airplane")
        XCTAssertEqual(AlarmMode.nightStay.iconName, "moon.stars")
    }

    func testIconNamesAreSFSymbols() {
        // Then icons should be valid SF Symbol names
        let icons = AlarmMode.allCases.map { $0.iconName }

        for icon in icons {
            XCTAssertFalse(icon.isEmpty, "Icon should not be empty")
        }
    }

    // MARK: - Button Color Tests

    func testButtonColors() {
        // Then each mode should have a button color
        XCTAssertNotNil(AlarmMode.disarm.buttonColor)
        XCTAssertNotNil(AlarmMode.stay.buttonColor)
        XCTAssertNotNil(AlarmMode.away.buttonColor)
        XCTAssertNotNil(AlarmMode.nightStay.buttonColor)
    }

    // MARK: - Equatable Tests

    func testEquality() {
        // Then same modes should be equal
        XCTAssertEqual(AlarmMode.disarm, AlarmMode.disarm)
        XCTAssertEqual(AlarmMode.stay, AlarmMode.stay)
        XCTAssertEqual(AlarmMode.away, AlarmMode.away)
        XCTAssertEqual(AlarmMode.nightStay, AlarmMode.nightStay)
    }

    func testInequality() {
        // Then different modes should not be equal
        XCTAssertNotEqual(AlarmMode.disarm, AlarmMode.stay)
        XCTAssertNotEqual(AlarmMode.stay, AlarmMode.away)
        XCTAssertNotEqual(AlarmMode.away, AlarmMode.nightStay)
        XCTAssertNotEqual(AlarmMode.nightStay, AlarmMode.disarm)
    }
}

// MARK: - Alarm State Tests

class AlarmStateTests: XCTestCase {

    // MARK: - Enum Cases Tests

    func testAllCasesExist() {
        // When accessing all cases
        let allCases = AlarmState.allCases

        // Then should have expected states
        XCTAssertTrue(allCases.contains(.disarmed), "Should have disarmed state")
        XCTAssertTrue(allCases.contains(.armedAway), "Should have armedAway state")
        XCTAssertTrue(allCases.contains(.armedStay), "Should have armedStay state")
        XCTAssertTrue(allCases.contains(.armedNightStay), "Should have armedNightStay state")
        XCTAssertTrue(allCases.contains(.unknown), "Should have unknown state")
    }

    func testAlarmStateCaseCount() {
        // When counting cases
        let count = AlarmState.allCases.count

        // Then should have 5 states
        XCTAssertEqual(count, 5, "Should have exactly 5 alarm states")
    }

    // MARK: - Raw Value Tests

    func testRawValues() {
        // Then each state should have a raw value
        XCTAssertEqual(AlarmState.disarmed.rawValue, "Disarmed")
        XCTAssertEqual(AlarmState.armedAway.rawValue, "Armed Away")
        XCTAssertEqual(AlarmState.armedStay.rawValue, "Armed Stay")
        XCTAssertEqual(AlarmState.armedNightStay.rawValue, "Armed Night-Stay")
        XCTAssertEqual(AlarmState.unknown.rawValue, "Unknown")
    }

    func testUniqueRawValues() {
        // When getting all raw values
        let rawValues = AlarmState.allCases.map { $0.rawValue }
        let uniqueRawValues = Set(rawValues)

        // Then all should be unique
        XCTAssertEqual(rawValues.count, uniqueRawValues.count, "All raw values should be unique")
    }

    // MARK: - Background Color Tests

    func testBackgroundColors() {
        // Then each state should have a background color
        XCTAssertNotNil(AlarmState.disarmed.backgroundColor)
        XCTAssertNotNil(AlarmState.armedAway.backgroundColor)
        XCTAssertNotNil(AlarmState.armedStay.backgroundColor)
        XCTAssertNotNil(AlarmState.armedNightStay.backgroundColor)
        XCTAssertNotNil(AlarmState.unknown.backgroundColor)
    }

    // MARK: - Icon Tests

    func testIconNames() {
        // Then each state should have an icon
        XCTAssertEqual(AlarmState.disarmed.iconName, "lock.open.fill")
        XCTAssertEqual(AlarmState.armedAway.iconName, "lock.shield.fill")
        XCTAssertEqual(AlarmState.armedStay.iconName, "house.fill")
        XCTAssertEqual(AlarmState.armedNightStay.iconName, "moon.fill")
        XCTAssertEqual(AlarmState.unknown.iconName, "questionmark.circle.fill")
    }

    // MARK: - Display Color Tests

    func testDisplayColors() {
        // Then each state should have a display color
        XCTAssertNotNil(AlarmState.disarmed.displayColor)
        XCTAssertNotNil(AlarmState.armedAway.displayColor)
        XCTAssertNotNil(AlarmState.armedStay.displayColor)
        XCTAssertNotNil(AlarmState.armedNightStay.displayColor)
        XCTAssertNotNil(AlarmState.unknown.displayColor)
    }

    // MARK: - Codable Tests

    func testCodable() throws {
        // Given all alarm states
        let states = AlarmState.allCases

        // When encoding and decoding
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for state in states {
            let data = try encoder.encode(state)
            let decoded = try decoder.decode(AlarmState.self, from: data)

            // Then should match original
            XCTAssertEqual(decoded, state, "\(state) should encode and decode correctly")
        }
    }

    // MARK: - Equatable Tests

    func testEquality() {
        // Then same states should be equal
        XCTAssertEqual(AlarmState.disarmed, AlarmState.disarmed)
        XCTAssertEqual(AlarmState.armedAway, AlarmState.armedAway)
        XCTAssertEqual(AlarmState.armedStay, AlarmState.armedStay)
        XCTAssertEqual(AlarmState.armedNightStay, AlarmState.armedNightStay)
        XCTAssertEqual(AlarmState.unknown, AlarmState.unknown)
    }

    func testInequality() {
        // Then different states should not be equal
        XCTAssertNotEqual(AlarmState.disarmed, AlarmState.armedAway)
        XCTAssertNotEqual(AlarmState.armedAway, AlarmState.armedStay)
        XCTAssertNotEqual(AlarmState.armedStay, AlarmState.armedNightStay)
        XCTAssertNotEqual(AlarmState.armedNightStay, AlarmState.unknown)
        XCTAssertNotEqual(AlarmState.unknown, AlarmState.disarmed)
    }
}

// MARK: - PIN Data Tests

class PINDataTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitialization() throws {
        // Given PIN data components
        let name = "John"
        let pin = "1234"

        // When creating PIN data
        let pinData = try PINData(pin: pin, name: name)

        // Then should have correct properties
        XCTAssertEqual(pinData.name, name)
        XCTAssertNotNil(pinData.id)
        XCTAssertNotNil(pinData.pinHash)
        XCTAssertNotNil(pinData.salt)
        XCTAssertNotNil(pinData.createdAt)
    }

    func testVerifyCorrectPIN() throws {
        // Given PIN data
        let pin = "5678"
        let pinData = try PINData(pin: pin, name: "Test")

        // When verifying correct PIN
        let isValid = pinData.verifyPIN(pin)

        // Then should return true
        XCTAssertTrue(isValid, "Should verify correct PIN")
    }

    func testVerifyIncorrectPIN() throws {
        // Given PIN data
        let correctPIN = "1234"
        let pinData = try PINData(pin: correctPIN, name: "Test")

        // When verifying incorrect PIN
        let isValid = pinData.verifyPIN("9999")

        // Then should return false
        XCTAssertFalse(isValid, "Should reject incorrect PIN")
    }

    // MARK: - Codable Tests

    func testCodable() throws {
        // Given PIN data
        let original = try PINData(pin: "1234", name: "Test User")

        // When encoding and decoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PINData.self, from: data)

        // Then should match original
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.pinHash, original.pinHash)
        XCTAssertEqual(decoded.salt, original.salt)
    }

    // MARK: - Identifiable Tests

    func testUniqueIDs() throws {
        // When creating multiple PIN data instances
        let pin1 = try PINData(pin: "1111", name: "User1")
        let pin2 = try PINData(pin: "2222", name: "User2")
        let pin3 = try PINData(pin: "3333", name: "User3")

        // Then all should have unique IDs
        XCTAssertNotEqual(pin1.id, pin2.id)
        XCTAssertNotEqual(pin2.id, pin3.id)
        XCTAssertNotEqual(pin1.id, pin3.id)
    }

    // MARK: - Security Tests

    func testPINIsHashed() throws {
        // Given a PIN
        let plainPIN = "1234"
        let pinData = try PINData(pin: plainPIN, name: "Test")

        // Then hash should not equal plain PIN
        XCTAssertNotEqual(pinData.pinHash, plainPIN, "PIN should be hashed, not stored in plain text")
    }

    func testUniqueSalts() throws {
        // When creating multiple PIN data with same PIN
        let pin1 = try PINData(pin: "1234", name: "User1")
        let pin2 = try PINData(pin: "1234", name: "User2")

        // Then salts should be different
        XCTAssertNotEqual(pin1.salt, pin2.salt, "Each PIN should have unique salt")

        // And hashes should be different due to different salts
        XCTAssertNotEqual(pin1.pinHash, pin2.pinHash, "Same PIN with different salt should produce different hash")
    }
}

// MARK: - Master PIN Data Tests

class MasterPINDataTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitialization() throws {
        // Given a master PIN
        let pin = "9876"

        // When creating master PIN data
        let masterPIN = try MasterPINData(pin: pin)

        // Then should have correct properties
        XCTAssertNotNil(masterPIN.pinHash)
        XCTAssertNotNil(masterPIN.salt)
    }

    func testVerifyCorrectPIN() throws {
        // Given master PIN data
        let pin = "5555"
        let masterPIN = try MasterPINData(pin: pin)

        // When verifying correct PIN
        let isValid = masterPIN.verifyPIN(pin)

        // Then should return true
        XCTAssertTrue(isValid, "Should verify correct master PIN")
    }

    func testVerifyIncorrectPIN() throws {
        // Given master PIN data
        let correctPIN = "1111"
        let masterPIN = try MasterPINData(pin: correctPIN)

        // When verifying incorrect PIN
        let isValid = masterPIN.verifyPIN("9999")

        // Then should return false
        XCTAssertFalse(isValid, "Should reject incorrect master PIN")
    }

    // MARK: - Codable Tests

    func testCodable() throws {
        // Given master PIN data
        let original = try MasterPINData(pin: "8888")

        // When encoding and decoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MasterPINData.self, from: data)

        // Then should match original
        XCTAssertEqual(decoded.pinHash, original.pinHash)
        XCTAssertEqual(decoded.salt, original.salt)
    }

    // MARK: - Security Tests

    func testPINIsHashed() throws {
        // Given a master PIN
        let plainPIN = "7777"
        let masterPIN = try MasterPINData(pin: plainPIN)

        // Then hash should not equal plain PIN
        XCTAssertNotEqual(masterPIN.pinHash, plainPIN, "Master PIN should be hashed")
    }
}
