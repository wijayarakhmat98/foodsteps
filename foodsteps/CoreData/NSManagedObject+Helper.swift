import CoreData
import CloudKit

private let erroneousUserIdentities = [CKUserIdentity]()
private let erroneousAuthorName = "? Unknown"
private let erroneousAuthorInitials = "?"

extension NSManagedObject {
    var share: CKShare? {
        try? dataController.container.fetchShares(matching: [self.objectID]).first?.value
    }

    private var userIdentities: [CKUserIdentity] {
        share?.participants
            .filter { participant in
                participant.userIdentity.userRecordID?.recordName != "__defaultOwner__"
            }
            .filter { participant in
                participant.acceptanceStatus == .accepted
            }
            .map { participant in
                participant.userIdentity
            }
        ?? erroneousUserIdentities
    }

    var userNames: [String] {
        ["You"] + userIdentities.map {
            $0.nameComponents?.formatted() ?? erroneousAuthorName
        }
    }

    var userInitials: [String] {
        ["Y"] + userNames.map { userName in
            if let c = userName.first {
                return String(c)
            }
            return erroneousAuthorInitials
        }
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
        return authorIdentity.nameComponents?.formatted() ?? erroneousAuthorName
    }

    func wrappedAuthorInitials(_ authorRecordName: String?) -> String {
        if let c = wrappedAuthorName(authorRecordName).first {
            return String(c)
        }
        return erroneousAuthorInitials
    }
}
