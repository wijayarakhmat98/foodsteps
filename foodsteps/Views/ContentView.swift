import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            TripView()
                .tabItem {
                    Label("Trip", systemImage: "paperplane")
                }
        }
    }
}
