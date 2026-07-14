import CoreData
import MapKit

private let erroneousID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
private let erroneousCreatedAt = Date(timeIntervalSinceReferenceDate: 0)
private let erroneousName = "Unknown Location"
private let erroneousAddress = "Unknown Address"
private let erroneousCategory = "Unknown Category"

extension Location {
    @discardableResult
    static func insert(
        into moc: NSManagedObjectContext,
        mapItem: MKMapItem
    )
    -> Location
    {
        let location = Location(context: moc)
        location.id = UUID()
        location.createdAt = Date()
        location.authorRecordName = dataController.currentUserRecordName
        location.name = mapItem.name
        location.address = mapItem.address?.fullAddress
        location.category = mapItem.pointOfInterestCategory?.rawValue
        location.latitude = mapItem.location.coordinate.latitude
        location.longitude = mapItem.location.coordinate.longitude
        return location
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

    var wrappedName: String {
        name ?? erroneousName
    }

    var wrappedAddress: String {
        address ?? erroneousAddress
    }

    var wrappedCategory: String {
        categoryLabel ?? erroneousCategory
    }

    /// A clean, human-readable label for this location's category — e.g.
    /// "Restaurant" rather than the raw `"MKPOICategoryRestaurant"` that's
    /// actually stored in `category` — or `nil` if there's no category.
    var categoryLabel: String? {
        Location.categoryLabel(fromRawCategory: category)
    }

    /// Turns a raw `MKPointOfInterestCategory.rawValue` (e.g.
    /// `"MKPOICategoryRestaurant"`, `"MKPOICategoryATM"`) into a
    /// human-readable label (`"Restaurant"`, `"ATM"`).
    ///
    /// Splitting PascalCase by putting a space before *every* capital
    /// letter breaks on back-to-back-capital categories like `"ATM"` or
    /// `"EVCharger"` (turning them into `"A T M"` / `"E V Charger"`). This
    /// instead only splits at an acronym/word boundary, so a run of
    /// capitals stays together until the last one that starts a new word.
    static func categoryLabel(fromRawCategory rawCategory: String?) -> String? {
        guard let rawCategory, !rawCategory.isEmpty else { return nil }

        let cleanString = rawCategory.replacingOccurrences(of: "MKPOICategory", with: "")
        guard !cleanString.isEmpty else { return nil }

        var readable = cleanString.replacingOccurrences(
            of: "([A-Z]+)([A-Z][a-z])",
            with: "$1 $2",
            options: .regularExpression
        )
        readable = readable.replacingOccurrences(
            of: "([a-z0-9])([A-Z])",
            with: "$1 $2",
            options: .regularExpression
        )
        readable = readable.trimmingCharacters(in: .whitespacesAndNewlines)

        return readable.isEmpty ? nil : readable
    }

    func toMapItem() -> MKMapItem {
        MKMapItem.create(
            name: wrappedName,
            address: address,
            category: category,
            latitude: latitude,
            longitude: longitude
        )
    }
}
