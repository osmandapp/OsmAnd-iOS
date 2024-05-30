//
//  SpeedLimitView.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 21.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

enum SpeedLimitRegion {
    case EU, NAM
}

final class SpeedLimitView: UIView {
    @IBOutlet private weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var valueSpeedLimitLabel: UILabel!
    @IBOutlet private weak var titleSpeedLimitLabel: UILabel! {
        didSet {
            titleSpeedLimitLabel.text = localizedString("shared_string_limit").uppercased()
        }
    }
    @IBOutlet private weak var topStackViewConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomStackViewConstraint: NSLayoutConstraint!
    @IBOutlet private weak var leadingStackViewConstraint: NSLayoutConstraint!
    @IBOutlet private weak var trailingStackViewConstraint: NSLayoutConstraint!
    
    let previewValueDefault = "85"
    
    var speedLimitRegion: SpeedLimitRegion = .EU
    var isPreview = false
    
    private var widgetSizeStyle: EOAWidgetSizeStyle = .medium
    
    func configureWith(widgetSizeStyle: EOAWidgetSizeStyle, width: CGFloat) {
        self.widgetSizeStyle = widgetSizeStyle
        
        valueSpeedLimitLabel.font = UIFont.systemFont(ofSize: speedLimitValueFontSize, weight: .semibold)
        
        setupConstraints(width: width)
        
        if isPreview {
            updateWith(value: previewValueDefault)
            isHidden = OAAppSettings.sharedManager().showSpeedLimitWarning.get() == .whenExceeded
        }
        overrideUserInterfaceStyle = OAAppSettings.sharedManager().nightMode ? .dark : .light
    }
    
    func updateWith(value: String) {
        valueSpeedLimitLabel.text = value
    }
    
    private func setupConstraints(width: CGFloat) {
        widthConstraint.constant = width
        
        if case .NAM = speedLimitRegion {
            topStackViewConstraint.constant = topStackViewPadding
            bottomStackViewConstraint.constant = bottomStackViewPadding
            leadingStackViewConstraint.constant = leadingTrailingStackViewPadding
            trailingStackViewConstraint.constant = leadingStackViewConstraint.constant
        }
    }
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
    
    private var topStackViewPadding: CGFloat {
        switch widgetSizeStyle {
        case .small: 8
        case .medium: 13
        case .large: 15
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    private var bottomStackViewPadding: CGFloat {
        switch widgetSizeStyle {
        case .small: 8
        case .medium: 13
        case .large: 12
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    private var leadingTrailingStackViewPadding: CGFloat {
        switch widgetSizeStyle {
        case .small: 9
        case .medium: 13
        case .large: 14
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
}
