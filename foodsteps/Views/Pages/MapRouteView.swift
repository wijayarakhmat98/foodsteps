//
//  MapRoutePOCView.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 12/07/26.
//

import SwiftUI
import MapKit
import PhotosUI
import CoreData

/// Entry point for reopening a trip from History (i.e. one the current user
/// has already saved a `Complete` record for — see
/// `Trip.hasCurrentUserCompleted`). Shows the exact same "Trip Finished"
/// screen `ActiveRouteView` hands off to right after finishing, rebuilt
/// purely from persisted Core Data:
///  - `waypoints` come from the trip's saved stops (see
///    `UserLocationManager.makeWaypoints(from:)`), not live GPS.
///  - `pathCoordinates` are the actual walking routes between each visited
///    stop, in order, fetched from MapKit — not a straight line from spot
///    to spot — since the real GPS trail recorded during the trip isn't
///    persisted anywhere; only the stops and their order are.
struct SavedTripMapRouteView: View {
    let trip: Trip

    /// Starts as the straight-line fallback so there's something to show
    /// immediately, then gets replaced by the real road-following route
    /// once `fetchWalkedPath()` finishes.
    @State private var pathCoordinates: [CLLocationCoordinate2D] = []

    /// The visited stops in the order they were completed, restored from
    /// the persisted `sortOrder` (falls back to the unsorted place stops if
    /// no order was ever saved).
    private var visitedStops: [Stop] {
        let ordered = trip.wrappedPlaceStopsBySortOrder
        guard !ordered.isEmpty else {
            return trip.wrappedStops.filter { $0.type != StopType.meetingPoint.rawValue }
        }
        return ordered
    }

    /// Meeting point, then every visited stop, in order — the sequence of
    /// legs to route between.
    private var orderedWaypointCoordinates: [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        if let meetingPoint = trip.meetingPointCoordinate {
            coordinates.append(meetingPoint.coordinate)
        }
        coordinates += visitedStops.compactMap { stop in
            guard let location = stop.location else { return nil }
            return CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        }
        return coordinates
    }

    var body: some View {
        MapRouteView(
            waypoints: UserLocationManager.makeWaypoints(from: trip),
            pathCoordinates: pathCoordinates,
            trip: trip
        )
        .task(id: trip.objectID) {
            // Straight-line fallback first (instant), then swap in the
            // real route once MapKit responds.
            pathCoordinates = orderedWaypointCoordinates
            pathCoordinates = await Self.fetchWalkedPath(through: orderedWaypointCoordinates)
        }
    }

    /// Chains together the actual walking route between each consecutive
    /// pair of stops (meeting point → stop 1 → stop 2 → …), the same way
    /// `RoutePlanner.fetchLegs` does for a live trip, so a reopened trip's
    /// path follows real streets instead of cutting straight lines between
    /// spots. Any leg MapKit can't route (offline, no result, etc.) falls
    /// back to a straight segment for just that leg rather than dropping
    /// the whole route.
    private static func fetchWalkedPath(through coordinates: [CLLocationCoordinate2D]) async -> [CLLocationCoordinate2D] {
        guard coordinates.count > 1 else { return coordinates }

        var fullPath: [CLLocationCoordinate2D] = [coordinates[0]]

        for index in 0..<(coordinates.count - 1) {
            let start = coordinates[index]
            let end = coordinates[index + 1]

            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
            request.transportType = .walking

            let directions = MKDirections(request: request)
            if let response = try? await directions.calculate(), let route = response.routes.first {
                fullPath += route.polyline.coordinates
            } else {
                fullPath.append(end)
            }
        }

        return fullPath
    }
}

private extension MKPolyline {
    /// Reads the polyline's underlying coordinates back out — `MKPolyline`
    /// only exposes them via `getCoordinates(_:range:)`.
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

struct MapRouteView: View {
    // 1. Terima parameter koordinat hasil tracking dari View sebelumnya
    let pathCoordinates: [CLLocationCoordinate2D]
    let trip: Trip
    
    // 2. State Data Waypoints untuk Titik Photo Picker (Tanpa terikat garis orange)
    @State private var waypoints: [Waypoint] = []
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var activeWaypointIndex: Int? = nil
    @State private var showPicker = false
    
