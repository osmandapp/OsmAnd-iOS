//
//  ShadowPathView.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 11.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers 
class ShadowPathView: UIView {
    
    @objc enum ShadowPathDirection: Int {
        case top, bottom, clear
    }
    
    var direction: ShadowPathDirection = .top {
        didSet {
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
         super.layoutSubviews()
        
        if case .clear = direction {
            removeShadow()
            return
        }

        layer.shadowRadius = 4
        layer.shadowOpacity = 0.5
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        switch direction {
        case .top:
            layer.shadowPath = UIBezierPath(rect: CGRect(x: 0,
                                                         y: bounds.minY - layer.shadowRadius,
                                                         width: bounds.width,
                                                         height: layer.shadowRadius)).cgPath
        case .bottom:
            layer.shadowPath = UIBezierPath(rect: CGRect(x: 0,
                                                         y: bounds.maxY - layer.shadowRadius,
                                                         width: bounds.width,
                                                         height: layer.shadowRadius)).cgPath
        default: break
        }
     }
    
    private func removeShadow() {
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowColor = UIColor.clear.cgColor
        layer.cornerRadius = 0.0
        layer.shadowRadius = 0.0
        layer.shadowOpacity = 0.0
    }
 }
