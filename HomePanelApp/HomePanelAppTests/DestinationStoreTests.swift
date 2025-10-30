import XCTest
@testable import HomePanelApp

// MARK: - Mock Keychain Service

class MockKeychainService: KeychainServiceProtocol {
    private var storage: [String: Data] = [:]
    var shouldThrowError = false

    func store(key: String, value: String, syncable: Bool) throws {
        if shouldThrowError {
            throw SecurityError.unexpectedKeychainError(errSecIO)
        }
        guard let data = value.data(using: .utf8) else {
            throw SecurityError.encodingError
        }
        storage[key] = data
    }

    func retrieve(key: String) throws -> String {
        if shouldThrowError {
            throw SecurityError.unexpectedKeychainError(errSecIO)
        }
        guard let data = storage[key] else {
            throw SecurityError.itemNotFound
        }
        guard let string = String(data: data, encoding: .utf8) else {
            throw SecurityError.decodingError
        }
        return string
    }

    func storeData(key: String, value: Data, syncable: Bool) throws {
        if shouldThrowError {
            throw SecurityError.unexpectedKeychainError(errSecIO)
        }
        storage[key] = value
    }

    func retrieveData(key: String) throws -> Data {
        if shouldThrowError {
            throw SecurityError.unexpectedKeychainError(errSecIO)
        }
        guard let data = storage[key] else {
            throw SecurityError.itemNotFound
        }
        return data
    }

    func delete(key: String) throws {
        if shouldThrowError {
            throw SecurityError.unexpectedKeychainError(errSecIO)
        }
        storage.removeValue(forKey: key)
    }

    func deleteAll() throws {
        if shouldThrowError {
            throw SecurityError.unexpectedKeychainError(errSecIO)
        }
        storage.removeAll()
    }

    func saveCameraPassword(for cameraId: String, password: String) throws {
        let key = "camera_password_\(cameraId)"
        try store(key: key, value: password, syncable: true)
    }

    func getCameraPassword(for cameraId: String) -> String? {
        let key = "camera_password_\(cameraId)"
        return try? retrieve(key: key)
    }

    func deleteCameraPassword(for cameraId: String) throws {
        let key = "camera_password_\(cameraId)"
        try delete(key: key)
    }

    // Helper to check if data exists
    func hasData(for key: String) -> Bool {
        return storage[key] != nil
    }
}

// MARK: - Destination Store Tests

@MainActor
class DestinationStoreTests: XCTestCase {

    var mockKeychain: MockKeychainService!
    var destinationStore: DestinationStore!

    override func setUp() async throws {
        try await super.setUp()
        mockKeychain = MockKeychainService()
        destinationStore = DestinationStore(keychainService: mockKeychain)
    }

    override func tearDown() async throws {
        mockKeychain = nil
        destinationStore = nil
        try await super.tearDown()
    }

    // MARK: - Load Tests

    func testLoadDestinationsWhenEmpty() async throws {
        // When loading with no saved destinations
        let destinations = try await destinationStore.loadDestinations()

        // Then should return empty array
        XCTAssertTrue(destinations.isEmpty, "Should return empty array when no destinations saved")
        XCTAssertTrue(destinationStore.destinations.isEmpty, "Store destinations should be empty")
    }

    func testLoadDestinationsWithSavedData() async throws {
        // Given some saved destinations
        let testDestinations = [
            FavoriteDestination(name: "Work", address: "123 Main St", latitude: 37.7749, longitude: -122.4194),
            FavoriteDestination(name: "Home", address: "456 Oak Ave", latitude: 37.3349, longitude: -122.0090)
        ]

        try await destinationStore.saveDestinations(testDestinations)

        // When loading destinations
        let loadedDestinations = try await destinationStore.loadDestinations()

        // Then should return saved destinations
        XCTAssertEqual(loadedDestinations.count, 2, "Should load 2 destinations")
        XCTAssertEqual(loadedDestinations[0].name, "Work")
        XCTAssertEqual(loadedDestinations[1].name, "Home")
    }

    func testLoadDestinationsHandlesError() async throws {
        // Given keychain will throw error
        mockKeychain.shouldThrowError = true

        // When loading destinations
        let destinations = try await destinationStore.loadDestinations()

        // Then should return empty array (error handled gracefully)
        XCTAssertTrue(destinations.isEmpty, "Should return empty array on error")
    }

    // MARK: - Save Tests

