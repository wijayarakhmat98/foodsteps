//
//  MapRoutePOCView.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 12/07/26.
//


struct MapRoutePOCView: View {
    // 2. State Data 3 Titik Rute
    @State private var waypoints = [
        Waypoint(name: "Start Point", coordinate: CLLocationCoordinate2D(latitude: -6.1751, longitude: 106.8272)),
        Waypoint(name: "Check Point 1", coordinate: CLLocationCoordinate2D(latitude: -6.1800, longitude: 106.8320)),
        Waypoint(name: "Finish Point", coordinate: CLLocationCoordinate2D(latitude: -6.1900, longitude: 106.8400))
    ]
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var activeWaypointIndex: Int? = nil
    @State private var showPicker = false
    
    // State tambahan untuk proses Generate Share Map Gambar
    @State private var mapSnapshotImage: UIImage? = nil
    @State private var isGeneratingSnapshot = false
    
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -6.1825, longitude: 106.8330),
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        )
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Spacer()
                
                Text("Trip Finished")
                    .font(.title3)
                    .bold()
                    .padding(.top, 36)
                    .padding(.leading, 20)
                
                Spacer()
                
                VStack() {
                    if isGeneratingSnapshot {
                        TimelineView(.animation) { timeline in
                            let angle = timeline.date.timeIntervalSinceReferenceDate * 180 // derajat/detik

                            Button {
                                generateMapSnapshot()
                            } label: {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.primary)
                                    .controlSize(.small)
                                    .frame(width: 50, height: 50)
                                    .glassEffect(in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        if let sharedImg = mapSnapshotImage {
                            ShareLink(
                                item: Image(uiImage: sharedImg),
                                preview: SharePreview(
                                    "Rute Perjalanan Saya",
                                    image: Image(uiImage: sharedImg)
                                )
                            ) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .frame(width: 52, height: 52)
                                    .glassEffect(in: Circle())
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                generateMapSnapshot()
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .frame(width: 50, height: 50)
                                    .glassEffect(in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, 36)
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.white)
            .background(
                Color(hex: "#4B08B5")
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 40,
                            style: .continuous
                        )
                    )
            )
            
            // 3. Komponen Map
            Map(position: $cameraPosition) {
                MapPolyline(coordinates: waypoints.map { $0.coordinate })
                    .stroke(.orange, lineWidth: 5)
                
                ForEach(waypoints, id: \.id) { waypoint in
                    Annotation("", coordinate: waypoint.coordinate) {
                        VStack(spacing: 4) {
                            WaypointAnnotationView(waypoint: waypoint) {
                                if let index = waypoints.firstIndex(where: { $0.id == waypoint.id }) {
                                    activeWaypointIndex = index
                                    showPicker = true
                                }
                            }
                        
                        Text(waypoint.name)
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
        }
        .ignoresSafeArea()
        .imagesWithRoute() // Memaksa update snapshot jika isi foto waypoint berubah
        .photosPicker(isPresented: $showPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem = newItem, let index = activeWaypointIndex else { return }
            
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    
                    await MainActor.run {
                        var updatedWaypoint = waypoints[index]
                        updatedWaypoint.id = UUID()
                        updatedWaypoint.image = uiImage
                        
                        waypoints[index] = updatedWaypoint
                        
                        // Reset picker states
                        selectedItem = nil
                        activeWaypointIndex = nil
                        
                        // Reset snapshot lama agar user dipaksa generate ulang yang baru sesuai foto ter-update
                        mapSnapshotImage = nil
                    }
                }
            }
        }
    }
    
    // 4. FUNGSI BACKGROUND RENDER: Mengubah Map + Path + Foto Jadi 1 Gambar Matang
    func generateMapSnapshot() {
        isGeneratingSnapshot = true
        
        let options = MKMapSnapshotter.Options()
        let coordinates = waypoints.map { $0.coordinate }
        
        // Setup batas region map agar membungkus seluruh rute
        options.region = regionForCoordinates(coordinates)
        options.size = CGSize(width: 1080, height: 1920) // Resolusi gambar output share
        options.scale = UIScreen.main.scale
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                isGeneratingSnapshot = false
                return
            }
            
            let baseImage = snapshot.image
            
            // Mulai Core Graphics Canvas Context
            UIGraphicsBeginImageContextWithOptions(options.size, true, options.scale)
            baseImage.draw(at: .zero)
            
            let context = UIGraphicsGetCurrentContext()
            
            // A. Menggambar Polyline Jingga Strava
            context?.setLineWidth(6.0)
            context?.setStrokeColor(UIColor.systemOrange.cgColor)
            context?.setLineJoin(.round)
            context?.setLineCap(.round)
            
            for (index, waypoint) in waypoints.enumerated() {
                let point = snapshot.point(for: waypoint.coordinate)
                if index == 0 {
                    context?.move(to: point)
                } else {
                    context?.addLine(to: point)
                }
            }
            context?.strokePath()
            
            // B. Menggambar Kustom Bulatan Foto / Kamera pada Setiap Titik Rute
            for waypoint in waypoints {
                let point = snapshot.point(for: waypoint.coordinate)
                let size: CGFloat = 200
                let rect = CGRect(x: point.x - size/2, y: point.y - size/2, width: size, height: size)
                
                if let wpImage = waypoint.image {
                    // Gambar Frame Lingkaran Border Orange
                    context?.setFillColor(UIColor.purple.cgColor)
                    context?.fillEllipse(in: rect)
                    
                    // Gambar Foto di Dalam Lingkaran (Clip)
                    let imageRect = rect.insetBy(dx: 3, dy: 3)
                    let path = UIBezierPath(ovalIn: imageRect)
                    context?.saveGState()
                    path.addClip()
                    wpImage.draw(in: imageRect)
                    context?.restoreGState()
                } else {
                    // Jika belum ada foto, gambar bulatan icon kamera orange bawaan
                    if let cameraIcon = UIImage(systemName: "camera.circle.fill")?.withTintColor(.purple, renderingMode: .alwaysOriginal) {
                        cameraIcon.draw(in: rect)
                    }
                }
            }
            
            let finalImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            DispatchQueue.main.async {
                self.mapSnapshotImage = finalImage
                self.isGeneratingSnapshot = false
            }
        }
    }
    
    // Fungsi pembantu untuk kalkulasi bounding box peta otomatis
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
}

// 5. Ekstensi pembantu deteksi update gambar rute
extension View {
    func imagesWithRoute() -> some View { self }
}