import SwiftUI
import MapKit
import CoreData

private enum HubTab: String, CaseIterable {
    case places = "Places"
    case route = "Route"
}

/// The trip "hub": a tab switcher between the Places and Route views, plus
/// the shared navigation chrome (title, rename menu, Start Trip button) and
/// state that spans both tabs (the route planner, live location, trip
/// finished flow, sharing). The tab contents themselves live in
/// `PlacesView` and `RouteView`.
struct TripInputView: View {
    @ObservedObject var trip: Trip

    @Environment(\.managedObjectContext) private var moc

    // MARK: - Core Data Propagation
    // Replaced @FetchRequest with computed properties straight from the ObservedObject.
    // Trip+Helper already exposes wrappedStops (all stops, sorted by createdAt),
    // so we don't need to redo that lookup/sort here.
    private var stops: [Stop] {
        trip.wrappedStops
    }

    /// The meeting-point Stop (type == .meetingPoint), if one has been set.
    /// Trip no longer exposes meetingPointStop/meetingPointName directly —
    /// only wrappedStops and a meetingPointCoordinate (CLLocation) — so the
    /// display name is derived here from the Stop's Location.
    private var meetingPointStop: Stop? {
        stops.first { $0.type == StopType.meetingPoint.rawValue }
    }

    private var meetingPointDisplayName: String? {
        meetingPointStop?.location?.name
    }

    /// The actual places to visit — everything in `stops` except the
    /// meeting point. The meeting point is where the group starts from,
    /// not a destination, so it's tracked separately (`meetingPointStop`)
    /// and shouldn't show up in the places list or be routed to as a stop.
    private var placeStops: [Stop] {
        stops.filter { $0.type != StopType.meetingPoint.rawValue }
    }

    @State private var locationManager = LocationManager()
    @State private var routePlanner = RoutePlanner()
    @State private var searchService = LocationSearchService()

    @State private var selectedTab: HubTab = .places

    @State private var currentParticipantName = "You"

    @State private var isRenamingTrip = false
    @State private var renameDraft = ""

    @State private var isPreparingRoute = false

    @State private var navigateToNavigation = false

    @State private var showShareView = false

    var body: some View {
        VStack(spacing: 0) {
            tabSwitcher

            switch selectedTab {
            case .places:
                PlacesView(
                    trip: trip,
                    routePlanner: routePlanner,
                    searchService: searchService,
                    stops: stops,
                    placeStops: placeStops,
                    meetingPointDisplayName: meetingPointDisplayName,
                    currentParticipantName: $currentParticipantName,
                    showShareView: $showShareView
                )
            case .route:
                RouteView(
                    trip: trip,
                    routePlanner: routePlanner,
                    locationManager: locationManager,
                    placeStops: placeStops,
                    meetingPointDisplayName: meetingPointDisplayName,
                    isPreparingRoute: $isPreparingRoute,
                    computeRoute: computeRoute
                )
            }

            startTripButton
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(selectedTab == .places ? (trip.name ?? "Trip") : "Route")
                    .font(.headline)
            }
            if selectedTab == .places {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Rename Trip") {
                            renameDraft = trip.name ?? ""
                            isRenamingTrip = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .navigationDestination(isPresented: $navigateToNavigation) {
            ActiveRouteView(
                trip: trip,
                routePlanner: routePlanner,
                locationManager: locationManager
            )
        }
        .fullScreenCover(isPresented: Binding(
            get: { routePlanner.isFinished },
            set: { routePlanner.isFinished = $0 }
        )) {
            TripFinishedView(
                trip: trip,
                visitedStops: finishedStopEntities,
                routePlanner: routePlanner,
                participantName: currentParticipantName,
                onSaveResult: saveTripResult
            )
        }
        .alert("Rename Trip", isPresented: $isRenamingTrip) {
            TextField("Trip name", text: $renameDraft)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let trimmed = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                trip.name = trimmed
                try? moc.save()
            }
        }
        .onAppear {
            locationManager.requestPermissionAndStart()
            restoreSavedOrderIfNeeded()
        }
        .sheet(isPresented: $showShareView) {
            ShareView(share: trip.share!)
                .onDisappear {
                    moc.refresh(trip, mergeChanges: true)
                }
        }
    }

    // MARK: - Tab switcher
    private var tabSwitcher: some View {
        HStack(spacing: 4) {
            ForEach(HubTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? Color(uiColor: .systemBackground) : Color.clear)
                        .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .black.opacity(selectedTab == tab ? 0.08 : 0), radius: 3, y: 1)
                }
            }
        }
        .padding(4)
        .background(Color(uiColor: .systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: - Shared "Start Trip" button
    private var startTripButton: some View {
        Button(action: startTrip) {
            if isPreparingRoute {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Finding the best route...")
                }
                .frame(maxWidth: .infinity)
            } else {
                Text("Start Trip")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
        }
        .font(.headline)
        .foregroundColor(.white)
        .padding(.vertical, 16)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding()
        .background(.bar)
        .disabled(placeStops.isEmpty || isPreparingRoute)
    }

    private func startTrip() {
        guard !placeStops.isEmpty else { return }
        if routePlanner.orderedStops.isEmpty {
            computeRoute { navigateToNavigation = true }
        } else {
            navigateToNavigation = true
        }
    }

    private func computeRoute(completion: @escaping () -> Void) {
        isPreparingRoute = true

        // Stop is identifiable and toMapItem() comes from Location+Helper,
        // so the planner can just work with the CoreData Stop entities
        // directly — no more separate RouteStop translation needed.
        routePlanner.stops = placeStops.filter { $0.location != nil }

        let start = trip.meetingPointCoordinate?.coordinate ?? locationManager.currentLocation ?? CLLocationCoordinate2D(latitude: -6.3000, longitude: 106.4000)

        Task {
            await routePlanner.optimizeAndCalculate(from: start, moc: moc)
            isPreparingRoute = false
            completion()
        }
    }

    /// Restores a previously generated/customized route order from the
    /// saved `sortOrder` on each Stop, so reopening a trip doesn't lose a
    /// manual reorder or force a re-generate. Only kicks in when the
    /// planner is still empty (fresh view) and an order was actually saved
    /// before (`hasSavedStopOrder`) — otherwise the "Generate Route" flow
    /// behaves exactly as before.
    private func restoreSavedOrderIfNeeded() {
        guard routePlanner.orderedStops.isEmpty, trip.hasSavedStopOrder else { return }

        let restored = trip.wrappedPlaceStopsBySortOrder.filter { $0.location != nil }
        guard !restored.isEmpty else { return }

        routePlanner.stops = restored
        routePlanner.orderedStops = restored
        routePlanner.startingCoordinate = trip.meetingPointCoordinate?.coordinate ?? locationManager.currentLocation

        Task {
            await routePlanner.recalculateLegsForCurrentOrder()
        }
    }

    // MARK: - Trip finished

    private var finishedStopEntities: [Stop] {
        routePlanner.orderedStops
    }

    private func saveTripResult() {
        // Stop.visitedAt/departedAt and Trip.finishedAt no longer exist in
        // the schema. Visit timing stays ephemeral in RoutePlanner for now
        // (TripFinishedView already reads it from there).
        routePlanner.isFinished = false
        navigateToNavigation = false
    }
}
