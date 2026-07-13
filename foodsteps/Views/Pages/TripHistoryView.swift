//
//  TripView.swift
//  strava-like
//
//  Created by Nazwa Sapta Pradana on 07/07/26.
//

import SwiftUI
import CoreData

/// Which subset of trips is showing: still being planned, or already
/// completed by the current user.
private enum TripSegment: String, CaseIterable, Identifiable {
    case planned = "Planned"
    case history = "History"

    var id: String { rawValue }
}

struct TripHistoryView: View {
    
    @StateObject private var viewModel = TripHistoryViewModel(context: dataController.container.viewContext)
    
    let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    
    @State private var showBottomSheet = false
    @State private var selectedSegment: TripSegment = .planned

    /// Trips filtered to the active segment — "History" is anything the
    /// current user has already saved a result for (`hasCurrentUserCompleted`),
    /// "Planned" is everything else.
    private var filteredTrips: [Trip] {
        viewModel.trips.filter { trip in
            switch selectedSegment {
            case .planned:
                return !trip.hasCurrentUserCompleted
            case .history:
                return trip.hasCurrentUserCompleted
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 18) {
                HStack(alignment: .center) {
                    Text("Trip History")
                        .font(.largeTitle)
                        .bold()

                    Spacer()

                    Button {
                        showBottomSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(width: 44, height: 44)
                            .glassEffect(in: Circle())
                    }
                }

                segmentedControl
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
            
            if filteredTrips.isEmpty {
                VStack(spacing: 0) {
                    Image("Mascot_3")
                        .resizable()
                        .frame(width: 390, height: 281)
                    
                    Text(emptyTitle)
                        .font(.title2)
                        .bold()
                        .padding(.top, 36)
                        .padding(.bottom, 6)
                    
                    Text(emptySubtitle)
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

                        ForEach(filteredTrips) { trip in
                            
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

    private var emptyTitle: String {
        selectedSegment == .planned ? "No Trip Planned Yet..." : "No Completed Trips Yet..."
    }

    private var emptySubtitle: String {
        selectedSegment == .planned ? "Click “+” to create new plan" : "Trips you finish will show up here"
    }

    // MARK: - Segmented control

    private var segmentedControl: some View {
        HStack(spacing: 4) {
            ForEach(TripSegment.allCases) { segment in
                let isSelected = segment == selectedSegment
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedSegment = segment
                    }
                } label: {
                    Text(segment.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isSelected ? Color(hex: "#4B08B5") : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(isSelected ? Color.white : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(Capsule().fill(Color.white.opacity(0.22)))
    }
}

#Preview {
    TripHistoryView()
}
