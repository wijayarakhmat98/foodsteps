import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView2()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            TripHistoryView()
                .tabItem {
                    Label("Trip", systemImage: "paperplane.fill")
                }
        }
        .tint(Color(hex: "#FF8F14"))
    }
}
