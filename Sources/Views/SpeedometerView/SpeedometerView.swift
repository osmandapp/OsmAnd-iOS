//
//  SpeedometerView.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 16.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
final class CarPlayConfig: NSObject {
    var isLeftSideDriving = false
}

@objcMembers
final class SpeedometerView: OATextInfoWidget {
    
    @IBOutlet private weak var centerPositionXConstraint: NSLayoutConstraint!
    @IBOutlet private weak var centerPositionYConstraint: NSLayoutConstraint!
    @IBOutlet private weak var leftPositionConstraint: NSLayoutConstraint!
    @IBOutlet private weak var rightPositionConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var contentStackView: UIStackView!
    
    @IBOutlet private weak var speedometerSpeedView: SpeedometerSpeedView! {
        didSet {
            speedometerSpeedView.isHidden = true
        }
    }
    @IBOutlet private weak var speedLimitEUView: SpeedLimitView! {
        didSet {
            speedLimitEUView.speedLimitRegion = .EU
            speedLimitEUView.isHidden = true
        }
    }
    @IBOutlet private weak var speedLimitNAMView: SpeedLimitView! {
        didSet {
            speedLimitNAMView.speedLimitRegion = .NAM
            speedLimitNAMView.isHidden = true
        }
    }
    let settings = OAAppSettings.sharedManager()
    var sizeStyle: EOAWidgetSizeStyle = .medium
    var didChangeIsVisible: (() -> Void)?
    
    var carPlayConfig: CarPlayConfig?
    var isPreview = false
    
