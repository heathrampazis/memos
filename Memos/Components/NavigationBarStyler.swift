import SwiftUI
import UIKit

/// Paints the navigation bar a flat colour with no separator.
///
/// SwiftUI's toolbarBackground gets the colour right but keeps the hairline
/// under it, and on a coloured tile that line reads as a seam across the top of
/// the note. Setting the appearance on the screen's own navigation item rather
/// than on the bar keeps it scoped to this screen.
struct NavigationBarStyler: UIViewControllerRepresentable {
    let color: UIColor

    func makeUIViewController(context: Context) -> Controller {
        let controller = Controller()
        controller.view.isUserInteractionEnabled = false
        controller.color = color
        return controller
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.color = color
        controller.apply()
    }

    final class Controller: UIViewController {
        var color: UIColor = .clear

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            apply()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            apply()
        }

        func apply() {
            guard let item = owner?.navigationItem else { return }

            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = color
            appearance.shadowColor = .clear
            appearance.shadowImage = UIImage()

            item.standardAppearance = appearance
            item.scrollEdgeAppearance = appearance
            item.compactAppearance = appearance
            item.compactScrollEdgeAppearance = appearance

            navigationController?.navigationBar.setNeedsLayout()
        }

        /// SwiftUI nests hosting controllers, so the parent of this one is not
        /// necessarily the screen the bar is reading from. The owner is the
        /// first one up the chain that the navigation stack actually holds.
        private var owner: UIViewController? {
            var candidate: UIViewController? = self
            while let current = candidate {
                if let navigation = current.navigationController,
                   navigation.viewControllers.contains(where: { $0 === current }) {
                    return current
                }
                candidate = current.parent
            }
            return nil
        }
    }
}
