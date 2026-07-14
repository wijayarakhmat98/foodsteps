import CoreData
import MapKit
import SwiftUI

struct NewTripView: View {
    @Environment(\.managedObjectContext) private var moc
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var date = Date()
    @State private var startTime = Date()
    @State private var endTime = Date()

    // Meeting point (held locally until the trip is saved).
    // Keeping the MKMapItem itself (rather than copying out individual
    // fields) lets us hand it straight to Location.insert(into:mapItem:)
    // from Location+Helper when the trip is saved.
    @State private var searchService = LocationSearchService()
    @State private var isPickingMeetingPoint = false
    @State private var meetingPointMapItem: MKMapItem?
    @State private var meetingPointDisplayName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Name") {
                    TextField("Provide a trip name", text: $name)
                }
                Section("Meeting Point") {
                    Button {
                        isPickingMeetingPoint = true
                    } label: {
                        HStack {
                            Text(meetingPointDisplayName.isEmpty ? "Set a meeting point" : meetingPointDisplayName)
                                .foregroundColor(meetingPointDisplayName.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section("Time") {
                    DatePicker("From", selection: $startTime, displayedComponents: [.hourAndMinute])
                    DatePicker("To", selection: $endTime, displayedComponents: [.hourAndMinute])
                }
                Section("Date") {
                    DatePicker("Pick a date", selection: $date, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let newTrip = Trip.insert(
                            into: moc,
                            name: name.isEmpty ? "New Trip" : name,
                            scheduleStart: combineDateAndTime(date: date, time: startTime),
                            scheduledEnd: combineDateAndTime(date: date, time: endTime)
                        )

                        if let mapItem = meetingPointMapItem {
                            let location = Location.insert(into: moc, mapItem: mapItem)
                            Stop.insert(into: moc, trip: newTrip, type: .meetingPoint, location: location)
                        }

                        try? moc.save()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isPickingMeetingPoint) { meetingPointPicker }
        }
    }

    // MARK: - Meeting point picker

    private var meetingPointPicker: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search a meeting point...", text: $searchService.searchQuery)
                    if !searchService.searchQuery.isEmpty {
                        Button {
                            searchService.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(.regularMaterial)

                List(searchService.completions, id: \.self) { completion in
                    Button {
                        selectMeetingPoint(from: completion)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(completion.title).font(.headline)
                            Text(completion.subtitle).font(.subheadline).foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Meeting Point")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        searchService.searchQuery = ""
                        isPickingMeetingPoint = false
                    }
                }
            }
            // Meeting point isn't food-specific — search everything, not just restaurants.
            .onAppear { searchService.configure(for: .anyPlace) }
        }
    }

    private func selectMeetingPoint(from completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        Task {
            let search = MKLocalSearch(request: request)
            if let response = try? await search.start(), let item = response.mapItems.first {
                meetingPointMapItem = item
                meetingPointDisplayName = item.name ?? completion.title
            }

            // Close the picker as soon as a place is chosen instead of leaving it open.
            searchService.searchQuery = ""
            isPickingMeetingPoint = false
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
