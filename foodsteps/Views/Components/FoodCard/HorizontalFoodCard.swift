//
//  VerticalFoodCard.swift
//  strava-like
//
//  Created by Nazwa Sapta Pradana on 03/07/26.
//

import SwiftUI

struct HorizontalFoodCard: View {

    var culinaryPlace: CulinaryPlace

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            ZStack(alignment: .topTrailing) {
                RemoteImageView(
                    url: culinaryPlace.imageUrl,
                    cornerRadius: 16
                )
                .frame(height: 120)
            }

            Text(culinaryPlace.name.limitToWords(7))
                .font(.headline)
                .lineLimit(2)

            HStack(spacing: 4) {
                Text("BSD")
                    .font(.caption)

                Text(".")
                    .font(.caption)

                Text(culinaryPlace.filteredType)
                    .font(.caption)
                    .lineLimit(1)
            }

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color(hex: "#FF8F14"))
                    .font(.system(size: 12))

                Text((culinaryPlace.rating), format: .number.precision(.fractionLength(1)))
                    .font(.system(size: 14, weight: .bold))
            }

            Spacer()
        }
        .padding()
        .frame(width: 180) // tetap fixed width
        .frame(maxHeight: .infinity, alignment: .top) // 👈 penting
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
        )
        .padding(.vertical, 10)
        .onTapGesture {
            AppRoute.push(.placeDetail(culinaryPlace: culinaryPlace))
        }
    }
}

//#Preview {
//    HorizontalFoodCard()
//}
