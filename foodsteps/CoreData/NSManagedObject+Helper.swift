import CoreData
import CloudKit

extension NSManagedObject {
    var share: CKShare? {
        try? dataController.container.fetchShares(matching: [self.objectID]).first?.value
    }
}
