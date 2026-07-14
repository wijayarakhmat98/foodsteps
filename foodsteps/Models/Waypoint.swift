//
//  Waypoint.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 12/07/26.
//
import SwiftUI
import MapKit

struct Waypoint: Identifiable {
    var id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    /// Human-readable category label (e.g. "Restaurant", "Shopping Mall") —
    /// see `Location.categoryLabel`. `nil` when unknown.
    var category: String?
    var image: UIImage?
}
