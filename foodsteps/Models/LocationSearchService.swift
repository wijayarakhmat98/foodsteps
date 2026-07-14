import Foundation
import MapKit
import Observation

/// What kind of places a search should surface.
enum LocationSearchMode {
    /// Any place at all — used for the meeting point, which doesn't have to be food-related.
    case anyPlace
    /// Restaurants, cafes, and bakeries only — used when picking trip stops.
    case foodOnly
}

@Observable
class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {
    private let completer = MKLocalSearchCompleter()
    var completions: [MKLocalSearchCompletion] = []

    var searchQuery = "" {
        didSet {
            if searchQuery.isEmpty {
                completions = []
            } else {
                completer.queryFragment = searchQuery
            }
        }
    }

    /// Region used to bias `.foodOnly` searches (trip stops) toward the
    /// Jakarta/Banten culinary scene the app is built around.
    private let bantenJakartaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -6.3000, longitude: 106.4000),
        span: MKCoordinateSpan(latitudeDelta: 1.5, longitudeDelta: 1.5)
    )

    /// A near-country-sized region used for `.anyPlace` (the meeting point)
    /// so it isn't boxed into the Jakarta/Banten area the way stop search
    /// is — a meeting point can reasonably be anywhere.
    private let unrestrictedRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -2.5, longitude: 118.0),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
    )

    override init() {
        super.init()
        completer.delegate = self
        configure(for: .foodOnly)
    }

    /// Switches what the completer searches for. Call this before presenting
    /// a picker — `.anyPlace` for the meeting point, `.foodOnly` for trip stops.
    func configure(for mode: LocationSearchMode) {
        switch mode {
        case .foodOnly:
            // Restaurants/cafes/bakeries only, biased to the local culinary region.
            completer.region = bantenJakartaRegion
            completer.resultTypes = .pointOfInterest
            completer.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .cafe, .bakery])
        case .anyPlace:
            // No category restriction, and no tight geographic box — the
            // meeting point can be any kind of place, anywhere.
            completer.region = unrestrictedRegion
            completer.resultTypes = [.pointOfInterest, .address]
            completer.pointOfInterestFilter = .includingAll
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
    }
}
