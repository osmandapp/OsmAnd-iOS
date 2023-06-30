//
//  OABaseSegmentedControlViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 25.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

class OABaseSegmentedControlViewController: OABaseButtonsViewController {
    
    private static let scrollOffset: CGFloat = -140
    private static let contentOffset: CGFloat = 48
    private static let segmentHeight: CGFloat = 46

    private var blurEffectView: UIVisualEffectView!
    
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.separator
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = tableView.backgroundColor
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
        if let segmentedControl {
            let container = UIView()
            setupContainerAppearance(container)
            container.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(container)
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
                container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
                container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
                container.heightAnchor.constraint(equalToConstant: Self.segmentHeight)
            ])
            segmentedControl.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(segmentedControl)
            NSLayoutConstraint.activate([
                segmentedControl.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
                segmentedControl.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
                segmentedControl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
                segmentedControl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
                segmentedControl.heightAnchor.constraint(equalToConstant: 30)
            ])
            container.addSubview(separatorView)
            separatorView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                separatorView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                separatorView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                separatorView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                separatorView.heightAnchor.constraint(equalToConstant: 0.5)
            ])
            tableView.contentInset = UIEdgeInsets(top: Self.contentOffset, left: 0, bottom: 0, right: 0)
            if let blurEffectView {
                container.insertSubview(blurEffectView, at: 0)
                NSLayoutConstraint.activate([
                    blurEffectView.topAnchor.constraint(equalTo: container.topAnchor),
                    blurEffectView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    blurEffectView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    blurEffectView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
                ])
                blurEffectView.alpha = 0
            }
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
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Check if the table view offset is greater than 0
        let offset = scrollView.contentOffset.y
        if offset > Self.scrollOffset {
            blurEffectView.alpha = 1
        } else if offset <= Self.scrollOffset {
            blurEffectView.alpha = 0
        }
    }
    
    override func isNavbarSeparatorVisible() -> Bool {
        false
    }

}
