import CoreData
import Foundation
import Observation

@Observable
class DataController {
    let container = NSPersistentCloudKitContainer(name: "foodsteps")

    init() {
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
}