    func testSaveDestinations() async throws {
        // Given some destinations
        let destinations = [
            FavoriteDestination(name: "Work", address: "123 Main St", latitude: 37.7749, longitude: -122.4194),
            FavoriteDestination(name: "Home", address: "456 Oak Ave", latitude: 37.3349, longitude: -122.0090)
        ]

        // When saving
        try await destinationStore.saveDestinations(destinations)

        // Then should be stored
        XCTAssertTrue(mockKeychain.hasData(for: "favoriteDestinations"), "Data should be saved to keychain")
        XCTAssertEqual(destinationStore.destinations.count, 2, "Store should have 2 destinations")
    }

    func testSaveDestinationsThrowsError() async {
        // Given keychain will throw error
        mockKeychain.shouldThrowError = true
        let destinations = [
            FavoriteDestination(name: "Work", address: "123 Main St", latitude: 37.7749, longitude: -122.4194)
        ]

        // When saving
        do {
            try await destinationStore.saveDestinations(destinations)
            XCTFail("Should have thrown an error")
        } catch {
            // Then should throw error
            XCTAssertNotNil(error, "Should throw error when keychain fails")
        }
    }

    // MARK: - Add Tests

    func testAddDestination() async throws {
        // Given empty store
        let destination = FavoriteDestination(name: "Work", address: "123 Main St", latitude: 37.7749, longitude: -122.4194)

        // When adding destination
        try await destinationStore.addDestination(destination)

        // Then should be added
        XCTAssertEqual(destinationStore.destinations.count, 1, "Should have 1 destination")
        XCTAssertEqual(destinationStore.destinations[0].name, "Work")
    }

    func testAddMultipleDestinations() async throws {
        // Given empty store
        let destination1 = FavoriteDestination(name: "Work", address: "123 Main St", latitude: 37.7749, longitude: -122.4194)
        let destination2 = FavoriteDestination(name: "Home", address: "456 Oak Ave", latitude: 37.3349, longitude: -122.0090)

        // When adding multiple destinations
        try await destinationStore.addDestination(destination1)
        try await destinationStore.addDestination(destination2)

        // Then both should be added
        XCTAssertEqual(destinationStore.destinations.count, 2, "Should have 2 destinations")
        XCTAssertEqual(destinationStore.destinations[0].name, "Work")
        XCTAssertEqual(destinationStore.destinations[1].name, "Home")
    }

    // MARK: - Update Tests

    func testUpdateDestination() async throws {
        // Given existing destination
        let original = FavoriteDestination(name: "Work", address: "123 Main St", latitude: 37.7749, longitude: -122.4194, isEnabled: true)
        try await destinationStore.addDestination(original)

        // When updating destination
        let updated = FavoriteDestination(id: original.id, name: "Work Updated", address: "789 New St", latitude: 37.8000, longitude: -122.5000, isEnabled: false)
        try await destinationStore.updateDestination(updated)

        // Then should be updated
        XCTAssertEqual(destinationStore.destinations.count, 1, "Should still have 1 destination")
        XCTAssertEqual(destinationStore.destinations[0].name, "Work Updated")
        XCTAssertEqual(destinationStore.destinations[0].address, "789 New St")
        XCTAssertFalse(destinationStore.destinations[0].isEnabled)
    }

    func testUpdateNonExistentDestination() async {
        // Given empty store
        let destination = FavoriteDestination(name: "Work", address: "123 Main St", latitude: 37.7749, longitude: -122.4194)

        // When updating non-existent destination
        do {
            try await destinationStore.updateDestination(destination)
            XCTFail("Should have thrown an error")
        } catch {
            // Then should throw error
            XCTAssertNotNil(error, "Should throw error when destination not found")
        }
    }

    // MARK: - Delete Tests

    func testDeleteDestination() async throws {
        // Given existing destinations
        let destination1 = FavoriteDestination(name: "Work", address: "123 Main St", latitude: 37.7749, longitude: -122.4194)
        let destination2 = FavoriteDestination(name: "Home", address: "456 Oak Ave", latitude: 37.3349, longitude: -122.0090)
        try await destinationStore.addDestination(destination1)
        try await destinationStore.addDestination(destination2)

        // When deleting one destination
        try await destinationStore.deleteDestination(id: destination1.id)

        // Then should be removed
        XCTAssertEqual(destinationStore.destinations.count, 1, "Should have 1 destination remaining")
        XCTAssertEqual(destinationStore.destinations[0].name, "Home")
    }

