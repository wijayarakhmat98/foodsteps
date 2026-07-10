import MapKit

extension MKMapItem {
    static func create(
        name: String,
        address: String?,
        category: String?,
        latitude: Double,
        longitude: Double
    ) -> MKMapItem {
        let location = CLLocation(latitude: latitude, longitude: longitude)

        let mkAddress: MKAddress? = {
            if let address {
                return MKAddress(fullAddress: address, shortAddress: nil)
            } else {
                return nil
            }
        }()

        let item = MKMapItem(location: location, address: mkAddress)

        item.name = name

        if let category {
            item.pointOfInterestCategory = MKPointOfInterestCategory(rawValue: category)
        }

        return item
    }
}
