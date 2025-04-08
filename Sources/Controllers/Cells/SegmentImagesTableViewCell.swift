//
//  SegmentImagesTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 02.04.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

final class SegmentImagesTableViewCell: UITableViewCell {
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var segmentedControlBottomConstraint: NSLayoutConstraint!

    var didSelectSegmentIndex: ((Int) -> Void)?

    private var icons: [UIImage]?
    private var selectedIcons: [UIImage]?
    private var selectedSegmentIndex = 0
    
    func configureSegmentedControl(icons: [UIImage], selectedSegmentIndex: Int, selectedIcons: [UIImage]? = nil) {
        self.selectedSegmentIndex = selectedSegmentIndex
        segmentedControl.removeAllSegments()
        self.icons = icons
        self.selectedIcons = selectedIcons
        for (index, icon) in icons.enumerated() {
            segmentedControl.insertSegment(with: icon, at: index, animated: false)
        }

        segmentedControl.selectedSegmentIndex = selectedSegmentIndex
        if let selectedIcons {
            segmentedControl.setImage(selectedIcons[selectedSegmentIndex], forSegmentAt: selectedSegmentIndex)
        }
    }
    
    func setSegmentedControlBottomSpacing(_ spacing: CGFloat) {
        segmentedControlBottomConstraint.constant = spacing
    }

    @IBAction private func segmentedControlButtonClickAction(_ sender: UISegmentedControl) {
        if let selectedIcons {
            segmentedControl.setImage(selectedIcons[sender.selectedSegmentIndex], forSegmentAt: sender.selectedSegmentIndex)
        }

        if let icons {
            segmentedControl.setImage(icons[selectedSegmentIndex], forSegmentAt: selectedSegmentIndex)
        }

        selectedSegmentIndex = sender.selectedSegmentIndex
        didSelectSegmentIndex?(sender.selectedSegmentIndex)
    }
}
