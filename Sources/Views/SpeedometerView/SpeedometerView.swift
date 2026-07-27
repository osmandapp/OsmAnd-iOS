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

    static var initView: SpeedometerView? {
        UINib(nibName: String(describing: self), bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as? SpeedometerView
    }
    
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
    
    var isDrivingRegionNAM: Bool {
        let drivingRegion = settings.drivingRegion.get()
        return drivingRegion == EOADrivingRegion.DR_US || drivingRegion == EOADrivingRegion.DR_CANADA
    }

    override var intrinsicContentSize: CGSize {
        let fittingSize = contentStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGSize(width: fittingSize.width, height: getCurrentSpeedViewMaxHeightWidth())
    }

    private lazy var speedViewWrapper = SpeedLimitWrapper()
    
    private var shouldShowSpeedometer: Bool {
        guard settings.showSpeedometer.get() else { return false }
        if isPreview || carPlayConfig != nil {
            return true
        }
        
        return !OARootViewController.instance().mapPanel.isContextMenuVisible()
    }
    
    override func isTextInfo() -> Bool {
        false
    }
    
    @discardableResult override func updateInfo() -> Bool {
        guard shouldShowSpeedometer else {
            isHidden = true
            return false
        }
        updateComponents()
        let speedLimitData = speedViewWrapper.speedLimitData()
        let speedLimit = Float(speedLimitData.value)
        let speedLimitText = speedLimitData.text
        let oldLimit = speedometerSpeedView.cachedSpeedLimit

        let shouldShowSpeedLimitSign = oldLimit == -1 && speedLimit != -1
        let shouldHideSpeedLimitSign = oldLimit != -1 && speedLimit == -1
        
        updateSpeedometerSpeedView(speedLimit: speedLimit)
        updateSpeedLimitView(speedLimit: Int(speedLimit),
                             speedLimitText: speedLimitText,
                             shouldShowSpeedLimitSign: shouldShowSpeedLimitSign,
                             shouldHideSpeedLimitSign: shouldHideSpeedLimitSign)
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
    
    private func updateSpeedLimitView(speedLimit: Int, speedLimitText: String?, shouldShowSpeedLimitSign: Bool, shouldHideSpeedLimitSign: Bool) {
        let speedLimitSignView: SpeedLimitView = isDrivingRegionNAM ? speedLimitNAMView : speedLimitEUView
        if speedLimit <= 0 {
            if shouldHideSpeedLimitSign {
                speedLimitSignView.fadeOut()
            } else {
                speedLimitSignView.isHidden = true
            }
        } else {
            setupSpeedLimitWith(view: speedLimitSignView,
                                speedLimit: speedLimit,
                                speedLimitText: speedLimitText,
                                shouldShowSpeedLimitSign: shouldShowSpeedLimitSign)
        }
    }
    
    private func setupSpeedLimitWith(view: SpeedLimitView,
                                     speedLimit: Int,
                                     speedLimitText: String?,
                                     shouldShowSpeedLimitSign: Bool) {
        if shouldShowSpeedLimitSign {
            view.fadeIn()
        }
        
        if speedLimit != -1 {
            view.updateWith(value: speedLimitText ?? "\(speedLimit)")
        }
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

private extension UIView {
    
    func fadeIn(duration: TimeInterval = 1.0) {
        guard isHidden || alpha < 1.0 else { return }
        
        alpha = 0
        isHidden = false

        UIView.animate(withDuration: duration) {
            self.alpha = 1.0
        }
    }

    func fadeOut(duration: TimeInterval = 1.0) {
        guard !isHidden, alpha > 0 else { return }
        
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.isHidden = true
        })
    }
}
