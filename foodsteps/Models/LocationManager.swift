import Foundation
import CoreLocation
import Observation

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {

    let manager = CLLocationManager()

    var currentLocation: CLLocationCoordinate2D?

    /// Fires whenever the GPS location changes.
    var onLocationUpdate: ((CLLocationCoordinate2D) -> Void)?

    /// Fires when arriving at a monitored destination.
    var onRegionEntered: ((String) -> Void)?

    override init() {
        super.init()

        manager.delegate = self

        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 5
        manager.activityType = .automotiveNavigation
        manager.pausesLocationUpdatesAutomatically = false
    }

    // MARK: - Start Location Updates

    func requestPermissionAndStart() {

        switch manager.authorizationStatus {

        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        case .authorizedAlways,
             .authorizedWhenInUse:

            manager.startUpdatingLocation()

        default:
            break
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    // MARK: - Authorization

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {

        switch manager.authorizationStatus {

        case .authorizedAlways,
             .authorizedWhenInUse:

            manager.startUpdatingLocation()

        default:
            break
        }
    }

    // MARK: - Live GPS

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {

        guard let latest = locations.last else {
            return
        }

        currentLocation = latest.coordinate

        onLocationUpdate?(latest.coordinate)
    }

    // MARK: - Arrival Monitoring

    func monitorArrival(
        at coordinate: CLLocationCoordinate2D,
        identifier: String,
        radius: CLLocationDistance = 40
    ) {

        stopMonitoringArrivals()

        let region = CLCircularRegion(
            center: coordinate,
            radius: min(radius, manager.maximumRegionMonitoringDistance),
            identifier: identifier
        )

        region.notifyOnEntry = true
        region.notifyOnExit = false

        manager.startMonitoring(for: region)
    }

    func stopMonitoringArrivals() {

        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didEnterRegion region: CLRegion
    ) {

        onRegionEntered?(region.identifier)
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {

        print("Location Error:", error.localizedDescription)
    }
}
