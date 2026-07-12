//
//  TripView.swift
//  strava-like
//
//  Created by Nazwa Sapta Pradana on 07/07/26.
//

import SwiftUI
import CoreData

struct TripHistoryView: View {
    
    @StateObject private var viewModel = TripHistoryViewModel(context: dataController.container.viewContext)
    
    let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    
    @State private var showBottomSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("Trip History")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 36)
                
                Spacer()
                
                Image(systemName: "plus")
                    .foregroundStyle(.white)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 36)
                    .padding(.trailing, 10)
                    .onTapGesture {
                        showBottomSheet = true
                    }
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.white)
            .background(
                Color(hex: "#4B08B5")
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 40,
                            style: .continuous
                        )
                    )
            )
            
            if viewModel.trips.isEmpty {
                VStack(spacing: 0) {
                    Image("Mascot_3")
                        .resizable()
                        .frame(width: 390, height: 281)
                    
                    Text("No Trip Planned Yet...")
                        .font(.title2)
                        .bold()
                        .padding(.top, 36)
                        .padding(.bottom, 6)
                    
                    Text("Click “+” to create new plan")
                        .font(.subheadline)
                        .fontWeight(.regular)
                        .foregroundStyle(Color(hex: "#8E8E93"))
                }
                .frame(maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(
                        columns: columns,
                        alignment: .leading,
                        spacing: 20
                    ) {
                        
//                        let allUrls = restaurants.compactMap { $0["image_url"] as? String }

                        ForEach(viewModel.trips) { trip in
                            
                            TripHistoryCard(
                                urls: viewModel.getMax4PlaceImageUrl(for: trip),
//                                tripName: trip.name
                                trip: trip
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 180)
                }
                .padding(.horizontal, 0)
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showBottomSheet) {
            BottomCreateTripView(viewModel: viewModel, showDialog: $showBottomSheet)
                .presentationDetents([.height(520)])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    TripHistoryView()
}
