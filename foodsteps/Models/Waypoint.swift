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
    var image: UIImage?
}
