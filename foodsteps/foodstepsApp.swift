import CoreData
import SwiftUI

@main
struct foodstepsApp: App {
    @State private var dataController = DataController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
}
