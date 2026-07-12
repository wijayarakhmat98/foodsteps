//
//  HorizontalFoodCardSkeleton.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 11/07/26.
//
import SwiftUI

struct HorizontalFoodCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Placeholder Image
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .frame(height: 120)
                .shimmerLoading()
            
            // Placeholder Title
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6))
                .frame(width: 120, height: 16)
                .shimmerLoading()
            
            // Placeholder Subtitle (BSD . Kategori)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6))
                .frame(width: 100, height: 12)
                .shimmerLoading()
            
            // Placeholder Rating
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 40, height: 14)
                    .shimmerLoading()
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 180) // Sama persis dengan ukuran aslinya
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
        )
        .padding(.vertical, 10)
    }
}
