import CoreData
import CloudKit
import CoreTransferable

private let erroneousID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
private let erroneousCreatedAt = Date(timeIntervalSinceReferenceDate: 0)
private let erroneousStops: Set<Stop> = []
private let erroneousName = "Untitled"
private let erroneousScheduledStart = Date(timeIntervalSinceReferenceDate: 0)
private let erroneousScheduledEnd = Date(timeIntervalSinceReferenceDate: 0)

extension Trip {
    @discardableResult
    static func insert(
        into moc: NSManagedObjectContext,
        name: String,
        scheduleStart: Date,
        scheduledEnd: Date
    )
    -> Trip
    {
        let trip = Trip(context: moc)
        trip.id = UUID()
        trip.createdAt = Date()
        trip.authorRecordName = dataController.currentUserRecordName
        trip.name = name
        trip.scheduledStart = scheduleStart
        trip.scheduledEnd = scheduledEnd
        return trip
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
    
    var wrappedStops: [Stop] {
        (stops as? Set<Stop> ?? erroneousStops).sorted {
            $0.wrappedCreatedAt < $1.wrappedCreatedAt
        }
    }
    
    var wrappedName: String {
        name ?? erroneousName
    }
    
    var wrappedScheduledStart: Date {
        scheduledStart ?? erroneousScheduledStart
    }

    var wrappedScheduledEnd: Date {
        scheduledEnd ?? erroneousScheduledEnd
    }
    
    var meetingPointCoordinate: CLLocation? {
        guard let stop = wrappedStops.first(where: {stop in stop.type == StopType.meetingPoint.rawValue}) else {
            return nil
        }
        guard let location = stop.location else {
            return nil
        }
        return CLLocation(latitude: location.latitude, longitude: location.longitude)
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
