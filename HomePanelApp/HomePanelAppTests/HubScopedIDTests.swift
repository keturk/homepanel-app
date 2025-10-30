import XCTest
@testable import HomePanelApp

// MARK: - Hub Scoped ID Tests

class HubScopedIDTests: XCTestCase {

    // MARK: - Device ID Creation Tests

    func testCreateDeviceID() {
        // Given hub ID and device ID
        let hubId = "hub1"
        let deviceId = "123"

        // When creating scoped device ID
        let scopedId = HubScopedID.deviceID(hubId: hubId, deviceId: deviceId)

        // Then should have correct format
        XCTAssertEqual(scopedId, "hub_hub1_device_123")
        XCTAssertTrue(scopedId.hasPrefix("hub_"))
        XCTAssertTrue(scopedId.contains("device"))
    }

    func testCreateDeviceIDWithComplexIds() {
        // Given complex IDs
        let hubId = "living_room_hub"
        let deviceId = "motion_sensor_42"

        // When creating scoped device ID
        let scopedId = HubScopedID.deviceID(hubId: hubId, deviceId: deviceId)

        // Then should contain all parts
        XCTAssertTrue(scopedId.contains(hubId))
        XCTAssertTrue(scopedId.contains(deviceId))
    }

    // MARK: - Room ID Creation Tests

    func testCreateRoomID() {
        // Given hub ID and room ID
        let hubId = "hub1"
        let roomId = "5"

        // When creating scoped room ID
        let scopedId = HubScopedID.roomID(hubId: hubId, roomId: roomId)

        // Then should have correct format
        XCTAssertEqual(scopedId, "hub_hub1_room_5")
        XCTAssertTrue(scopedId.contains("room"))
    }

    // MARK: - Scene ID Creation Tests

    func testCreateSceneID() {
        // Given hub ID and scene ID
        let hubId = "hub1"
        let sceneId = 7

        // When creating scoped scene ID
        let scopedId = HubScopedID.sceneID(hubId: hubId, sceneId: sceneId)

        // Then should have correct format
        XCTAssertEqual(scopedId, "hub_hub1_scene_7")
        XCTAssertTrue(scopedId.contains("scene"))
    }

    // MARK: - Extract Device ID Tests

    func testExtractDeviceID() {
        // Given a scoped device ID
        let hubId = "hub1"
        let deviceId = "123"
        let scopedId = HubScopedID.deviceID(hubId: hubId, deviceId: deviceId)

        // When extracting device ID
        let extractedDeviceId = HubScopedID.extractDeviceID(from: scopedId)

        // Then should match original
        XCTAssertEqual(extractedDeviceId, deviceId)
    }

    func testExtractDeviceIDWithUnderscore() {
        // Given device ID containing underscores
        let hubId = "hub1"
        let deviceId = "motion_sensor_42"
        let scopedId = HubScopedID.deviceID(hubId: hubId, deviceId: deviceId)

        // When extracting
        let extractedDeviceId = HubScopedID.extractDeviceID(from: scopedId)

        // Then should preserve underscores
        XCTAssertEqual(extractedDeviceId, deviceId)
    }

    func testExtractDeviceIDFromInvalidFormat() {
        // Given invalid format
        let invalidId = "not_a_valid_format"

        // When extracting
        let extractedDeviceId = HubScopedID.extractDeviceID(from: invalidId)

        // Then should return nil
        XCTAssertNil(extractedDeviceId)
    }

    // MARK: - Extract Room ID Tests

    func testExtractRoomID() {
        // Given a scoped room ID
        let hubId = "hub1"
        let roomId = "5"
        let scopedId = HubScopedID.roomID(hubId: hubId, roomId: roomId)

        // When extracting room ID
        let extractedRoomId = HubScopedID.extractRoomID(from: scopedId)

        // Then should match original
        XCTAssertEqual(extractedRoomId, roomId)
    }

    func testExtractRoomIDFromInvalidFormat() {
        // Given invalid format
        let invalidId = "hub_test_device_123"

        // When extracting room ID
        let extractedRoomId = HubScopedID.extractRoomID(from: invalidId)

        // Then should return nil
        XCTAssertNil(extractedRoomId)
    }

    // MARK: - Extract Scene ID Tests

    func testExtractSceneID() {
        // Given a scoped scene ID
        let hubId = "hub1"
        let sceneId = 7
        let scopedId = HubScopedID.sceneID(hubId: hubId, sceneId: sceneId)

        // When extracting scene ID
        let extractedSceneId = HubScopedID.extractSceneID(from: scopedId)

        // Then should match original
        XCTAssertEqual(extractedSceneId, sceneId)
    }

    func testExtractSceneIDFromInvalidFormat() {
        // Given invalid format
        let invalidId = "hub_test_device_123"

        // When extracting scene ID
        let extractedSceneId = HubScopedID.extractSceneID(from: invalidId)

        // Then should return nil
        XCTAssertNil(extractedSceneId)
    }

    // MARK: - Extract Hub ID Tests

    func testExtractHubID() {
        // Given a scoped device ID
        let hubId = "hub1"
        let deviceId = "123"
        let scopedId = HubScopedID.deviceID(hubId: hubId, deviceId: deviceId)

        // When extracting hub ID
        let extractedHubId = HubScopedID.extractHubID(from: scopedId)

        // Then should match original
        XCTAssertEqual(extractedHubId, hubId)
    }

