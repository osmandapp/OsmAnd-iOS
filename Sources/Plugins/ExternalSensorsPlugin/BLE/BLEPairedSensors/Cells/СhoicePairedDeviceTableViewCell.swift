//
//  СhoicePairedDeviceTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//


final class СhoicePairedDeviceTableViewCell: SearchDeviceTableViewCell {
    @IBOutlet private weak var checkmarkImageView: UIImageView!
    @IBOutlet private weak var bottomSeparatorView: UIView!
    @IBOutlet private weak var bottomSeparatorHeightConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        bottomSeparatorView.backgroundColor = .adaptiveSeparator
        bottomSeparatorHeightConstraint.constant = UIScreen.adaptiveSeparatorThickness
    }
    
    override func configure(item: Device) {
        super.configure(item: item)
        checkmarkImageView.image =  item.isSelected ? UIImage(named: "ic_checkmark_default") : nil
    }
}
