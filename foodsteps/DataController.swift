import CoreData

class DataController {
    let container = NSPersistentContainer(name: "foodsteps")

    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
}
