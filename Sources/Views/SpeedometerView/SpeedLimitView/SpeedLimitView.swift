//
//  SpeedLimitView.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 21.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//


final class SpeedLimitView: UIView {
    @IBOutlet private weak var withConstraint: NSLayoutConstraint!
    @IBOutlet private weak var valueSpeedLimitLabel: UILabel!
    @IBOutlet private weak var titleSpeedLimitLabel: UILabel! {
        didSet {
            titleSpeedLimitLabel.text = localizedString("shared_string_limit")
        }
    }
    
    private var widgetSizeStyle: EOAWidgetSizeStyle = .medium
    
    func configureWith(widgetSizeStyle: EOAWidgetSizeStyle, width: CGFloat) {
        self.widgetSizeStyle = widgetSizeStyle
        
        withConstraint.constant = width
        valueSpeedLimitLabel.font = UIFont.systemFont(ofSize: speedLimitValueFontSize, weight: .semibold)
    }
    
//    private func setupLimitView() {
//        let settings = OAAppSettings.sharedManager()!
//        let drivingRegion = settings.drivingRegion.get()
//        if drivingRegion == EOADrivingRegion.DR_US || drivingRegion == EOADrivingRegion.DR_CANADA  {
//            speedLimitImageView.image = .imgSpeedlimitNam
//        } else {
//            speedLimitImageView.image = .imgSpeedlimitEu
//        }
//    }
}

extension SpeedLimitView {
    private var speedLimitValueFontSize: CGFloat {
        switch widgetSizeStyle {
        case .small: 22
        case .medium: 33
        case .large: 50
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
}
