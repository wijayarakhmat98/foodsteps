//
//  TripHistory.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 10/07/26.
//


import Foundation
import CoreLocation

struct TripHistory: Identifiable {
    let id: UUID = UUID()
    let name: String
    let date: Date
    let startTime: Date
    let endTime: Date
    let meetingPoint: String
    let coordinate: CLLocationCoordinate2D?
    var places: [Place] = []
}
