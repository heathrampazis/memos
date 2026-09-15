import SwiftUI
import UIKit

/// Hiding the system back button also disables the swipe-from-edge gesture.
/// This puts it back, but only on a pushed screen — allowing it on the root
/// would let the user swipe the stack out from under itself.
struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.isUserInteractionEnabled = false

        DispatchQueue.main.async {
            guard let navigation = controller.navigationController,
                  navigation.viewControllers.count > 1
            else { return }

            navigation.interactivePopGestureRecognizer?.isEnabled = true
            navigation.interactivePopGestureRecognizer?.delegate = nil
        }
        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {}
}