    static var initView: SpeedometerView? {
        UINib(nibName: String(describing: self), bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as? SpeedometerView
    }
    
    var isDrivingRegionNAM: Bool {
        let drivingRegion = settings.drivingRegion.get()
        return drivingRegion == EOADrivingRegion.DR_US || drivingRegion == EOADrivingRegion.DR_CANADA
    }
    
    private lazy var speedViewWrapper = SpeedLimitWrapper()
    
    override var intrinsicContentSize: CGSize {
        let fittingSize = contentStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGSize(width: fittingSize.width, height: getCurrentSpeedViewMaxHeightWidth())
    }
    
    override func isTextInfo() -> Bool {
        false
    }
    
    @discardableResult
    override func updateInfo() -> Bool {
        guard settings.showSpeedometer.get() else {
            isHidden = true
            return false
        }
        updateComponents()
        let speedLimit: Float = Float(speedViewWrapper.speedLimit())
        updateSpeedometerSpeedView(speedLimit: speedLimit)
        updateSpeedLimitView(speedLimit: Int(speedLimit))
        var isChangedVisible = false
        if !speedometerSpeedView.isHidden && isHidden {
            isChangedVisible = true
        }
        isHidden = speedometerSpeedView.isHidden
        if isChangedVisible {
            didChangeIsVisible?()
        }
        
        return true
    }
    
    func configure() {
        sizeStyle = settings.speedometerSize.get()
        
        updateComponents()
        
        centerPositionYConstraint.isActive = true
        if isPreview {
            isHidden = false
            speedometerSpeedView.layer.cornerRadius = 6
            speedometerSpeedView.configureShadow()
            configureContentStackViewSemanticContentAttribute()
            centerPositionXConstraint.isActive = true
            leftPositionConstraint.isActive = false
            rightPositionConstraint.isActive = false
            configureUserInterfaceStyleWithMapTheme()
        } else {
            isHidden = true
            centerPositionXConstraint.isActive = false
            if let carPlayConfig {
                speedometerSpeedView.layer.cornerRadius = 10
                speedometerSpeedView.animationOrigin = carPlayConfig.isLeftSideDriving ? .left : .right
                contentStackView.semanticContentAttribute = carPlayConfig.isLeftSideDriving ? .forceRightToLeft : .forceLeftToRight
                speedometerSpeedView.configureTextAlignmentContent(isTextAlignmentRight: carPlayConfig.isLeftSideDriving)
                if carPlayConfig.isLeftSideDriving {
                    contentAlignment(isRight: true)
                } else {
                    contentAlignment(isRight: false)
                }
            } else {
                configureContentStackViewSemanticContentAttribute()
                speedometerSpeedView.layer.cornerRadius = 6
                speedometerSpeedView.animationOrigin = isDirectionRTL() ? .left : .right
                speedometerSpeedView.configureShadow()
                leftPositionConstraint.isActive = true
                rightPositionConstraint.isActive = false
                configureUserInterfaceStyleWithMapTheme()
            }
        }
    }
    
    func configureUserInterfaceStyleWith(style: UIUserInterfaceStyle) {
        overrideUserInterfaceStyle = style
        let borderColor: UIColor = style == .light ? .widgetAutoBgStroke.light : .widgetAutoBgStroke.dark
        speedometerSpeedView.layer.borderWidth = 1.0
        speedometerSpeedView.layer.borderColor = borderColor.cgColor
    }
    
    func contentAlignment(isRight: Bool) {
        if isRight {
            rightPositionConstraint.isActive = true
            leftPositionConstraint.isActive = false
        } else {
            leftPositionConstraint.isActive = true
            rightPositionConstraint.isActive = false
        }
    }
    
    private func configureContentStackViewSemanticContentAttribute() {
        contentStackView.semanticContentAttribute = isDirectionRTL() ? .forceRightToLeft : .forceLeftToRight
    }
    
    private func configureUserInterfaceStyleWithMapTheme() {
        overrideUserInterfaceStyle = OAAppSettings.sharedManager().nightMode ? .dark : .light
    }
    
    private func updateComponents() {
        let width = getCurrentSpeedViewMaxHeightWidth()
        speedometerSpeedView.isPreview = isPreview
        speedometerSpeedView.configureWith(widgetSizeStyle: sizeStyle, width: width)
        if isDrivingRegionNAM {
            speedLimitNAMView.isPreview = isPreview
            speedLimitNAMView.configureWith(widgetSizeStyle: sizeStyle, width: width)
        } else {
            speedLimitEUView.isPreview = isPreview
            speedLimitEUView.configureWith(widgetSizeStyle: sizeStyle, width: width)
        }
    }
    
    private func updateSpeedometerSpeedView(speedLimit: Float) {
        speedometerSpeedView.updateInfo(speedLimit: speedLimit)
    }
    
    private func updateSpeedLimitView(speedLimit: Int) {
        speedLimitEUView.isHidden = true
        speedLimitNAMView.isHidden = true
        
        setupSpeedLimitWith(view: isDrivingRegionNAM ? speedLimitNAMView : speedLimitEUView, speedLimit: speedLimit)
    }
    
    private func setupSpeedLimitWith(view: SpeedLimitView, speedLimit: Int) {
        guard speedLimit > -1 else {
            view.isHidden = true
            return
        }
        let value = String(speedLimit)
        view.isHidden = false
        view.updateWith(value: value)
    }
}

extension SpeedometerView {
    func getCurrentSpeedViewMaxHeightWidth() -> CGFloat {
        switch sizeStyle {
        case .small: 56
        case .medium: 72
        case .large: 96
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
}

/**
 * Defines the visual state of the Speedometer widget based on the current speed.
 * Each case provides the necessary set of colors for the background, speed value, and units
 * by loading them from the Asset Catalogue.
 */
enum SpeedometerState {
    case normal           // Default appearance, no speeding.
    case tolerance        // Speed is within the tolerance threshold of the limit.
    case exceedingLimit   // Speed limit has been exceeded.
    
    /// Returns the background color for the speedometerSpeedView.
    var backgroundColor: UIColor {
        switch self {
        case .normal: .widgetBg
        case .tolerance: .speedometerToleranceBg
        case .exceedingLimit: .speedometerLimitBg
        }
    }
    
    /// Returns the color for the main speed value (the numbers).
    var valueColor: UIColor {
        switch self {
        case .normal: .widgetValue
        case .tolerance: .speedometerToleranceValue
        case .exceedingLimit: .speedometerLimitValue
        }
    }
    
    /// Returns the color for the units text (e.g., "km/h" or "mph").
    var unitsColor: UIColor {
        switch self {
        case .normal: .widgetUnits
        case .tolerance: .speedometerToleranceUnits
        case .exceedingLimit: .speedometerLimitUnits
        }
    }
}
