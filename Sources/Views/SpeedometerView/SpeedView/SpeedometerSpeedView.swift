//
//  SpeedometerSpeedView.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 20.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

final class SpeedometerSpeedView: UIView {
    @IBOutlet private weak var topConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var withConstraint: NSLayoutConstraint!
    @IBOutlet private weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var valueSpeedLabel: UILabel!
    @IBOutlet private weak var unitSpeedLabel: UILabel!
    
    let LOW_SPEED_THRESHOLD_MPS = 6.0
    let UPDATE_THRESHOLD_MPS = 0.1
    let LOW_SPEED_UPDATE_THRESHOLD_MPS = 0.015 // Update more often while walking/running
    
    private var widgetSizeStyle: EOAWidgetSizeStyle = .medium
    private var cachedSpeed = 0.0
    private var cachedMetricSystem = -1
    
    func configureWith(widgetSizeStyle: EOAWidgetSizeStyle, width: CGFloat) {
        self.widgetSizeStyle = widgetSizeStyle
        layer.masksToBounds = false
        withConstraint.constant = width
        valueSpeedLabel.font = UIFont.systemFont(ofSize: speedValueFontSize, weight: .semibold)
        configureConstraints()
    }
    
    func updateInfo() {
        guard OARoutingHelper.sharedInstance().isFollowingMode() else {
            valueSpeedLabel.text = "-"
            return
        }
        if let lastKnownLocation = OsmAndApp.swiftInstance().locationServices?.lastKnownLocation {
            let currentSpeed = lastKnownLocation.speed
            if currentSpeed >= 0 {
                let updateThreshold = cachedSpeed < LOW_SPEED_THRESHOLD_MPS ? LOW_SPEED_UPDATE_THRESHOLD_MPS : UPDATE_THRESHOLD_MPS
                
                if isUpdateNeeded() || abs(currentSpeed - cachedSpeed) > updateThreshold {
                    cachedSpeed = currentSpeed
                    let valueUnitArray: NSMutableArray = []
                    OAOsmAndFormatter.getFormattedSpeed(Float(currentSpeed), valueUnitArray: valueUnitArray)
                    if let result = getValueAndUnit(with: valueUnitArray) {
                        valueSpeedLabel.text = result.value
                        unitSpeedLabel.text = result.unit
                    }
                }
            } else if cachedSpeed != 0 {
                cachedSpeed = 0
                valueSpeedLabel.text = "-"
            }
        }
    }
    
    private func isUpdateNeeded() -> Bool {
        var res = false
        if let metricSystem: EOAMetricsConstant = OAAppSettings.sharedManager()?.metricSystem.get() {
            res = cachedMetricSystem != metricSystem.rawValue
            if res {
                cachedMetricSystem = metricSystem.rawValue
            }
        }
        return res
    }
    
    private func getValueAndUnit(with valueUnitArray: NSMutableArray) -> (value: String, unit: String)? {
        guard valueUnitArray.count == 2,
              let value = valueUnitArray[0] as? String,
              let unit = valueUnitArray[1] as? String else {
            return nil
        }
        return (value: value, unit: unit)
    }
    
    private func configureConstraints() {
        topConstraint.constant = speedValueTopPadding
        bottomConstraint.constant = speedValueBottomPadding
        leadingConstraint.constant = speedValueLeadingTrailingPadding
        trailingConstraint.constant = leadingConstraint.constant
        stackView.spacing = speedValueStackViewSpacing
    }
}

extension SpeedometerSpeedView {
    private var speedValueTopPadding: CGFloat {
        switch widgetSizeStyle {
        case .small, .medium: 3
        case .large: 6
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    private var speedValueBottomPadding: CGFloat {
        switch widgetSizeStyle {
        case .small: 8
        case .medium: 9
        case .large: 12
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    private var speedValueLeadingTrailingPadding: CGFloat {
        switch widgetSizeStyle {
        case .small: 10
        case .medium, .large: 12
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    private var speedValueStackViewSpacing: CGFloat {
        switch widgetSizeStyle {
        case .small: 3
        case .medium, .large: 6
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    private var speedValueFontSize: CGFloat {
        switch widgetSizeStyle {
        case .small: 22
        case .medium: 33
        case .large: 50
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
}
