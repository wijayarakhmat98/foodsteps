//
//  TripHistoryViewModel.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 10/07/26.
//

//
//  TripHistoryViewModel.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 10/07/26.
//

import Foundation
import CoreLocation
import Combine
import CoreData
import MapKit

class TripHistoryViewModel: NSObject, ObservableObject {
    @Published var trips: [Trip] = []
    
    private let moc: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<Trip>
    
    init(context: NSManagedObjectContext) {
        // 1. ISI semua property milik class ini terlebih dahulu
        self.moc = context
        
        // 2. SETUP Request untuk NSFetchedResultsController
        let request = NSFetchRequest<Trip>(entityName: "Trip")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Trip.createdAt, ascending: false)]
        
        // 3. INISIALISASI Controller-nya
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        // 4. SEKARANG panggil super.init() dengan aman
        super.init()
        
        // 5. SET delegate ke diri sendiri (membutuhkan super.init() selesai)
        self.fetchedResultsController.delegate = self
        
        // 6. JALANKAN Fetch pertama kali untuk mengambil data lokal + cloud
        do {
            try fetchedResultsController.performFetch()
            self.trips = fetchedResultsController.fetchedObjects ?? []
        } catch {
            print("Gagal mengambil data trips: \(error)")
        }
    }
    
    func createTrip(
        name: String,
        date: Date,
        startTime: Date,
        endTime: Date,
        meetingPoint: String,
        coordinate: CLLocationCoordinate2D?,
        meetingPointMapItem: MKMapItem?
    ) {
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
    }
    
    func addCulinaryPlaceToTrip(
        trip: Trip,
        culinaryPlace: CulinaryPlace
    ) {
        let location = Location.insert(into: moc, mapItem: culinaryPlace.toMKMapItem())
        Stop.insert(into: moc, trip: trip, type: .stop, location: location)
        try? moc.save()
    }
    
    func getMax4PlaceImageUrl(for trip: Trip) -> [String] {
        // 1. Ambil semua stops. Jika berbentuk NSSet (Core Data), konversikan ke Array objek aslinya
        // Ganti 'Stop' dengan nama class/struct model Stop Anda jika namanya berbeda
        guard let locations = trip.stops as? Set<Stop> else { return [] }
        
        // 2. Lakukan mapping untuk mengambil, memecah, dan mengekstrak URL gambar
        let allUrls = locations.compactMap { (stop: Stop) -> String? in
            // Karena stop.mapItem bukan opsional, langsung ambil name-nya yang opsional
            let mapItem = stop.mapItem
            guard let fullName = mapItem.name else { return nil }
            
            // Pecah string berdasarkan delimiter " ::: "
            let components = fullName.components(separatedBy: " ::: ")
            
            // Pastikan hasil pecahannya ada 2 bagian (index 0: nama, index 1: imageUrl)
            guard components.count >= 2 else { return nil }
            
            // Ambil bagian kedua (imageUrl)
            let imageUrl = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            
            return imageUrl.isEmpty ? nil : imageUrl
        }
        
        return Array(allUrls.prefix(4)).reversed()
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
    
    func getTripWithoutCulinaryPlaceItem(culinaryPlace: CulinaryPlace) -> [Trip] {
        return trips.filter { trip in
            let stops = trip.stops as? Set<Stop> ?? []
            
            let hasCulinaryPlace = stops.contains { (stop: Stop) in
                let cleanStopName = stop.displayName.components(separatedBy: " ::: ").first ?? ""
                    
                return cleanStopName == culinaryPlace.name
            }
            
            return !hasCulinaryPlace
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TripHistoryViewModel: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let updatedTrips = controller.fetchedObjects as? [Trip] {
            DispatchQueue.main.async {
                self.trips = updatedTrips
            }
        }
    }
}
