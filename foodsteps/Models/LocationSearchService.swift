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

    override init() {
        super.init()
        completer.delegate = self

        // Define the region right here so it never gets lost!
        let bantenJakartaCenter = CLLocationCoordinate2D(latitude: -6.3000, longitude: 106.4000)
        let bantenJakartaRegion = MKCoordinateRegion(
            center: bantenJakartaCenter,
            span: MKCoordinateSpan(latitudeDelta: 1.5, longitudeDelta: 1.5)
        )

        completer.region = bantenJakartaRegion
        configure(for: .foodOnly)
    }

    /// Switches what the completer searches for. Call this before presenting
    /// a picker — `.anyPlace` for the meeting point, `.foodOnly` for trip stops.
    func configure(for mode: LocationSearchMode) {
        switch mode {
        case .foodOnly:
            completer.resultTypes = .pointOfInterest
            completer.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .cafe, .bakery])
        case .anyPlace:
            completer.resultTypes = [.pointOfInterest, .address]
            completer.pointOfInterestFilter = .includingAll
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
    }
}
