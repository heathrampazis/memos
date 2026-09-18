import SwiftUI
import UIKit

// Restores going back by swiping, and widens it.
struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = Controller()
        controller.coordinator = context.coordinator
        controller.view.isUserInteractionEnabled = false
        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {}

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var navigation: UINavigationController?
        private(set) var widePan: UIPanGestureRecognizer?

        func install(on navigation: UINavigationController) {
            self.navigation = navigation

            navigation.interactivePopGestureRecognizer?.isEnabled = true
            navigation.interactivePopGestureRecognizer?.delegate = self

            guard widePan == nil else { return }
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handle(_:)))
            pan.delegate = self
            navigation.view.addGestureRecognizer(pan)
            widePan = pan
        }

        private var canGoBack: Bool {
            (navigation?.viewControllers.count ?? 0) > 1
        }

        @objc private func handle(_ pan: UIPanGestureRecognizer) {
            guard pan.state == .ended, canGoBack, let view = navigation?.view else { return }

            let travel = pan.translation(in: view)
            let speed = pan.velocity(in: view)

            // Rightward, and clearly not a scroll.
            guard abs(travel.y) < 80, speed.x > 0 else { return }
            guard travel.x > 90 || (travel.x > 40 && speed.x > 800) else { return }

            navigation?.popViewController(animated: true)
        }

        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            canGoBack
        }

        // The wide pan has to share with the text view, or scrolling and selecting text stop
        // working.
        func gestureRecognizer(
            _ recognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            recognizer === widePan
        }
    }

    final class Controller: UIViewController {
        var coordinator: Coordinator?

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            attach()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            attach()
        }

        private func attach() {
            guard let navigation = navigationController else { return }
            coordinator?.install(on: navigation)
        }
    }
}
