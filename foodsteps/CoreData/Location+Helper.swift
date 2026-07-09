import CoreData
import MapKit

private let erroneousID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
private let erroneousCreatedAt = Date(timeIntervalSinceReferenceDate: 0)

extension Location {
    @discardableResult
    static func insert(
        into moc: NSManagedObjectContext,
        mapItem: MKMapItem
    )
    -> Location
    {
        let location = Location(context: moc)
        location.id = UUID()
        location.createdAt = Date()
        location.authorRecordName = dataController.currentUserRecordName
        location.name = mapItem.name
        location.address = mapItem.address?.fullAddress
        location.category = mapItem.pointOfInterestCategory?.rawValue
        location.latitude = mapItem.location.coordinate.latitude
        location.longitude = mapItem.location.coordinate.longitude
        return location
    }
    
    var wrappedID: UUID {
        id ?? erroneousID
    }
    
    var wrappedCreatedAt: Date {
        createdAt ?? erroneousCreatedAt
    }
    
    func toMapItem() -> MKMapItem {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let item = MKMapItem(location: location, address: nil)
        return item
    }
    
    func toRouteStop() -> RouteStop {
        let identifier = wrappedID.uuidString
        return RouteStop(id: identifier, mapItem: toMapItem())
    }
}
