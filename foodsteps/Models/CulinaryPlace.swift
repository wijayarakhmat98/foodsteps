//
//  CulinaryPlace.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 11/07/26.
//


import Foundation
import MapKit

struct Review: Identifiable, Hashable {
    let id: String = UUID().uuidString
    let authorName: String
    let authorPhoto: String
    let rating: Int
    let timeDescription: String
    let comment: String
    
    init(dict: [String: Any]) {
        let author = dict["authorAttribution"] as? [String: Any]
        self.authorName = author?["displayName"] as? String ?? "Anonymous"
        self.authorPhoto = author?["photoUri"] as? String ?? ""
        
        self.rating = dict["rating"] as? Int ?? 5
        self.timeDescription = dict["relativePublishTimeDescription"] as? String ?? ""
        
        let textDict = dict["text"] as? [String: Any]
        self.comment = textDict?["text"] as? String ?? ""
    }
}

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
    
    let reviews: [Review]
    
    let weekdayDescriptions: [String]
    
    // Inisialisasi dari [String: Any]
    init(dict: [String: Any]) {
        self.id = dict["id"] as? String ?? UUID().uuidString
        self.types = dict["types"] as? [String] ?? []
        self.nationalPhoneNumber = dict["nationalPhoneNumber"] as? String ?? "-"
        self.formattedAddress = dict["formattedAddress"] as? String ?? ""
        self.shortFormattedAddress = dict["shortFormattedAddress"] as? String ?? ""
        
        // Parsing koordinat dari objek bertingkat "location"
        let locationDict = dict["location"] as? [String: Any]
        self.latitude = locationDict?["latitude"] as? Double ?? 0.0
        self.longitude = locationDict!["longitude"] as? Double ?? 0.0
        
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
        
        if let reviewsRaw = dict["reviews"] as? [[String: Any]] {
            // Mapping tiap dictionary review ke dalam struct Review
            self.reviews = reviewsRaw.map { Review(dict: $0) }
        } else {
            self.reviews = []
        }
        
        if let openingHours = dict["regularOpeningHours"] as? [String: Any] {
            self.weekdayDescriptions = openingHours["weekdayDescriptions"] as? [String] ?? []
        } else {
            self.weekdayDescriptions = []
        }
        
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
    
    // Properti baru untuk mengelompokkan hari yang jam bukanya sama
    var groupedOpeningHours: [(days: String, hours: String)] {
        guard !weekdayDescriptions.isEmpty else { return [] }
        
        var tempGroup: [String: [String]] = [:]
        var dayOrder: [String] = []
        
        for desc in weekdayDescriptions {
            // Pisahkan antara "Hari" dan "Jam Buka" berdasarkan tanda titik dua pertama ":"
            let components = desc.components(separatedBy: ": ")
            if components.count >= 2 {
                let day = components[0].trimmingCharacters(in: .whitespaces)
                let hours = components[1].trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: " – ", with: " - ") // Rapikan strip bawaan Google
                    .replacingOccurrences(of: " ", with: " ")     // Bersihkan whitespace aneh
                
                if tempGroup[hours] == nil {
                    tempGroup[hours] = []
                }
                tempGroup[hours]?.append(day)
                
                if !dayOrder.contains(hours) {
                    dayOrder.append(hours)
                }
            }
        }
        
        // Format hasilnya menjadi "Monday - Friday" dsb.
        return dayOrder.compactMap { hours in
            guard let days = tempGroup[hours], !days.isEmpty else { return nil }
            
            if days.count == 7 {
                return (days: "Everyday", hours: hours)
            } else if days.count > 1 {
                return (days: "\(days.first!) - \(days.last!)", hours: hours)
            } else {
                return (days: days.first!, hours: hours)
            }
        }
    }
    
    func toMKMapItem() -> MKMapItem {
        return MKMapItem.fromRawData(
            latitude: self.latitude,
            longitude: self.longitude,
            name: self.name + " ::: " + self.imageUrl,
            address: self.formattedAddress.isEmpty ? self.shortFormattedAddress : self.formattedAddress
        )
    }
}
