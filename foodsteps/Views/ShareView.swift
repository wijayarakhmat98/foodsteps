import CloudKit
import CoreData
import SwiftUI
import UIKit

/// Presents the collaborative "Invite People" surface for a trip.
///
/// `UICloudSharingController` has to be *presented* by a real UIKit view
/// controller (`present(_:animated:)`); handing it to SwiftUI's `.sheet()`
/// as if it were ordinary sheet content renders a blank white screen,
/// especially on the `preparationHandler` (new share) path. The old fix for
/// that — wrapping it in an empty host controller and presenting the
/// sharing controller *from* that host, with the host itself still sitting
/// inside a SwiftUI `.sheet()` — traded the blank screen for a different
/// bug: two card presentations stacked on top of each other (the outer
/// SwiftUI sheet card, then the `UICloudSharingController`'s own form-sheet
/// card on top of it), which is what showed up as "2 cards" during share.
///
/// This presents `UICloudSharingController` directly from the app's actual
/// top-most view controller instead, with no SwiftUI `.sheet()` in the
/// mix at all, so there's only ever one card on screen.
enum TripSharePresenter {
    /// `UICloudSharingControllerDelegate` is held weakly by the controller,
    /// so this keeps it alive for the lifetime of the presentation.
    private static var activeCoordinator: Coordinator?

    /// - Parameter onDismiss: called once the share sheet is done (saved,
    ///   stopped, cancelled, or failed) so the caller can refresh anything
    ///   that depends on the trip's sharing state (e.g. re-fetching
    ///   participants).
    static func present(trip: Trip, onDismiss: @escaping () -> Void = {}) {
        guard let topViewController = topMostViewController() else { return }

        let coordinator = Coordinator(tripName: trip.name, onDismiss: onDismiss)
        activeCoordinator = coordinator

        let sharingController: UICloudSharingController

        if let share = trip.share {
            sharingController = UICloudSharingController(share: share, container: dataController.ckContainer)
        } else {
            let container = dataController.container
            let tripURI = trip.objectID.uriRepresentation()
            sharingController = UICloudSharingController { _, completion in
                Task {
                    do {
                        let moc = container.viewContext
                        let managedTrip = try await moc.perform {
                            guard let objectID = moc.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: tripURI) else {
                                throw CocoaError(.persistentStoreUnsupportedRequestType)
                            }
                            return moc.object(with: objectID)
                        }
                        let (_, share, ckContainer) = try await container.share([managedTrip], to: nil)
                        completion(share, ckContainer, nil)
                    } catch {
                        completion(nil, nil, error)
                    }
                }
            }
        }

        sharingController.modalPresentationStyle = .formSheet
        sharingController.delegate = coordinator

        topViewController.present(sharingController, animated: true)
    }

    private static func topMostViewController() -> UIViewController? {
        guard
            let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let tripName: String?
        let onDismiss: () -> Void

        init(tripName: String?, onDismiss: @escaping () -> Void) {
            self.tripName = tripName
            self.onDismiss = onDismiss
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            tripName
        }

        func cloudSharingController(_: UICloudSharingController, failedToSaveShareWithError error: Error) {
            // A share failure (e.g. no network) shouldn't crash the app —
            // just let the caller know the sheet is done so it can refresh.
            onDismiss()
            TripSharePresenter.activeCoordinator = nil
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            onDismiss()
            TripSharePresenter.activeCoordinator = nil
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            onDismiss()
            TripSharePresenter.activeCoordinator = nil
        }
    }
}
