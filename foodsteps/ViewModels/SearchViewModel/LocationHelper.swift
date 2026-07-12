//
//  LocationHelper.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 11/07/26.
//


import MapKit

struct LocationHelper {
    static func calculateRouteDistance(
        userLat: Double,
        userLng: Double,
        placeLat: Double,
        placeLng: Double,
        completion: @escaping (Double?) -> Void
    ) {
        let userCoordinate = CLLocationCoordinate2D(latitude: userLat, longitude: userLng)
        let placeCoordinate = CLLocationCoordinate2D(latitude: placeLat, longitude: placeLng)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: placeCoordinate))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let route = response?.routes.first else {
                completion(nil)
                return
            }
            
            let distanceInKM = route.distance / 1000
            completion(distanceInKM)
        }
    }
}