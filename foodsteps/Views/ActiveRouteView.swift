import SwiftUI
import MapKit
import CoreData

struct ActiveRouteView: View {

    @ObservedObject var trip: Trip
    var routePlanner: RoutePlanner
    var locationManager: LocationManager

    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var followUser = true
    @State private var showFinishConfirmation = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var moc

    // MARK: - Draggable sheet

    /// The sheet's resting height, updated once a drag ends.
    @State private var sheetHeight: CGFloat = 300
    @GestureState private var dragTranslation: CGFloat = 0
    
    @StateObject private var userLocationManager = UserLocationManager()

    private let minSheetHeight: CGFloat = 170
    private let handleAreaHeight: CGFloat = 28

    // MARK: - Meeting point
    // Trip no longer carries a meetingPointName, and meetingPointCoordinate
    // is a CLLocation (not CLLocationCoordinate2D), so we derive the display
    // name here from the meeting-point Stop's Location.
    private var meetingPointStop: Stop? {
        trip.wrappedStops.first { $0.type == StopType.meetingPoint.rawValue }
    }

    private var meetingPointName: String? {
        meetingPointStop?.location?.name
    }

    var body: some View {

        GeometryReader { geo in

            let maxSheetHeight = geo.size.height - 140
            let liveHeight = min(
                max(sheetHeight - dragTranslation, minSheetHeight),
                maxSheetHeight
            )

            ZStack(alignment: .top) {

                mapLayer
                    .ignoresSafeArea()

                VStack {

                    Spacer()

                    sheetView
                        .frame(height: liveHeight)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedCorner(radius: 24, corners: [.topLeft, .topRight])
                                .fill(Color(uiColor: .systemBackground))
                                .shadow(color: .black.opacity(0.15), radius: 12, y: -4)
                        )

                }
                .ignoresSafeArea(edges: .bottom)

            }

        }
        .ignoresSafeArea(edges: .top)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                statsPill
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .confirmationDialogOverlay(
            isPresented: $showFinishConfirmation,
            title: "Finish Trip?",
            message: "This process cannot be undone.",
            confirmTitle: "Finish Trip"
        ) {
            // Marks the trip as complete for the current user right away —
            // this is what makes it show up under the "History" segment in
            // TripHistoryView (see Trip.hasCurrentUserCompleted) — then
            // hands off to the map/share recap screen. Reopening the trip
            // later goes straight to the saved result instead of back into
            // the Places/Route hub (see AppRoute's tripDetail destination).
            userLocationManager.stopRecording()
            markTripComplete()
            AppRoute.replace(
                .mapRoute(
                    wayPoints: UserLocationManager.makeWaypoints(from: trip),
                    pathCoordinates: userLocationManager.livePathCoordinates,
                    trip: trip
                )
            )
        }
        .onAppear {

            if !routePlanner.isNavigating {
                routePlanner.startNavigation()
                userLocationManager.startRecording()
            }

            if let stop = routePlanner.currentNavigationStop {
                locationManager.monitorArrival(
                    at: stop.mapItem.placemark.coordinate,
                    identifier: stop.displayName
                )
            }

            updateCamera()

            locationManager.onLocationUpdate = { _ in
                DispatchQueue.main.async {
                    routePlanner.updateNavigation(using: locationManager)
                    updateCamera()
                }
            }

            locationManager.onRegionEntered = { _ in
                DispatchQueue.main.async {
                    routePlanner.updateNavigation(using: locationManager)
                    updateCamera()
                }
            }
        }
        .onDisappear {
            locationManager.onLocationUpdate = nil
            locationManager.onRegionEntered = nil
        }
        .onChange(of: routePlanner.currentLegIndex) { _, _ in
            updateCamera()
        }

    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $mapPosition) {
            
            UserAnnotation()
            
            // 🔴 LIVE TRACKING USER POLYLINE (Garis Biru Tracker)
            if !userLocationManager.livePathCoordinates.isEmpty {
                MapPolyline(coordinates: userLocationManager.livePathCoordinates)
                    .stroke(.blue.opacity(0.8), lineWidth: 6)
            }
            
            // RUTE TRIP PLANNER UTAMA (Garis Ungu Anda)
            if let route = routePlanner.currentNavigationLeg {
                MapPolyline(route)
                    .stroke(Color.brandPurple, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }
            
            // PIN MEETING POINT
            if let start = trip.meetingPointCoordinate {
                Annotation(meetingPointName ?? "Start", coordinate: start.coordinate) {
                    ZStack {
                        Circle().fill(Color.black).frame(width: 24, height: 24)
                        Image(systemName: "flag.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(radius: 2)
                }
            }
            
            // PIN DESTINASI-DESTINASI (Urutan Stop)
            ForEach(Array(routePlanner.orderedStops.enumerated()), id: \.offset) { index, stop in
                // Menggunakan properti baru displayNameOnly (yang menghilangkan info URL gambar)
                Annotation(stop.displayName, coordinate: stop.mapItem.placemark.coordinate) {
                    ZStack {
                        Circle().fill(Color.brandPurple).frame(width: 24, height: 24)
                        Text("\(index + 1)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                    }
                    .shadow(radius: 2)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
            MapUserLocationButton()
        }
    }
    
    private var distanceIndicatorPanel: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text("LIVE TRACKING")
                        .font(.caption2).bold().foregroundColor(.gray)
                    Text(String(format: "%.2f KM", userLocationManager.totalDistance))
                        .font(.title).bold().foregroundColor(.orange)
                }
                Spacer()
                if userLocationManager.isRecording {
                    HStack {
                        Circle()
                            .fill(userLocationManager.isPaused ? Color.yellow : Color.red)
                            .frame(width: 8, height: 8)
                        Text(userLocationManager.isPaused ? "PAUSED" : "REC")
                            .font(.caption).bold()
                            .foregroundColor(userLocationManager.isPaused ? .yellow : .red)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(14)
            .padding(.horizontal)
            .padding(.top, 10)
        }

    // MARK: - Header / status

    private var statsPill: some View {
        HStack(spacing: 4) {
            Text(formattedRemainingTime())
                .font(.subheadline.bold())
            Text("·")
            Text("\(remainingStopsCount()) stops")
                .font(.subheadline.bold())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.blue)
        .clipShape(Capsule())
    }

    private var statusBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: routePlanner.isPaused ? "pause.fill" : "figure.walk")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(routePlanner.isPaused ? "Trip Paused" : "Trip Ongoing")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(min(routePlanner.currentLegIndex, routePlanner.orderedStops.count)) of \(routePlanner.orderedStops.count) stops visited")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color.brandPurple, Color.brandPurple.opacity(0.85)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .shadow(color: Color.brandPurple.opacity(0.35), radius: 8, y: 4)
    }

    // MARK: - Sheet

    private var sheetView: some View {
        VStack(spacing: 0) {

            dragHandle
                .frame(height: handleAreaHeight)
                .contentShape(Rectangle())
                .gesture(sheetDragGesture)

            statusBanner
                .padding(.bottom, 12)
                .contentShape(Rectangle())
                .gesture(sheetDragGesture)

            stopsList

            actionButtons

        }
    }

    private var dragHandle: some View {
        Capsule()
            .fill(Color(uiColor: .systemGray4))
            .frame(width: 40, height: 5)
            .padding(.top, 8)
    }

    private var sheetDragGesture: some Gesture {
        DragGesture()
            .updating($dragTranslation) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                sheetHeight -= value.translation.height
            }
    }

    // MARK: - Stops list

    private var stopsList: some View {
        ScrollView {
            VStack(spacing: 0) {

                if let start = trip.meetingPointCoordinate {
                    StopTimelineRow(
                        index: -1,
                        title: meetingPointName ?? "Your Location",
                        subtitle: "Meeting Point | Start",
                        isLast: routePlanner.orderedStops.isEmpty,
                        placeholderSystemImage: "mappin.and.ellipse",
                        badgeSystemImage: "flag.fill"
                    )
                    .id(start.coordinate.latitude)
                }

                ForEach(Array(routePlanner.orderedStops.enumerated()), id: \.offset) { index, stop in
                    StopTimelineRow(
                        index: index,
                        title: stop.displayName,
                        subtitle: subtitle(for: stop, at: index),
                        isLast: index == routePlanner.orderedStops.count - 1,
                        isHighlighted: index == routePlanner.currentLegIndex
                    )
                }
            }
            .padding()
        }
    }

    private func subtitle(for stop: Stop, at index: Int) -> String {
        let category = categoryLabel(for: stop.mapItem.pointOfInterestCategory) ?? "Place"

        if index == routePlanner.currentLegIndex {
            return "\(category) | Ongoing"
        }

        if index < routePlanner.currentLegIndex {
            return "\(category) | Visited"
        }

        if index - 1 < routePlanner.legs.count, index >= 1 {
            let meters = Double(routePlanner.legs[index - 1].distance)
            let distance = meters >= 1000 ? String(format: "%.1f km", meters / 1000.0) : String(format: "%.0f m", meters)
            return "\(category) | \(distance)"
        }

        if index == 0, let firstLeg = routePlanner.legs.first {
            let meters = Double(firstLeg.distance)
            let distance = meters >= 1000 ? String(format: "%.1f km", meters / 1000.0) : String(format: "%.0f m", meters)
            return "\(category) | \(distance)"
        }

        return category
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: 12) {

            if routePlanner.isPaused {
                Button {
                    userLocationManager.resumeRecording()
                    routePlanner.resumeNavigation()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brandPurple)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else {
                Button {
                    userLocationManager.pauseRecording()
                    routePlanner.pauseNavigation()
                } label: {
                    Text("Pause")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            Button {
                showFinishConfirmation = true
            } label: {
                Text("Finish")
                    .font(.headline)
                    .foregroundColor(.brandPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.brandPurple, lineWidth: 1.5)
                    )
            }
            
//            Button {
//                userLocationManager.startRecording()
//            } label: {
//                Text("Start")
//                    .font(.headline)
//                    .foregroundColor(.brandPurple)
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 14)
//                    .background(
//                        RoundedRectangle(cornerRadius: 14)
//                            .stroke(Color.brandPurple, lineWidth: 1.5)
//                    )
//            }

        }
        .padding()
        .background(.bar)
    }

    /// Persists a `Complete` record for the current user, if one doesn't
    /// already exist. This is what `Trip.hasCurrentUserCompleted` reads —
    /// once it's true, `TripHistoryView`'s segmented control moves this
    /// trip out of "Planned" and into "History".
    private func markTripComplete() {
        guard !trip.hasCurrentUserCompleted else { return }
        Complete.insert(into: moc, trip: trip)
        try? moc.save()
    }

    // MARK: - Helpers
    
    /// Parses the raw MKPointOfInterestCategory into a readable string (e.g., "MKPOICategoryRestaurant" -> "Restaurant")
    private func categoryLabel(for category: MKPointOfInterestCategory?) -> String? {
        guard let category = category else { return nil }
        
        // Remove the "MKPOICategory" prefix to get a clean UI string
        let rawString = category.rawValue
        let cleanString = rawString.replacingOccurrences(of: "MKPOICategory", with: "")
        
        // Add spaces before capital letters for camel case categories like "NationalPark" -> "National Park"
        let readableString = cleanString.replacingOccurrences(
            of: "([A-Z])",
            with: " $1",
            options: .regularExpression,
            range: cleanString.startIndex..<cleanString.endIndex
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        
        return readableString.isEmpty ? nil : readableString
    }

    private func remainingStopsCount() -> Int {
        max(routePlanner.orderedStops.count - routePlanner.currentLegIndex, 0)
    }

    private func formattedRemainingTime() -> String {
        let remainingLegs = routePlanner.legs.dropFirst(routePlanner.currentLegIndex)
        let seconds = remainingLegs.reduce(0) { $0 + $1.expectedTravelTime }
        let minutes = max(Int(seconds / 60), 0)
        return "\(minutes) min"
    }

    private func updateCamera() {
        guard followUser else { return }
        guard let location = locationManager.currentLocation else { return }

        mapPosition = .camera(
            MapCamera(
                centerCoordinate: location,
                distance: 700,
                heading: 0,
                pitch: 60
            )
        )
    }

}

/// A shape that rounds only the specified corners, used for the draggable
/// bottom sheet so its top corners are rounded while the bottom stays flush
/// with the screen edge.
struct RoundedCorner: Shape {
    var radius: CGFloat = 12
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
