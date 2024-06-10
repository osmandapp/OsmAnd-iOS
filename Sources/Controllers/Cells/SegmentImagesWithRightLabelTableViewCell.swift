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
    
    var didSelectSegmentIndex: ((Int) -> Void)?
    
    func configureTitle(title: String) {
        titleLabel.text = title
    }
    
    func configureSegmentedControl(icons: [String], selectedSegmentIndex: Int ) {
        for (index, icon) in icons.enumerated() {
            if let image = UIImage(named: icon) {
                segmentedControl.setImage(image, forSegmentAt: index)
            }
        }
        segmentedControl.selectedSegmentIndex = selectedSegmentIndex
    }

    @IBAction private func segmentedControlButtonClickAction(_ sender: UISegmentedControl) {
        didSelectSegmentIndex?(sender.selectedSegmentIndex)
    }
}
