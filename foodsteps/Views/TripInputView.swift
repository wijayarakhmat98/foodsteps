import SwiftUI
import MapKit
import CoreData

private enum HubTab: String, CaseIterable {
    case places = "Places"
    case route = "Route"
}

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
    
    // Participant entity no longer exists in the schema. Track names locally
    // (in-memory only, not persisted) until a replacement is designed.
    @State private var participantNames: [String] = ["You"]

    /// Real participants, pulled from the CKShare via the existing
    /// NSManagedObject+Helper `userNames` helper. Falls back to the
    /// locally-tracked names (merged in) so unshared trips, and anyone
    /// added manually via "Add Person", still show up.
    private var displayedParticipantNames: [String] {
        let synced = trip.userNames
        guard !synced.isEmpty else { return participantNames }
        var merged = synced
        for name in participantNames where !merged.contains(name) {
            merged.append(name)
        }
        return merged
    }

    @State private var locationManager = LocationManager()
    @State private var routePlanner = RoutePlanner()
    @State private var searchService = LocationSearchService()
    @FocusState private var isSearchFocused: Bool

    @State private var selectedTab: HubTab = .places

    @State private var currentParticipantName = "You"
    @State private var isAddingParticipant = false
    @State private var newParticipantName = ""

    @State private var isRenamingTrip = false
    @State private var renameDraft = ""

    @State private var isEditingSchedule = false
    @State private var draftStart = Date()
    @State private var draftEnd = Date().addingTimeInterval(4 * 3600)

    @State private var isEditingMeetingPoint = false

    @State private var isShowingAddSheet = false
    @State private var isSearching = false
    @State private var isShowingDuplicatePlaceAlert = false
    @State private var duplicatePlaceName = ""

    @State private var isPreparingRoute = false
    @State private var isUpdatingOrder = false
    @State private var reorderToken = UUID()
    @State private var mapPosition: MapCameraPosition = .automatic

    @State private var navigateToNavigation = false
    
    @State private var showShareView = false

    var body: some View {
        VStack(spacing: 0) {
            tabSwitcher

            switch selectedTab {
            case .places:
                placesTab
            case .route:
                routeTab
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
        .sheet(isPresented: $isShowingAddSheet) { addPlaceSheet }
        .sheet(isPresented: $isEditingSchedule) { scheduleSheet }
        .sheet(isPresented: $isEditingMeetingPoint) { meetingPointSheet }
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
        .alert("Add Person", isPresented: $isAddingParticipant) {
            TextField("Name", text: $newParticipantName)
            Button("Cancel", role: .cancel) { newParticipantName = "" }
            Button("Add") { addParticipant() }
        } message: {
            Text("They'll be tagged on the stops they add.")
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
        .alert("Already Added", isPresented: $isShowingDuplicatePlaceAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(duplicatePlaceName) is already a stop on this trip.")
        }
        .onAppear {
            locationManager.requestPermissionAndStart()
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .route, routePlanner.orderedStops.isEmpty, !placeStops.isEmpty {
                computeRoute {}
            }
        }
        .onChange(of: routePlanner.orderedStops.count) { _, _ in
            fitMapPreview()
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

    // MARK: - Places tab
    private var placesTab: some View {
        VStack(spacing: 0) {
            peopleJoinedSection
            Divider()
            scheduleRow
            Divider()
            meetingPointRow
            Divider()
            sortHeaderRow
            placesList
        }
    }

    private var peopleJoinedSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: -10) {
                ForEach(displayedParticipantNames, id: \.self) { name in
                    avatarCircle(for: name)
                }
                if trip.share == nil {
                    ShareLink(item: trip, preview: SharePreview("Share thiss Trip")) {
                        Image(systemName: "plus")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color(uiColor: .systemGray5)))
                            .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                    }
                } else {
                    Button {
                        showShareView.toggle()
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color(uiColor: .systemGray5)))
                            .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                    }
                }
            }
            Text("\(displayedParticipantNames.count) \(displayedParticipantNames.count == 1 ? "Person" : "People") Joined")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
    }

    private func avatarCircle(for name: String) -> some View {
        let isSelected = name == currentParticipantName
        return Button {
            currentParticipantName = name
        } label: {
            Text(String(name.prefix(1)).uppercased())
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(isSelected ? Color.blue : Color.gray))
                .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
        }
    }

    private var addPersonButton: some View {
        Button {
            isAddingParticipant = true
        } label: {
            Image(systemName: "plus")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color(uiColor: .systemGray5)))
                .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
        }
    }

    private func addParticipant() {
        let trimmed = newParticipantName.trimmingCharacters(in: .whitespacesAndNewlines)
        newParticipantName = ""
        guard !trimmed.isEmpty, !participantNames.contains(trimmed) else { return }
        participantNames.append(trimmed)
        currentParticipantName = trimmed
    }

    private var scheduleRow: some View {
        HStack {
            if let start = trip.scheduledStart, let end = trip.scheduledEnd {
                Text(scheduleLabel(start: start, end: end))
                    .font(.subheadline)
            } else {
                Text("Set date & time")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Edit") {
                draftStart = trip.scheduledStart ?? Date()
                draftEnd = trip.scheduledEnd ?? Date().addingTimeInterval(4 * 3600)
                isEditingSchedule = true
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func scheduleLabel(start: Date, end: Date) -> String {
        let day = DateFormatter()
        day.dateFormat = "EEE, MMM d"
        let time = DateFormatter()
        time.dateFormat = "HH:mm"
        return "\(day.string(from: start)) · \(time.string(from: start))-\(time.string(from: end))"
    }

    private var scheduleSheet: some View {
        NavigationStack {
            Form {
                DatePicker("Starts", selection: $draftStart)
                DatePicker("Ends", selection: $draftEnd)
            }
            .navigationTitle("Trip Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isEditingSchedule = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        trip.scheduledStart = draftStart
                        trip.scheduledEnd = draftEnd
                        try? moc.save()
                        isEditingSchedule = false
                    }
                }
            }
        }
    }

    private var meetingPointRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Meeting point")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(meetingPointDisplayName ?? "Not set")
                    .font(.subheadline)
            }
            Spacer()
            Button("Edit") {
                isEditingMeetingPoint = true
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var meetingPointSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search a meeting point...", text: $searchService.searchQuery)
                    if !searchService.searchQuery.isEmpty {
                        Button {
                            searchService.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(.regularMaterial)

                List(searchService.completions, id: \.self) { completion in
                    Button {
                        setMeetingPoint(from: completion)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(completion.title).font(.headline)
                            Text(completion.subtitle).font(.subheadline).foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Meeting Point")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isEditingMeetingPoint = false }
                }
            }
            .onAppear { searchService.configure(for: .anyPlace) }
        }
    }

    private func setMeetingPoint(from completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)

        Task {
            let search = MKLocalSearch(request: request)
            if let response = try? await search.start(),
               let item = response.mapItems.first {

                // meetingPointAppleMapsId isn't stored yet — Location doesn't
                // have a field for it in the current schema.
                if let existingStop = meetingPointStop {
                    let location = existingStop.location ?? Location.insert(into: moc, mapItem: item)
                    location.name = item.name
                    location.address = item.placemark.title
                    location.latitude = item.placemark.coordinate.latitude
                    location.longitude = item.placemark.coordinate.longitude
                    existingStop.location = location
                } else {
                    let location = Location.insert(into: moc, mapItem: item)
                    Stop.insert(into: moc, trip: trip, type: .meetingPoint, location: location)
                }

                try? moc.save()

                searchService.searchQuery = ""
                isEditingMeetingPoint = false

                // Reset existing route
                routePlanner.orderedStops.removeAll()
                routePlanner.legs.removeAll()
                fitMapPreview()

                // Recalculate immediately if there are stops
                if !placeStops.isEmpty {
                    computeRoute { }
                }
            }
        }
    }

    private var sortHeaderRow: some View {
        HStack {
            Text("Sorted by hearts")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Button {
                isShowingAddSheet = true
            } label: {
                Label("Add", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var sortedStops: [Stop] {
        placeStops.sorted { $0.hearts > $1.hearts }
    }

    @ViewBuilder
    private var placesList: some View {
        if placeStops.isEmpty {
            ContentUnavailableView(
                "No Stops Yet",
                systemImage: "mappin.and.ellipse",
                description: Text("Tap Add to search for places your group wants to visit.")
            )
            .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(sortedStops, id: \.objectID) { stop in
                    placeRow(stop: stop)
                }
                .onDelete { offsets in
                    for index in offsets {
                        moc.delete(sortedStops[index])
                    }
                    try? moc.save()
                    routePlanner.orderedStops = []
                    routePlanner.legs = []
                }
            }
            .listStyle(.plain)
        }
    }

    private func placeRow(stop: Stop) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(stop.location?.name ?? "Unknown")
                    .font(.headline)
                Text(stop.location?.address ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text(stop.wrappedAuthorName)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(uiColor: .systemGray6))
                    .clipShape(Capsule())
            }
            Spacer()
            Button {
                toggleVote(for: stop)
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: hasVoted(on: stop) ? "heart.fill" : "heart")
                        .foregroundColor(hasVoted(on: stop) ? .red : .secondary)
                    Text("\(stop.hearts)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }

    /// Vote model has no hasVoted/toggleVote convenience — those were on the
    /// old Stop entity and don't exist in the current schema/helpers. Voting
    /// is expressed purely through the `votes` relationship (one Vote per
    /// authorRecordName) plus Vote.insert(into:stop:) from Vote+Helper.
    private func hasVoted(on stop: Stop) -> Bool {
        guard let recordName = dataController.currentUserRecordName else { return false }
        let votes = stop.votes as? Set<Vote> ?? []
        return votes.contains { $0.authorRecordName == recordName }
    }

    private func toggleVote(for stop: Stop) {
        guard let recordName = dataController.currentUserRecordName else { return }
        let votes = stop.votes as? Set<Vote> ?? []
        if let existingVote = votes.first(where: { $0.authorRecordName == recordName }) {
            moc.delete(existingVote)
        } else {
            Vote.insert(into: moc, stop: stop)
        }
        try? moc.save()
    }

    private var addPlaceSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search cafes & restaurants...", text: $searchService.searchQuery)
                        .focused($isSearchFocused)
                    if isSearching {
                        ProgressView()
                    } else if !searchService.searchQuery.isEmpty {
                        Button {
                            searchService.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(.regularMaterial)

                List(searchService.completions, id: \.self) { completion in
                    Button {
                        addStop(from: completion)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(completion.title).font(.headline)
                                Text(completion.subtitle).font(.subheadline).foregroundColor(.secondary)
                            }
                            Spacer()
                            if isAlreadyAdded(completion) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .foregroundColor(isAlreadyAdded(completion) ? .secondary : .primary)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Add a Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isShowingAddSheet = false }
                }
            }
            .onAppear {
                searchService.configure(for: .foodOnly)
                isSearchFocused = true
            }
        }
    }

    private func isAlreadyAdded(_ completion: MKLocalSearchCompletion) -> Bool {
        stops.contains { existing in
            (existing.location?.name ?? "").caseInsensitiveCompare(completion.title) == .orderedSame
        }
    }

    private func addStop(from completion: MKLocalSearchCompletion) {
        isSearching = true
        let request = MKLocalSearch.Request(completion: completion)
        Task {
            let search = MKLocalSearch(request: request)
            defer { isSearching = false }
            if let response = try? await search.start(), let item = response.mapItems.first {

                // appleMapsId-based dedup dropped — Location has no field for
                // it in the current schema. Falls back to name + distance.
                let candidateCoordinate = item.placemark.coordinate

                let isDuplicate = stops.contains { existing in
                    guard let existingLocationEntity = existing.location else { return false }
                    let sameName = (existingLocationEntity.name ?? "").caseInsensitiveCompare(item.name ?? "") == .orderedSame
                    let existingLocation = CLLocation(latitude: existingLocationEntity.latitude, longitude: existingLocationEntity.longitude)
                    let candidateLocation = CLLocation(latitude: candidateCoordinate.latitude, longitude: candidateCoordinate.longitude)
                    return sameName && existingLocation.distance(from: candidateLocation) < 25
                }

                searchService.searchQuery = ""
                isShowingAddSheet = false

                guard !isDuplicate else {
                    duplicatePlaceName = item.name ?? "This place"
                    isShowingDuplicatePlaceAlert = true
                    return
                }

                let location = Location.insert(into: moc, mapItem: item)
                Stop.insert(into: moc, trip: trip, type: .stop, location: location)
                try? moc.save()

                routePlanner.orderedStops = []
                routePlanner.legs = []
            }
        }
    }

    // MARK: - Route tab
    @ViewBuilder
    private var routeTab: some View {
        if placeStops.isEmpty {
            ContentUnavailableView(
                "Nothing to Route Yet",
                systemImage: "map",
                description: Text("Add stops on the Places tab first.")
            )
            .frame(maxHeight: .infinity)
        } else if isPreparingRoute && routePlanner.orderedStops.isEmpty {
            VStack(spacing: 12) {
                ProgressView()
                Text("Finding the best route...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                routeMapPreview.frame(height: 220)
                routeStatsRow
                Divider()
                routeOrderList
            }
        }
    }

    private var routeMapPreview: some View {
        Map(position: $mapPosition, interactionModes: [.pan, .zoom]) {
            UserAnnotation()

            if let start = trip.meetingPointCoordinate?.coordinate ?? locationManager.currentLocation {
                Annotation(meetingPointDisplayName ?? "Start", coordinate: start) {
                    ZStack {
                        Circle().fill(Color.black).frame(width: 28, height: 28)
                        Image(systemName: "mappin")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                    .shadow(radius: 2)
                }
            }

            ForEach(Array(routePlanner.orderedStops.enumerated()), id: \.offset) { index, stop in
                Annotation(stop.name, coordinate: stop.mapItem.placemark.coordinate) {
                    ZStack {
                        Circle().fill(Color.black).frame(width: 24, height: 24)
                        Text("\(index + 1)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                    }
                    .shadow(radius: 2)
                }
            }

            ForEach(Array(routePlanner.legs.enumerated()), id: \.offset) { _, leg in
                MapPolyline(leg)
                    .stroke(.black.opacity(0.6), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }
        }
        .mapStyle(.standard)
    }

    private var routeStatsRow: some View {
        HStack(spacing: 6) {
            Text("\(routePlanner.orderedStops.count) stops")
            Text("·")
            Text(formattedTotalDistance())
            Text("·")
            Text("Distance order")
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formattedTotalDistance() -> String {
        let meters = Double(routePlanner.totalDistance)
        return meters >= 1000 ? String(format: "~%.1f km", meters / 1000.0) : String(format: "~%.0f m", meters)
    }

    private var routeOrderList: some View {
        List {
            Section {
                routeStartRow.moveDisabled(true)

                ForEach(Array(routePlanner.orderedStops.enumerated()), id: \.element.id) { index, stop in
                    routeStopRow(index: index, stop: stop)
                }
                .onMove(perform: moveStops)
            } header: {
                Text("Suggested order (by distance)")
            }
        }
        .listStyle(.plain)
        .contentMargins(.top, 0, for: .scrollContent)
    }

    private var routeStartRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.black).frame(width: 28, height: 28)
                Image(systemName: "mappin").font(.caption.bold()).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(meetingPointDisplayName ?? "Your Location")
                    .font(.subheadline.weight(.semibold))
                Text("Start")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func routeStopRow(index: Int, stop: RouteStop) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.black).frame(width: 28, height: 28)
                Text("\(index + 1)").font(.caption.bold()).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(stop.name)
                    .font(.subheadline.weight(.semibold))
                Text(distanceLabel(forLegAt: index))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func distanceLabel(forLegAt index: Int) -> String {
        if !isUpdatingOrder, index < routePlanner.legs.count {
            let dist = Double(routePlanner.legs[index].distance)
            return dist >= 1000 ? String(format: "%.1f km", dist / 1000.0) : String(format: "%.0f m", dist)
        }

        let orderedStops = routePlanner.orderedStops
        guard index < orderedStops.count else { return "" }

        let fromCoordinate: CLLocationCoordinate2D
        if index == 0 {
            guard let start = trip.meetingPointCoordinate?.coordinate ?? locationManager.currentLocation else { return "" }
            fromCoordinate = start
        } else {
            fromCoordinate = orderedStops[index - 1].mapItem.placemark.coordinate
        }

        let from = CLLocation(latitude: fromCoordinate.latitude, longitude: fromCoordinate.longitude)
        let to = CLLocation(
            latitude: orderedStops[index].mapItem.placemark.coordinate.latitude,
            longitude: orderedStops[index].mapItem.placemark.coordinate.longitude
        )
        let dist = Double(from.distance(from: to))
        return dist >= 1000 ? String(format: "%.1f km", dist / 1000.0) : String(format: "%.0f m", dist)
    }

    private func moveStops(from source: IndexSet, to destination: Int) {
        routePlanner.orderedStops.move(fromOffsets: source, toOffset: destination)

        let token = UUID()
        reorderToken = token
        isUpdatingOrder = true

        Task {
            await routePlanner.recalculateLegsForCurrentOrder()
            guard token == reorderToken else { return }
            isUpdatingOrder = false
        }
    }

    private func fitMapPreview() {
        var coordinates = routePlanner.orderedStops.map { $0.mapItem.placemark.coordinate }
        if let start = trip.meetingPointCoordinate?.coordinate ?? locationManager.currentLocation {
            coordinates.append(start)
        }
        guard let first = coordinates.first else { return }

        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }

        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.6, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.6, 0.01)
        )
        mapPosition = .region(MKCoordinateRegion(center: center, span: span))
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
            
            // Map the CoreData Stop entities directly into RouteStops inline
            routePlanner.stops = placeStops.compactMap { stop in
                guard let location = stop.location, let id = stop.id else { return nil }
                return RouteStop(id: id.uuidString, mapItem: location.toMapItem())
            }
            
            let start = trip.meetingPointCoordinate?.coordinate ?? locationManager.currentLocation ?? CLLocationCoordinate2D(latitude: -6.3000, longitude: 106.4000)
            
            Task {
                await routePlanner.optimizeAndCalculate(from: start)
                isPreparingRoute = false
                completion()
            }
        }

    // MARK: - Trip finished

    private var finishedStopEntities: [Stop] {
        routePlanner.orderedStops.compactMap { routeStop in
            stops.first { $0.id?.uuidString == routeStop.id }
        }
    }

    private func saveTripResult() {
        // Stop.visitedAt/departedAt and Trip.finishedAt no longer exist in
        // the schema. Visit timing stays ephemeral in RoutePlanner for now
        // (TripFinishedView already reads it from there).
        routePlanner.isFinished = false
        navigateToNavigation = false
    }
}
