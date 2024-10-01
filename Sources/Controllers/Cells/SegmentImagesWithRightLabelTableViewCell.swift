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

    private var icons: [String]?
    private var selectedIcons: [String]?
    private var selectedSegmentIndex = 0
    
    func configureTitle(title: String?) {
        titleLabel.text = title
        let hasTitle = title != nil
        segmentedControlLeadingConstraint.priority = UILayoutPriority(hasTitle ? 1 : 1000)
        titleLabel.isHidden = !hasTitle
    }
    
    func configureSegmentedControl(icons: [String],
                                   selectedSegmentIndex: Int,
                                   selectedIcons: [String]? = nil) {
        self.selectedSegmentIndex = selectedSegmentIndex
        segmentedControl.removeAllSegments()
        self.icons = icons
        self.selectedIcons = selectedIcons
        for (index, icon) in icons.enumerated() {
            if let image = UIImage(named: icon) {
                segmentedControl.insertSegment(with: image, at: index, animated: true)
            }
        }
        segmentedControl.selectedSegmentIndex = selectedSegmentIndex
        if let selectedIcons,
           let image = UIImage(named: selectedIcons[selectedSegmentIndex]) {
            segmentedControl.setImage(image,
                                      forSegmentAt: selectedSegmentIndex)
        }
    }

    @IBAction private func segmentedControlButtonClickAction(_ sender: UISegmentedControl) {
        if let selectedIcons,
           let image = UIImage(named: selectedIcons[sender.selectedSegmentIndex]) {
            segmentedControl.setImage(image,
                                      forSegmentAt: sender.selectedSegmentIndex)
        }
        if let icons,
           let image = UIImage(named: icons[selectedSegmentIndex]) {
            segmentedControl.setImage(image,
                                      forSegmentAt: selectedSegmentIndex)
        }
        selectedSegmentIndex = sender.selectedSegmentIndex
        didSelectSegmentIndex?(sender.selectedSegmentIndex)
    }
}
