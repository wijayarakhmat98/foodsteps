//
//  MKMapItemExt.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 12/07/26.
//

import MapKit
import CoreLocation

extension MKMapItem {
    /// Membuat MKMapItem tanpa risiko nil menggunakan koordinat Double (iOS 26.0+)
    static func fromRawData(
        latitude: Double,
        longitude: Double,
        name: String,
        address: String
    ) -> MKMapItem {
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let location = CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1, timestamp: Date())
        
        // 2. Buat objek MKAddress
        let mkAddress = MKAddress(fullAddress: address, shortAddress: nil)
        
        // 3. Inisialisasi MKMapItem
        let mapItem = MKMapItem(location: location, address: mkAddress)
        mapItem.name = name
        
        // 4. Set kategori sebagai Restoran
        mapItem.pointOfInterestCategory = .restaurant
        
        return mapItem
    }
}
