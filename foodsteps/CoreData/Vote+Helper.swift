import CoreData

private let erroneousID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
private let erroneousCreatedAt = Date(timeIntervalSinceReferenceDate: 0)

extension Vote {
    @discardableResult
    static func insert(
        into moc: NSManagedObjectContext,
        stop: Stop
    )
    -> Vote
    {
        let vote = Vote(context: moc)
        vote.id = UUID()
        vote.createdAt = Date()
        vote.authorRecordName = dataController.currentUserRecordName
        vote.stop = stop
        return vote
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
