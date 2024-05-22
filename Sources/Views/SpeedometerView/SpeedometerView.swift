//
//  SpeedometerView.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 16.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class SpeedometerView: OATextInfoWidget {
    @IBOutlet private weak var centerPositionXConstraint: NSLayoutConstraint!
    @IBOutlet private weak var centerPositionYConstraint: NSLayoutConstraint!
    @IBOutlet private weak var leadingPositionConstraint: NSLayoutConstraint!
    @IBOutlet private weak var trailingPositionConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var contentStackView: UIStackView!
    
    @IBOutlet private weak var speedometerSpeedView: SpeedometerSpeedView! {
        didSet {
            speedometerSpeedView.isHidden = true
        }
    }
    
    @IBOutlet private weak var speedLimitEUView: SpeedLimitView! {
        didSet {
            speedLimitEUView.isHidden = true
        }
    }
    @IBOutlet private weak var speedLimitNAMView: SpeedLimitView! {
        didSet {
            speedLimitNAMView.isHidden = true
        }
    }
    
    let settings = OAAppSettings.sharedManager()!
    var style = EOAWidgetSizeStyle(rawValue: 2)!
    
    var isCarPlay = false
    var isPreview = false
    
    let speedViewWrapper = SpeedViewWrapper()
    
    static var initView: SpeedometerView? {
        UINib(nibName: String(describing: self), bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as? SpeedometerView
    }
    
    var speedLimitText: NSString? {
        speedViewWrapper.speedLimitText() as NSString?
    }
        
//    func updateWidgetSize() {
//        let maxHeightWidth = getCurrentSpeedViewMaxHeightWidth()
//        [speedometerSpeedView, speedLimitNAMView, speedLimitNAMView].forEach {
//            $0.heightEqualConstraint?.constant = maxHeightWidth
//            $0.widthEqualConstraint?.constant = maxHeightWidth
//        }
//    }
    
    func updateWidgetSizeTest() {
        widgetSizePref = settings.registerWidgetSizeStylePreference("updateWidgetSizeTest", defValue: style)
        updateWith(style: style, appMode: settings.applicationMode.get())
    }
    
    func configure() {
        isHidden = true
        updateWidgetSizeTest()

        let width = getCurrentSpeedViewMaxHeightWidth()
        speedometerSpeedView.configureWith(widgetSizeStyle: style, width: width)
        speedLimitEUView.configureWith(widgetSizeStyle: style, width: width)
        speedLimitNAMView.configureWith(widgetSizeStyle: style, width: width)

        centerPositionYConstraint.isActive = true
        if isPreview {
            centerPositionXConstraint.isActive = true
            leadingPositionConstraint.isActive = false
            trailingPositionConstraint.isActive = false
        } else {
            centerPositionXConstraint.isActive = false
            if isCarPlay {
                layer.cornerRadius = 10
                leadingPositionConstraint.isActive = false
                trailingPositionConstraint.isActive = true
            } else {
                layer.cornerRadius = 6
                leadingPositionConstraint.isActive = true
                trailingPositionConstraint.isActive = false
            }
        }
    }
    
    override func updateInfo() -> Bool {
        updateSpeedometerSpeedView()
        updateSpeedLimitView()
        isHidden = speedometerSpeedView.isHidden && speedLimitEUView.isHidden && speedLimitNAMView.isHidden
       
        return true
    }
    
    override var intrinsicContentSize: CGSize {
        let fittingSize = contentStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGSize(width: fittingSize.width, height: getCurrentSpeedViewMaxHeightWidth())
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
        
        if drivingRegion == EOADrivingRegion.DR_US || drivingRegion == EOADrivingRegion.DR_CANADA {
            if let value = speedLimitText as? String {
                speedLimitNAMView.isHidden = false
                speedLimitNAMView.updateWith(value: value)
            }
        } else {
            if let value = speedLimitText as? String {
                speedLimitEUView.isHidden = false
                speedLimitEUView.updateWith(value: value)
            }
        }
    }
    
    private func configureStackPosition() {
        guard isCarPlay else { return }
        if let itemView = contentStackView.subviews.first {
            contentStackView.removeArrangedSubview(itemView)
            contentStackView.setNeedsLayout()
            contentStackView.layoutIfNeeded()
            
            contentStackView.insertArrangedSubview(itemView, at: 1)
            contentStackView.setNeedsLayout()
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
