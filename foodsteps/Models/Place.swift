//
//  Place.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 10/07/26.
//

import Foundation
import CoreLocation

// MARK: - Main Model Place
struct Place: Identifiable, Hashable {
    let id: UUID = UUID()
    let name: String
    let location: PlaceLocation
    let imageUrl: String
    let totalLikes: Int
    let type: String
    let comments: [PlaceComment] // Berbentuk array karena biasanya satu tempat punya banyak komen

    // Berfungsi agar model bisa mengadopsi Hashable dengan mudah (terutama untuk CLLocationCoordinate2D)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Place, rhs: Place) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Sub-Model Location
struct PlaceLocation: Hashable {
    let name: String
    let latitude: Double
    let longitude: Double
    
    // Helper property jika kamu butuh object CLLocationCoordinate2D untuk MapKit
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Sub-Model Comment
struct PlaceComment: Identifiable, Hashable {
    let id: UUID = UUID()
    let userName: String // Menggunakan userName agar tidak rancu dengan properti 'name' milik Place
    let content: String
}
