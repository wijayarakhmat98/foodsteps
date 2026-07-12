//
//  TripHistoryCard.swift
//  strava-like
//
//  Created by Nazwa Sapta Pradana on 07/07/26.
//

import SwiftUI

import SwiftUI

struct TripHistoryCard: View {
    var urls: [String]?
    var trip: Trip
    
    // Grid 2x2: Kiri dan Kanan
    let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Kontainer Grid Gambar (Tetap berjumlah 4 kotak)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    // Gunakan fungsi pengecekan aman, apakah index tersebut ada datanya di array urls
                    if let safeUrls = urls, index < safeUrls.count {
                        // JIKA ADA GAMBAR: Tampilkan RemoteImageView
                        Color.clear
                            .aspectRatio(1, contentMode: .fill)
                            .overlay(
                                RemoteImageView(
                                    url: safeUrls[index],
                                    cornerRadius: 0
                                )
                                .scaledToFill()
                            )
                            .clipped() // Mencegah gambar off-bounds keluar dari kotak grid
                    } else {
                        // JIKA KOSONG / PLACEHOLDER: Kotak abu-abu dengan ikon foto di tengah
                        ZStack {
                            Color(.systemGray5) // Warna background abu-abu bawaan iOS
                            
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                        .aspectRatio(1, contentMode: .fill)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12)) // Memotong sudut terluar dari susunan grid gambar
            .padding(.bottom, 10)
            
            // Nama Trip
            Text(trip.name ?? "Dummy Trip Name")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1) // Membatasi agar teks nama trip tidak merusak layout ke bawah
        }
        .onTapGesture {
            AppRoute.push(.tripDetail(trip: trip))
        }
    }
}

//#Preview {
//    TripHistoryCard(urls: [])
//}
