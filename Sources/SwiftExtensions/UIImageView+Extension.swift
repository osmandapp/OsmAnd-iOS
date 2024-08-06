//
//  UIImageView+Extension.swift
//  OsmAnd Maps
//
//  Created by Skalii. All rights reserved.
//

import Foundation

struct GradientPoint {
   var location: CGFloat
   var color: UIColor
}

extension UIImageView {

    func gradated(_ gradientPoints: [GradientPoint]) {
        removeGradation()

        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        gradientMaskLayer.colors = gradientPoints.map { $0.color.cgColor }
        gradientMaskLayer.locations = gradientPoints.map { $0.location as NSNumber }
        gradientMaskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientMaskLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradientMaskLayer, at: 0)
    }

    @objc func removeGradation() {
        if let sublayers = layer.sublayers {
            for subLayer in sublayers where subLayer is CAGradientLayer {
                subLayer.removeFromSuperlayer()
            }
        }
    }
}
