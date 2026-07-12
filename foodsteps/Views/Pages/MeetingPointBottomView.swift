import SwiftUI
import MapKit
import CoreLocation

struct MeetingPointBottomView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocationName: String
    
    // State untuk peta & pencarian
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    
    // Location Manager untuk menarik koordinat saat ini
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Search Bar & Header
            VStack(spacing: 12) {
                Text("Select Meeting Point")
                    .font(.headline)
                    .padding(.top, 16)
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search location...", text: $searchText)
                        .onChange(of: searchText) { _ in
                            searchLocation()
                        }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding(.bottom, 12)
            
            // MARK: - Map & Result Split
            ZStack(alignment: .bottom) {
                // Map View (iOS 17+)
                Map(position: $cameraPosition) {
                    UserAnnotation() // Titik lokasi user saat ini
                    
                    // Menampilkan pin hasil pencarian jika dipilih
                    ForEach(searchResults, id: \.self) { item in
                        Marker(item.name ?? "Destination", coordinate: item.placemark.coordinate)
                            .tint(.purple)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                
                // Menampilkan daftar hasil pencarian di atas peta jika user sedang mengetik
                if !searchResults.isEmpty && !searchText.isEmpty {
                    List(searchResults, id: \.self) { item in
                        VStack(alignment: .leading) {
                            Text(item.name ?? "")
                                .font(.body)
                                .fontWeight(.semibold)
                            Text(item.placemark.title ?? "")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .listRowBackground(Color(.systemBackground).opacity(0.9))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectLocation(item)
                        }
                    }
                    .listStyle(.plain)
                    .frame(maxHeight: 250)
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .onAppear {
            locationManager.requestPermission()
        }
    }
    
    // Fungsi untuk mencari lokasi menggunakan MapKit Search
    private func searchLocation() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        // Membatasi pencarian di sekitar lokasi user saat ini jika tersedia
        if let userRegion = locationManager.region {
            request.region = userRegion
        }
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }
            self.searchResults = response.mapItems
        }
    }
    
    // Fungsi mengeksekusi lokasi yang dipilih user
    private func selectLocation(_ item: MKMapItem) {
        let name = item.name ?? "Unknown Location"
        selectedLocationName = name
        
        // Pindahkan kamera peta ke lokasi terpilih
        let region = MKCoordinateRegion(
            center: item.placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        withAnimation {
            cameraPosition = .region(region)
        }
        
        // Berikan delay sedikit agar user melihat pin berpindah, lalu tutup sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

// MARK: - Location Manager Helper
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var region: MKCoordinateRegion?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        DispatchQueue.main.async {
            self.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
}