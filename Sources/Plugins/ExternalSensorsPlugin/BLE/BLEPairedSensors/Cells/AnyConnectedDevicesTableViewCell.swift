//
//  AnyConnectedDevicesTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 29.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

final class AnyConnectedDevice: Device {
    
}

final class AnyConnectedDevicesTableViewCell: UITableViewCell {
    @IBOutlet private weak var deviceImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    
    private lazy var accessoryImageView: UIImageView = {
        let imgView = UIImageView(frame: .init(x: 0, y: 0, width: 30, height: 30))
        imgView.image = UIImage(named: "ic_checkmark_default")!
        return imgView
    }()
    
    func configure(anyConnectedDevice: AnyConnectedDevice, widgetType: WidgetType, title: String) {
        switch widgetType {
        case .heartRate:
            deviceImageView.image = UIImage(named: "ic_custom_sensor_heart_rate_outlined")
        default:
            break
        }
        titleLabel.text = title
        if anyConnectedDevice.isSelected {
            accessoryView = accessoryImageView
            deviceImageView.tintColor = UIColor.iconColorActive
        } else {
            deviceImageView.tintColor = UIColor.iconColorDefault
            accessoryView = nil
            accessoryType = .none
        }
    }
}
