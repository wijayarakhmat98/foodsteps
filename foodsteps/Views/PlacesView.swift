import SwiftUI
import MapKit
import CoreData

/// The "Places" tab: who's joined, the trip schedule, the meeting point,
/// and the candidate stops (with voting). Owns everything needed to add or
/// edit those, including presenting the schedule and stop/meeting-point
/// search sheets.
struct PlacesView: View {
    @ObservedObject var trip: Trip
    var routePlanner: RoutePlanner
    var searchService: LocationSearchService

    /// All stops on the trip (including the meeting point) — used for
    /// duplicate checks when adding a new place.
    var stops: [Stop]
    /// The actual places to visit, i.e. `stops` minus the meeting point.
    var placeStops: [Stop]
    var meetingPointDisplayName: String?

    @Binding var currentParticipantName: String
    @Binding var showShareView: Bool

    @Environment(\.managedObjectContext) private var moc

    // Participant entity no longer exists in the schema. Track names locally
    // (in-memory only, not persisted) until a replacement is designed.
    @State private var participantNames: [String] = ["You"]
    @State private var isAddingParticipant = false
    @State private var newParticipantName = ""

    @State private var isEditingSchedule = false
    @State private var draftStart = Date()
    @State private var draftEnd = Date().addingTimeInterval(4 * 3600)

    @State private var isEditingMeetingPoint = false

    @State private var isShowingAddSheet = false
    @State private var isSearching = false
    @State private var isShowingDuplicatePlaceAlert = false
    @State private var duplicatePlaceName = ""

    /// The meeting-point Stop (type == .meetingPoint), if one has been set.
    /// Derived here (rather than threaded in) since it's only needed by the
    /// meeting-point sheet flow, which lives entirely in this view.
    private var meetingPointStop: Stop? {
        stops.first { $0.type == StopType.meetingPoint.rawValue }
    }

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

    var body: some View {
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
        .sheet(isPresented: $isShowingAddSheet) { addStopSheet }
        .sheet(isPresented: $isEditingSchedule) { scheduleSheet }
        .sheet(isPresented: $isEditingMeetingPoint) { meetingPointSheet }
        .alert("Add Person", isPresented: $isAddingParticipant) {
            TextField("Name", text: $newParticipantName)
            Button("Cancel", role: .cancel) { newParticipantName = "" }
            Button("Add") { addParticipant() }
        } message: {
            Text("They'll be tagged on the stops they add.")
        }
        .alert("Already Added", isPresented: $isShowingDuplicatePlaceAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(duplicatePlaceName) is already a stop on this trip.")
        }
    }

    // MARK: - People joined

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
        Text(String(name.prefix(1)).uppercased())
            .font(.caption.bold())
            .foregroundColor(.white)
            .frame(width: 36, height: 36)
            .background(Circle().fill(Color.gray))
            .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
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

    // MARK: - Schedule

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
        SchedulePickerSheetView(
            draftStart: $draftStart,
            draftEnd: $draftEnd,
            onCancel: { isEditingSchedule = false },
            onSave: {
                trip.scheduledStart = draftStart
                trip.scheduledEnd = draftEnd
                try? moc.save()
                isEditingSchedule = false
            }
        )
    }

    // MARK: - Meeting point

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
        StopMeetingPointSheetView(
            kind: .meetingPoint,
            searchService: searchService,
            onSelect: { completion in setMeetingPoint(from: completion) },
            onDone: { isEditingMeetingPoint = false }
        )
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

                // Reset existing route — RouteView refits/recomputes itself
                // (onAppear + onChange of orderedStops.count) the next time
                // it's shown, so no direct map-fitting call is needed here.
                routePlanner.orderedStops.removeAll()
                routePlanner.legs.removeAll()
            }
        }
    }

    // MARK: - Stops list

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

    /// Trip+Helper's `wrappedStops` sorts ascending by hearts (lowest
    /// first); reversing that gives highest-voted first without adding any
    /// sorting logic of our own here.
    private var topVotedStops: [Stop] {
        placeStops.reversed()
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
                ForEach(topVotedStops, id: \.objectID) { stop in
                    PlaceRow(stop: stop, trip: trip)
                }
                .onDelete { offsets in
                    for index in offsets {
                        moc.delete(topVotedStops[index])
                    }
                    try? moc.save()
                    routePlanner.orderedStops = []
                    routePlanner.legs = []
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Place row
    // A dedicated View (rather than a helper function returning `some View`)
    // so `stop` can be held as @ObservedObject. NSManagedObject conforms to
    // ObservableObject, so this subscribes this row specifically to changes
    // on that Stop's `votes` relationship — including votes that arrive from
    // other participants via CloudKit sync and get merged into this context.
    // Without this, only `trip`'s own attributes were observed (see the
    // Core Data Propagation note above), so a vote cast by someone else on
    // a shared trip would land in the store but never repaint the heart.
    private struct PlaceRow: View {
        @ObservedObject var stop: Stop
        let trip: Trip
        @Environment(\.managedObjectContext) private var moc

        var body: some View {
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
                    toggleVote()
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: hasVoted ? "heart.fill" : "heart")
                            .foregroundColor(hasVoted ? .red : .secondary)
                        Text("\(stop.hearts)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 6)
        }

        /// Vote model has no hasVoted/toggleVote convenience — those were on
        /// the old Stop entity and don't exist in the current schema/helpers.
        /// Voting is expressed purely through the `votes` relationship (one
        /// Vote per authorRecordName) plus Vote.insert(into:stop:) from
        /// Vote+Helper.
        private var hasVoted: Bool {
            guard let recordName = dataController.currentUserRecordName else { return false }
            let votes = stop.votes as? Set<Vote> ?? []
            return votes.contains { $0.authorRecordName == recordName }
        }

        private func toggleVote() {
            guard let recordName = dataController.currentUserRecordName else { return }
            let votes = stop.votes as? Set<Vote> ?? []
            if let existingVote = votes.first(where: { $0.authorRecordName == recordName }) {
                moc.delete(existingVote)
            } else {
                Vote.insert(into: moc, stop: stop)
            }
            try? moc.save()
            // Voting changes `hearts`, which the places list is ordered by
            // (via `trip.wrappedStops` → `placeStops`), not something that
            // lives on `stop` itself. Refreshing just `stop` wouldn't
            // re-trigger that re-order, so refresh `trip` (merging in the
            // save) to make sure the row order updates too.
            moc.refresh(trip, mergeChanges: true)
        }
    }

    // MARK: - Add place

    private var addStopSheet: some View {
        StopMeetingPointSheetView(
            kind: .stop,
            searchService: searchService,
            isSearching: isSearching,
            isAlreadyAdded: isAlreadyAdded,
            onSelect: { completion in addStop(from: completion) },
            onDone: { isShowingAddSheet = false }
        )
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
}
