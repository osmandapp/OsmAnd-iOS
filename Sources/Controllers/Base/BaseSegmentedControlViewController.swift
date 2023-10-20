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

    private static let segmentHeight: CGFloat = 46

    private var containerView: UIView?
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.separator
        return view
    }()

    //MARK: - Base setup UI

    override func updateNavbar() {
        super.updateNavbar()
        setupSegmentedControl()
    }

    private func setupSegmentedControl() {
        updateSegmentedControl(false)
    }

    private func setupContainerAppearance(_ container: UIView) {
        switch getNavbarColorScheme() {
        case .gray:
            container.backgroundColor = tableView.backgroundColor
        case .orange:
            container.backgroundColor = .navBarBgColorPrimary
        case .white:
            container.backgroundColor = .groupBgColor
        @unknown default:
            container.backgroundColor = .groupBgColor
        }
    }

    func createSegmentControl() -> UISegmentedControl? {
        nil
    }

    //MARK: - Base UI

    override func isNavbarBlurring() -> Bool {
        false
    }
    
    override func isNavbarSeparatorVisible() -> Bool {
        false
    }

    override func getNavbarHeight() -> CGFloat {
        return super.getNavbarHeight() + (containerView != nil ? Self.segmentHeight : 0)
    }

    //MARK: - Selectors
    
    override func onRotation() {
        updateSegmentedControl(true)
    }

    //MARK: - Additions

    private func updateSegmentedControl(_ forceUpdate: Bool) {
        let segmentedControl = createSegmentControl()
        if let segmentedControl, (containerView == nil || forceUpdate) {
            if forceUpdate, self.containerView != nil {
                self.containerView?.removeFromSuperview()
                self.containerView = nil
            }
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
                segmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: OAUtilities.getLeftMargin() + 20),
                segmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -OAUtilities.getLeftMargin() + -20),
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
            tableView.contentInset = UIEdgeInsets(top: Self.segmentHeight, left: 0, bottom: 0, right: 0)
            self.containerView = containerView
            let scrollOffset = -getNavbarHeight()
            if tableView.contentOffset.y == scrollOffset + Self.segmentHeight {
                tableView.setContentOffset(CGPoint(x: 0, y: scrollOffset), animated: true)
            }
        }
        else if segmentedControl == nil, self.containerView != nil {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            self.containerView?.removeFromSuperview()
            self.containerView = nil
        }
    }

}
