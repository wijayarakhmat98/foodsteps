//
//  DetailPlaceView.swift
//  strava-like
//
//  Created by Nazwa Sapta Pradana on 08/07/26.
//

import SwiftUI
import MapKit

struct DetailPlaceView: View {
    let url: String? = nil
    
    private let placeCoordinate = CLLocationCoordinate2D(
        latitude: -6.175392,
        longitude: 106.827153
    )
    
    // 3. Atur posisi kamera peta agar fokus ke koordinat tersebut
    @State private var position: MapCameraPosition
    
    init() {
        // Mengatur posisi awal kamera peta (jarak pandang sekitar 500 meter)
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -6.175392, longitude: 106.827153),
            latitudinalMeters: 200,
            longitudinalMeters: 200
        )))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                ZStack(alignment: .topLeading) {
                    RemoteImageView(
                        url: url ?? "https://lh3.googleusercontent.com/gps-cs-s/APNQkAE1JSdDBFs2lBCjg_Hvx8dcvMtYX5opaYy4ErQIx22QjdZt1C7h0JkENr5-EnWuwab-OP9mzUnB9WC1tylzTz7PvlKYXAy9bPBZtUynGKh5xNIOw6U9PgLwk8jh5be_y3gCx0QkSg=w122-h92-k-no",
                        height: 300,
                        cornerRadius: 0
                    )
                    .padding(.horizontal, -4)
                    
                    Button(action: {
                        print("Button Tapped!")
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .padding(12)
                            .background(.white)
                            .foregroundStyle(.black)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                    .padding(.top, 60)
                    .padding(.leading, 16)
                }
                
                HStack(alignment: .top,) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Futago Ya")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 20) {
                            Text("Ramen Bar")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            HStack (alignment: .center, spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(Color(hex: "#FF8F14"))
                                    .font(.system(size: 12))
                                Text((4.7), format: .number.precision(.fractionLength(1)))
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        
                    }
                    
//                    Spacer()
//                    
//                    Image(systemName: "heart")
//                        .font(.system(size: 24))
//                        .fontWeight(.semibold)
//                        .foregroundStyle(Color(hex: "#FF8F14"))
//                        .padding(10)
                }
                .padding(.horizontal, 16)
                
                VStack() {
                    Map(position: $position) {
                        Marker("Lokasi Tempat", coordinate: placeCoordinate)
                            .tint(.red)
                    }
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(16)
                    
                    HStack(alignment: .top,) {
                        Image(systemName: "mappin")
                        Text("2, Jl. Sultan Hasanuddin Dalam No.24, RT.3/RW.1, Melawai, Kec. Kby. Baru, Kota Jakarta Selatan, Daerah Khusus Ibukota Jakarta 12160")
                            .font(.footnote)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .background(Color(hex: "#FFF5EB"))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding(.horizontal, 16)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Opening Hours")
                        .font(.subheadline)
                        .bold()
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    
                    HStack() {
                        Text("Monday - Friday")
                            .font(.subheadline)
                            .bold()
                        
                        Spacer()
                        
                        Text("8.00 AM - 10.00 PM")
                          .font(.subheadline)
                          .bold()
                    }
                    .padding(.horizontal, 16)
                    
                    HStack() {
                        Text("Saturday - Sunday")
                            .font(.subheadline)
                            .bold()
                        
                        Spacer()
                        
                        Text("8.00 AM - 10.00 PM")
                          .font(.subheadline)
                          .bold()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .background(Color(hex: "#FFF5EB"))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding(.horizontal, 16)
                
                Button(action: {
                    // Aksi Button A
                }) {
                    Text("Add To Trip")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#FF8F14"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                
            }
        }
        .ignoresSafeArea(edges: .top) // Gambar full menembus status bar atas
    }
}

#Preview {
    DetailPlaceView()
}
