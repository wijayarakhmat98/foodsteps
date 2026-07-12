struct VerticalFoodCardSkeleton: View {
    var body: some View {
        HStack(spacing: 12) { // Biasanya vertical card berbentuk list baris kesamping
            // Placeholder Image Kotak/Rounded
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(width: 80, height: 80)
                .shimmerLoading()
            
            VStack(alignment: .leading, spacing: 6) {
                // Placeholder Title
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 150, height: 16)
                    .shimmerLoading()
                
                // Placeholder Type / Kategori
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 80, height: 12)
                    .shimmerLoading()
                
                // Placeholder Comment / Address
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 12)
                    .shimmerLoading()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 1)
        )
        .padding(.horizontal)
    }
}