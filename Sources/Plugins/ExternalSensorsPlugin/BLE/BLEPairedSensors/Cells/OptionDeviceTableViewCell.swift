//
//  OptionDeviceTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 29.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

final class OptionDevice: Device {
    enum SelectedOptionDevice: Int {
        case none, anyConnected
    }
    
    var option: SelectedOptionDevice = .none
}

final class OptionDeviceTableViewCell: UITableViewCell {
    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet private weak var topSeparatorHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomSeparatorView: UIView!
    @IBOutlet private weak var bottomSeparatorHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var deviceImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    
    @IBOutlet private weak var separatorBottomInsetLeftConstraint: NSLayoutConstraint!
    
    var separatorBottomInsetLeft: CGFloat = 0 {
        didSet {
            separatorBottomInsetLeftConstraint.constant = separatorBottomInsetLeft
        }
    }
    
    private lazy var accessoryImageView: UIImageView = {
        let imgView = UIImageView(frame: .init(x: 0, y: 0, width: 30, height: 30))
        imgView.image = UIImage(named: "ic_checkmark_default")
        return imgView
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        topSeparatorView.backgroundColor = .adaptiveSeparator
        bottomSeparatorView.backgroundColor = .adaptiveSeparator
        topSeparatorHeightConstraint.constant = UIScreen.adaptiveSeparatorThickness
        bottomSeparatorHeightConstraint.constant = UIScreen.adaptiveSeparatorThickness
    }
    
    func configure(optionDevice: OptionDevice, widgetType: WidgetType, title: String) {
        backgroundColor = UIColor.groupBg
        if optionDevice.option == .anyConnected {
            if let iconName = widgetType.disabledIconName {
                deviceImageView.image = UIImage(named: iconName)
            }
        } else if optionDevice.option == .none {
            deviceImageView.image = UIImage(named: "ic_custom_trip_hide")
        }

        titleLabel.text = title
        if optionDevice.isSelected {
            accessoryView = accessoryImageView
            deviceImageView.tintColor = UIColor.iconColorActive
        } else {
            deviceImageView.tintColor = UIColor.iconColorDefault
            accessoryView = nil
            accessoryType = .none
        }
    }
}
