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
    @Environment(\.dismiss) private var dismiss

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

    /// Candidate stops the owner has marked as `selected` — the only ones
    /// that actually feed the route (Route tab, Start Trip, navigation).
    /// `placeStops` itself stays the full candidate list, since PlacesView
    /// still needs to show everyone's suggestions regardless of selection.
    private var selectedPlaceStops: [Stop] {
        placeStops.filter { $0.selected }
    }

    @State private var locationManager = LocationManager()
    @State private var routePlanner = RoutePlanner()
    @State private var searchService = LocationSearchService()

    @State private var selectedTab: HubTab = .places

    @State private var currentParticipantName = "You"

    @State private var isRenamingTrip = false
    @State private var renameDraft = ""

    @State private var isPreparingRoute = false

    @State private var showStartConfirmation = false

    @State private var navigateToNavigation = false

    @State private var showShareView = false

    /// Set right before closing the "trip finished" fullScreenCover when the
    /// trip was just saved. Read in that cover's `onDismiss`, once the cover
    /// has actually finished closing, to then pop `TripInputView` itself off
    /// `TripView`'s stack. Calling `dismiss()` in the same moment as closing
    /// the cover doesn't reliably work — `TripInputView` is still busy
    /// presenting a modal at that instant, so the pop request gets dropped
    /// and you land back on `TripInputView` instead of `TripView`.
    @State private var dismissAfterFinishedCoverCloses = false

    var body: some View {
        VStack(spacing: 0) {
            TripHeaderView(
                title: trip.name ?? "Trip",
                tabs: HubTab.allCases.map { ($0, $0.rawValue) },
                selectedTab: $selectedTab,
                onBack: { dismiss() }
            )

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
                    placeStops: selectedPlaceStops,
                    meetingPointDisplayName: meetingPointDisplayName,
                    isPreparingRoute: $isPreparingRoute,
                    computeRoute: computeRoute
                )
            }

            startTripButton
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
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
        ), onDismiss: {
            if dismissAfterFinishedCoverCloses {
                dismissAfterFinishedCoverCloses = false
                dismiss()
            }
        }) {
            NavigationStack {
                TripFinishedView(
                    trip: trip,
                    visitedStops: finishedStopEntities,
                    routePlanner: routePlanner,
                    participantName: currentParticipantName,
                    onSaveResult: saveTripResult
                )
            }
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
        .confirmationDialogOverlay(
            isPresented: $showStartConfirmation,
            title: "Start Trip?",
            message: "You're about to head out to your selected places. Make sure everyone's ready before you begin.",
            confirmTitle: "Start Trip"
        ) {
            beginTrip()
        }
        .onAppear {
            locationManager.requestPermissionAndStart()
            syncRoutePlannerOrderIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: moc)) { notification in
            handleContextObjectsChanged(notification)
        }
        .onChange(of: showShareView) { _, isShowing in
            guard isShowing else { return }
            showShareView = false
            TripSharePresenter.present(trip: trip) {
                moc.refresh(trip, mergeChanges: true)
            }
        }
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
        .background(selectedPlaceStops.isEmpty || isPreparingRoute ? Color.brandOrange.opacity(0.5) : Color.brandOrange)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding()
        .background(.bar)
        .disabled(selectedPlaceStops.isEmpty || isPreparingRoute)
    }

    private func startTrip() {
        guard !selectedPlaceStops.isEmpty else { return }
        showStartConfirmation = true
    }

    private func beginTrip() {
        guard !selectedPlaceStops.isEmpty else { return }
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
        routePlanner.stops = selectedPlaceStops.filter { $0.location != nil }

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
        if !trip.hasCurrentUserCompleted {
            Complete.insert(into: moc, trip: trip)
            try? moc.save()
        }

        // Stop.visitedAt/departedAt and Trip.finishedAt no longer exist in
        // the schema. Visit timing stays ephemeral in RoutePlanner for now
        // (TripFinishedView already reads it from there).
        // Trip is finished and saved — there's nothing left to do on the
        // Places/Route hub, so leave it entirely and land back on TripView.
        // (Reopening this trip later now goes straight to TripFinishedView
        // via TripView's own navigationDestination check.) The actual pop
        // happens in the fullScreenCover's onDismiss, once it's confirmed
        // closed — see dismissAfterFinishedCoverCloses above.
        dismissAfterFinishedCoverCloses = true
        routePlanner.isFinished = false
        navigateToNavigation = false
    }
}