    // State untuk kontrol Custom Share Sheet
    @State private var mapSnapshotImage: UIImage? = nil
    @State private var isGeneratingSnapshot = false
    @State private var showCustomShareSheet = false
    
    @State private var offset: CGFloat = 300
    
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.33192591260795, longitude: -122.03025654681196),
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        )
    )
    
    // 3. Inisialisasi posisi kamera agar otomatis membungkus rute tracking yang dikirim
    init(
        waypoints: [Waypoint],
        pathCoordinates: [CLLocationCoordinate2D],
        trip: Trip
    ) {
        self.pathCoordinates = pathCoordinates
        
        self._waypoints = State(initialValue: waypoints)
        
        self.trip = trip

        // Prefer fitting the tracked/walked path; if that's not available
        // yet (e.g. a reopened trip whose real route is still being fetched
        // from MapKit), fall back to fitting the waypoints themselves —
        // those ARE available immediately, so this only needs the "no data
        // at all" default for a genuinely empty trip.
        let fitCoordinates = !pathCoordinates.isEmpty ? pathCoordinates : waypoints.map(\.coordinate)
        if let region = Self.regionFitting(fitCoordinates) {
            self._cameraPosition = State(initialValue: .region(region))
        }
    }

    /// The smallest region containing every coordinate given, padded out a
    /// bit so points aren't jammed against the map's edges — or `nil` if
    /// there's nothing to fit (caller should keep whatever camera position
    /// it already has rather than jump to an arbitrary default).
    private static func regionFitting(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return nil }

        var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0
        for c in coordinates {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        // Pengali diturunkan ke 1.8 agar nge-fit pas di tengah dan tidak terlalu jauh zoom-out-nya.
        // A single point (or all-identical points) has zero span, so floor
        // it to a sane neighborhood-level zoom instead of maxing in.
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.8, 0.02),
            longitudeDelta: max((maxLon - minLon) * 1.8, 0.02)
        )

        return MKCoordinateRegion(center: center, span: span)
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // MARK: - Header
                HStack(alignment: .center) {
                    Spacer()
                    
                    Text("Trip Finished")
                        .font(.title3)
                        .bold()
                        .padding(.top, 24)
                        .padding(.leading, 20)
                    
                    Spacer()
                    
                    //                .padding(.top, 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.white)
                .background(Color(hex: "#4B08B5").clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous)))
                
                // MARK: - Komponen Map
                Map(position: $cameraPosition) {
                    // A. MENGGAMBAR LINE: Garis murni dari data tracking parameter
                    if !pathCoordinates.isEmpty {
                        MapPolyline(coordinates: pathCoordinates)
                            .stroke(.orange, lineWidth: 5)
                    }
                    
                    // B. MENGGAMBAR WAYPOINTS: Murni penanda untuk Photos Picker saja
                    ForEach(waypoints, id: \.id) { waypoint in
                        Annotation("", coordinate: waypoint.coordinate) {
                            VStack(spacing: 4) {
                                WaypointAnnotationView(waypoint: waypoint) {
                                    if let index = waypoints.firstIndex(where: { $0.id == waypoint.id }) {
                                        activeWaypointIndex = index
                                        showPicker = true
                                    }
                                }
                                
                                Text(waypoint.name.components(separatedBy: " ::: ").first ?? "")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: "#4B08B5"))
                                    .clipShape(Capsule())
                                    .shadow(radius: 3)
                            }
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .onChange(of: pathCoordinates.count) {
                    if let region = Self.regionFitting(pathCoordinates) {
                        withAnimation {
                            cameraPosition = .region(region)
                        }
                    }
                }
            }
            BottomSheet(
                offset: $offset,
                showPicker: $showPicker,
                activeWaypointIndex: $activeWaypointIndex,
                waypoints: $waypoints,
                trip: trip
            )
            VStack {
                if isGeneratingSnapshot {
                    Button {
                        // disabled action
                    } label: {
                        HStack(spacing: 10) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.primary)

                            Text("Generating Image")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
//                        .glassEffect(in: Capsule())
//                        .overlay {
//                            Capsule()
//                                .fill(Color(hex: "#FF8F14").opacity(0.25)
//                                )
//                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#FF8F14"))
                    .disabled(true)

                } else if mapSnapshotImage != nil {

                    Button {
                        showCustomShareSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .semibold))

                            Text("Share Image")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
//                        .glassEffect(in: Capsule())
//                        .overlay {
//                            Capsule()
//                                .fill(Color(hex: "#FF8F14").opacity(0.25)
//                                )
//                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#FF8F14"))

                } else {

                    Button {
                        generateMapSnapshot()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "photo")
                                .font(.system(size: 18, weight: .semibold))

                            Text("Generate Image")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
//                        .glassEffect(in: Capsule())
//                        .overlay {
//                            Capsule()
//                                .fill(Color(hex: "#FF8F14").opacity(0.25)
//                                )
//                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#FF8F14"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .ignoresSafeArea()
        .photosPicker(isPresented: $showPicker, selection: $selectedItem, matching: .images)
        .sheet(isPresented: $showCustomShareSheet) {
            if let img = mapSnapshotImage {
                // Panggil fungsi hitungJarakTotal di parameter distance
                CustomShareSheetView(sharedImage: img, distance: calculateTotalDistance(from: pathCoordinates))
                    .presentationDetents([.medium, .large])
            }
        }
        .onChange(of: selectedItem) {
            guard let newItem = selectedItem, let index = activeWaypointIndex else { return }
            
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    
                    await MainActor.run {
                        var updatedWaypoint = waypoints[index]
                        updatedWaypoint.id = UUID()
                        updatedWaypoint.image = uiImage
                        
                        waypoints[index] = updatedWaypoint
                        
                        selectedItem = nil
                        activeWaypointIndex = nil
                        mapSnapshotImage = nil // Reset snapshot lama agar dipaksa render ulang
                    }
                }
            }
        }
    }
    
    // MARK: - FUNGSI BACKGROUND RENDER SNAPSHOT MAP
    func generateMapSnapshot() {
        // Ambil basis rute koordinat dari tracking untuk menentukan batasan gambar snapshot
        let baseRoute = pathCoordinates.isEmpty ? waypoints.map { $0.coordinate } : pathCoordinates
        
        isGeneratingSnapshot = true
        
        let options = MKMapSnapshotter.Options()
        options.region = regionForCoordinates(baseRoute)
        options.size = CGSize(width: 1080, height: 1920)
        options.scale = UIScreen.main.scale
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start(with: DispatchQueue.global(qos: .userInitiated)) { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                DispatchQueue.main.async { self.isGeneratingSnapshot = false }
                return
            }
            
            let baseImage = snapshot.image
            UIGraphicsBeginImageContextWithOptions(options.size, true, options.scale)
            baseImage.draw(at: .zero)
            
            let context = UIGraphicsGetCurrentContext()
            
            // A. Menggambar Polyline dari Koordinat Parameter Tracking
            if !pathCoordinates.isEmpty {
                context?.setLineWidth(6.0)
                context?.setStrokeColor(UIColor.systemOrange.cgColor) // Garis rute tetap orange khas Strava
                context?.setLineJoin(.round)
                context?.setLineCap(.round)
                
                for (index, coord) in pathCoordinates.enumerated() {
                    let point = snapshot.point(for: coord)
                    if index == 0 {
                        context?.move(to: point)
                    } else {
                        context?.addLine(to: point)
                    }
                }
                context?.strokePath()
            }
            
            // B. Menggambar Bulatan Kustom Foto pada Setiap Titik Waypoint Picker
            for waypoint in waypoints {
                let point = snapshot.point(for: waypoint.coordinate)
                let size: CGFloat = 200
                let rect = CGRect(x: point.x - size/2, y: point.y - size/2, width: size, height: size)
                
                if let wpImage = waypoint.image {
                    context?.setFillColor(UIColor.purple.cgColor)
                    context?.fillEllipse(in: rect)
                    
                    let imageRect = rect.insetBy(dx: 3, dy: 3)
                    let path = UIBezierPath(ovalIn: imageRect)
                    context?.saveGState()
                    path.addClip()
                    wpImage.draw(in: imageRect)
                    context?.restoreGState()
                } else {
                    if let cameraIcon = UIImage(systemName: "camera.circle.fill")?.withTintColor(.purple, renderingMode: .alwaysOriginal) {
                        cameraIcon.draw(in: rect)
                    }
                }
            }
            
            // MARK: - C. Menambahkan Watermark Teks dengan Stroke Hitam
            let paddingSide: CGFloat = 60
            let paddingBottom: CGFloat = 80
            
            // 1. Setup Jenis Font
            let titleFont = UIFont.systemFont(ofSize: 62, weight: .bold)
            let dateFont = UIFont.systemFont(ofSize: 40, weight: .medium)
            let footnoteFont = UIFont.systemFont(ofSize: 32, weight: .regular)
            
            // 2. Setup Nilai Teks
            let titleText = "Jajan Bareng"
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "id_ID")
            formatter.dateFormat = "EEEE, d MMMM yyyy"

            let dateText = formatter.string(from: Date())
            let footnoteText = "generated by foodstep"
            
            // 3. Fungsi Pembantu Menggambar Teks (Stroke Hitam + Isi Putih)
            let drawTextWithStroke = { (text: String, point: CGPoint, font: UIFont, strokeWidth: CGFloat, isRightAligned: Bool) in
                var targetPoint = point
                
                if isRightAligned {
                    let textSize = text.size(withAttributes: [.font: font])
                    targetPoint.x -= textSize.width
                }
                
                // Langkah A: Gambar Stroke Outer (Ubah warna ke HITAM di sini)
                let strokeAttributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.systemPurple,
                    .strokeColor: UIColor.systemOrange, // 👈 Diubah jadi hitam
                    .strokeWidth: strokeWidth
                ]
                text.draw(at: targetPoint, withAttributes: strokeAttributes)
                
                // Langkah B: Timpa Tengahnya dengan Warna Putih Solid
                let fillAttributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.systemPurple
                ]
                text.draw(at: targetPoint, withAttributes: fillAttributes)
            }
            
            // 4. Kalkulasi Posisi Sumbu Y Berdasarkan Ukuran Font
            let dateHeight = dateText.size(withAttributes: [.font: dateFont]).height
            let titleHeight = titleText.size(withAttributes: [.font: titleFont]).height
            let footnoteHeight = footnoteText.size(withAttributes: [.font: footnoteFont]).height
            
            let dateY = 1920 - paddingBottom - dateHeight
            let titleY = dateY - titleHeight - 12
            let footnoteY = 1920 - paddingBottom - footnoteHeight
            
            // 5. Menggambar Icon "paperplane.fill" (Putih dengan Border Hitam)
            let iconSize: CGFloat = 46
            if let paperplaneIcon = UIImage(systemName: "paperplane.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal) {
                let iconRect = CGRect(x: paddingSide, y: titleY + (titleHeight - iconSize)/2, width: iconSize, height: iconSize)
                
                // Background lingkaran penegas diganti hitam agar match dengan teks
                context?.setFillColor(UIColor.black.cgColor) // 👈 Diubah jadi hitam
                context?.fillEllipse(in: iconRect.insetBy(dx: -4, dy: -4))
                
                paperplaneIcon.draw(in: iconRect)
            }
            
            // 6. Gambar Semua Komponen Teks ke Kanvas Peta
            let titleX = paddingSide + iconSize + 16
            drawTextWithStroke(titleText, CGPoint(x: titleX, y: titleY), titleFont, 4.0, false)
            drawTextWithStroke(dateText, CGPoint(x: paddingSide, y: dateY), dateFont, 4.0, false)
            
            let footnoteX = 1080 - paddingSide
            drawTextWithStroke(footnoteText, CGPoint(x: footnoteX, y: footnoteY), footnoteFont, 4.5, true)
            
            // --- Akhir Proses Render ---
            let finalImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            DispatchQueue.main.async {
                self.mapSnapshotImage = finalImage
                self.isGeneratingSnapshot = false
            }
        }
    }
    
    func regionForCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0
        for c in coordinates {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.6, longitudeDelta: (maxLon - minLon) * 1.6)
        return MKCoordinateRegion(center: center, span: span)
    }
    
    func calculateTotalDistance(from coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count > 1 else { return 0.0 }
        
        var totalDistanceInMeters: Double = 0.0
        
        for i in 0..<(coordinates.count - 1) {
            let startLocation = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            let endLocation = CLLocation(latitude: coordinates[i+1].latitude, longitude: coordinates[i+1].longitude)
            
            totalDistanceInMeters += startLocation.distance(from: endLocation)
        }
        
        // Mengubah meter ke kilometer (KM)
        return totalDistanceInMeters / 1000.0
    }
}

