//
//  DetailPlaceView.swift
//  strava-like
//
//  Created by Nazwa Sapta Pradana on 08/07/26.
//

import SwiftUI
import MapKit

struct DetailPlaceView: View {
    var culinaryPlace: CulinaryPlace
    
    private var placeCoordinate = CLLocationCoordinate2D(
        latitude: -6.175392,
        longitude: 106.827153
    )
    
    // 3. Atur posisi kamera peta agar fokus ke koordinat tersebut
    @State private var position: MapCameraPosition
    
    @State private var showBottomSheet = false
    
    init(culinaryPlace: CulinaryPlace) {
        self.culinaryPlace = culinaryPlace
        
        self.placeCoordinate = CLLocationCoordinate2D(
            latitude: culinaryPlace.latitude, longitude: culinaryPlace.longitude
        )
        // Mengatur posisi awal kamera peta (jarak pandang sekitar 500 meter)
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: culinaryPlace.latitude, longitude: culinaryPlace.longitude),
            latitudinalMeters: 200,
            longitudinalMeters: 200
        )))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                ZStack(alignment: .topLeading) {
                    RemoteImageView(
                        url: culinaryPlace.imageUrl,
                        height: 300,
                        cornerRadius: 0
                    )
                    .padding(.horizontal, -4)
                    
//                    Button(action: {
//                        print("Button Tapped!")
//                    }) {
//                        Image(systemName: "chevron.left")
//                            .font(.system(size: 18, weight: .bold))
//                            .padding(12)
//                            .background(.white)
//                            .foregroundStyle(.black)
//                            .clipShape(Circle())
//                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
//                    }
//                    .padding(.top, 60)
//                    .padding(.leading, 16)
                }
                
                HStack(alignment: .top,) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(culinaryPlace.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 20) {
                            Text(culinaryPlace.filteredType)
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
                        Text(culinaryPlace.formattedAddress)
                            .font(.footnote)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .background(Color(hex: "#FFF5EB"))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding(.horizontal, 16)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Opening Hours")
                        .font(.subheadline)
                        .bold()
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    
                    if culinaryPlace.groupedOpeningHours.isEmpty {
                        // Jaga-jaga kalau datanya kosong
                        HStack {
                            Text("Information not available")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    } else {
                        // Melakukan perulangan otomatis berdasarkan grup hari & jam buka
                        ForEach(culinaryPlace.groupedOpeningHours, id: \.days) { group in
                            HStack {
                                Text(group.days)
                                    .font(.subheadline)
                                    .bold()
                                
                                Spacer()
                                
                                Text(group.hours)
                                    .font(.subheadline)
                                    .bold()
                            }
                            .padding(.horizontal, 16)
                            // Kasih padding bottom cuma di item paling terakhir grup
                            .padding(.bottom, group.days == culinaryPlace.groupedOpeningHours.last?.days ? 16 : 0)
                        }
                    }
                }
                .background(Color(hex: "#FFF5EB"))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding(.horizontal, 16)
                
                Button(action: {
                   showBottomSheet = true
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
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showBottomSheet) {
            TripBottomView(culinaryPlace: culinaryPlace, showDialog: $showBottomSheet)
                .presentationDetents([.height(520)])
                .presentationDragIndicator(.visible)
        }
    }
}

//#Preview {
//    DetailPlaceView()
//}
