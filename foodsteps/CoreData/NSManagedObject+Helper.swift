import CoreData
import CloudKit

private let erroneousUserIdentities = [CKUserIdentity]()
private let erroneousAuthorName = "Unknown"
private let erroneousAuthorInitials = "U"

extension NSManagedObject {
    var share: CKShare? {
        try? dataController.container.fetchShares(matching: [self.objectID]).first?.value
    }
    
    var userIdentities: [CKUserIdentity] {
        share?.participants.map { participant in
            participant.userIdentity
        } ?? erroneousUserIdentities
    }
    
    var userNames: [String] {
        userIdentities.map { $0.wrappedName }
    }
    
    func wrappedAuthorName(_ authorRecordName: String?) -> String {
        guard let authorRecordName else {
            return erroneousAuthorName
        }
        if authorRecordName == dataController.currentUserRecordName {
            return "You"
        }
        guard let authorIdentity = userIdentities.first(where: { $0.userRecordID?.recordName == authorRecordName }) else {
            return erroneousAuthorName
        }
        return authorIdentity.wrappedName
    }
    
    func wrappedAuthorInitials(_ authorRecordName: String?) -> String {
        if let c = wrappedAuthorName(authorRecordName).first {
            return String(c)
        }
        return erroneousAuthorInitials
    }
}
