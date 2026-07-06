import CoreData
import SwiftUI

struct TripView: View {
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(sortDescriptors: [SortDescriptor(\.created)])
    private var trips: FetchedResults<Trip>

    @State private var showNewTrip = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(trips) { trip in
                    NavigationLink(value: trip) {
                        Text(trip.name ?? "Unknown Trip")
                    }
                }
                .onDelete(perform: deleteTrips)
            }
            .navigationTitle("Trip")
            .navigationDestination(for: Trip.self) { trip in
				TripDetailView(trip: trip)
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

#Preview {
    TripView()
}
