//
//  TripFinishedView.swift
//  foodsteps
//
//  Created by Willy Tanuwijaya on 07/07/26.
//


import SwiftUI
import MapKit
import CoreData

struct TripFinishedView: View {
    let trip: Trip
    let visitedStops: [Stop]
    let routePlanner: RoutePlanner
    let participantName: String
    let onSaveResult: () -> Void

    @Environment(\.managedObjectContext) private var moc
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var newPlacesCount: Int = 0

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    mapHeader
                        .frame(height: 260)

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

            topBar
        }
        .safeAreaInset(edge: .bottom) {
            saveResultButton
        }
        .onAppear {
            fitMap()
            computeNewPlacesCount()
        }
    }

    // MARK: - Header

    private var mapHeader: some View {
        Map(position: $mapPosition, interactionModes: []) {
            ForEach(Array(visitedStops.enumerated()), id: \.offset) { index, stop in
                Annotation(stop.name ?? "Stop", coordinate: CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)) {
                    ZStack {
                        Circle().fill(Color.orange).frame(width: 22, height: 22)
                        Text("\(index + 1)")
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

    private var topBar: some View {
        HStack {
            Button(action: onSaveResult) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(Color.black.opacity(0.35)))
            }

            Spacer()

            Text("Trip Finished")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Circle()
                .fill(Color.clear)
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal)
        .padding(.top, 50)
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
                placeTimelineRow(index: index, stop: stop, isLast: index == visitedStops.count - 1)
            }
        }
    }

    private func placeTimelineRow(index: Int, stop: Stop, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(Color.purple).frame(width: 26, height: 26)
                    Text("\(index + 1)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                }
                if !isLast {
                    Rectangle()
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 2)
                        .frame(minHeight: 30)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(stop.name ?? "Unknown place")
                    .font(.subheadline.weight(.semibold))

                Text(subtitle(for: stop, at: index))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.bottom, isLast ? 0 : 10)
        }
    }

    private func subtitle(for stop: Stop, at index: Int) -> String {
        var parts: [String] = []
        if let category = stop.category {
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
        let date = routePlanner.finishedAt ?? trip.finishedAt ?? Date()
        return formatter.string(from: date)
    }

    // MARK: - Save

    private var saveResultButton: some View {
        Button(action: onSaveResult) {
            Text("Save Result")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding()
        .background(.bar)
    }

    // MARK: - Helpers

    private func fitMap() {
        let coordinates = visitedStops.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
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

    /// Counts stops from this trip whose Apple Maps place id hasn't shown up
    /// in any previously *finished* trip — i.e. genuinely new discoveries.
    private func computeNewPlacesCount() {
        let request: NSFetchRequest<Stop> = Stop.fetchRequest()
        request.predicate = NSPredicate(
            format: "trip != %@ AND trip.finishedAt != nil AND appleMapsId != nil AND appleMapsId != ''",
            trip
        )

        let previouslyVisitedIds: Set<String>
        if let results = try? moc.fetch(request) {
            previouslyVisitedIds = Set(results.compactMap { $0.appleMapsId })
        } else {
            previouslyVisitedIds = []
        }

        newPlacesCount = visitedStops.filter { stop in
            guard let id = stop.appleMapsId, !id.isEmpty else { return true }
            return !previouslyVisitedIds.contains(id)
        }.count
    }
}