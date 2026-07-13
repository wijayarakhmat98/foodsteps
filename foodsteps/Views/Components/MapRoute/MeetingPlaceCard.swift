import SwiftUI

struct MeetingPlaceCard: View {

    let number: Int
    let title: String
    let category: String
    let startTime: String
    let endTime: String

    var body: some View {
        HStack(spacing: 12) {

            // Number + Icon
            ZStack(alignment: .topLeading) {

                Circle()
                    .stroke(Color.purple, lineWidth: 3)
                    .frame(width: 44, height: 44)

                Image(systemName: "photo")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
                    .frame(width: 24, height: 24)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text("\(number)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(Color.purple)
                    .clipShape(Circle())
                    .offset(x: -6, y: -6)
            }

            VStack(alignment: .leading, spacing: 4) {

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.black)
                    .lineLimit(1)

                HStack(spacing: 4) {

                    Text(category)

                    Text("|")

                    Text(startTime)

                    Text("-")

                    Text(endTime)
                }
                .font(.subheadline)
                .foregroundStyle(.gray)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
}

#Preview {
    VStack {
        MeetingPlaceCard(
            number: 1,
            title: "Titik Temu Coffee - Blok M",
            category: "Coffee Shop",
            startTime: "09:15",
            endTime: "09:45"
        )
    }
    .padding()
    .background(Color(.systemGray6))
}