    func testExtractHubIDFromRoomID() {
        // Given a scoped room ID
        let hubId = "living_room_hub"
        let roomId = "5"
        let scopedId = HubScopedID.roomID(hubId: hubId, roomId: roomId)

        // When extracting hub ID
        let extractedHubId = HubScopedID.extractHubID(from: scopedId)

        // Then should match original
        XCTAssertEqual(extractedHubId, hubId)
    }

    func testExtractHubIDFromSceneID() {
        // Given a scoped scene ID
        let hubId = "hub2"
        let sceneId = 3
        let scopedId = HubScopedID.sceneID(hubId: hubId, sceneId: sceneId)

        // When extracting hub ID
        let extractedHubId = HubScopedID.extractHubID(from: scopedId)

        // Then should match original
        XCTAssertEqual(extractedHubId, hubId)
    }

    func testExtractHubIDFromInvalidFormat() {
        // Given invalid format
        let invalidId = "not_hub_scoped"

        // When extracting hub ID
        let extractedHubId = HubScopedID.extractHubID(from: invalidId)

        // Then should return nil
        XCTAssertNil(extractedHubId)
    }

    // MARK: - Is Hub Scoped Tests

    func testIsHubScoped() {
        // Given hub-scoped IDs
        let deviceId = HubScopedID.deviceID(hubId: "hub1", deviceId: "123")
        let roomId = HubScopedID.roomID(hubId: "hub1", roomId: "5")
        let sceneId = HubScopedID.sceneID(hubId: "hub1", sceneId: 7)

        // Then should all be recognized as hub-scoped
        XCTAssertTrue(HubScopedID.isHubScoped(deviceId))
        XCTAssertTrue(HubScopedID.isHubScoped(roomId))
        XCTAssertTrue(HubScopedID.isHubScoped(sceneId))
    }

    func testIsNotHubScoped() {
        // Given non-scoped IDs
        let plainId = "123"
        let invalidFormat = "device_123"

        // Then should not be recognized as hub-scoped
        XCTAssertFalse(HubScopedID.isHubScoped(plainId))
        XCTAssertFalse(HubScopedID.isHubScoped(invalidFormat))
    }

    // MARK: - Uniqueness Tests

    func testDifferentHubsSameDevice() {
        // Given same device ID on different hubs
        let hub1Device = HubScopedID.deviceID(hubId: "hub1", deviceId: "123")
        let hub2Device = HubScopedID.deviceID(hubId: "hub2", deviceId: "123")

        // Then should produce different scoped IDs
        XCTAssertNotEqual(hub1Device, hub2Device)
    }

    func testDifferentDevicesSameHub() {
        // Given different devices on same hub
        let device1 = HubScopedID.deviceID(hubId: "hub1", deviceId: "123")
        let device2 = HubScopedID.deviceID(hubId: "hub1", deviceId: "456")

        // Then should produce different scoped IDs
        XCTAssertNotEqual(device1, device2)
    }

    func testUniquenessWith100Devices() {
        // Given 100 devices on same hub
        var scopedIds = Set<String>()
        let hubId = "hub1"

        for i in 1...100 {
            let scopedId = HubScopedID.deviceID(hubId: hubId, deviceId: "\(i)")
            scopedIds.insert(scopedId)
        }

        // Then all should be unique
        XCTAssertEqual(scopedIds.count, 100, "All 100 scoped IDs should be unique")
    }

    // MARK: - Round Trip Tests

    func testDeviceIDRoundTrip() {
        // Given original IDs
        let hubId = "hub1"
        let deviceId = "motion_sensor_42"

        // When creating and extracting
        let scopedId = HubScopedID.deviceID(hubId: hubId, deviceId: deviceId)
        let extractedHubId = HubScopedID.extractHubID(from: scopedId)
        let extractedDeviceId = HubScopedID.extractDeviceID(from: scopedId)

        // Then should match originals
        XCTAssertEqual(extractedHubId, hubId)
        XCTAssertEqual(extractedDeviceId, deviceId)
    }

    func testRoomIDRoundTrip() {
        // Given original IDs
        let hubId = "hub1"
        let roomId = "living_room"

        // When creating and extracting
        let scopedId = HubScopedID.roomID(hubId: hubId, roomId: roomId)
        let extractedHubId = HubScopedID.extractHubID(from: scopedId)
        let extractedRoomId = HubScopedID.extractRoomID(from: scopedId)

        // Then should match originals
        XCTAssertEqual(extractedHubId, hubId)
        XCTAssertEqual(extractedRoomId, roomId)
    }

    func testSceneIDRoundTrip() {
        // Given original IDs
        let hubId = "hub1"
        let sceneId = 42

        // When creating and extracting
        let scopedId = HubScopedID.sceneID(hubId: hubId, sceneId: sceneId)
        let extractedHubId = HubScopedID.extractHubID(from: scopedId)
        let extractedSceneId = HubScopedID.extractSceneID(from: scopedId)

        // Then should match originals
        XCTAssertEqual(extractedHubId, hubId)
        XCTAssertEqual(extractedSceneId, sceneId)
    }
}
