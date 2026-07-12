import Foundation
import CoreLocation

struct TripHistory: Identifiable {
    let id: UUID = UUID()
    let tripName: String
    let tripDate: Date
    let startTime: Date
    let endTime: Date
    let meetingPoint: String
    let coordinate: CLLocationCoordinate2D? // Menyimpan lat & long dari MapKit
}