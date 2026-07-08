import CloudKit
import SwiftUI

struct ShareView: UIViewControllerRepresentable {
    let share: CKShare

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let sharingController = UICloudSharingController(share: share, container: dataController.ckContainer)
        sharingController.modalPresentationStyle = .formSheet
        sharingController.delegate = context.coordinator
        return sharingController
    }

    func updateUIViewController(_: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func itemTitle(for csc: UICloudSharingController) -> String? {
					return nil
        }

        func cloudSharingController(_: UICloudSharingController, failedToSaveShareWithError error: Error) {
            fatalError("\(error)")
        }
    }
}
