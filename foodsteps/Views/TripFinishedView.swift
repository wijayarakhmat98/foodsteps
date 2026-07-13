import SwiftUI
import MapKit
import CoreData

/// Entry point for reopening a trip this user has *already* saved a result
/// for. Pushed straight from `TripView` (see its `navigationDestination`),
/// entirely bypassing `TripInputView`'s Places/Route hub — there's nothing
/// left to plan, so there's no reason to route through it first.
///
/// Rebuilds the same "saved result" state `TripInputView` used to assemble
/// on `onAppear` (visited stops restored from the persisted `sortOrder`,
/// a fresh `RoutePlanner` just for display), but its back button pops this
/// view off `TripView`'s navigation stack instead of dismissing a sheet.
struct SavedTripFinishedView: View {
    @ObservedObject var trip: Trip
    @Environment(\.dismiss) private var dismiss
    @State private var routePlanner = RoutePlanner()

    /// The visited stops for the saved-result screen, restored from the
    /// persisted `sortOrder` (falls back to the unsorted place stops if no
    /// order was ever saved).
    private var visitedStops: [Stop] {
        let ordered = trip.wrappedPlaceStopsBySortOrder
        guard !ordered.isEmpty else {
            return trip.wrappedStops.filter { $0.type != StopType.meetingPoint.rawValue }
        }
        return ordered
    }

    var body: some View {
        TripFinishedView(
            trip: trip,
            visitedStops: visitedStops,
            routePlanner: routePlanner,
            participantName: "You",
            onSaveResult: { dismiss() }
        )
        .onAppear {
            routePlanner.orderedStops = visitedStops
        }
    }
}

struct TripFinishedView: View {
    @ObservedObject var trip: Trip
    let visitedStops: [Stop]
    let routePlanner: RoutePlanner
    let participantName: String
    let onSaveResult: () -> Void

    @Environment(\.managedObjectContext) private var moc
    @Environment(\.dismiss) private var dismiss
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var newPlacesCount: Int = 0
    @State private var showDeleteConfirmation = false
    @State private var shareCardImage: UIImage?
    @State private var showShareCard = false

    var body: some View {
        GeometryReader { globalGeometry in
            let topSafeArea = globalGeometry.safeAreaInsets.top

            ScrollView {
                VStack(spacing: 0) {
                    // Header area
                    ZStack(alignment: .top) {
                        // Map stays in the background
                        mapHeader
                            .frame(height: 260)

                        // Purple card overlays the top of the map
                        Color.brandPurple
                            .frame(height: 180)
                            .clipShape(
                                UnevenRoundedRectangle(
                                    bottomLeadingRadius: 40,
                                    bottomTrailingRadius: 40
                                )
                            )
                            .ignoresSafeArea(edges: .top)

                        headerButtons
                            .padding(.horizontal, 16)
                            .padding(.top, topSafeArea + 8)
                    }

                    // Keep all existing content BELOW the map
                    VStack(alignment: .leading, spacing: 18) {
                        tripSummaryRow

                        Text(trip.name ?? "Trip")
                            .font(.title2.bold())

                        if newPlacesCount > 0 {
                            newPlacesBadge
                        }

                        Text("Places Visited")
                            .font(.headline)
                            .padding(.top, 4)

                        placesTimeline
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if !trip.hasCurrentUserCompleted {
                saveResultButton
            }
        }
        .confirmationDialogOverlay(
            isPresented: $showDeleteConfirmation,
            title: "Delete Trip?",
            message: "This will permanently delete this trip and cannot be undone.",
            confirmTitle: "Delete"
        ) {
            deleteTrip()
        }
        .onAppear {
            fitMap()
            computeNewPlacesCount()
        }
        .sheet(isPresented: $showShareCard) {
            if let shareCardImage {
                CustomShareSheetView(sharedImage: shareCardImage, distance: routePlanner.totalDistance / 1000)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Header buttons

    /// Back chevron (translucent circle) and "..." menu (solid circle) laid
    /// over the purple card — same treatment as `TripHeaderView`, with the
    /// menu holding Share and Delete instead of a trailing action closure.
    private var headerButtons: some View {
        HStack {
            Button(action: onSaveResult) {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.22)))
            }

            Spacer()

            Menu {
                Button(action: shareTrip) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.brandPurple)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white))
            }
        }
    }

