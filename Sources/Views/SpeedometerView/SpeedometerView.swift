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
    // swiftlint:disable force_unwrapping
    let settings = OAAppSettings.sharedManager()!
    // swiftlint:enable force_unwrapping

    var sizeStyle: EOAWidgetSizeStyle = .medium
    var didChangeIsVisible: (() -> Void)?
   
    var isCarPlay = false
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
    
    private var speedLimitText: NSString? {
        speedViewWrapper.speedLimitText() as NSString?
    }
    
    override var intrinsicContentSize: CGSize {
        let fittingSize = contentStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGSize(width: fittingSize.width, height: getCurrentSpeedViewMaxHeightWidth())
    }

    override func updateInfo() -> Bool {
        guard settings.showSpeedometer.get() else {
            isHidden = true
            return false
        }
        updateComponents()
        updateSpeedometerSpeedView()
        updateSpeedLimitView()
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
        overrideUserInterfaceStyle = OAAppSettings.sharedManager().nightMode ? .dark : .light
        
        let isDirectionRTL = isDirectionRTL()
        contentStackView.semanticContentAttribute = isDirectionRTL ? .forceRightToLeft : .forceLeftToRight
        
        updateComponents()

        centerPositionYConstraint.isActive = true
        if isPreview {
            isHidden = false
            centerPositionXConstraint.isActive = true
            leftPositionConstraint.isActive = false
            rightPositionConstraint.isActive = false
        } else {
            isHidden = true
            centerPositionXConstraint.isActive = false
            if isCarPlay {
                layer.cornerRadius = 10
                // TODO: isCarPlay https://github.com/osmandapp/OsmAnd-iOS/issues/3668
                leftPositionConstraint.isActive = false
                rightPositionConstraint.isActive = true
            } else {
                layer.cornerRadius = 6
                leftPositionConstraint.isActive = true
                rightPositionConstraint.isActive = false
            }
        }
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
    
    private func updateSpeedometerSpeedView() {
        speedometerSpeedView.updateInfo()
    }
    
    private func updateSpeedLimitView() {
        speedLimitEUView.isHidden = true
        speedLimitNAMView.isHidden = true
        
        setupSpeedLimitWith(view: isDrivingRegionNAM ? speedLimitNAMView : speedLimitEUView)
    }
    
    private func setupSpeedLimitWith(view: SpeedLimitView) {
        guard let value = speedLimitText as? String else { 
            view.isHidden = true
            return
        }
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
