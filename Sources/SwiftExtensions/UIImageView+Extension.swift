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
        removeGradientLayers()

        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        gradientMaskLayer.colors = gradientPoints.map { $0.color.cgColor }
        gradientMaskLayer.locations = gradientPoints.map { $0.location as NSNumber }
        gradientMaskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientMaskLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradientMaskLayer, at: 0)
    }

    @objc func removeGradientLayers() {
        layer.sublayers?
            .compactMap { $0 as? CAGradientLayer }
            .forEach { $0.removeFromSuperlayer() }
    }
}

extension UIImage {

    /// Returns a new image by drawing a circular border over the current image.
    /// The image is assumed to be square and already clipped to a circle.
    ///
    /// - Parameters:
    ///   - borderWidth: Width of the border in points.
    ///   - borderColor: Color of the border.
    /// - Returns: New UIImage with the drawn border.
    func withCircularBorder(
        borderWidth: CGFloat,
        borderColor: UIColor
    ) -> UIImage {

        let size = self.size

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)

            // Draw original image
            self.draw(in: rect)

            // Draw circular border
            let inset = borderWidth / 2
            let borderRect = rect.insetBy(dx: inset, dy: inset)
            let radius = min(borderRect.width, borderRect.height) / 2

            let path = UIBezierPath(
                roundedRect: borderRect,
                cornerRadius: radius
            )
            path.lineWidth = borderWidth
            borderColor.setStroke()
            path.stroke()
        }
    }
}

