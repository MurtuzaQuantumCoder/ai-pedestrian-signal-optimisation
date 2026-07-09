import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var locationLabel: String = "Locating…"
    @Published private(set) var errorMessage: String?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor in
                guard let self else { return }
                if let placemark = placemarks?.first {
                    let parts = [placemark.name, placemark.locality, placemark.administrativeArea]
                        .compactMap { $0 }
                    self.locationLabel = parts.isEmpty ? "Current location" : parts.joined(separator: ", ")
                } else if let error {
                    self.locationLabel = String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude)
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
                startUpdating()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            currentLocation = location
            reverseGeocode(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
            locationLabel = "Location unavailable"
        }
    }
}
