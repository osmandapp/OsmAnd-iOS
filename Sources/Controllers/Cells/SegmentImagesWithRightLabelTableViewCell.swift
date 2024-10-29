//
//  SegmentImagesWithRightLabelTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 18.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

final class SegmentImagesWithRightLabelTableViewCell: UITableViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var segmentedControlLeadingConstraint: NSLayoutConstraint!

    var didSelectSegmentIndex: ((Int) -> Void)?

    private var icons: [UIImage]?
    private var selectedIcons: [UIImage]?
    private var selectedSegmentIndex = 0
    
    func configureTitle(title: String?) {
        titleLabel.text = title
        let hasTitle = title != nil
        segmentedControlLeadingConstraint.priority = UILayoutPriority(hasTitle ? 1 : 1000)
        titleLabel.isHidden = !hasTitle
    }
    
    func configureSegmentedControl(icons: [UIImage],
                                   selectedSegmentIndex: Int,
                                   selectedIcons: [UIImage]? = nil) {
        self.selectedSegmentIndex = selectedSegmentIndex
        segmentedControl.removeAllSegments()
        self.icons = icons
        self.selectedIcons = selectedIcons
        for (index, icon) in icons.enumerated() {
            segmentedControl.insertSegment(with: icon, at: index, animated: false)
        }
        segmentedControl.selectedSegmentIndex = selectedSegmentIndex
        if let selectedIcons {
            segmentedControl.setImage(selectedIcons[selectedSegmentIndex],
                                      forSegmentAt: selectedSegmentIndex)
        }
    }

    @IBAction private func segmentedControlButtonClickAction(_ sender: UISegmentedControl) {
        if let selectedIcons {
            segmentedControl.setImage(selectedIcons[sender.selectedSegmentIndex],
                                      forSegmentAt: sender.selectedSegmentIndex)
        }
        if let icons {
            segmentedControl.setImage(icons[selectedSegmentIndex],
                                      forSegmentAt: selectedSegmentIndex)
        }
        selectedSegmentIndex = sender.selectedSegmentIndex
        didSelectSegmentIndex?(sender.selectedSegmentIndex)
    }
}
