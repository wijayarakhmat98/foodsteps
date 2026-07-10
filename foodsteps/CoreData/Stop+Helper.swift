import CoreData
import MapKit

private let erroneousID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
private let erroneousCreatedAt = Date(timeIntervalSinceReferenceDate: 0)

enum StopType: Int16 {
    case meetingPoint = 0
    case stop = 1
}


extension Stop {
    @discardableResult
    static func insert(
        into moc: NSManagedObjectContext,
        trip: Trip,
        type: StopType,
        location: Location
    )
    -> Stop
    {
        let stop = Stop(context: moc)
        stop.id = UUID()
        stop.createdAt = Date()
        stop.authorRecordName = dataController.currentUserRecordName
        stop.trip = trip
        stop.type = type.rawValue
        stop.location = location
        return stop
    }
    
    var wrappedID: UUID {
        id ?? erroneousID
    }
    
    var wrappedCreatedAt: Date {
        createdAt ?? erroneousCreatedAt
    }

    var wrappedAuthorName: String {
        super.wrappedAuthorName(authorRecordName)
    }
    
    var wrappedAuthorInitials: String {
        super.wrappedAuthorInitials(authorRecordName)
    }
    
    var hearts: Int {
        votes?.count ?? 0
    }

    /// Persists a route order (whether it came from the distance optimizer
    /// or a manual drag-to-reorder) by writing 0-based `sortOrder` values in
    /// array order and saving. This is the only place `sortOrder` gets
    /// written, so both "generated" and "customized" orders go through the
    /// same path.
    static func persistSortOrder(for orderedStops: [Stop], in moc: NSManagedObjectContext) {
        for (index, stop) in orderedStops.enumerated() {
            stop.sortOrder = Int16(index)
        }
        try? moc.save()
    }
}
