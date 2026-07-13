import CloudKit
import CoreData
import SwiftUI

/// The single invite/share surface for a trip. If the trip hasn't been
/// shared yet, `UICloudSharingController`'s `preparationHandler` creates
/// the `CKShare` on demand; if it has, the existing share is reused. Either
/// way the caller just toggles one button — no branching on `trip.share`.
struct ShareView: UIViewControllerRepresentable {
    let trip: Trip

    /// `UICloudSharingController` is designed to be *presented* by a view
    /// controller (`present(_:animated:)`), not returned directly as a
    /// SwiftUI `.sheet()`'s root content — doing the latter renders a blank
    /// white screen, especially on the `preparationHandler` (new share)
    /// path. So this hands back an empty host controller and presents the
    /// sharing controller from it instead.
    func makeUIViewController(context: Context) -> UIViewController {
        let hostController = UIViewController()
        hostController.view.backgroundColor = .clear

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
                        let trip = try await moc.perform {
                            guard let objectID = moc.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: tripURI) else {
                                throw CocoaError(.persistentStoreUnsupportedRequestType)
                            }
                            return moc.object(with: objectID)
                        }
                        let (_, share, ckContainer) = try await container.share([trip], to: nil)
                        completion(share, ckContainer, nil)
                    } catch {
                        completion(nil, nil, error)
                    }
                }
            }
        }

        sharingController.modalPresentationStyle = .formSheet
        sharingController.delegate = context.coordinator

        // The host controller isn't in the window yet on this run loop turn
        // (it's still being inserted by the `.sheet()` transition), so
        // presenting has to wait a tick or `present` silently no-ops.
        DispatchQueue.main.async {
            hostController.present(sharingController, animated: true)
        }

        return hostController
    }

    func updateUIViewController(_: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(tripName: trip.name)
    }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let tripName: String?

        init(tripName: String?) {
            self.tripName = tripName
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            tripName
        }

        func cloudSharingController(_: UICloudSharingController, failedToSaveShareWithError error: Error) {
            fatalError("\(error)")
        }
    }
}
