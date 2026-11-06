import UIKit

/// Transfers the shared phone navigation hierarchy to the scene that is now visible.
@objc final class SceneWindowStateRestorer: NSObject {
    private final class PendingTransfer {
        let root: OARootViewController
        let navigationController: UINavigationController
        let navigationStack: [UIViewController]
        let topController: UIViewController?
        let presenter: UIViewController
        let modals: [ModalState]
        weak var destinationWindow: UIWindow?
        var generation = 0
        var isInstallingWindow = false

        init(
            root: OARootViewController,
            navigationController: UINavigationController,
            navigationStack: [UIViewController],
            topController: UIViewController?,
            presenter: UIViewController,
            modals: [ModalState],
            destinationWindow: UIWindow
        ) {
            self.root = root
            self.navigationController = navigationController
            self.navigationStack = navigationStack
            self.topController = topController
            self.presenter = presenter
            self.modals = modals
            self.destinationWindow = destinationWindow
        }
    }

    /// Presentation controllers can lose sheet height and popover anchors when moved between windows.
    private struct ModalState {
        let controller: UIViewController
        let hadSheet: Bool
        let detents: [UISheetPresentationController.Detent]
        let selectedDetent: UISheetPresentationController.Detent.Identifier?
        let sheetDelegate: UISheetPresentationControllerDelegate?
        let prefersGrabberVisible: Bool
        let preferredCornerRadius: CGFloat?
        let prefersScrollingExpandsWhenScrolledToEdge: Bool
        let largestUndimmedDetentIdentifier: UISheetPresentationController.Detent.Identifier?
        let sourceView: UIView?
        let sourceRect: CGRect
        let barButtonItem: UIBarButtonItem?
        let arrowDirections: UIPopoverArrowDirection

        init(_ controller: UIViewController) {
            self.controller = controller
            let sheet = controller.sheetPresentationController
            hadSheet = sheet != nil
            detents = sheet?.detents ?? []
            selectedDetent = sheet?.selectedDetentIdentifier
            sheetDelegate = sheet?.delegate
            prefersGrabberVisible = sheet?.prefersGrabberVisible ?? false
            preferredCornerRadius = sheet?.preferredCornerRadius
            prefersScrollingExpandsWhenScrolledToEdge = sheet?.prefersScrollingExpandsWhenScrolledToEdge ?? true
            largestUndimmedDetentIdentifier = sheet?.largestUndimmedDetentIdentifier

            let popover = controller.popoverPresentationController
            sourceView = popover?.sourceView
            sourceRect = popover?.sourceRect ?? .zero
            barButtonItem = popover?.barButtonItem
            arrowDirections = popover?.permittedArrowDirections ?? .any
        }

        func restorePresentation() {
            if hadSheet, let sheet = controller.sheetPresentationController {
                if !detents.isEmpty {
                    sheet.detents = detents
                }
                sheet.selectedDetentIdentifier = selectedDetent
                sheet.prefersGrabberVisible = prefersGrabberVisible
                sheet.preferredCornerRadius = preferredCornerRadius
                sheet.prefersScrollingExpandsWhenScrolledToEdge = prefersScrollingExpandsWhenScrolledToEdge
                sheet.largestUndimmedDetentIdentifier = largestUndimmedDetentIdentifier
                sheet.delegate = sheetDelegate
            }

            if let popover = controller.popoverPresentationController {
                if let barButtonItem {
                    popover.sourceView = nil
                    popover.barButtonItem = barButtonItem
                } else {
                    popover.barButtonItem = nil
                    popover.sourceView = sourceView
                    popover.sourceRect = sourceRect
                }
                popover.permittedArrowDirections = arrowDirections
            }
        }
    }

    private static var pendingTransfer: PendingTransfer?

