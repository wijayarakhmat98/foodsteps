//
//  TripHistoryCard.swift
//  strava-like
//
//  Created by Nazwa Sapta Pradana on 07/07/26.
//

import SwiftUI

struct TripHistoryCard: View {
    var urls: [String]?
    var tripName: String?
    
    let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6)
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            LazyVGrid(
                columns: columns,
                alignment: .leading,
                spacing: 6
            ) {
                if let safeUrls = urls {
                    ForEach(safeUrls.indices, id: \.self) { index in
                        // 1. Buat kotak transparan sebagai jangkar ukuran (1:1)
                        Color.clear
                            .aspectRatio(1, contentMode: .fill)
                            // 2. Tempelkan gambar di atas kotak transparan tersebut
                            .overlay(
                                RemoteImageView(
                                    url: urls![index] ?? "https://lh3.googleusercontent.com/gps-cs-s/APNQkAE1JSdDBFs2lBCjg_Hvx8dcvMtYX5opaYy4ErQIx22QjdZt1C7h0JkENr5-EnWuwab-OP9mzUnB9WC1tylzTz7PvlKYXAy9bPBZtUynGKh5xNIOw6U9PgLwk8jh5be_y3gCx0QkSg=w122-h92-k-no",
                                    cornerRadius: 0
                                )
                                // Pastikan gambarnya mengisi penuh ruang overlay
                                .scaledToFill()
                            )
                            // 3. Potong paksa semua yang meluber keluar dari batas kotak
                            .clipShape(RoundedRectangle(cornerRadius: 0))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.bottom, 8)
//            .padding(.horizontal, 16)
            
            Text(tripName ?? "Dummy Trip Name")
                .font(.headline)
                .fontWeight(.semibold)
//                .padding(.horizontal, 16)
        }
    }
}

#Preview {
    TripHistoryCard(urls: ["", "", "", ""])
}
