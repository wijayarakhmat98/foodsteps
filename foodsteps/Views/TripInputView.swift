import SwiftUI
import MapKit
import CoreData
import Combine

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

    /// True once *this* user (identified by their CloudKit record name, same
    /// as every other `authorRecordName` in the schema) has saved a result
    /// for this trip. Each participant gets their own `Complete` row, so
    /// this is independent per-user — one person finishing/saving doesn't
    /// affect anyone else's view of the trip.
    private var hasCurrentUserCompleted: Bool {
        trip.wrappedCompletes.contains { $0.authorRecordName == dataController.currentUserRecordName }
    }

    /// Drives the "already finished" presentation of `TripFinishedView`
    /// when reopening a trip this user previously saved a result for. Kept
    /// separate from `routePlanner.isFinished` (which drives the "just
    /// finished navigating" flow) since this can trigger on a fresh launch
    /// where `routePlanner` never ran.
    @State private var showSavedResult = false
    @State private var savedResultRoutePlanner = RoutePlanner()

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
        // Reopening a trip this user already saved a result for should just
        // show that saved result, not the Places/Route hub with a "Start
        // Trip" button. Uses a separate RoutePlanner instance (pre-loaded
        // with the persisted stop order) since the live `routePlanner`
        // above never ran this session.
        .fullScreenCover(isPresented: $showSavedResult) {
            TripFinishedView(
                trip: trip,
                visitedStops: savedResultStopEntities,
                routePlanner: savedResultRoutePlanner,
                participantName: currentParticipantName,
                onSaveResult: { showSavedResult = false }
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
            syncRoutePlannerOrderIfNeeded()
            if hasCurrentUserCompleted {
                savedResultRoutePlanner.orderedStops = savedResultStopEntities
                showSavedResult = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: moc)) { notification in
            handleContextObjectsChanged(notification)
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

    /// Keeps this trip's data live across devices.
    ///
    /// `@ObservedObject var trip` only re-renders when Trip's *own*
    /// properties change. A collaborator's edit — a vote on a Stop, a
    /// changed `sortOrder` — mutates a related object, not Trip itself, so
    /// CloudKit merges it into our local store just fine but SwiftUI never
    /// hears about it (that's why quitting and reopening "fixed" it: that
    /// forces a fresh fetch). `PlacesView.toggleVote` already works around
    /// this for local vote taps; this does the same thing but for changes
    /// arriving from *any* source, including a remote CloudKit merge.
    ///
    /// IMPORTANT: this must never call any Core Data API that itself marks
    /// objects as changed/refreshed (e.g. `moc.refresh(_:mergeChanges:)`) —
    /// doing so posts another `NSManagedObjectContextObjectsDidChange`
    /// notification, which re-triggers this very handler. That doesn't blow
    /// the call stack (each pass returns before the next notification
    /// arrives, on the next run-loop turn via Core Data's own batching), so
    /// a same-frame reentrancy guard doesn't catch it — it just becomes an
    /// infinite loop spread across run-loop ticks, spawning a fresh legs
    /// recalculation `Task` each pass, that quietly balloons memory until
    /// iOS kills the app for excessive memory use. `objectWillChange.send()`
    /// notifies SwiftUI directly without touching Core Data's change
    /// tracking, so it can't feed back into this notification at all.
    private func handleContextObjectsChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }

        let changed: [NSManagedObject] = [
            userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? [],
            userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? [],
            userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? [],
            userInfo[NSRefreshedObjectsKey] as? Set<NSManagedObject> ?? [],
        ].flatMap { $0 }

        guard changed.contains(where: isRelevantToThisTrip) else { return }

        trip.objectWillChange.send()
        syncRoutePlannerOrderIfNeeded()
    }

    private func isRelevantToThisTrip(_ object: NSManagedObject) -> Bool {
        switch object {
        case let candidate as Trip:
            return candidate.objectID == trip.objectID
        case let stop as Stop:
            return stop.trip?.objectID == trip.objectID
        case let vote as Vote:
            return vote.stop?.trip?.objectID == trip.objectID
        case let location as Location:
            return location.stop?.trip?.objectID == trip.objectID
        default:
            return false
        }
    }

    /// Syncs `routePlanner.orderedStops` from the saved `sortOrder` on each
    /// Stop whenever it's out of date — on first appearance (restoring a
    /// previously generated/customized order instead of forcing a
    /// re-generate) and again whenever a remote change updates the order,
    /// e.g. a collaborator drags stops around on their own phone.
    private func syncRoutePlannerOrderIfNeeded() {
        guard !routePlanner.isNavigating, trip.hasSavedStopOrder else { return }

        let latestOrder = trip.wrappedPlaceStopsBySortOrder.filter { $0.location != nil }
        guard !latestOrder.isEmpty else { return }

        let currentIDs = routePlanner.orderedStops.map { $0.wrappedID }
        let latestIDs = latestOrder.map { $0.wrappedID }
        guard currentIDs != latestIDs else { return }

        routePlanner.stops = latestOrder
        routePlanner.orderedStops = latestOrder
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
        // Record that *this* user finished the trip. Each participant's
        // Complete is tagged with their own authorRecordName (see
        // Complete+Helper), so this is independent per-user — guard against
        // inserting a duplicate if they somehow land here twice.
        if !hasCurrentUserCompleted {
            Complete.insert(into: moc, trip: trip)
            try? moc.save()
        }

        // Stop.visitedAt/departedAt and Trip.finishedAt no longer exist in
        // the schema. Visit timing stays ephemeral in RoutePlanner for now
        // (TripFinishedView already reads it from there).
        routePlanner.isFinished = false
        navigateToNavigation = false
    }

    // MARK: - Reopening an already-saved trip

    /// The visited stops for the saved-result screen, restored from the
    /// persisted `sortOrder` (falls back to the unsorted place stops if no
    /// order was ever saved).
    private var savedResultStopEntities: [Stop] {
        let ordered = trip.wrappedPlaceStopsBySortOrder
        return ordered.isEmpty ? placeStops : ordered
    }
}
