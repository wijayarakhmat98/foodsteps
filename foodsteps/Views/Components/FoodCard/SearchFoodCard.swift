//
//  SearchFoodCard.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 09/07/26.
//

import SwiftUI

struct SearchFoodCard: View {
    var body: some View {
        HStack(alignment: .center) {
            RemoteImageView(
                url: "https://lh3.googleusercontent.com/gps-cs-s/APNQkAE1JSdDBFs2lBCjg_Hvx8dcvMtYX5opaYy4ErQIx22QjdZt1C7h0JkENr5-EnWuwab-OP9mzUnB9WC1tylzTz7PvlKYXAy9bPBZtUynGKh5xNIOw6U9PgLwk8jh5be_y3gCx0QkSg=w122-h92-k-no",
                height: 70,
                cornerRadius: 16
            )
            .frame(width: 79)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Naked Papa")
                    .font(.headline)
                    .padding(.horizontal, 12)
                
                Text("Cafe and Dessert")
                    .font(.caption)
                    .padding(.horizontal, 12)
                
                // Bottom row (star)
                HStack (alignment: .firstTextBaseline, spacing: 4) {
                    Text("3 KM")
                        .font(.caption)
                        .padding(.trailing, 12)
                    
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color(hex: "#FF8F14"))
                        .font(.system(size: 12))
                    Text((4.7), format: .number.precision(.fractionLength(1)))
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 12)
            }
        }
    }
}

#Preview {
    SearchFoodCard()
}
