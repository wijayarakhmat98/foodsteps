import CoreData
import SwiftUI

struct NewTripView: View {
    @Environment(\.managedObjectContext) private var moc
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var date = Date()
    @State private var startTime = Date()
    @State private var endTime = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Name") {
					TextField("Provide a trip name", text: $name)
                }
                Section("Meeting Point") {
                    TextField("Set a meeting point", text: .constant(""))
                        .disabled(true)
                }
                Section("Time") {
                    DatePicker(
                        "From",
                        selection: $startTime,
                        displayedComponents: [.hourAndMinute]
                    )
                    DatePicker(
                        "To",
                        selection: $startTime,
                        displayedComponents: [.hourAndMinute]
                    )
                }
                Section("Date") {
                    DatePicker(
                        "Pick a date",
                        selection: $date,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .confirm) {
						let newTrip = Trip(context: moc)
                        newTrip.id = UUID()
                        newTrip.created = Date()
                        newTrip.name = name
                        newTrip.start = combineDateAndTime(date: date, time: startTime)
                        newTrip.end = combineDateAndTime(date: date, time: endTime)
                        try? moc.save()
                        dismiss()
                    }
                }

            }
        }
    }

    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var mergedComponents = DateComponents()
        mergedComponents.year = dateComponents.year
        mergedComponents.month = dateComponents.month
        mergedComponents.day = dateComponents.day
        mergedComponents.hour = timeComponents.hour
        mergedComponents.minute = timeComponents.minute

        return calendar.date(from: mergedComponents) ?? Date()
    }
}

#Preview {
    NewTripView()
}
