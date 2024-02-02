//
//  SegmentImagesWithRightLableTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 18.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

final class SegmentImagesWithRightLableTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var segmenedtControl: UISegmentedControl!
    
    var didSelectSegmentIndex: ((Int) -> Void)?
    
    func configureTitle(title: String) {
        titleLabel.text = title
    }
    
    func configureSegmenedtControl(icons: [String], selectedSegmentIndex: Int ) {
        for (index, icon) in icons.enumerated() {
            if let image = UIImage(named: icon) {
                segmenedtControl.setImage(image, forSegmentAt: index)
            }
        }
        segmenedtControl.selectedSegmentIndex = selectedSegmentIndex
    }

    @IBAction private func segmentedControlButtonClickAction(_ sender: UISegmentedControl) {
        didSelectSegmentIndex?(sender.selectedSegmentIndex)
    }
}
