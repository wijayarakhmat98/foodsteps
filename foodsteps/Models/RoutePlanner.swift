import Foundation
import MapKit
import Observation
import CoreData

// RouteStop is gone — Stop is now identifiable on its own (see Stop+Helper)
// and Location+Helper already gives us `toMapItem()`, so RoutePlanner can
// work with Stop entities directly. These two accessors just bridge that
// gap for the routing/distance math below; they live here (not in
// Stop+Helper.swift) since they're routing-specific, not general helpers.
extension Stop {
    var mapItem: MKMapItem {
        location?.toMapItem() ?? MKMapItem()
    }

    var displayName: String {
        location?.wrappedName ?? "Unknown"
    }
}

@Observable
class RoutePlanner {
    // Explicitly tracking by ID using Stop (Core Data entity, identifiable)
    var startingCoordinate: CLLocationCoordinate2D?
    var stops: [Stop] = []
    var orderedStops: [Stop] = []
    var legs: [MKRoute] = []

    var isOptimizing = false
    var totalDistance: CLLocationDistance = 0
    var totalTime: TimeInterval = 0
    var transportType: MKDirectionsTransportType = .automobile

    var isNavigating = false
    var isPaused = false
    var currentLegIndex = 0

    /// Set to true once every stop has been visited, so the app can present
    /// the Trip Finished summary screen. Reset whenever navigation (re)starts.
    var isFinished = false

    /// Arrival time at each stop, keyed by its index in `orderedStops`.
    var arrivalTimestamps: [Int: Date] = [:]
    var tripStartedAt: Date?
    var finishedAt: Date?

    private let arrivalDistance: CLLocationDistance = 40

    /// The time window spent at a given stop, derived from arrival timestamps.
    /// The stop's departure is the arrival at the next stop, or the trip's
    /// finish time for the last stop.
    func visitedWindow(at index: Int) -> (start: Date, end: Date)? {
        guard let start = arrivalTimestamps[index] else { return nil }

        if let nextArrival = arrivalTimestamps[index + 1] {
            return (start, nextArrival)
        }

        if index == orderedStops.count - 1, let finishedAt {
            return (start, finishedAt)
        }

        return (start, Date())
    }
    
    func clear() {
        stops = []
        invalidateCalculatedRoute()
    }

    private func invalidateCalculatedRoute() {
        orderedStops = []
        legs = []
        totalDistance = 0
        totalTime = 0
        stopNavigation()
        isFinished = false
        arrivalTimestamps = [:]
        tripStartedAt = nil
        finishedAt = nil
    }

    @MainActor
        func recalculateLegsForCurrentOrder() async {
            // Grab the saved starting coordinate
            guard !orderedStops.isEmpty, let start = startingCoordinate else { return }
            isOptimizing = true
            defer { isOptimizing = false }

            // Pass the start coordinate into fetchLegs
            let (newLegs, distanceSum, timeSum) = await Self.fetchLegs(for: orderedStops, startingAt: start, transportType: transportType)
            legs = newLegs
            totalDistance = distanceSum
            totalTime = timeSum
        }

    @MainActor
        func optimizeAndCalculate(from userCoordinate: CLLocationCoordinate2D, moc: NSManagedObjectContext) async {
            guard !stops.isEmpty else { return }
            isOptimizing = true
            self.startingCoordinate = userCoordinate // Save the meeting point here!
            defer { isOptimizing = false }

            let ordered = Self.bestOrder(stops: stops, startingAt: userCoordinate)
            orderedStops = ordered
            Stop.persistSortOrder(for: ordered, in: moc)

            // Pass the start coordinate into fetchLegs
            let (newLegs, distanceSum, timeSum) = await Self.fetchLegs(for: ordered, startingAt: userCoordinate, transportType: transportType)
            legs = newLegs
            totalDistance = distanceSum
            totalTime = timeSum
        }

