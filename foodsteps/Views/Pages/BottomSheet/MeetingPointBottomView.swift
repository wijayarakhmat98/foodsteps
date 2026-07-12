import SwiftUI
import MapKit

struct MeetingPointBottomView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocationName: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    
    // 1. Tambahkan Binding baru untuk mengoper MKMapItem secara utuh
    @Binding var selectedMapItem: MKMapItem?
    
    // State untuk peta & pencarian
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    
    // Default posisi kamera langsung mengarah ke lokasi user otomatis
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    
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
                        .onChange(of: searchText) { oldValue, newValue in
                            searchLocation()
                        }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding(.bottom, 12)
            
            // MARK: - Conditional Content
            if !searchResults.isEmpty && !searchText.isEmpty {
                List(searchResults, id: \.self) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name ?? "")
                            .font(.body)
                            .fontWeight(.semibold)
                        Text(item.placemark.title ?? "")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectLocation(item)
                    }
                }
                .listStyle(.plain)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        UserAnnotation()
                        
                        ForEach(searchResults, id: \.self) { item in
                            Marker(item.name ?? "Destination", coordinate: item.placemark.coordinate)
                                .tint(Color(hex: "4B08B5"))
                        }
                    }
                    .mapControls {
                        MapUserLocationButton()
                        MapCompass()
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: searchText.isEmpty)
    }
    
    // Fungsi untuk mencari lokasi berbasis MapKit Search
    private func searchLocation() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        if let region = cameraPosition.region {
            request.region = region
        }
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }
            withAnimation {
                self.searchResults = response.mapItems
            }
        }
    }
    
    // Fungsi mengeksekusi lokasi yang dipilih user
    private func selectLocation(_ item: MKMapItem) {
        let name = item.name ?? "Unknown Location"
        let coordinate = item.placemark.coordinate
        
        // Simpan data ke Binding agar terbaca di view utama
        selectedLocationName = name
        selectedCoordinate = coordinate
        
        // 2. Simpan objek MKMapItem utuh ke binding pembungkusnya di sini!
        selectedMapItem = item
        
        // Kosongkan search text agar list menutup dan peta kembali terlihat
        searchText = ""
        
        // Pindahkan posisi kamera peta ke lokasi terpilih
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        withAnimation {
            cameraPosition = .region(region)
        }
        
        // Beri jeda sedikit agar user melihat lokasi baru di peta sebelum sheet menutup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
}
