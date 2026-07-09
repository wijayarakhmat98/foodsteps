import CoreData
import CloudKit
import CoreTransferable

extension Trip {
    var meetingPointCoordinate: CLLocationCoordinate2D? {
        guard meetingPointLatitude != 0 || meetingPointLongitude != 0 else { return nil }
        return CLLocationCoordinate2D(latitude: meetingPointLatitude, longitude: meetingPointLongitude)
    }
}

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
