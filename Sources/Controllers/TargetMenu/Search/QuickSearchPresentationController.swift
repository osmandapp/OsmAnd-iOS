//
//  QuickSearchPresentationController.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class QuickSearchTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var onOutsideTap: (() -> Void)?

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        let presentationController = QuickSearchPresentationController(presentedViewController: presented, presenting: presenting)
        presentationController.onOutsideTap = onOutsideTap
        return presentationController
    }
}

final class QuickSearchPresentationController: UIPresentationController {
    private static let minimumPanelWidth: CGFloat = 320
    private static let shadowOpacity: Float = 0.2
    private static let shadowRadius: CGFloat = 8

    var onOutsideTap: (() -> Void)?

    private let outsideTapView = UIView()

    override var shouldRemovePresentersView: Bool {
        false
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView else { return .zero }
        return panelFrame(for: containerView.bounds.size)
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let containerView else { return }
        outsideTapView.backgroundColor = .clear
        outsideTapView.frame = containerView.bounds
        outsideTapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        outsideTapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onOutsideTapped)))
        containerView.insertSubview(outsideTapView, at: 0)
        updateShadow(for: frameOfPresentedViewInContainerView, in: containerView.bounds.size)
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            outsideTapView.removeFromSuperview()
        }
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        guard let containerView, presentedViewController.transitionCoordinator == nil else { return }
        let frame = frameOfPresentedViewInContainerView
        presentedView?.frame = frame
        updateShadow(for: frame, in: containerView.bounds.size)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let frame = panelFrame(for: size)
        coordinator.animate { [weak self] _ in
            self?.presentedView?.frame = frame
            self?.updateShadow(for: frame, in: size)
        }
    }

    private func panelFrame(for size: CGSize) -> CGRect {
        let bounds = CGRect(origin: .zero, size: size)
        let panelWidth = floor(size.width / 2)
        let sidePanelAllowed = OAUtilities.isIPad() || ProcessInfo.processInfo.isiOSAppOnMac || size.width > size.height
        guard sidePanelAllowed, panelWidth >= Self.minimumPanelWidth else { return bounds }
        let isRTL = containerView?.effectiveUserInterfaceLayoutDirection == .rightToLeft
        return CGRect(x: isRTL ? size.width - panelWidth : 0, y: 0, width: panelWidth, height: size.height)
    }

    private func updateShadow(for frame: CGRect, in size: CGSize) {
        guard let layer = presentedView?.layer else { return }
        let isSidePanel = frame.width < size.width
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = Self.shadowRadius
        layer.shadowOpacity = isSidePanel ? Self.shadowOpacity : 0
        layer.shadowPath = isSidePanel ? UIBezierPath(rect: CGRect(origin: .zero, size: frame.size)).cgPath : nil
    }

    @objc private func onOutsideTapped() {
        onOutsideTap?()
    }
}
