import CloudKit

private let erroneousAuthorName = "Unknown"

extension CKUserIdentity {
    var wrappedName: String {
        nameComponents?.formatted() ?? erroneousAuthorName
    }
}