    @objc static func attach(_ rootViewController: OARootViewController, to window: UIWindow) -> Bool {
        let navigationController = rootViewController.navigationController
            ?? OANavigationController(rootViewController: rootViewController)
        let pending = pendingTransfer
        let navigationStack = pending?.navigationStack ?? navigationController.viewControllers
        let topController = pending?.topController ?? navigationController.topViewController
        var modals: [ModalState] = []
        var presenter: UIViewController?
        if pending == nil {
            presenter = navigationController.presentedViewController == nil
                ? navigationController.visibleViewController ?? navigationController
                : navigationController
            var presented = presenter?.presentedViewController
            while let modal = presented {
                modals.append(ModalState(modal))
                presented = modal.presentedViewController
            }
        }

        let previousWindow = navigationController.view.window
            ?? pending?.modals.first?.controller.viewIfLoaded?.window
            ?? modals.first?.controller.viewIfLoaded?.window

        // A waiting scene may still have portrait geometry while another scene is landscape.
        if let previousWindow, previousWindow !== window,
           window.windowScene?.activationState != .foregroundActive {
            return false
        }

        if let pending, pending.destinationWindow !== window {
            pending.destinationWindow = window
            pending.generation += 1
        }
        pending?.isInstallingWindow = true

        rootViewController.movingBetweenWindowScenes = pending != nil
            || (previousWindow != nil && previousWindow !== window)
        if let previousWindow, previousWindow !== window,
           previousWindow.rootViewController === navigationController {
            // Its app-switcher preview must have a root after the shared controller leaves.
            previousWindow.rootViewController = OALaunchScreenViewController()
        }

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        restoreNavigationStack(navigationStack, on: navigationController, root: rootViewController)
        pending?.isInstallingWindow = false

        // A dismissal already in progress must restore into whichever window owns the root last.
        if pending != nil { return true }
        guard let previousWindow, previousWindow !== window, !modals.isEmpty,
              let presenter else {
            rootViewController.movingBetweenWindowScenes = false
            return true
        }
        let transfer = PendingTransfer(root: rootViewController,
                                       navigationController: navigationController,
                                       navigationStack: navigationStack,
                                       topController: topController,
                                       presenter: presenter,
                                       modals: modals,
                                       destinationWindow: window)
        pendingTransfer = transfer
        // Re-present the same modal controllers so UIKit creates presentations for the new window.
        presenter.dismiss(animated: false) {
            resume(transfer)
        }
        return true
    }

    private static func restoreNavigationStack(_ stack: [UIViewController],
                                               on navigationController: UINavigationController,
                                               root: OARootViewController) {
        guard !navigationController.viewControllers.elementsEqual(stack, by: { $0 === $1 }) else { return }
        // UIKit may change the stack while detaching the navigation controller from its window.
        let wasMoving = root.movingBetweenWindowScenes
        root.movingBetweenWindowScenes = true
        navigationController.setViewControllers(stack, animated: false)
        root.movingBetweenWindowScenes = wasMoving
    }

    private static func resume(_ transfer: PendingTransfer) {
        guard pendingTransfer === transfer else { return }
        if transfer.isInstallingWindow {
            DispatchQueue.main.async { resume(transfer) }
            return
        }
        let navigationController = transfer.navigationController
        guard let destinationWindow = transfer.destinationWindow,
              navigationController.view.window === destinationWindow else {
            finish(transfer)
            return
        }
        restoreNavigationStack(transfer.navigationStack, on: navigationController, root: transfer.root)
        guard navigationController.topViewController === transfer.topController else {
            finish(transfer)
            return
        }
        restoreModals(transfer, from: transfer.presenter, at: 0, generation: transfer.generation)
    }

    private static func restart(_ transfer: PendingTransfer) {
        guard pendingTransfer === transfer else { return }
        guard transfer.presenter.presentedViewController != nil else {
            resume(transfer)
            return
        }
        transfer.presenter.dismiss(animated: false) {
            resume(transfer)
        }
    }

    private static func restoreModals(
        _ transfer: PendingTransfer,
        from presenter: UIViewController,
        at index: Int,
        generation: Int
    ) {
        guard pendingTransfer === transfer else { return }
        if transfer.isInstallingWindow {
            DispatchQueue.main.async {
                restoreModals(transfer, from: presenter, at: index, generation: generation)
            }
            return
        }
        guard generation == transfer.generation else {
            restart(transfer)
            return
        }
        guard index < transfer.modals.count else {
            finish(transfer)
            return
        }
        let modal = transfer.modals[index]
        modal.restorePresentation()
        presenter.present(modal.controller, animated: false) {
            // The presentation controller can be recreated by present(_:animated:completion:).
            modal.restorePresentation()
            restoreModals(transfer, from: modal.controller, at: index + 1, generation: generation)
        }
    }

    private static func finish(_ transfer: PendingTransfer) {
        guard pendingTransfer === transfer else { return }
        transfer.root.movingBetweenWindowScenes = false
        pendingTransfer = nil
    }
}
