//
//  SearchOBDDeviceTableViewCell.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 21.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class SearchOBDDeviceTableViewCell: UITableViewCell {
    @IBOutlet private weak var deviceNameLabel: UILabel!
    @IBOutlet private weak var deviceImageView: UIImageView!
    @IBOutlet private weak var deviceIdLabel: UILabel!
    @IBOutlet private weak var separatorBottomInsetLeftConstraint: NSLayoutConstraint!
    
    var separatorBottomInsetLeft: CGFloat = 0 {
        didSet {
            separatorBottomInsetLeftConstraint.constant = separatorBottomInsetLeft
        }
    }
    
    func configure(item: Device) {
        deviceNameLabel.text = item.deviceName
        deviceIdLabel.text = item.id
        configureConnectUI(item: item)
    }
    
    private func configureConnectUI(item: Device) {
        if item.isConnected {
            deviceImageView.image = item.getServiceConnectedImage
        } else {
            deviceImageView.image = item.getServiceDisconnectedImage
            deviceImageView.tintColor = .iconColorDefault
        }
    }
}
