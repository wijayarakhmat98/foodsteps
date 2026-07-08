import Foundation
import MapKit
import CoreLocation
import CoreTransferable
import CloudKit
import CoreData

extension Trip {
    var share: CKShare? {
        try? dataController.container.fetchShares(matching: [self.objectID]).first?.value
    }
}

extension Trip: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        let container = dataController.container
        let ckContainer = dataController.ckContainer
        CKShareTransferRepresentation { trip in
            if let share = try? container.fetchShares(matching: [trip.objectID]).first?.value {
                return .existing(share, container: ckContainer)
            }
            let tripURI = trip.objectID.uriRepresentation()
            return .prepareShare(container: ckContainer) {
                let moc = container.viewContext
                let trip = await moc.perform {
                    guard let objectID = moc.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: tripURI) else {
                        fatalError("Unable to get managed objectID for: \(tripURI).")
                    }
                    return moc.object(with: objectID)
                }
                let (_, share, _) = try await container.share([trip], to: nil)
                return share
            }
        }
    }
}

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

extension Trip {
    var meetingPointCoordinate: CLLocationCoordinate2D? {
        guard meetingPointLatitude != 0 || meetingPointLongitude != 0 else { return nil }
        return CLLocationCoordinate2D(latitude: meetingPointLatitude, longitude: meetingPointLongitude)
    }
}

/// Maps MapKit's point-of-interest category to a short, friendly label used
/// on the trip summary screen (e.g. "Coffee Shop", "Bakery", "Street Food").
func categoryLabel(for category: MKPointOfInterestCategory?) -> String? {
    guard let category else { return nil }
    switch category {
    case .cafe:
        return "Coffee Shop"
    case .bakery:
        return "Bakery"
    case .restaurant:
        return "Street Food"
    default:
        return "Restaurant"
    }
}
