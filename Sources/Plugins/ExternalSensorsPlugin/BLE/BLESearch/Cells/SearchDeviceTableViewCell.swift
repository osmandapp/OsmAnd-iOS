//
//  SearchDeviceTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 22.09.2023.
//

import UIKit

class SearchDeviceTableViewCell: UITableViewCell {
    @IBOutlet private weak var deviceNameLabel: UILabel!
    @IBOutlet private weak var deviceImageView: UIImageView!
    @IBOutlet private weak var signalIndicatorImageView: UIImageView!
    @IBOutlet private weak var connectStatusLabel: UILabel!
    @IBOutlet private weak var separatorBottomInsetLeftConstraint: NSLayoutConstraint!
    
    var separatorBottomInsetLeft: CGFloat = 0 {
        didSet {
            separatorBottomInsetLeftConstraint.constant = separatorBottomInsetLeft
        }
    }
    
    func configure(item: Device) {
        deviceNameLabel.text = item.deviceName
        configureConnectUI(item: item)
    }
    
    private func configureConnectUI(item: Device) {
        if item.isConnected {
            connectStatusLabel.text = localizedString("external_device_status_connected")
            signalIndicatorImageView.tintColor = UIColor.buttonBgColorPrimary
            signalIndicatorImageView.configureSignalImage(signal: item.rssi)
            deviceImageView.image = item.getServiceConnectedImage
        } else {
            connectStatusLabel.text = localizedString("external_device_status_disconnected")
            signalIndicatorImageView.tintColor = UIColor.iconColorSecondary
            signalIndicatorImageView.image = UIImage(named: "ic_small_signal_not_found")
            deviceImageView.image = item.getServiceConnectedImage.noir
        }
    }
}

extension UIImageView {
    func configureSignalImage(signal: Int) {
        var signalLevelIcon = ""
        switch abs(signal) {
        case 0...70:
            signalLevelIcon = "ic_small_signal_4"
        case 70..<80:
            signalLevelIcon = "ic_small_signal_3"
        case 80...90:
            signalLevelIcon = "ic_small_signal_2"
        case 90...100:
            signalLevelIcon = "ic_small_signal_1"
        default:
            signalLevelIcon = "ic_small_signal_not_found"
        }
        image = UIImage(named: signalLevelIcon)
    }
}
