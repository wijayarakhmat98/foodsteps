//
//  HomeViewModel.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 11/07/26.
//


import Foundation
import SwiftUI

@Observable
class HomeViewModel {
    var culinaryPlaces: [CulinaryPlace] = []
    
    var isLoading: Bool = false
    
    init() {
        loadCulinaryPlaces()
    }
    
    func loadCulinaryPlaces() {
        self.isLoading = true
        
        Task(priority: .userInitiated) {
            let jsonArray = getRawDummyDataFromAssets(assetName: "dummy.json")
            
            if jsonArray.isEmpty {
                await MainActor.run {
                    self.isLoading = false
                }
                return
            }
            
            let loadedPlaces = jsonArray.map { CulinaryPlace(dict: $0) }
            await MainActor.run {
                self.culinaryPlaces = loadedPlaces
                self.isLoading = false
            }
        }
    }
}
