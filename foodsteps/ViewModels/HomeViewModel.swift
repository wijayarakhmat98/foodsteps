import Foundation
import UIKit

@Observable
class HomeViewModel {
    // Array penampung data yang sudah rapi dan siap dikonsumsi oleh SwiftUI View
    var culinaryPlaces: [CulinaryPlace] = []
    
    // Indikator loading jika sewaktu-waktu data kamu butuh diproses agak lama
    var isLoading: Bool = false
    
    init() {
        loadCulinaryPlaces()
    }
    
    func loadCulinaryPlaces() {
        self.isLoading = true
        
        // Panggil nama data asset JSON kamu yang ada di Assets.xcassets
        // (Pastikan namanya disamakan dengan nama asset di Xcode kamu, misal: "MegaRestaurantData")
        guard let asset = NSDataAsset(name: "MegaRestaurantData") else {
            print("❌ Gagal: Data Asset 'MegaRestaurantData' tidak ditemukan di Assets.xcassets")
            self.isLoading = false
            return
        }
        
        // Gunakan Background Thread (Task) agar UI tidak freeze saat parsing 16k baris JSON
        Task(priority: .userInitiated) {
            do {
                // 1. Parsing data mentah dari asset menjadi Array of Dictionary [[String: Any]]
                guard let jsonArray = try JSONSerialization.jsonObject(with: asset.data, options: []) as? [[String: Any]] else {
                    print("❌ Gagal: Format JSON di dalam Asset tidak sesuai dengan [[String: Any]]")
                    await MainActor.run { self.isLoading = false }
                    return
                }
                
                // 2. Mapping & Transformasi dari Dictionary ke Model CulinaryPlace
                let loadedPlaces = jsonArray.map { CulinaryPlace(dict: $0) }
                
                // 3. Kembalikan data ke Main Thread (UI Thread) untuk mengupdate View
                await MainActor.run {
                    self.culinaryPlaces = loadedPlaces
                    self.isLoading = false
                    print("✅ Sukses: Berhasil memuat \(self.culinaryPlaces.count) tempat kuliner ke ViewModel!")
                }
                
            } catch {
                print("❌ Gagal parsing JSON: \(error.localizedDescription)")
                await MainActor.run { self.isLoading = false }
            }
        }
    }
}