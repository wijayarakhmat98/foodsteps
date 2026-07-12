//
//  SearchViewModel.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 11/07/26.
//


import Foundation
import Observation
import MapKit

@Observable
class SearchViewModel {
    private var allCulinaryPlaces: [CulinaryPlace] = []
    var filteredPlaces: [CulinaryPlace] = []
    var isLoading: Bool = false
    var searchQuery: String = ""
    
    private var isDataLoaded: Bool = false
    
    var mapKitPlaces: [MKMapItem] = []
    
    init() {
        loadAllCulinaryPlaces()
    }
    
    private func loadAllCulinaryPlaces() {
        self.isLoading = true
        
        Task(priority: .userInitiated) {
            let jsonArray = getRawDummyDataFromAssets(assetName: "dummy.json")
            
            if jsonArray.isEmpty {
                await MainActor.run {
                    self.isLoading = false
                    self.isDataLoaded = true
                }
                return
            }
            
            let loadedPlaces = jsonArray.map { CulinaryPlace(dict: $0) }
            
            await MainActor.run {
                self.allCulinaryPlaces = loadedPlaces
                self.filteredPlaces = loadedPlaces
                self.isLoading = false
                self.isDataLoaded = true // Menandakan load awal selesai
                
                // Jika user terlanjur mengetik saat loading awal, langsung jalankan pencarian tertunda
                if !self.searchQuery.isEmpty {
                    self.search(query: self.searchQuery)
                }
            }
        }
    }
    
    func search(query: String) {
        self.searchQuery = query
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard isDataLoaded else {
            self.isLoading = true
            Task {
                do {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        self.search(query: query)
                    }
                } catch {}
            }
            return
        }
        
        if trimmedQuery.isEmpty {
            self.filteredPlaces = allCulinaryPlaces
            self.mapKitPlaces = []
            self.isLoading = false
            return
        }
        
        self.isLoading = true
        
        self.filteredPlaces = allCulinaryPlaces.filter { place in
            let matchName = place.name.localizedCaseInsensitiveContains(trimmedQuery)
            let matchType = place.filteredType.localizedCaseInsensitiveContains(trimmedQuery)
            return matchName || matchType
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmedQuery
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let response = response {
                    self.mapKitPlaces = response.mapItems
                } else {
                    self.mapKitPlaces = []
                }
                self.isLoading = false
            }
        }
    }
    
    func searchUsingMapKit(query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        // Opsional: Kamu bisa batasi wilayah pencarian di sekitar lokasi user
        // request.region = MKCoordinateRegion(...)
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            // Masukkan hasilnya ke MainActor agar SwiftUI langsung update UI
            DispatchQueue.main.async {
                if let response = response {
                    self.mapKitPlaces = response.mapItems
                } else {
                    self.mapKitPlaces = []
                }
            }
        }
    }
}
