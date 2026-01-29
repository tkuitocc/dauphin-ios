import EventKit
import EventKitUI
import SwiftUI

/// SwiftUI 包裝 EKEventEditViewController
struct EventEditSheet: UIViewControllerRepresentable {
  let eventStore: EKEventStore
  let event: EKEvent
  var onComplete: (EKEventEditViewController, EKEventEditViewAction) -> Void = { vc, _ in
    vc.dismiss(animated: true)
  }

  func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

  func makeUIViewController(context: Context) -> EKEventEditViewController {
    let vc = EKEventEditViewController()
    vc.eventStore = eventStore
    vc.event = event
    vc.editViewDelegate = context.coordinator
    return vc
  }

  func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

  final class Coordinator: NSObject, EKEventEditViewDelegate {
    let onComplete: (EKEventEditViewController, EKEventEditViewAction) -> Void
    init(onComplete: @escaping (EKEventEditViewController, EKEventEditViewAction) -> Void) {
      self.onComplete = onComplete
    }
    func eventEditViewController(
      _ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction
    ) {
      onComplete(controller, action)  // .saved / .canceled / .deleted
    }
  }
}