// 5. Ekstensi pembantu deteksi update gambar rute
extension View {
    func imagesWithRoute() -> some View { self }
}

struct BottomSheet: View {
    @Binding var offset: CGFloat
    @Binding var showPicker: Bool
    @Binding var activeWaypointIndex: Int?
    @Binding var waypoints: [Waypoint]
    
    let trip: Trip
    
    private let expandedOffset: CGFloat = 20
    private let collapsedOffset: CGFloat = 300
    
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 16) {
            
            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 6)
                .padding(.top, 8)
            
            HStack() {
                Circle()
                    .fill(.gray.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                
                VStack(alignment: .leading,) {
                    Text("Hara Hara")
                        .font(.headline)
                    Text("25 July 2026")
                        .font(.footnote)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            Text(trip.name ?? "Unknow")
                .font(.title2)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                
                Text("\(getDiscoverCount()) New Place Discover")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Color(hex: "#FFF5EB")
            )
            .clipShape(Capsule())
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            Text("Places Visited")
                .foregroundStyle(Color(hex: "#4B08B5"))
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            
            ScrollView () {
                VStack(spacing: 0) {
                    ForEach(Array(waypoints.enumerated()), id: \.element.id) {
                        index, waypoint in
                        
                        MeetingPlaceCard(
                            number: index + 1,
                            title: waypoint.name,
                            category: waypoint.category ?? "Place",
                            isLast: index == waypoints.count - 1,
                            image: waypoint.image,
                            onTapImage: {
                                showPicker = true
                                activeWaypointIndex = index
                            }
                        )
                        
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 80)
            }
            
            Spacer()
            
            
        }
        .frame(maxWidth: .infinity)
        .frame(height: 600)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 10)
        .offset(y: offset + dragOffset)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.height
                }
                .onEnded { value in
                    let newOffset = offset + value.translation.height
                    
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        if newOffset < (expandedOffset + collapsedOffset) / 2 {
                            offset = expandedOffset
                        } else {
                            offset = collapsedOffset
                        }
                    }
                }
        )
    }

    func getDiscoverCount() -> Int {
        let count = trip.stops?.count ?? 0
        return count > 1 ? count - 1 : 0
    }
}

