import Foundation
import CoreLocation

// MARK: - Geocoding Service

@MainActor
class GeocodingService {

    // MARK: - Geocode Address

    func geocodeAddress(_ address: String) async throws -> (latitude: Double, longitude: Double, formattedAddress: String) {
        DebugLogger.log("🗺️ [GeocodingService] Geocoding address: \(address)", feature: .settings)

        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.geocodeAddressString(address)

            guard let placemark = placemarks.first,
                  let location = placemark.location else {
                throw DestinationError.geocodingFailed
            }

            // Build formatted address
            var addressComponents: [String] = []
            if let name = placemark.name {
                addressComponents.append(name)
            }
            if let locality = placemark.locality {
                addressComponents.append(locality)
            }
            if let state = placemark.administrativeArea {
                addressComponents.append(state)
            }

            let formattedAddress = addressComponents.isEmpty ? address : addressComponents.joined(separator: ", ")

            DebugLogger.log("✅ [GeocodingService] Geocoded: \(formattedAddress) -> \(location.coordinate.latitude), \(location.coordinate.longitude)", feature: .settings)

            return (location.coordinate.latitude, location.coordinate.longitude, formattedAddress)
        } catch {
            DebugLogger.error("❌ [GeocodingService] Geocoding failed: \(error.localizedDescription)", feature: .settings)
            throw DestinationError.geocodingFailed
        }
    }

    // MARK: - Reverse Geocode

    func reverseGeocodeLocation(latitude: Double, longitude: Double) async throws -> String {
        DebugLogger.log("🗺️ [GeocodingService] Reverse geocoding: \(latitude), \(longitude)", feature: .settings)

        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)

            guard let placemark = placemarks.first else {
                throw DestinationError.geocodingFailed
            }

            // Build address string
            var addressComponents: [String] = []
            if let name = placemark.name {
                addressComponents.append(name)
            }
            if let locality = placemark.locality {
                addressComponents.append(locality)
            }
            if let state = placemark.administrativeArea {
                addressComponents.append(state)
            }

            let address = addressComponents.joined(separator: ", ")

            DebugLogger.log("✅ [GeocodingService] Reverse geocoded: \(address)", feature: .settings)

            return address
        } catch {
            DebugLogger.error("❌ [GeocodingService] Reverse geocoding failed: \(error.localizedDescription)", feature: .settings)
            throw DestinationError.geocodingFailed
        }
    }
}
