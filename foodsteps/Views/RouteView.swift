import SwiftUI
import MapKit

/// The "Route" tab: a map preview of the suggested/current route, distance
/// stats, and the reorderable list of stops. Owns its own map camera state
/// and refits it whenever the route changes.
struct RouteView: View {
    @ObservedObject var trip: Trip
    var routePlanner: RoutePlanner
    var locationManager: LocationManager

    var placeStops: [Stop]
    var meetingPointDisplayName: String?

    @Binding var isPreparingRoute: Bool
    /// Kicks off route calculation; owned by the parent (TripInputView)
    /// since it's also triggered from the "Start Trip" button outside this
    /// tab. Passed in so the "Generate/Regenerate" button here can reuse it.
    var computeRoute: (@escaping () -> Void) -> Void

    @State private var isUpdatingOrder = false
    @State private var reorderToken = UUID()
    @State private var mapPosition: MapCameraPosition = .automatic

    var body: some View {
        content
            .onAppear { fitMapPreview() }
            .onChange(of: routePlanner.orderedStops.count) { _, _ in
                fitMapPreview()
            }
    }

    @ViewBuilder
    private var content: some View {
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

    // MARK: - Map

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
                Annotation(stop.displayName, coordinate: stop.mapItem.placemark.coordinate) {
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

    // MARK: - Stats

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

    // MARK: - Ordered stop list

    private var routeOrderList: some View {
        List {
            Section {
                routeStartRow.moveDisabled(true)

                ForEach(Array(routePlanner.orderedStops.enumerated()), id: \.element.id) { index, stop in
                    routeStopRow(index: index, stop: stop)
                }
                .onMove(perform: moveStops)
            } header: {
                HStack {
                    Text("Suggested order (by distance)")
                    Spacer()
                    // The new manual Generate Route button
                    if !placeStops.isEmpty {
                        Button {
                            computeRoute {}
                        } label: {
                            Text(routePlanner.orderedStops.isEmpty ? "Generate Route" : "Regenerate")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.blue)
                        }
                        .disabled(isPreparingRoute)
                    }
                }
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

    private func routeStopRow(index: Int, stop: Stop) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.black).frame(width: 28, height: 28)
                Text("\(index + 1)").font(.caption.bold()).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(stop.displayName)
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

    // MARK: - Map fitting

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
}
