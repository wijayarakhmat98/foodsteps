import SwiftUI

struct TripDetailView: View {
    let trip: Trip

    let dateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm E, d MMM y"
        return dateFormatter
    }()

    var body: some View {
        Text(trip.name ?? "Unknown Trip Name")
        if let start = trip.start {
            Text(dateFormatter.string(from: start))
        } else {
            Text("Unknown Trip Start")
        }
        if let end = trip.end {
            Text(dateFormatter.string(from: end))
        } else {
            Text("Unknown Trip End")
        }
    }
}

//#Preview {
//    TripDetailView()
//}
