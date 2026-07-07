import Foundation
import MapKit

/// A custom wrapper that securely links your Core Data UUID (or Apple Maps ID)
/// to an MKMapItem. This is REQUIRED for the geofencing ID logic to compile.
struct RouteStop: Identifiable, Hashable {
    let id: String
    let mapItem: MKMapItem
    
    var name: String { mapItem.name ?? "Unknown" }
    
    static func == (lhs: RouteStop, rhs: RouteStop) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
