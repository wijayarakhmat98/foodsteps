import ActivityKit
import Foundation
import Observation

@Observable
final class LiveActivityController {
    private var activity: Activity<RouteActivityAttributes>?

    func start(routeName: String, state: RouteActivityAttributes.ContentState) {
        guard activity == nil else {
            update(state: state)
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = RouteActivityAttributes(routeName: routeName)
        let content = ActivityContent(state: state, staleDate: nil)

        activity = try? Activity.request(attributes: attributes, content: content)
    }

    func update(state: RouteActivityAttributes.ContentState) {
        guard let activity else { return }
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func end(finalState: RouteActivityAttributes.ContentState) {
        guard let activity else { return }
        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .after(.now.addingTimeInterval(5))
            )
        }
        self.activity = nil
    }
}
