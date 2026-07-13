//
//  BottomTripCard.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 12/07/26.
//

import SwiftUI

struct BottomTripCard: View {
    var urls: [String]?
    let trip: Trip;
    
    let onAddToTrip: (Trip) -> Void
    
    // Grid 2x2: Kiri dan Kanan dengan spacing yang diperkecil agar pas untuk ukuran kecil
    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        // 1. Ubah alignment HStack menjadi .center agar gambar dan teks sejajar tengah secara vertikal
        HStack(alignment: .center, spacing: 0) {
            
            // Kontainer Grid Gambar (Tetap berjumlah 4 kotak)
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<4, id: \.self) { index in
                    if let safeUrls = urls, index < safeUrls.count {
                        // JIKA ADA GAMBAR
                        Color.clear
                            .aspectRatio(1, contentMode: .fill)
                            .overlay(
                                RemoteImageView(
                                    url: safeUrls[index],
                                    cornerRadius: 0
                                )
                                .scaledToFill()
                            )
                            .clipped()
                    } else {
                        // JIKA KOSONG / PLACEHOLDER
                        ZStack {
                            Color(.systemGray5)
                            
                            Image(systemName: "photo")
                                .font(.system(size: 10)) // Diperkecil agar muat di kotak kecil
                                .foregroundColor(.gray)
                        }
                        .aspectRatio(1, contentMode: .fill)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6)) // Sudut grid disesuaikan ukurannya
            // 2. Tentukan lebar grid saja, biarkan tinggi otomatis menjadi persegi (aspectRatio 1)
            // Ukuran 48-50 biasanya sangat pas dengan tinggi 2 baris teks di kanan
            .frame(width: 48)
            .aspectRatio(1, contentMode: .fit)
            
            // Nama Trip (Kanan)
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name ?? "Dummy Trip Name")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#4B08B5"))
                    .lineLimit(1)
                
                Text("\(trip.createdAt?.formatted(.dateTime.day().month(.abbreviated)) ?? "2 Aug") | Created by \(trip.authorRecordName)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .padding(.leading, 12)
            
            Spacer()
            
            Image(systemName: "plus")
                .padding(.trailing, 12)
                .font(.title)
                .foregroundColor(Color(hex: "#4B08B5"))
                .onTapGesture {
                    onAddToTrip(trip)
                }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 11)
        .background(Color(hex: "#EDE6F8"))
        .cornerRadius(16)
    }
}

//#Preview {
//    BottomTripCard()
//}