    private static func bestOrder(stops: [Stop], startingAt userCoordinate: CLLocationCoordinate2D) -> [Stop] {
        guard stops.count > 1 else { return stops }
        let matrix = distanceMatrix(stops: stops, userCoordinate: userCoordinate)
        let orderIndices: [Int]
        
        if stops.count <= 12 {
            orderIndices = heldKarpOrder(stopCount: stops.count, matrix: matrix)
        } else {
            let greedy = nearestNeighborIndices(stopCount: stops.count, matrix: matrix)
            orderIndices = twoOptImprove(order: greedy, matrix: matrix)
        }
        return orderIndices.map { stops[$0] }
    }

    private static func distanceMatrix(stops: [Stop], userCoordinate: CLLocationCoordinate2D) -> [[CLLocationDistance]] {
        var points = [CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)]
        points.append(contentsOf: stops.map { item in
            CLLocation(latitude: item.mapItem.placemark.coordinate.latitude, longitude: item.mapItem.placemark.coordinate.longitude)
        })

        let n = points.count
        var matrix = Array(repeating: Array(repeating: CLLocationDistance(0), count: n), count: n)
        for i in 0..<n {
            for j in (i + 1)..<n {
                let d = points[i].distance(from: points[j])
                matrix[i][j] = d
                matrix[j][i] = d
            }
        }
        return matrix
    }

    private static func heldKarpOrder(stopCount n: Int, matrix: [[CLLocationDistance]]) -> [Int] {
        let fullMask = (1 << n) - 1
        var dp = Array(repeating: Array(repeating: CLLocationDistance.infinity, count: n), count: 1 << n)
        var parent = Array(repeating: Array(repeating: -1, count: n), count: 1 << n)

        for i in 0..<n {
            dp[1 << i][i] = matrix[0][i + 1]
        }

        for mask in 1...fullMask {
            for i in 0..<n where mask & (1 << i) != 0 {
                let currentCost = dp[mask][i]
                guard currentCost.isFinite else { continue }

                for j in 0..<n where mask & (1 << j) == 0 {
                    let nextMask = mask | (1 << j)
                    let candidateCost = currentCost + matrix[i + 1][j + 1]
                    if candidateCost < dp[nextMask][j] {
                        dp[nextMask][j] = candidateCost
                        parent[nextMask][j] = i
                    }
                }
            }
        }

        var bestEnd = 0
        var bestCost = CLLocationDistance.infinity
        for i in 0..<n where dp[fullMask][i] < bestCost {
            bestCost = dp[fullMask][i]
            bestEnd = i
        }

        var order: [Int] = []
        var mask = fullMask
        var current = bestEnd
        while current != -1 {
            order.append(current)
            let previous = parent[mask][current]
            mask &= ~(1 << current)
            current = previous
        }
        return order.reversed()
    }

    private static func nearestNeighborIndices(stopCount n: Int, matrix: [[CLLocationDistance]]) -> [Int] {
        var visited = Array(repeating: false, count: n)
        var order: [Int] = []
        var current = 0

        for _ in 0..<n {
            var bestIndex = -1
            var bestDistance = CLLocationDistance.infinity
            for j in 0..<n where !visited[j] {
                let d = matrix[current][j + 1]
                if d < bestDistance {
                    bestDistance = d
                    bestIndex = j
                }
            }
            visited[bestIndex] = true
            order.append(bestIndex)
            current = bestIndex + 1
        }
        return order
    }

    private static func twoOptImprove(order initialOrder: [Int], matrix: [[CLLocationDistance]]) -> [Int] {
        var order = initialOrder
        guard order.count > 2 else { return order }

        func routeLength(_ order: [Int]) -> CLLocationDistance {
            var total = matrix[0][order[0] + 1]
            for k in 0..<(order.count - 1) {
                total += matrix[order[k] + 1][order[k + 1] + 1]
            }
            return total
        }

        var improved = true
        while improved {
            improved = false
            for i in 0..<(order.count - 1) {
                for j in (i + 1)..<order.count {
                    var candidate = order
                    candidate[i...j].reverse()
                    if routeLength(candidate) < routeLength(order) {
                        order = candidate
                        improved = true
                    }
                }
            }
        }
        return order
    }

    // Update the function signature to accept `startingAt`
        private static func fetchLegs(for orderedStops: [Stop], startingAt startCoordinate: CLLocationCoordinate2D, transportType: MKDirectionsTransportType) async -> ([MKRoute], CLLocationDistance, TimeInterval) {
            var newLegs: [MKRoute] = []
            
            // FIX: Start from the given coordinate instead of the device GPS
            let startPlacemark = MKPlacemark(coordinate: startCoordinate)
            var previousMapItem = MKMapItem(placemark: startPlacemark)
            
            var distanceSum: CLLocationDistance = 0
            var timeSum: TimeInterval = 0

            for stop in orderedStops {
                let request = MKDirections.Request()
                request.source = previousMapItem
                request.destination = stop.mapItem
                request.transportType = transportType

                let directions = MKDirections(request: request)
                if let response = try? await directions.calculate(), let leg = response.routes.first {
                    newLegs.append(leg)
                    distanceSum += leg.distance
                    timeSum += leg.expectedTravelTime
                }
                previousMapItem = stop.mapItem
            }
            return (newLegs, distanceSum, timeSum)
        }

    // MARK: Navigation control
    func startNavigation() {

        guard !orderedStops.isEmpty else { return }

        currentLegIndex = 0

        isPaused = false

        isNavigating = true

        isFinished = false

        arrivalTimestamps = [:]

        tripStartedAt = Date()

        finishedAt = nil
    }

    func stopNavigation() {
        isNavigating = false
        isPaused = false
        currentLegIndex = 0
    }

    func pauseNavigation() {
        guard isNavigating else { return }
        isPaused = true
    }

    func resumeNavigation() {
        guard isNavigating else { return }
        isPaused = false
    }

    var currentNavigationStop: Stop? {
        guard isNavigating, currentLegIndex < orderedStops.count else { return nil }
        return orderedStops[currentLegIndex]
    }

    var currentNavigationLeg: MKRoute? {
        guard isNavigating, currentLegIndex < legs.count else { return nil }
        return legs[currentLegIndex]
    }

    var isLastNavigationStop: Bool {
        currentLegIndex >= orderedStops.count - 1
    }

    @discardableResult
    func advanceToNextStop() -> Bool {

        guard isNavigating else {
            return false
        }

        arrivalTimestamps[currentLegIndex] = Date()

        currentLegIndex += 1

        if currentLegIndex >= orderedStops.count {

            finishedAt = Date()

            isFinished = true

            stopNavigation()

            return false
        }

        return true
    }
    
    func updateNavigation(using locationManager: LocationManager) {

        guard isNavigating else { return }

        guard !isPaused else { return }

        guard let destination = currentNavigationStop else { return }

        guard let currentLocation = locationManager.currentLocation else { return }

        let user = CLLocation(
            latitude: currentLocation.latitude,
            longitude: currentLocation.longitude
        )

        let target = CLLocation(
            latitude: destination.mapItem.placemark.coordinate.latitude,
            longitude: destination.mapItem.placemark.coordinate.longitude
        )

        let distance = user.distance(from: target)

        print("Distance to \(destination.displayName): \(Int(distance))m")

        if distance <= arrivalDistance {

            print("Arrived at \(destination.displayName)")

            if advanceToNextStop() {

                if let next = currentNavigationStop {

                    locationManager.monitorArrival(
                        at: next.mapItem.placemark.coordinate,
                        identifier: next.displayName
                    )

                }

            } else {

                locationManager.stopMonitoringArrivals()

                print("Trip Finished")

            }

        }

    }

    func reorderStops(to newOrder: [Stop]) {
        let previousCurrentStop = currentNavigationStop
        orderedStops = newOrder
        stops = newOrder
        if let previousCurrentStop, let newIndex = newOrder.firstIndex(of: previousCurrentStop) {
            currentLegIndex = newIndex
        }
    }
}
