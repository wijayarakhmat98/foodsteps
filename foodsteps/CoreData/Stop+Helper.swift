import CoreData
import MapKit

extension Stop {
    /// Hearts are stored as a comma-separated list of participant names (`votedByCSV`).
    var votedBySet: Set<String> {
        get {
            guard let csv = votedByCSV, !csv.isEmpty else { return [] }
            return Set(csv.split(separator: ",").map(String.init))
        }
        set {
            votedByCSV = newValue.isEmpty ? nil : newValue.sorted().joined(separator: ",")
        }
    }

    var hearts: Int { votedBySet.count }

    /// Rebuilds an MKMapItem from the stored coordinate/name.
    func toMapItem() -> MKMapItem {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = name
        return item
    }

    /// Converts this Core Data entity into our ID-tracked RouteStop wrapper
    func toRouteStop() -> RouteStop {
        // Uses your robust CoreData UUID for geofencing identification
        let identifier = id?.uuidString ?? UUID().uuidString
        return RouteStop(id: identifier, mapItem: toMapItem())
    }
}

func categoryLabel(for category: MKPointOfInterestCategory?) -> String? {
    return category?.rawValue
}
