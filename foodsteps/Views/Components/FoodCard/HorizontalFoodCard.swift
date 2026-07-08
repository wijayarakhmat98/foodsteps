//
//  VerticalFoodCard.swift
//  strava-like
//
//  Created by Nazwa Sapta Pradana on 03/07/26.
//

import SwiftUI

struct HorizontalFoodCard: View {

    var url: String?
    var title: String?
    var location: String?
    var type: String?
    var rating: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            ZStack(alignment: .topTrailing) {
                RemoteImageView(
                    url: url ?? "https://lh3.googleusercontent.com/gps-cs-s/APNQkAE1JSdDBFs2lBCjg_Hvx8dcvMtYX5opaYy4ErQIx22QjdZt1C7h0JkENr5-EnWuwab-OP9mzUnB9WC1tylzTz7PvlKYXAy9bPBZtUynGKh5xNIOw6U9PgLwk8jh5be_y3gCx0QkSg=w122-h92-k-no",
                    cornerRadius: 16
                )
                .frame(height: 120) // 👈 penting: kunci tinggi image

//                Image(systemName: "heart")
//                    .font(.system(size: 20))
//                    .foregroundStyle(Color(hex: "#FF8F14"))
//                    .padding(10)
            }

            Text(title ?? "Naked Papa")
                .font(.headline)
                .lineLimit(2)

            HStack(spacing: 4) {
                Text("BSD")
                    .font(.caption)

                Text(".")
                    .font(.caption)

                Text(type ?? "Cafe and Dessert")
                    .font(.caption)
                    .lineLimit(1)
            }

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color(hex: "#FF8F14"))
                    .font(.system(size: 12))

                Text((rating ?? 4.7), format: .number.precision(.fractionLength(1)))
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
    }
}

#Preview {
    HorizontalFoodCard()
}
