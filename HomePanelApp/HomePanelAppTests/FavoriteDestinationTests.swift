import XCTest
import CoreLocation
@testable import HomePanelApp

// MARK: - Favorite Destination Model Tests

class FavoriteDestinationTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitializationWithAllParameters() {
        // When creating destination with all parameters
        let id = UUID()
        let destination = FavoriteDestination(
            id: id,
            name: "Work",
            address: "123 Main St, San Francisco, CA",
            latitude: 37.7749,
            longitude: -122.4194,
            isEnabled: true
        )

        // Then all properties should be set correctly
        XCTAssertEqual(destination.id, id)
        XCTAssertEqual(destination.name, "Work")
        XCTAssertEqual(destination.address, "123 Main St, San Francisco, CA")
        XCTAssertEqual(destination.latitude, 37.7749)
        XCTAssertEqual(destination.longitude, -122.4194)
        XCTAssertTrue(destination.isEnabled)
    }

    func testInitializationWithDefaults() {
        // When creating destination without optional parameters
        let destination = FavoriteDestination(
            name: "Home",
            address: "456 Oak Ave",
            latitude: 37.3349,
            longitude: -122.0090
        )

        // Then should have default values
        XCTAssertNotNil(destination.id, "Should have auto-generated ID")
        XCTAssertTrue(destination.isEnabled, "Should be enabled by default")
    }

    func testInitializationDisabled() {
        // When creating disabled destination
        let destination = FavoriteDestination(
            name: "Gym",
            address: "789 Fit St",
            latitude: 37.5000,
            longitude: -122.3000,
            isEnabled: false
        )

        // Then should be disabled
        XCTAssertFalse(destination.isEnabled)
    }

    // MARK: - Coordinate Tests

    func testCoordinateProperty() {
        // Given destination with specific coordinates
        let destination = FavoriteDestination(
            name: "Work",
            address: "123 Main St",
            latitude: 37.7749,
            longitude: -122.4194
        )

        // When accessing coordinate
        let coordinate = destination.coordinate

        // Then should match latitude and longitude
        XCTAssertEqual(coordinate.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(coordinate.longitude, -122.4194, accuracy: 0.0001)
    }

    func testLocationProperty() {
        // Given destination with specific coordinates
        let destination = FavoriteDestination(
            name: "Work",
            address: "123 Main St",
            latitude: 37.7749,
            longitude: -122.4194
        )

        // When accessing location
        let location = destination.location

        // Then should be CLLocation with correct coordinates
        XCTAssertEqual(location.coordinate.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(location.coordinate.longitude, -122.4194, accuracy: 0.0001)
    }

    // MARK: - Equatable Tests

    func testEqualityWithSameID() {
        // Given two destinations with same ID but different properties
        let id = UUID()
        let destination1 = FavoriteDestination(
            id: id,
            name: "Work",
            address: "123 Main St",
            latitude: 37.7749,
            longitude: -122.4194
        )
        let destination2 = FavoriteDestination(
            id: id,
            name: "Work Modified",  // Different name
            address: "456 Other St", // Different address
            latitude: 37.8000,       // Different coordinates
            longitude: -122.5000,
            isEnabled: false         // Different state
        )

        // When comparing
        let areEqual = destination1 == destination2

        // Then should NOT be equal (Swift's auto-synthesized Equatable compares ALL properties)
        XCTAssertFalse(areEqual, "Destinations with different properties should not be equal even with same ID")
    }

    func testInequalityWithDifferentIDs() {
        // Given two destinations with different IDs but same other properties
        let destination1 = FavoriteDestination(
            name: "Work",
            address: "123 Main St",
            latitude: 37.7749,
            longitude: -122.4194
        )
        let destination2 = FavoriteDestination(
            name: "Work",
            address: "123 Main St",
            latitude: 37.7749,
            longitude: -122.4194
        )

        // When comparing
        let areEqual = destination1 == destination2

        // Then should not be equal (different IDs)
        XCTAssertFalse(areEqual, "Destinations with different IDs should not be equal")
    }

    // MARK: - Codable Tests

    func testEncodingAndDecoding() throws {
        // Given a destination
        let original = FavoriteDestination(
            name: "Work",
            address: "123 Main St, San Francisco, CA",
            latitude: 37.7749,
            longitude: -122.4194,
            isEnabled: true
        )

        // When encoding and decoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FavoriteDestination.self, from: data)

        // Then should match original
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.address, original.address)
        XCTAssertEqual(decoded.latitude, original.latitude)
        XCTAssertEqual(decoded.longitude, original.longitude)
        XCTAssertEqual(decoded.isEnabled, original.isEnabled)
    }

    func testEncodingMultipleDestinations() throws {
        // Given multiple destinations
        let destinations = [
            FavoriteDestination(name: "Work", address: "123 Main St", latitude: 37.7749, longitude: -122.4194),
            FavoriteDestination(name: "Home", address: "456 Oak Ave", latitude: 37.3349, longitude: -122.0090, isEnabled: false),
            FavoriteDestination(name: "Gym", address: "789 Fit St", latitude: 37.5000, longitude: -122.3000)
        ]

        // When encoding and decoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(destinations)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([FavoriteDestination].self, from: data)

        // Then should match original
        XCTAssertEqual(decoded.count, 3)
        XCTAssertEqual(decoded[0].name, "Work")
        XCTAssertEqual(decoded[1].name, "Home")
        XCTAssertEqual(decoded[2].name, "Gym")
        XCTAssertTrue(decoded[0].isEnabled)
        XCTAssertFalse(decoded[1].isEnabled)
        XCTAssertTrue(decoded[2].isEnabled)
    }

    // MARK: - Edge Cases and Validation

    func testEmptyStrings() {
        // When creating destination with empty strings
        let destination = FavoriteDestination(
            name: "",
            address: "",
            latitude: 0.0,
            longitude: 0.0
        )

        // Then should be created (no validation in model)
        XCTAssertEqual(destination.name, "")
        XCTAssertEqual(destination.address, "")
    }

    func testExtremeCoordinates() {
        // When creating destination with extreme coordinates
        let destination = FavoriteDestination(
            name: "North Pole",
            address: "90°N",
            latitude: 90.0,
            longitude: 0.0
        )

        // Then should be created
        XCTAssertEqual(destination.latitude, 90.0)
        XCTAssertEqual(destination.longitude, 0.0)
    }

    func testNegativeCoordinates() {
        // When creating destination with negative coordinates
        let destination = FavoriteDestination(
            name: "South America",
            address: "Buenos Aires",
            latitude: -34.6037,
            longitude: -58.3816
        )

        // Then should be created
        XCTAssertEqual(destination.latitude, -34.6037, accuracy: 0.0001)
        XCTAssertEqual(destination.longitude, -58.3816, accuracy: 0.0001)
    }

    func testLongNameAndAddress() {
        // When creating destination with very long name and address
        let longName = String(repeating: "A", count: 500)
        let longAddress = String(repeating: "B", count: 1000)

        let destination = FavoriteDestination(
            name: longName,
            address: longAddress,
            latitude: 37.7749,
            longitude: -122.4194
        )

        // Then should be created
        XCTAssertEqual(destination.name.count, 500)
        XCTAssertEqual(destination.address.count, 1000)
    }

    func testSpecialCharactersInText() {
        // When creating destination with special characters
        let destination = FavoriteDestination(
            name: "Café René's Place™",
            address: "123 Main St #5, São Paulo, Brazil 🇧🇷",
            latitude: -23.5505,
            longitude: -46.6333
        )

        // Then should preserve special characters
        XCTAssertTrue(destination.name.contains("é"))
        XCTAssertTrue(destination.name.contains("™"))
        XCTAssertTrue(destination.address.contains("ã"))
        XCTAssertTrue(destination.address.contains("🇧🇷"))
    }

    // MARK: - Sample Data Tests

    func testSampleDataExists() {
        // When accessing sample data
        let samples = FavoriteDestination.samples

        // Then should have expected samples
        XCTAssertEqual(samples.count, 2, "Should have 2 sample destinations")
        XCTAssertEqual(samples[0].name, "Work")
        XCTAssertEqual(samples[1].name, "Home")
    }

    func testSampleDataValidity() {
        // When accessing sample data
        let samples = FavoriteDestination.samples

        // Then all samples should be valid
        for sample in samples {
            XCTAssertFalse(sample.name.isEmpty, "Sample name should not be empty")
            XCTAssertFalse(sample.address.isEmpty, "Sample address should not be empty")
            XCTAssertNotEqual(sample.latitude, 0.0, "Sample latitude should not be 0")
            XCTAssertNotEqual(sample.longitude, 0.0, "Sample longitude should not be 0")
        }
    }

    // MARK: - Identifiable Tests

    func testIdentifiableConformance() {
        // Given a destination
        let destination = FavoriteDestination(
            name: "Work",
            address: "123 Main St",
            latitude: 37.7749,
            longitude: -122.4194
        )

        // When using in ForEach context (requires Identifiable)
        let destinations = [destination]
        let ids = destinations.map { $0.id }

        // Then should have unique ID
        XCTAssertEqual(ids.count, 1)
        XCTAssertEqual(ids[0], destination.id)
    }

    func testUniqueIDsForDifferentInstances() {
        // When creating multiple destinations
        let destinations = (0..<100).map { _ in
            FavoriteDestination(
                name: "Test",
                address: "Test Address",
                latitude: 37.7749,
                longitude: -122.4194
            )
        }

        // Then all IDs should be unique
        let ids = Set(destinations.map { $0.id })
        XCTAssertEqual(ids.count, 100, "All destinations should have unique IDs")
    }
}
