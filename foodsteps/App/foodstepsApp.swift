import CoreData
import SwiftUI

let dataController = DataController()

@main
struct foodstepsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
}
