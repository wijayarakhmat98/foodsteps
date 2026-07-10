import SwiftUI

struct ContentView: View {
    
    @State private var router = AppRoute.shared
    
    var body: some View {
        @Bindable var bindableRouter = router
        
        NavigationStack(path: $bindableRouter.path) {
            TabView {
                HomeView2()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                TripHistoryView()
                    .tabItem {
                        Label("Trip", systemImage: "paperplane.fill")
                    }
                TripView()
                    .tabItem {
                        Label("will Trip", systemImage: "ant.circle")
                    }
            }
            .tint(Color(hex: "#FF8F14"))
            .navigationDestination(for: Route.self) { route in
                route.destinationView()
            }
        }
//        .navigationBarHidden(true)
    }
}

#Preview {
    ContentView()
}