    private func deleteTrip() {
        moc.delete(trip)
        try? moc.save()
        dismiss()
    }

    // MARK: - Header

    /// `Stop` no longer carries name/lat/long directly — those now live on
    /// its `Location` relationship. Stops without a Location (shouldn't
    /// normally happen for visited stops) are skipped on the map.
    private var visitedStopAnnotations: [(index: Int, name: String, coordinate: CLLocationCoordinate2D)] {
        visitedStops.enumerated().compactMap { index, stop in
            guard let location = stop.location else { return nil }
            return (index, location.name ?? "Stop", CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
        }
    }

    private var mapHeader: some View {
        Map(position: $mapPosition, interactionModes: [.pan, .zoom]) {
            ForEach(visitedStopAnnotations, id: \.index) { item in
                Annotation(item.name, coordinate: item.coordinate) {
                    ZStack {
                        Circle().fill(Color.orange).frame(width: 22, height: 22)
                        Text("\(item.index + 1)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                    }
                    .shadow(radius: 2)
                }
            }

            ForEach(Array(routePlanner.legs.enumerated()), id: \.offset) { _, leg in
                MapPolyline(leg)
                    .stroke(.orange, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }
        }
        .mapStyle(.standard)
    }

    private func shareTrip() {
        let card = ShareTripCardView(
            tripName: trip.name ?? "Trip",
            dateText: formattedTripDate(),
            participantName: participantName,
            distanceKm: routePlanner.totalDistance / 1000,
            placeCount: visitedStops.count,
            stopNames: visitedStops.prefix(6).compactMap { $0.location?.name }
        )

        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        renderer.isOpaque = false

        guard let image = renderer.uiImage else { return }
        shareCardImage = image
        showShareCard = true
    }

    // MARK: - Summary

    private var tripSummaryRow: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.blue)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(participantName.prefix(1)).uppercased())
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(participantName)
                    .font(.subheadline.weight(.semibold))
                Text(formattedTripDate())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private var newPlacesBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .foregroundColor(.orange)
            Text("\(newPlacesCount) New \(newPlacesCount == 1 ? "place" : "places") discovered!")
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Timeline

    private var placesTimeline: some View {
        VStack(spacing: 0) {
            ForEach(Array(visitedStops.enumerated()), id: \.offset) { index, stop in
                StopTimelineRow(
                    index: index,
                    title: stop.location?.name ?? "Unknown place",
                    subtitle: subtitle(for: stop, at: index),
                    isLast: index == visitedStops.count - 1
                )
            }
        }
    }

    private func subtitle(for stop: Stop, at index: Int) -> String {
        var parts: [String] = []
        if let category = stop.location?.category {
            parts.append(category)
        }
        if let window = routePlanner.visitedWindow(at: index) {
            parts.append(timeRangeLabel(from: window.start, to: window.end))
        }
        return parts.joined(separator: " | ")
    }

    private func timeRangeLabel(from start: Date, to end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: start))-\(formatter.string(from: end))"
    }

    private func formattedTripDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        // Trip.finishedAt no longer exists in the schema; this timing is
        // ephemeral (RoutePlanner) until finish state is persisted again.
        let date = routePlanner.finishedAt ?? Date()
        return formatter.string(from: date)
    }

    // MARK: - Save

    @State private var isSaved = false

    private var saveResultButton: some View {
        Button {
            onSaveResult()
            isSaved = true
        } label: {
            HStack(spacing: 8) {
                if isSaved {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text(isSaved ? "Saved" : "Save Result")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSaved ? Color.green : Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isSaved)
        .padding()
        .background(.bar)
    }

    // MARK: - Helpers

    private func fitMap() {
        let coordinates = visitedStopAnnotations.map { $0.coordinate }
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

    /// Counts stops from this trip that are genuinely new discoveries.
    /// TODO: Trip.finishedAt and a place-identity field (like the old
    /// appleMapsId) no longer exist in the schema, so this can't be computed
    /// from Core Data yet. Stubbed to 0 until those are reintroduced.
    private func computeNewPlacesCount() {
        newPlacesCount = 0
    }
}
