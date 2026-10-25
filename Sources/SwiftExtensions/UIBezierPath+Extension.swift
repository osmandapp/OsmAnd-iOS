// Copyright © 2014–2026 OsmAnd. All rights reserved.

import UIKit

extension UIBezierPath {
    private static let radiansPerDegree = Float(Double.pi / 180)

    @objc func cubicToX(_ x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) {
        addCurve(to: CGPoint(x: CGFloat(x3), y: CGFloat(y3)),
                 controlPoint1: CGPoint(x: CGFloat(x1), y: CGFloat(y1)),
                 controlPoint2: CGPoint(x: CGFloat(x2), y: CGFloat(y2)))
    }

    @objc func arcTo(_ oval: CGRect, startAngle: Float, sweepAngle: Float) {
        appendArc(in: oval, startAngle: startAngle, sweepAngle: sweepAngle)
    }

    @objc func addArc(_ oval: CGRect, startAngle: Float, sweepAngle: Float) {
        appendArc(in: oval, startAngle: startAngle, sweepAngle: sweepAngle)
    }

    @objc func moveToX(_ x: CGFloat, y: CGFloat) {
        move(to: CGPoint(x: x, y: y))
    }

    @objc func lineToX(_ x: CGFloat, y: CGFloat) {
        addLine(to: CGPoint(x: x, y: y))
    }

    @objc func rLineToX(_ x: CGFloat, y: CGFloat) {
        addLine(to: CGPoint(x: currentPoint.x + x, y: currentPoint.y + y))
    }

    private func appendArc(in oval: CGRect, startAngle: Float, sweepAngle: Float) {
        let center = CGPoint(x: oval.midX, y: oval.midY)
        let width = oval.maxX - oval.minX
        let height = oval.maxY - oval.minY
        let radius = max(width, height) / 2
        let startRadians = CGFloat(startAngle * Self.radiansPerDegree)
        let endRadians = CGFloat((startAngle + sweepAngle) * Self.radiansPerDegree)

        if width == height {
            addArc(withCenter: center, radius: radius, startAngle: startRadians,
                   endAngle: endRadians, clockwise: sweepAngle > 0)
        } else {
            let transform: CGAffineTransform
            if width > height {
                transform = CGAffineTransform(scaleX: 1, y: height / width)
                    .translatedBy(x: 0, y: (width - height) * (height / width))
            } else {
                transform = CGAffineTransform(scaleX: width / height, y: 1)
                    .translatedBy(x: (height - width) * (width / height), y: 0)
            }
            guard let path = cgPath.mutableCopy() else { return }
            path.addArc(center: center, radius: radius, startAngle: startRadians,
                        endAngle: endRadians, clockwise: sweepAngle < 0, transform: transform)
            cgPath = path
        }
    }
}
