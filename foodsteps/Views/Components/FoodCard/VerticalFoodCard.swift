//
//  HorizontalFoodCard.swift
//  strava-like
//
//  Created by Nazwa Sapta Pradana on 06/07/26.
//

import SwiftUI

struct VerticalFoodCard: View {
    
    var culinaryPlace: CulinaryPlace;
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            ZStack(alignment: .topTrailing) {
                // Image placeholder
                //                RoundedRectangle(cornerRadius: 5)
                //                    .fill(.gray)
                //                    .frame(height: 110)
                RemoteImageView(
                    url: culinaryPlace.imageUrl,
                    cornerRadius: 16
                )
                .frame(maxWidth: .infinity)
                
                HStack() {
                    Spacer()
                        .frame(width: 8)
                    Text("Trending")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(hex: "#FF8F14"))
                        )
                    
                    Spacer()
                    
//                    Image(systemName: "heart")
//                        .font(.system(size: 20))
//                        .fontWeight(.bold)
//                        .foregroundStyle(Color(hex: "#FF8F14"))
//                        .padding(10)
                    
                }
                .padding(.top, 10)
            }
            
            Text(culinaryPlace.name.limitToWords(7))
                .font(.headline)
                .padding(.horizontal, 16)
            
            HStack(spacing: 4) {
                Text("BSD")
                    .font(.caption)
                
                Text(".")
                    .font(.caption)
                
                Text(culinaryPlace.filteredType)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            
            // Bottom row (star)
            HStack (alignment: .center, spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color(hex: "#FF8F14"))
                    .font(.system(size: 12))
                Text((culinaryPlace.rating), format: .number.precision(.fractionLength(1)))
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(.horizontal, 16)
            Divider()
                .background(Color.gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            Text((culinaryPlace.reviews.first?.comment ?? "").limitToWords(15))
                .padding(.horizontal, 16)
                .font(.subheadline)
                .padding(.bottom, 24)
            
            Spacer()
        }
//        .padding()
        .background(
        RoundedRectangle(cornerRadius: 12)
            .fill(.white)
            .shadow(
                color: .gray.opacity(0.3), // Diperhalus opasitasnya biar lebih clean
                radius: 4,
                x: 0,
                y: 2
            )
        )
        .onTapGesture {
            AppRoute.push(.placeDetail(culinaryPlace: culinaryPlace))
        }
//        .frame(height: 180)
    }
}

//#Preview {
//    VerticalFoodCard()
//}
