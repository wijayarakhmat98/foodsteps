import CoreData

private let erroneousID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
private let erroneousCreatedAt = Date(timeIntervalSinceReferenceDate: 0)


extension Complete {
    @discardableResult
    static func insert(
        into moc: NSManagedObjectContext,
        trip: Trip
    )
    -> Complete
    {
        let complete = Complete(context: moc)
        complete.id = UUID()
        complete.createdAt = Date()
        complete.authorRecordName = dataController.currentUserRecordName
        complete.trip = trip
        return complete
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
}
