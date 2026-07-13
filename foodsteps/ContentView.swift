import SwiftUI

struct ContentView: View {
    
    @State private var router = AppRoute.shared
    
    var body: some View {
        @Bindable var bindableRouter = router
        
        NavigationStack(path: $bindableRouter.path) {
            TabView {
                HomeView2()
                    .tabItem {
                        Label("Discover", systemImage: "figure.walk")
                    }
                
                TripHistoryView()
                    .tabItem {
                        Label("Trip", systemImage: "paperplane.fill")
                    }
            }
            .tint(Color(hex: "#FF8F14"))
            .navigationDestination(for: Route.self) { route in
                route.destinationView()
            }
        }
    }
}

#Preview {
    ContentView()
}
