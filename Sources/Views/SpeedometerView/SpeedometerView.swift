//
//  SpeedometerView.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 16.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

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
    
    let settings = OAAppSettings.sharedManager()!
    
    var style = EOAWidgetSizeStyle(rawValue: 2)!
    var isCarPlay = false
    var isPreview = false
    
    static var initView: SpeedometerView? {
        UINib(nibName: String(describing: self), bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as? SpeedometerView
    }
    
    private lazy var speedViewWrapper = SpeedLimitWrapper()
    
    private var speedLimitText: NSString? {
        speedViewWrapper.speedLimitText() as NSString?
    }
    
    func updateWidgetSizeTest() {
        widgetSizePref = settings.registerWidgetSizeStylePreference("updateWidgetSizeTest", defValue: style)
        updateWith(style: style, appMode: settings.applicationMode.get())
    }
    
    func configure() {
        isHidden = false
        updateWidgetSizeTest()
        let isDirectionRTL = isDirectionRTL()
        contentStackView.semanticContentAttribute = isDirectionRTL ? .forceRightToLeft : .forceLeftToRight

        let width = getCurrentSpeedViewMaxHeightWidth()
        speedometerSpeedView.configureWith(widgetSizeStyle: style, width: width)
        speedLimitEUView.configureWith(widgetSizeStyle: style, width: width)
        speedLimitNAMView.configureWith(widgetSizeStyle: style, width: width)

        centerPositionYConstraint.isActive = true
        if isPreview {
            centerPositionXConstraint.isActive = true
            leftPositionConstraint.isActive = false
            rightPositionConstraint.isActive = false
        } else {
            centerPositionXConstraint.isActive = false
            if isCarPlay {
                layer.cornerRadius = 10
                // TODO: isCarPlay
                leftPositionConstraint.isActive = false
                rightPositionConstraint.isActive = true
            } else {
                layer.cornerRadius = 6
                leftPositionConstraint.isActive = true
                rightPositionConstraint.isActive = false
            }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        let fittingSize = contentStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGSize(width: fittingSize.width, height: getCurrentSpeedViewMaxHeightWidth())
    }
    
    override func updateInfo() -> Bool {
        updateSpeedometerSpeedView()
        updateSpeedLimitView()
        isHidden = speedometerSpeedView.isHidden && speedLimitEUView.isHidden && speedLimitNAMView.isHidden
       
        return true
    }
    
    private func updateSpeedometerSpeedView() {
        // TODO:
        if true {
            speedometerSpeedView.isHidden = false
            speedometerSpeedView.updateInfo()
        } else {
            speedometerSpeedView.isHidden = true
        }
    }
    
    private func updateSpeedLimitView() {
        guard let settings = OAAppSettings.sharedManager() else { return }
        let drivingRegion = settings.drivingRegion.get()
        
        speedLimitEUView.isHidden = true
        speedLimitNAMView.isHidden = true
        
//        speedLimitEUView.isHidden = false
//        speedLimitEUView.updateWith(value: "35")
        
        if drivingRegion == EOADrivingRegion.DR_US || drivingRegion == EOADrivingRegion.DR_CANADA {
            setupSpeedLimitWith(view: speedLimitNAMView)
//            if let value = speedLimitText as? String {
//                speedLimitNAMView.isHidden = false
//                speedLimitNAMView.updateWith(value: value)
//            }
        } else {
            setupSpeedLimitWith(view: speedLimitEUView)
//            if let value = speedLimitText as? String {
//                speedLimitEUView.isHidden = false
//                speedLimitEUView.updateWith(value: value)
//            }
        }
    }
    
    private func setupSpeedLimitWith(view: SpeedLimitView) {
        if let value = speedLimitText as? String {
            view.isHidden = false
            view.updateWith(value: value)
        }
    }
}

extension SpeedometerView {
    func getCurrentSpeedViewMaxHeightWidth() -> CGFloat {
        switch widgetSizeStyle {
        case .small: 56
        case .medium: 72
        case .large: 96
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
}
