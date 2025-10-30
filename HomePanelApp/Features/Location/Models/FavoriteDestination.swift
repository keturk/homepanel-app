import Foundation
import CoreLocation

// MARK: - Favorite Destination Model

struct FavoriteDestination: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var isEnabled: Bool

    init(id: UUID = UUID(), name: String, address: String, latitude: Double, longitude: Double, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.isEnabled = isEnabled
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Sample Data

extension FavoriteDestination {
    static let samples: [FavoriteDestination] = [
        FavoriteDestination(
            name: "Work",
            address: "1 Apple Park Way, Cupertino, CA",
            latitude: 37.3349,
            longitude: -122.0090
        ),
        FavoriteDestination(
            name: "Home",
            address: "123 Main St, San Francisco, CA",
            latitude: 37.7749,
            longitude: -122.4194
        )
    ]
}
