//
//  SearchFoodCard.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 09/07/26.
//

import SwiftUI

struct SearchFoodCard: View {
    let culinaryPlace: CulinaryPlace
    
    // State untuk menampung teks jarak dari MapKit
    @State private var distanceString: String = "Loading..."
    
    // Koordinat dummy user yang kamu berikit (BSD)
    private let userLatitude = -6.302546057945934
    private let userLongitude = 106.6520469974770
    
    var body: some View {
        HStack(alignment: .center) {
            RemoteImageView(
                url: culinaryPlace.imageUrl,
                height: 70,
                cornerRadius: 16
            )
            .frame(width: 79)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(culinaryPlace.name.limitToWords(8))
                    .font(.headline)
                    .padding(.horizontal, 12)
                
                Text(culinaryPlace.filteredType)
                    .font(.caption)
                    .padding(.horizontal, 12)
                
                // Bottom row (star)
                HStack (alignment: .firstTextBaseline, spacing: 4) {
                    Text(distanceString)
                        .font(.caption)
                        .padding(.trailing, 12)
                    
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color(hex: "#FF8F14"))
                        .font(.system(size: 12))
                    Text((culinaryPlace.rating), format: .number.precision(.fractionLength(1)))
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 12)
            }
        }
        .onTapGesture {
            AppRoute.push(.placeDetail(culinaryPlace: culinaryPlace))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // 💡 HIT API MAPKIT BEGITU KARTU DI-RENDER DI LAYAR
        .onAppear {
            LocationHelper.calculateRouteDistance(
                userLat: userLatitude,
                userLng: userLongitude,
                placeLat: culinaryPlace.latitude,
                placeLng: culinaryPlace.longitude
            ) { distance in
                // Pastikan UI di-update di Main Thread
                DispatchQueue.main.async {
                    if let distance = distance {
                        self.distanceString = String(format: "%.1f KM", distance)
                    } else {
                        self.distanceString = "-- KM" // Jika rute tidak ditemukan
                    }
                }
            }
        }
    }
}

//#Preview {
//    SearchFoodCard()
//}