    func testDeleteNonExistentDestination() async throws {
        // Given empty store
        let randomID = UUID()

        // When deleting non-existent destination
        try await destinationStore.deleteDestination(id: randomID)

        // Then should succeed silently (doesn't throw when destination not found)
        XCTAssertEqual(destinationStore.destinations.count, 0, "Store should still be empty")
    }

    func testDeleteAllDestinations() async throws {
        // Given multiple destinations
        let destination1 = FavoriteDestination(name: "Work", address: "123 Main St", latitude: 37.7749, longitude: -122.4194)
        let destination2 = FavoriteDestination(name: "Home", address: "456 Oak Ave", latitude: 37.3349, longitude: -122.0090)
        let destination3 = FavoriteDestination(name: "Gym", address: "789 Fit St", latitude: 37.5000, longitude: -122.3000)

        try await destinationStore.addDestination(destination1)
        try await destinationStore.addDestination(destination2)
        try await destinationStore.addDestination(destination3)

        // When deleting all
        try await destinationStore.deleteDestination(id: destination1.id)
        try await destinationStore.deleteDestination(id: destination2.id)
        try await destinationStore.deleteDestination(id: destination3.id)

        // Then should be empty
        XCTAssertTrue(destinationStore.destinations.isEmpty, "Should have no destinations")
    }

    // MARK: - Order/Reorder Tests

    func testDestinationOrderPreserved() async throws {
        // Given destinations added in specific order
        let destination1 = FavoriteDestination(name: "First", address: "123 Main St", latitude: 37.7749, longitude: -122.4194)
        let destination2 = FavoriteDestination(name: "Second", address: "456 Oak Ave", latitude: 37.3349, longitude: -122.0090)
        let destination3 = FavoriteDestination(name: "Third", address: "789 Fit St", latitude: 37.5000, longitude: -122.3000)

        try await destinationStore.addDestination(destination1)
        try await destinationStore.addDestination(destination2)
        try await destinationStore.addDestination(destination3)

        // When reloading
        let loaded = try await destinationStore.loadDestinations()

        // Then order should be preserved
        XCTAssertEqual(loaded[0].name, "First")
        XCTAssertEqual(loaded[1].name, "Second")
        XCTAssertEqual(loaded[2].name, "Third")
    }

    func testManualReorder() async throws {
        // Given destinations in original order
        let destination1 = FavoriteDestination(name: "First", address: "123 Main St", latitude: 37.7749, longitude: -122.4194)
        let destination2 = FavoriteDestination(name: "Second", address: "456 Oak Ave", latitude: 37.3349, longitude: -122.0090)
        let destination3 = FavoriteDestination(name: "Third", address: "789 Fit St", latitude: 37.5000, longitude: -122.3000)

        try await destinationStore.addDestination(destination1)
        try await destinationStore.addDestination(destination2)
        try await destinationStore.addDestination(destination3)

        // When reordering (swap first and last)
        var reordered = destinationStore.destinations
        reordered.swapAt(0, 2)
        try await destinationStore.saveDestinations(reordered)

        // Then new order should be saved
        XCTAssertEqual(destinationStore.destinations[0].name, "Third")
        XCTAssertEqual(destinationStore.destinations[1].name, "Second")
        XCTAssertEqual(destinationStore.destinations[2].name, "First")
    }

    // MARK: - Edge Cases

    func testSaveEmptyArray() async throws {
        // Given store with destinations
        let destination = FavoriteDestination(name: "Work", address: "123 Main St", latitude: 37.7749, longitude: -122.4194)
        try await destinationStore.addDestination(destination)

        // When saving empty array
        try await destinationStore.saveDestinations([])

        // Then should clear destinations
        XCTAssertTrue(destinationStore.destinations.isEmpty, "Should be empty")
    }

    func testEnabledDisabledDestinations() async throws {
        // Given mix of enabled and disabled destinations
        let enabled = FavoriteDestination(name: "Enabled", address: "123 Main St", latitude: 37.7749, longitude: -122.4194, isEnabled: true)
        let disabled = FavoriteDestination(name: "Disabled", address: "456 Oak Ave", latitude: 37.3349, longitude: -122.0090, isEnabled: false)

        try await destinationStore.addDestination(enabled)
        try await destinationStore.addDestination(disabled)

        // When loading
        let loaded = try await destinationStore.loadDestinations()

        // Then states should be preserved
        XCTAssertTrue(loaded[0].isEnabled, "First destination should be enabled")
        XCTAssertFalse(loaded[1].isEnabled, "Second destination should be disabled")
    }
}
