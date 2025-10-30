import Foundation
import MapKit
import CoreLocation

// MARK: - Traffic Info Model

struct TrafficInfo: Identifiable {
    let id: UUID
    let destinationName: String
    let estimatedTravelTime: TimeInterval
    let distance: CLLocationDistance
    let expectedArrivalDate: Date

    var formattedETA: String {
        let minutes = Int(estimatedTravelTime / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        }
    }

    var formattedDistance: String {
        let miles = distance / 1609.34 // Convert meters to miles
        return String(format: "%.1f mi", miles)
    }
}

// MARK: - Traffic Service Protocol

@MainActor
protocol TrafficServiceProtocol {
    func fetchTrafficInfo(for destinations: [FavoriteDestination]) async -> [TrafficInfo]
    func getCurrentLocation() async -> CLLocation?
}

// MARK: - Traffic Service

@MainActor
class TrafficService: NSObject, TrafficServiceProtocol, ObservableObject, CLLocationManagerDelegate {

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Location Manager Delegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            if let location = locations.last {
                self.currentLocation = location
                self.locationContinuation?.resume(returning: location)
                self.locationContinuation = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            DebugLogger.error("❌ [TrafficService] Location error: \(error.localizedDescription)", feature: .common)
            self.locationContinuation?.resume(returning: nil)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            DebugLogger.log("📍 [TrafficService] Authorization status changed: \(status.rawValue)", feature: .common)
        }
    }

    // MARK: - Get Current Location

    func getCurrentLocation() async -> CLLocation? {
        // Check authorization status
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }

        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            DebugLogger.log("⚠️ [TrafficService] Location not authorized", feature: .common)
            return nil
        }

        // If we already have a recent location, use it
        if let current = currentLocation, current.timestamp.timeIntervalSinceNow > -60 {
            return current
        }

        // Request new location
        return await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()

            // Timeout after 10 seconds
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                if self.locationContinuation != nil {
                    self.locationContinuation?.resume(returning: nil)
                    self.locationContinuation = nil
                }
            }
        }
    }

    // MARK: - Fetch Traffic Info

    func fetchTrafficInfo(for destinations: [FavoriteDestination]) async -> [TrafficInfo] {
        DebugLogger.log("🚗 [TrafficService] Fetching traffic info for \(destinations.count) destinations", feature: .common)

        // Get current location
        guard let currentLocation = await getCurrentLocation() else {
            DebugLogger.log("⚠️ [TrafficService] No current location available", feature: .common)
            return []
        }

        DebugLogger.log("📍 [TrafficService] Current location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)", feature: .common)

        // Filter enabled destinations
        let enabledDestinations = destinations.filter { $0.isEnabled }

        var trafficInfos: [TrafficInfo] = []

        for destination in enabledDestinations {
            if let info = await calculateRoute(from: currentLocation, to: destination) {
                trafficInfos.append(info)
            }
        }

        DebugLogger.log("✅ [TrafficService] Fetched traffic info for \(trafficInfos.count) destinations", feature: .common)
        return trafficInfos
    }

    // MARK: - Calculate Route

    private func calculateRoute(from source: CLLocation, to destination: FavoriteDestination) async -> TrafficInfo? {
        DebugLogger.log("🗺️ [TrafficService] Calculating route to \(destination.name)", feature: .common)
        DebugLogger.log("   FROM: \(source.coordinate.latitude), \(source.coordinate.longitude)", feature: .common)
        DebugLogger.log("   TO: \(destination.latitude), \(destination.longitude) (\(destination.address))", feature: .common)

        let sourcePlacemark = MKPlacemark(coordinate: source.coordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destination.coordinate)

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

        do {
            let response = try await directions.calculate()

            guard let route = response.routes.first else {
                DebugLogger.log("⚠️ [TrafficService] No route found for \(destination.name)", feature: .common)
                return nil
            }

            let expectedArrival = Date().addingTimeInterval(route.expectedTravelTime)

            DebugLogger.log("✅ [TrafficService] Route calculated: \(route.distance / 1609.34) mi, \(route.expectedTravelTime / 60) min", feature: .common)

            let info = TrafficInfo(
                id: destination.id,
                destinationName: destination.name,
                estimatedTravelTime: route.expectedTravelTime,
                distance: route.distance,
                expectedArrivalDate: expectedArrival
            )

            DebugLogger.log("✅ [TrafficService] Route to \(destination.name): \(info.formattedETA), \(info.formattedDistance)", feature: .common)

            return info
        } catch {
            DebugLogger.error("❌ [TrafficService] Failed to calculate route to \(destination.name): \(error.localizedDescription)", feature: .common)
            return nil
        }
    }
}
