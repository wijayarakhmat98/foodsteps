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

/// How the History segment's trips are ordered. Only relevant there —
/// Planned trips stay in their natural (most-recently-created-first) order.
private enum TripSortOption: String, CaseIterable, Identifiable {
    case date = "Date"
    case name = "Name"

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
    @State private var historySortOption: TripSortOption = .date

    /// Trips filtered to the active segment — "History" is anything the
    /// current user has already saved a result for (`hasCurrentUserCompleted`),
    /// "Planned" is everything else. History is additionally sorted per
    /// `historySortOption`, chosen from the sort menu that replaces the "+"
    /// button on that segment.
    private var filteredTrips: [Trip] {
        let segmentTrips = viewModel.trips.filter { trip in
            switch selectedSegment {
            case .planned:
                return !trip.hasCurrentUserCompleted
            case .history:
                return trip.hasCurrentUserCompleted
            }
        }

        guard selectedSegment == .history else { return segmentTrips }

        switch historySortOption {
        case .date:
            return segmentTrips.sorted {
                ($0.scheduledStart ?? $0.wrappedCreatedAt) > ($1.scheduledStart ?? $1.wrappedCreatedAt)
            }
        case .name:
            return segmentTrips.sorted {
                ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending
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

                    if selectedSegment == .planned {
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
                    } else {
                        historySortMenu
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

    // MARK: - History sort menu

    /// Replaces the "+" button when the History segment is active — trips
    /// there are all already completed, so "add a trip" doesn't apply, but
    /// choosing how they're ordered does.
    private var historySortMenu: some View {
        Menu {
            Picker("Sort by", selection: $historySortOption) {
                ForEach(TripSortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundStyle(.white)
                .font(.title2)
                .fontWeight(.semibold)
                .frame(width: 44, height: 44)
                .glassEffect(in: Circle())
        }
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
