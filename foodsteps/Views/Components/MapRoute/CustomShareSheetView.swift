import SwiftUI

struct CustomShareSheetView: View {
    let sharedImage: UIImage
    let distance: Double
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Bagikan Petualangan Anda")
                .font(.headline)
                .padding(.top)
            
            Image(uiImage: sharedImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 360)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.15), radius: 8)
                .padding(.horizontal)
            
            VStack(spacing: 4) {
                Text(String(format: "%.2f KM", distance))
                    .font(.title).bold()
                    .foregroundColor(Color(hex: "#4B08B5"))
                Text("Total Jarak Tempuh Berhasil Direkam")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            ShareLink(
                item: Image(uiImage: sharedImage),
                preview: SharePreview("Rute Perjalanan Saya", image: Image(uiImage: sharedImage))
            ) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Kirim Gambar Rute Kustom")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(Color(hex: "#4B08B5")).cornerRadius(25)
                .padding(.horizontal, 24)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
    }
}