//#Preview {
//    MapRouteView(waypoints: [], pathCoordinates: [
//        // --- Menuju Check Point 1 (Muter-muter area Monas & Gambir) ---
//        CLLocationCoordinate2D(latitude: -6.1751, longitude: 106.8272), // Start Point
//        CLLocationCoordinate2D(latitude: -6.1755, longitude: 106.8290),
//        CLLocationCoordinate2D(latitude: -6.1770, longitude: 106.8295),
//        CLLocationCoordinate2D(latitude: -6.1765, longitude: 106.8310),
//        CLLocationCoordinate2D(latitude: -6.1750, longitude: 106.8315),
//        CLLocationCoordinate2D(latitude: -6.1745, longitude: 106.8330),
//        CLLocationCoordinate2D(latitude: -6.1760, longitude: 106.8340),
//        CLLocationCoordinate2D(latitude: -6.1785, longitude: 106.8335),
//        CLLocationCoordinate2D(latitude: -6.1800, longitude: 106.8320), // Check Point 1
//
//        // --- Menuju Finish Point (Muter-muter area Kwitang & Cikini) ---
//        CLLocationCoordinate2D(latitude: -6.1815, longitude: 106.8310),
//        CLLocationCoordinate2D(latitude: -6.1830, longitude: 106.8315),
//        CLLocationCoordinate2D(latitude: -6.1820, longitude: 106.8340),
//        CLLocationCoordinate2D(latitude: -6.1845, longitude: 106.8355),
//        CLLocationCoordinate2D(latitude: -6.1860, longitude: 106.8340),
//        CLLocationCoordinate2D(latitude: -6.1875, longitude: 106.8365),
//        CLLocationCoordinate2D(latitude: -6.1865, longitude: 106.8385),
//        CLLocationCoordinate2D(latitude: -6.1885, longitude: 106.8390),
//        CLLocationCoordinate2D(latitude: -6.1900, longitude: 106.8400)  // Finish Point
//    ])
//}
