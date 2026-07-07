import CoreData
import SwiftUI

@main
struct foodstepsApp: App {
    // Switch this back to @State since DataController is now @Observable
    @State private var dataController = DataController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
}
