//
//  СhoicePairedDeviceTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//


final class СhoicePairedDeviceTableViewCell: SearchDeviceTableViewCell {
    
    private lazy var accessoryImageView: UIImageView = {
        let imgView = UIImageView(frame: .init(x: 0, y: 0, width: 30, height: 30))
        imgView.image = UIImage(named: "ic_checkmark_default")!
        return imgView
    }()
    
    override func configure(item: Device) {
        super.configure(item: item)
        if item.isSelected {
            accessoryView = accessoryImageView
        } else {
            accessoryView = nil
            accessoryType = .none
        }
    }
}
