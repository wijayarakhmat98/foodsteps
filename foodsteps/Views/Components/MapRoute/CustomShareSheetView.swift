//
//  CustomShareSheetView.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 12/07/26.
//


import SwiftUI

struct CustomShareSheetView: View {
    let sharedImage: UIImage
    let distance: Double
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Header (Xmark Kiri, Teks Center Sempurna)
            HStack(alignment: .center) {
                // Tombol dismiss di kiri
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body)
                        .bold()
                        .foregroundColor(.gray)
                        .frame(width: 44, height: 44) // Area tap yang nyaman
                }
                
                Spacer()
                
                Text("Let’s Share Your Trip!")
                    .font(.headline)
                    .foregroundColor(Color(hex: "#4B08B5"))
                
                Spacer()
                
                // Invisible placeholder di kanan agar teks center-nya simetris dan mutlak
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24) // Disesuaikan agar pas di atas sheet tanpa menabrak notch/capsule sheet
            
            // MARK: - Preview Gambar
            Image(uiImage: sharedImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 420) // Sedikit dikurangi agar proporsional di layar medium sheet
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.15), radius: 8)
                .padding(.horizontal)
            
            // MARK: - Info Jarak Rute
            VStack(spacing: 4) {
                Text(String(format: "%.2f KM", distance))
                    .font(.title).bold()
                    .foregroundColor(Color(hex: "#4B08B5"))
                Text("Total Distance Traveled Successfully Recorded")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // MARK: - Tombol Share
            ShareLink(
                item: Image(uiImage: sharedImage),
                preview: SharePreview("Travel Route", image: Image(uiImage: sharedImage))
            ) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Send Image Route")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(Color(hex: "#4B08B5"))
                .cornerRadius(25)
                .padding(.horizontal, 24)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
    }
}

