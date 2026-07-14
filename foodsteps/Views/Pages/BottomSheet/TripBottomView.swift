//
//  TripBottomView.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 12/07/26.
//

import SwiftUI
import CoreData

struct TripBottomView: View {
    
    let culinaryPlace: CulinaryPlace
    
    @Binding var showDialog: Bool
    
    @State var showDialogCreate: Bool = false
    
    @StateObject private var viewModel = TripHistoryViewModel(context: dataController.container.viewContext)
    
    private let primaryColor = Color(hex: "4B08B5")
    private let borderColor = Color(hex: "#4B08B5")
    
    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Header
            ZStack {
                HStack {
                    Button {
                        showDialog = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                }
                Text("Add To Trip")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(primaryColor)
            }
            .padding(.top, 32)
            .padding(.bottom, 16)
            .padding(.horizontal, 20)
            
            if viewModel.trips.isEmpty {
                VStack(spacing: 0) {
                    Image("Mascot_5")
                        .resizable()
                        .frame(width: 258, height: 114)
                    
                    Text("No Trip Planned Yet...")
                        .font(.title2)
                        .bold()
                        .padding(.top, 12)
                        .padding(.bottom, 6)
                    
                    Text("Click “Create Plan” to add new trip")
                        .font(.subheadline)
                        .fontWeight(.regular)
                        .foregroundStyle(Color(hex: "#8E8E93"))
                }
                .frame(maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.getTripWithoutCulinaryPlaceItem(culinaryPlace: culinaryPlace)) {
                            trip in
                            BottomTripCard(
                                urls: viewModel.getMax4PlaceImageUrl(for: trip),
                                trip: trip,
                                onAddToTrip: { selectedTrip in
                                    // Tulis kode Anda di sini saat trip ditambahkan
                                    print("Trip dipilih: \(selectedTrip.name)")
                                    viewModel.addCulinaryPlaceToTrip(
                                        trip: selectedTrip,
                                        culinaryPlace: culinaryPlace
                                    )
                                    showDialog = false
                                    print("add \(culinaryPlace.name) to Trip with name \(trip.name) and id \(trip.id)")
                                }
                            )
                        }
                    }
                }
            }
            
            Button(action: {
                showDialogCreate = true
            }) {
                Text("Create Trip")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#FF8F14"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .ignoresSafeArea()
        .contentMargins(.horizontal, 20)
        .background(Color(.systemBackground))
        // Menampilkan sheet .medium untuk pencarian lokasi
        .sheet(isPresented: $showDialogCreate) {
            BottomCreateTripView(
                viewModel: viewModel,
                showDialog: $showDialogCreate
            )
                .presentationDetents([.height(520)]) // Membuka awal di .medium, bisa di-drag ke .large
                .presentationDragIndicator(.visible)
        }
    }
       
}

//#Preview {
//    TripBottomView()
//}
