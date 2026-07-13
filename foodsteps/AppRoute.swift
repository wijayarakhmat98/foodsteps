//
//  AppRoute.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 09/07/26.
//

import SwiftUI
import CoreData
import MapKit

enum Route {
    case search(query: String)
    case placeDetail(culinaryPlace: CulinaryPlace)
    case tripDetail(trip: Trip)
    case mapRoute(wayPoints: [Waypoint], pathCoordinates: [CLLocationCoordinate2D], trip: Trip)
    
    @ViewBuilder
    func destinationView() -> some View {
        switch self {
        case .search(let query):
            SearchView2(query: query)
        case .placeDetail(let culinaryPlace):
            DetailPlaceView(culinaryPlace: culinaryPlace)
        case .tripDetail(let trip):
            if trip.hasCurrentUserCompleted {
                SavedTripMapRouteView(trip: trip)
            } else {
                TripInputView(trip: trip)
            }
        case .mapRoute(let wayPoints, let pathCoordinates, let trip):
            MapRouteView(waypoints: wayPoints, pathCoordinates: pathCoordinates, trip: trip)
        }
    }
}

@Observable
class AppRoute {
    // Array penampung antrean halaman (Gaya murni)
    var path: [Route] = []
    
    // Singleton Instance agar bisa diakses secara global di mana saja
    static let shared = AppRoute()
    
    static func push(_ route: Route) {
        shared.path.append(route)
    }
    
    static func replace(_ route: Route) {
        if !shared.path.isEmpty {
            shared.path.removeLast()
        }
        shared.path.append(route)
    }
    
    static func pop() {
        if !shared.path.isEmpty {
            shared.path.removeLast()
        }
    }
    
    static func popToRoot() {
        shared.path.removeAll()
    }
}

extension Route: Equatable {
    static func == (lhs: Route, rhs: Route) -> Bool {
        switch (lhs, rhs) {
        case (.search(let lQuery), .search(let rQuery)):
            return lQuery == rQuery
            
        case (.placeDetail(let lPlace), .placeDetail(let rPlace)):
            return lPlace.id == rPlace.id
            
        case (.tripDetail(let lTrip), .tripDetail(let rTrip)):
            // Karena Trip adalah CoreData, kita bandingkan lewat objectID bawaan CoreData-nya
            return lTrip.objectID == rTrip.objectID
            
        default:
            return false
        }
    }
}

extension Route: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .search(let query):
            hasher.combine(0) // identifier unique untuk case search
            hasher.combine(query)
            
        case .placeDetail(let culinaryPlace):
            hasher.combine(1) // identifier unique untuk case placeDetail
            hasher.combine(culinaryPlace.id)
            
        case .tripDetail(let trip):
            hasher.combine(2) // identifier unique untuk case tripDetail
            hasher.combine(trip.objectID) // Memakai objectID bawaan CoreData yang sudah pasti Hashable
        case .mapRoute(wayPoints: let wayPoints, pathCoordinates: let pathCoordinates, let trip):
            hasher.combine(3)
            hasher.combine(wayPoints.first?.id)
        }
    }
}
