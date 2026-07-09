import CoreData
import SwiftUI

struct TripView: View {
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(sortDescriptors: [SortDescriptor(\.createdAt, order: .reverse)])
    private var trips: FetchedResults<Trip>

    @State private var showNewTrip = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(trips) { trip in
                    NavigationLink(value: trip) {
                        Text(trip.name ?? "Unknown Trip")
                            .font(.headline)
                    }
                }
                .onDelete(perform: deleteTrips)
            }
            .navigationTitle("Trips")
            .navigationDestination(for: Trip.self) { trip in
                TripInputView(trip: trip)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewTrip.toggle()
                    } label: {
                        Label("New Trip", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewTrip) {
                NewTripView()
            }
            .overlay {
                if trips.isEmpty {
                    ContentUnavailableView("No Trips", systemImage: "paperplane", description: Text("Tap the + button to plan your first trip."))
                }
            }
        }
    }

    func deleteTrips(at offsets: IndexSet) {
        for offset in offsets {
            let trip = trips[offset]
            moc.delete(trip)
        }
        try? moc.save()
    }
}
