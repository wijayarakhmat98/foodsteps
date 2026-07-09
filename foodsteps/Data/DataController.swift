import CoreData
import CloudKit

class DataController {
    let container = NSPersistentCloudKitContainer(name: "foodsteps")

    let _ckContainer: CKContainer?
    lazy var ckContainer: CKContainer = {
        _ckContainer!
    }()

    private(set) var userRecordName: String?

    let privatePersistentStore: NSPersistentStore
    let sharedPersistentStore: NSPersistentStore

    init() {
        let containerIdentifier = container.persistentStoreDescriptions.first?.cloudKitContainerOptions?.containerIdentifier

        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            fatalError("Unable to find persistent store URL")
        }

        let baseStoreURL = storeURL.deletingLastPathComponent()

        let privateStoreURL = baseStoreURL.appendingPathComponent("private.sqlite")
        let privateDescription = NSPersistentStoreDescription(url: privateStoreURL)
        if let containerIdentifier {
            let privateOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
            privateOptions.databaseScope = .private
            privateDescription.cloudKitContainerOptions = privateOptions
        } else {
            fatalError("Unable to find cloud container identifier")
        }
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        let sharedStoreURL = baseStoreURL.appendingPathComponent("shared.sqlite")
        let sharedDescription = NSPersistentStoreDescription(url: sharedStoreURL)
        if let containerIdentifier {
            let sharedOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
            sharedOptions.databaseScope = .shared
            sharedDescription.cloudKitContainerOptions = sharedOptions
        } else {
            fatalError("Unable to find cloud container identifier")
        }
        sharedDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        sharedDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.persistentStoreDescriptions = [privateDescription, sharedDescription]
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("\(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        privatePersistentStore = container.persistentStoreCoordinator.persistentStore(for: privateDescription.url!)!
        sharedPersistentStore = container.persistentStoreCoordinator.persistentStore(for: sharedDescription.url!)!

        if let containerIdentifier {
            _ckContainer = CKContainer(identifier: containerIdentifier)
            Task {
                if let userRecordName = try? await _ckContainer?.userRecordID().recordName {
                    await MainActor.run {
                        self.userRecordName = userRecordName
                    }
                } else {
                    fatalError("Unable to determine current user")
                }
            }
        } else {
            fatalError("Unable to find cloud container identifier")
        }
    }
}
