//
//  MeetingPlaceCard.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 13/07/26.
//


import SwiftUI

struct MeetingPlaceCard: View {
    let number: Int
    let title: String
    let category: String
    let isLast: Bool?
    let image: UIImage?
    let onTapImage: () -> Void
    
    @State private var isWaving = false

    var body: some View {
        // Ambil data ukuran layar/kontainer secara dinamis
        GeometryReader { geometry in
            // Hitung variabel posisi berdasarkan lebar layar
            // Misal: kita ingin lingkaran berada di 10% dari lebar layar
            let timelineX = geometry.size.width * 0.12
            let circleSize: CGFloat = image == nil ? 44 : 55
            
            ZStack(alignment: .leading) {
                
                // --- 2. SEKTOR KONTEN INFORMASI (Kanan) ---
                VStack(alignment: .leading, spacing: 6) {
                    Text(title.components(separatedBy: " ::: ").first ?? "")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .lineLimit(1)

                    Text(category)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                .padding(.leading, 74)
                .padding(.trailing, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#F9F9FA"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.trailing, 16)
                
                // --- 1. SEKTOR LINI MASA (Dinamis Berdasarkan Variabel) ---
                ZStack {
                    // Garis Vertikal (Tanpa offset manual, otomatis di posisi timelineX)
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(hex: "#4B08B5"))
                            .frame(width: 3)
                            .opacity(number == 1 ? 0 : 1)
                        
                        Rectangle()
                            .fill(Color(hex: "#4B08B5"))
                            .frame(width: 3)
                            .opacity((isLast ?? false) ? 0 : 1)
                    }
                    
                    // Lingkaran & Badge Angka
                    ZStack(alignment: .topLeading) {
                        Group {
                            if let actualImage = image {
                                Image(uiImage: actualImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: circleSize, height: circleSize)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color(hex: "#4B08B5"), lineWidth: 3))
                                    .shadow(radius: 2)
                            } else {
                                ZStack {
                                    Circle()
                                        .stroke(Color(hex: "#4B08B5"), lineWidth: 2)
                                        .frame(width: 40, height: 40)
                                        .scaleEffect(isWaving ? 1.8 : 1.0)
                                        .opacity(isWaving ? 0.0 : 0.8)
                                    
                                    Circle()
                                        .fill(Color(.systemGray6))
                                        .frame(width: 40, height: 40)
                                        .overlay {
                                            Circle().stroke(Color(hex: "#4B08B5"), lineWidth: 3)
                                        }

                                    Image(systemName: "photo")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.gray)
                                }
                                .frame(width: circleSize, height: circleSize)
                                .onAppear {
                                    if image == nil {
                                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                                            isWaving = true
                                        }
                                    }
                                }
                            }
                        }
                        .onTapGesture { onTapImage() }
                        
                        // Badge Angka
                        Text("\(number)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 16, height: 16)
                            .background(
                                Circle()
                                    .fill(Color(hex: "#4B08B5"))
                                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
                            )
                            .offset(x: -2, y: -2)
                    }
                    .background(Circle().fill(.white))
                }
                // SEKARANG POSISI DIATUR OLEH VARIABEL DINAMIS LAYAR
                .frame(width: timelineX)
                .padding(.leading, 16)
            }
        }
        // Menentukan tinggi maksimum komponen secara fleksibel agar GeometryReader tidak merusak layout vertikal
        .frame(height: 85)
        .onChange(of: image) {
            if image != nil { isWaving = false }
        }
    }
}

#Preview {
    VStack {
        MeetingPlaceCard(
            number: 1,
            title: "Titik Temu Coffee - Blok M",
            category: "Coffee Shop",
            isLast: true,
//            image: UIImage(systemName: "square.and.arrow.up")
            image: nil,
            onTapImage: {
                print("Hello World")
            }
        )
    }
    .padding()
}
