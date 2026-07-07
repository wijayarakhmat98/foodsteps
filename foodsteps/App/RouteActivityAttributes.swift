import ActivityKit
import Foundation

/// Remember: Target Membership for this file MUST be checked for BOTH
/// the main app target AND the Widget Extension target.
struct RouteActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentStopName: String
        var stopNumber: Int
        var totalStops: Int
        var etaMinutes: Int
        var distanceMeters: Double
        var isPaused: Bool
    }

    var routeName: String
}
