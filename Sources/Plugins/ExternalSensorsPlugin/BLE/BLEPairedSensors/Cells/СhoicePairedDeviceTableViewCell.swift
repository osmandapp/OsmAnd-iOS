//
//  СhoicePairedDeviceTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//


final class СhoicePairedDeviceTableViewCell: SearchDeviceTableViewCell {
    @IBOutlet private weak var checkmarkImageView: UIImageView!
    
    override func configure(item: Device) {
        super.configure(item: item)
        checkmarkImageView.image =  item.isSelected ? UIImage(named: "ic_checkmark_default") : nil
    }
}
