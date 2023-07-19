//
//  BaseSegmentedControlViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 25.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objc(OABaseSegmentedControlViewController)
@objcMembers
class BaseSegmentedControlViewController: OABaseButtonsViewController {

    private static let scrollOffset: CGFloat = -140
    private static let contentOffset: CGFloat = 48
    private static let segmentHeight: CGFloat = 46

    private var containerView: UIView?
    private var blurEffectView: UIVisualEffectView!

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.separator
        return view
    }()

    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = tableView.backgroundColor
    }

    //MARK: - Base setup UI

    override func updateNavbar() {
        super.updateNavbar()
        setupBlurView()
        setupSegmentedControl()
    }

    private func setupBlurView() {
        if getNavbarColorScheme() == .gray, !UIAccessibility.isReduceTransparencyEnabled {
            let blurEffect = UIBlurEffect(style: .systemThickMaterial)
            blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private func setupSegmentedControl() {
        let segmentedControl = createSegmentControl()
        if let segmentedControl, self.containerView == nil {
            let containerView: UIView = UIView()
            setupContainerAppearance(containerView)
            containerView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(containerView)
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
                containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
                containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
                containerView.heightAnchor.constraint(equalToConstant: Self.segmentHeight)
            ])
            segmentedControl.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(segmentedControl)
            NSLayoutConstraint.activate([
                segmentedControl.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                segmentedControl.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
                segmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                segmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
                segmentedControl.heightAnchor.constraint(equalToConstant: 30)
            ])
            containerView.addSubview(separatorView)
            separatorView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                separatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                separatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                separatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                separatorView.heightAnchor.constraint(equalToConstant: 0.5)
            ])
            tableView.contentInset = UIEdgeInsets(top: Self.contentOffset, left: 0, bottom: 0, right: 0)
            if let blurEffectView {
                containerView.insertSubview(blurEffectView, at: 0)
                NSLayoutConstraint.activate([
                    blurEffectView.topAnchor.constraint(equalTo: containerView.topAnchor),
                    blurEffectView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                    blurEffectView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                    blurEffectView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
                ])
                blurEffectView.alpha = 0
            }
            self.containerView = containerView
        }
        else if segmentedControl == nil, self.containerView != nil {
            self.containerView?.removeFromSuperview()
            self.containerView = nil
        }
    }

    private func setupContainerAppearance(_ container: UIView) {
        switch getNavbarColorScheme() {
        case .gray:
            container.backgroundColor = .clear
        case .orange:
            container.backgroundColor = UIColor(rgb: Int(color_osmand_orange))
        case .white:
            container.backgroundColor = .white
        @unknown default:
            container.backgroundColor = .white
        }
    }

    func createSegmentControl() -> UISegmentedControl? {
        nil
    }

    //MARK: - Base UI

    override func isNavbarSeparatorVisible() -> Bool {
        false
    }

    //MARK: - Selectors

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Check if the table view offset is greater than 0
        let offset = scrollView.contentOffset.y
        if offset > Self.scrollOffset {
            blurEffectView.alpha = 1
        } else if offset <= Self.scrollOffset {
            blurEffectView.alpha = 0
        }
    }

}
