import Foundation

struct CulinaryPlace: Identifiable {
    let id: String
    let types: [String]
    let nationalPhoneNumber: String
    let formattedAddress: String
    let shortFormattedAddress: String
    let latitude: Double
    let longitude: Double
    let imageUrl: String
    let rating: Double
    let googleMapsUri: String
    let websiteUri: String
    let businessStatus: String
    let priceLevel: String
    let userRatingCount: Int
    let name: String
    let rawType: String
    let filteredType: String // <- Ini tipe yang udah bersih ("Indonesian", "Restaurant", dll)
    
    // Fitur Tambahan (Boolean flags)
    let takeout: Bool
    let delivery: Bool
    let dineIn: Bool
    
    // Inisialisasi dari [String: Any]
    init(dict: [String: Any]) {
        self.id = dict["id"] as? String ?? UUID().uuidString
        self.types = dict["types"] as? [String] ?? []
        self.nationalPhoneNumber = dict["nationalPhoneNumber"] as? String ?? "-"
        self.formattedAddress = dict["formattedAddress"] as? String ?? ""
        self.shortFormattedAddress = dict["shortFormattedAddress"] as? String ?? ""
        
        // Parsing koordinat dari objek bertingkat "location"
        let locationDict = dict["location"] as? [String: Any]
        self.latitude = locationDict["latitude"] as? Double ?? 0.0
        self.longitude = locationDict["longitude"] as? Double ?? 0.0
        
        self.imageUrl = dict["image_url"] as? String ?? ""
        self.rating = dict["rating"] as? Double ?? 0.0
        self.googleMapsUri = dict["googleMapsUri"] as? String ?? ""
        self.websiteUri = dict["websiteUri"] as? String ?? ""
        self.businessStatus = dict["businessStatus"] as? String ?? ""
        self.priceLevel = dict["priceLevel"] as? String ?? ""
        self.userRatingCount = dict["userRatingCount"] as? Int ?? 0
        
        // Parsing Nama Tempat dari objek bertingkat "displayName"
        let displayNameDict = dict["displayName"] as? [String: Any]
        self.name = displayNameDict?["text"] as? String ?? "Unknown Culinary Place"
        
        // Flags Boolean
        self.takeout = dict["takeout"] as? Bool ?? false
        self.delivery = dict["delivery"] as? Bool ?? false
        self.dineIn = dict["dineIn"] as? Bool ?? false
        
        // --- LOGIKA REPLACING DELIMITER & HAPUS KATA "RESTAURANT" ---
        let primaryTypeRaw = dict["primaryType"] as? String ?? ""
        self.rawType = primaryTypeRaw
        
        // 1. Ubah "_" menjadi spasi
        let typeWithSpaces = primaryTypeRaw.replacingOccurrences(of: "_", with: " ")
        let lowercasedType = typeWithSpaces.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 2. Filter kata "restaurant" sesuai aturan
        if lowercasedType == "restaurant" {
            self.filteredType = typeWithSpaces.capitalized // Tetap jadi "Restaurant"
        } else {
            let cleanType = typeWithSpaces.replacingOccurrences(of: "restaurant", with: "", options: .caseInsensitive)
            // Lakukan .capitalized agar rapi (contoh: "indonesian" -> "Indonesian")
            self.filteredType = cleanType.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
        }
    }
}