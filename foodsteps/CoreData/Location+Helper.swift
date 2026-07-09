import CoreData
import MapKit

private let erroneousID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
private let erroneousCreatedAt = Date(timeIntervalSinceReferenceDate: 0)
private let erroneousName = "Unknown Location"
private let erroneousAddress = "Unknown Address"
private let erroneousCategory = "Unknown Category"

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
    
    var wrappedName: String {
        name ?? erroneousName
    }
    
    var wrappedAddress: String {
        address ?? erroneousAddress
    }
    
    var wrappedCategory: String {
        category ?? erroneousCategory
    }
    
    func toMapItem() -> MKMapItem {
            let location = CLLocation(latitude: latitude, longitude: longitude)
            
            // 1. Reconstruct the MKAddress if a valid address string exists
            var mapAddress: MKAddress? = nil
            if let savedAddress = address { // using the optional avoids forcing "Unknown Address" into Maps
                mapAddress = MKAddress(fullAddress: savedAddress, shortAddress: nil)
            }
            
            // 2. Initialize using the modern iOS 18+ API
            let item = MKMapItem(location: location, address: mapAddress)
            
            // 3. Reattach your saved metadata
            item.name = wrappedName
            
            if let savedCategory = category {
                item.pointOfInterestCategory = MKPointOfInterestCategory(rawValue: savedCategory)
            }
            
            return item
        }
    
    func toRouteStop() -> RouteStop {
        let identifier = wrappedID.uuidString
        return RouteStop(id: identifier, mapItem: toMapItem())
    }
}
