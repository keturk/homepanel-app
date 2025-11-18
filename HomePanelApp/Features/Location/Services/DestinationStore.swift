import Foundation
import Combine

// MARK: - Destination Store Protocol

protocol DestinationStoreProtocol {
    func loadDestinations() async throws -> [FavoriteDestination]
    func saveDestinations(_ destinations: [FavoriteDestination]) async throws
    func addDestination(_ destination: FavoriteDestination) async throws
    func updateDestination(_ destination: FavoriteDestination) async throws
    func deleteDestination(id: UUID) async throws
}

// MARK: - Destination Store

@MainActor
class DestinationStore: ObservableObject, DestinationStoreProtocol {
    @Published var destinations: [FavoriteDestination] = []

    private let keychainService: KeychainServiceProtocol
    private let destinationsKey = "favoriteDestinations"

    init(keychainService: KeychainServiceProtocol) {
        self.keychainService = keychainService
    }

    // MARK: - Load Destinations

    func loadDestinations() async throws -> [FavoriteDestination] {
        DebugLogger.log("📍 [DestinationStore] Loading destinations from keychain", feature: .settings)

        do {
            let data = try keychainService.retrieveData(key: destinationsKey)
            let decoder = JSONDecoder()
            let loadedDestinations = try decoder.decode([FavoriteDestination].self, from: data)

            destinations = loadedDestinations
            DebugLogger.log("✅ [DestinationStore] Loaded \(loadedDestinations.count) destinations", feature: .settings)

            return loadedDestinations
        } catch {
            // If key doesn't exist or data is invalid, return empty array
            DebugLogger.log("📍 [DestinationStore] No destinations found, returning empty array", feature: .settings)
            destinations = []
            return []
        }
    }

    // MARK: - Save Destinations

    func saveDestinations(_ destinations: [FavoriteDestination]) async throws {
        DebugLogger.log("💾 [DestinationStore] Saving \(destinations.count) destinations", feature: .settings)

        let encoder = JSONEncoder()
        let data = try encoder.encode(destinations)

        // Enable iCloud sync so destinations persist across app deletions
        try keychainService.storeData(key: destinationsKey, value: data, syncable: true)

        self.destinations = destinations
        DebugLogger.log("✅ [DestinationStore] Destinations saved successfully to iCloud Keychain", feature: .settings)
    }

    // MARK: - Add Destination

    func addDestination(_ destination: FavoriteDestination) async throws {
        DebugLogger.log("➕ [DestinationStore] Adding destination: \(destination.name)", feature: .settings)

        var updatedDestinations = destinations
        updatedDestinations.append(destination)

        try await saveDestinations(updatedDestinations)
    }

    // MARK: - Update Destination

    func updateDestination(_ destination: FavoriteDestination) async throws {
        DebugLogger.log("✏️ [DestinationStore] Updating destination: \(destination.name)", feature: .settings)

        guard let index = destinations.firstIndex(where: { $0.id == destination.id }) else {
            throw DestinationError.destinationNotFound
        }

        var updatedDestinations = destinations
        updatedDestinations[index] = destination

        try await saveDestinations(updatedDestinations)
    }

    // MARK: - Delete Destination

    func deleteDestination(id: UUID) async throws {
        DebugLogger.log("🗑️ [DestinationStore] Deleting destination with id: \(id)", feature: .settings)

        let updatedDestinations = destinations.filter { $0.id != id }
        try await saveDestinations(updatedDestinations)
    }
}

// MARK: - Destination Errors

enum DestinationError: LocalizedError {
    case destinationNotFound
    case invalidAddress
    case geocodingFailed

    var errorDescription: String? {
        switch self {
        case .destinationNotFound:
            return "Destination not found"
        case .invalidAddress:
            return "Invalid address format"
        case .geocodingFailed:
            return "Failed to geocode address"
        }
    }
}
