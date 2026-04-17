import Foundation
import CoreLocation
import UserNotifications

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var userLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var hasRequestedPermission = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 100 // Performance: only update on 100m+ movement
        manager.pausesLocationUpdatesAutomatically = true
        manager.activityType = .other
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        guard authorizationStatus == .notDetermined else {
            if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
            return
        }
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        manager.requestLocation()
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if isAuthorized { manager.requestLocation() }
    }
}

// MARK: - Notifications
@MainActor
func requestNotificationPermission() async {
    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()
    guard settings.authorizationStatus == .notDetermined else { return }

    try? await center.requestAuthorization(options: [.alert, .badge, .sound])
}
