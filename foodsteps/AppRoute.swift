//
//  AppRoute.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 09/07/26.
//

import SwiftUI

enum Route: Hashable {
    case search(query: String)
    case placeDetail
    
    @ViewBuilder
    func destinationView() -> some View {
        switch self {
        case .search(let query):
            SearchView2(query: query) // Slicing page tujuan kamu
        case .placeDetail:
            DetailPlaceView()
        }
    }
}

@Observable
class AppRoute {
    // Array penampung antrean halaman (Gaya murni)
    var path: [Route] = []
    
    // Singleton Instance agar bisa diakses secara global di mana saja
    static let shared = AppRoute()
    
    // Fungsi push yang sangat clean, mirip Flutter!
    static func push(_ route: Route) {
        shared.path.append(route)
    }
    
    // Fungsi pop (Navigator.pop)
    static func pop() {
        if !shared.path.isEmpty {
            shared.path.removeLast()
        }
    }
    
    // Fungsi pop to root (Kembali ke halaman awal)
    static func popToRoot() {
        shared.path.removeAll()
    }
}
