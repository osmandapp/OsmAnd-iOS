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
    
    @IBOutlet private weak var speedView: UIView!
    @IBOutlet private weak var valueSpeedLabel: UILabel!
    @IBOutlet private weak var unitSpeedLabel: UILabel!
    
    @IBOutlet private weak var speedLimitEUView: UIView! {
        didSet {
            speedLimitEUView.isHidden = true
        }
    }
    @IBOutlet private weak var speedLimitNAMView: UIView! {
        didSet {
            speedLimitNAMView.isHidden = true
        }
    }
    @IBOutlet private weak var unitSpeedLimitNAMLabel: UILabel! {
        didSet {
            unitSpeedLimitNAMLabel.text = localizedString("shared_string_maximum")
        }
    }
    @IBOutlet private weak var valueSpeedLimitLabel: UILabel!
    
    var isCarPlay = false
    var isPreview = false
    
//    var currentSpeedWidth: Float {
//        static func getCurrentSpeedWidthFor(type: EOAWidgetSizeStyle) -> CGFloat {
//            switch type {
//            case .small, .medium, .large: 11
//            @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
//            }
//        }
//    }
    
    class SpeedometerViewConfig {
        //enum case
    }
    
    static var initView: SpeedometerView? {
        UINib(nibName: String(describing: self), bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as? SpeedometerView
    }
        
    func updateWidgetSize() {
        let maxHeightWidth = getCurrentSpeedViewMaxHeightWidth()
        [speedView, speedLimitNAMView, speedLimitNAMView].forEach {
            $0.heightEqualConstraint?.constant = maxHeightWidth
            $0.widthEqualConstraint?.constant = maxHeightWidth
        }
    }
    
    func updateWidgetSizeTest() {
        //[[OAAppSettings sharedManager] registerWidgetSizeStylePreference:prefId defValue:EOAWidgetSizeStyleMedium]
        let settings = OAAppSettings.sharedManager()!
        widgetSizePref = settings.registerWidgetSizeStylePreference("updateWidgetSizeTest", defValue: EOAWidgetSizeStyle(rawValue: 1)!)
        updateWith(style: EOAWidgetSizeStyle(rawValue: 0)!, appMode: settings.applicationMode.get())
        updateWidgetSize()
        layoutIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.updateWith(style: EOAWidgetSizeStyle(rawValue: 1)!, appMode: settings.applicationMode.get())
            self.updateWidgetSize()
            self.layoutIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.updateWith(style: EOAWidgetSizeStyle(rawValue: 2)!, appMode: settings.applicationMode.get())
                self.updateWidgetSize()
                self.layoutIfNeeded()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
//    override func invalidateIntrinsicContentSize() {
//        getCurrentSpeedViewMaxHeightWidth()
//    }
    
    override var intrinsicContentSize: CGSize {
        let size = getCurrentSpeedViewMaxHeightWidth()
        let fittingSize = contentStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGSize(width: fittingSize.width, height: fittingSize.height)
    }
    
    func configure() {
        centerPositionYConstraint.isActive = true
        if isPreview {
            centerPositionXConstraint.isActive = true
            leadingPositionConstraint.isActive = false
            trailingPositionConstraint.isActive = false
        } else {
            centerPositionXConstraint.isActive = false
            if isCarPlay {
                speedView.layer.cornerRadius = 10
                leadingPositionConstraint.isActive = false
                trailingPositionConstraint.isActive = true
            } else {
                speedView.layer.cornerRadius = 6
                leadingPositionConstraint.isActive = true
                trailingPositionConstraint.isActive = false
            }
        }
        // TODO: property 
        speedLimitEUView.isHidden = false
        // EU – img_speedlimit_eu
        // USA, Canada – img_speedlimit_nam
        
        configureStackPosition()
    }
    
    override func updateInfo() -> Bool {
        // TODO:
        return true
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
