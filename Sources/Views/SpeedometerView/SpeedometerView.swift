//
//  SpeedometerView.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 16.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

extension SpeedometerView {
    static func getCurrentSpeedViewMaxHeightWidthFor(type: EOAWidgetSizeStyle) -> Float {
        switch type {
        case .small: 56
        case .medium: 72
        case .large: 96
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
}

final class SpeedometerView: UIView {
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
    @IBOutlet private weak var speedLimitNAMView: UIView!{
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
    
//    private func setupCarPlayConstraints() {
//        centerPositionXConstraint.isActive = true
//        leadingPositionConstraint.isActive = false
//        trailingPositionConstraint.isActive = false
//    }
//    
//    private func setupPreviewConstraints() {
//        centerPositionXConstraint.isActive = true
//        leadingPositionConstraint.isActive = false
//        trailingPositionConstraint.isActive = false
//    }
    
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
