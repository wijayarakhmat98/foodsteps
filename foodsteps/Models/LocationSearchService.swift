import Foundation
import MapKit
import Observation

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
        completer.resultTypes = .pointOfInterest
        completer.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .cafe, .bakery])
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
    }
}
