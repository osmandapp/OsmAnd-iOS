//
//  InclinometerLevelView.swift
//  OsmAnd Maps
//
//  Created by Eugene Zmeuk on 02.11.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

/// Bubble level for the inclinometer calibration screen: a circle with a crosshair and a ball
/// that rolls towards the lowered side of the vehicle. The ball is drawn in the level colour while
/// both angles are within `levelToleranceDegrees`, otherwise in the tilted colour.
final class InclinometerLevelView: UIView {

    private static let fullScaleDegrees: CGFloat = 30
    private static let levelToleranceDegrees: CGFloat = 2
    private static let ballRadius: CGFloat = 12

    var outlineColor: UIColor = .iconColorSecondary { didSet { setNeedsDisplay() } }
    var targetColor: UIColor = .iconColorActive { didSet { setNeedsDisplay() } }
    var levelColor: UIColor = UIColor(rgb: 0x5BAF3F) { didSet { setNeedsDisplay() } }
    var tiltedColor: UIColor = UIColor(rgb: 0xF0B400) { didSet { setNeedsDisplay() } }

    private var pitch: CGFloat = 0
    private var roll: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }

    func setInclination(pitch: Float, roll: Float) {
        self.pitch = CGFloat(pitch)
        self.roll = CGFloat(roll)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let outlineWidth: CGFloat = 1.5
        let radius = min(bounds.width, bounds.height) / 2 - outlineWidth
        if radius <= Self.ballRadius {
            return
        }

        context.setLineWidth(outlineWidth)
        context.setStrokeColor(outlineColor.cgColor)
        context.strokeEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))

        context.setLineWidth(1)
        context.move(to: CGPoint(x: center.x - radius, y: center.y))
        context.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        context.move(to: CGPoint(x: center.x, y: center.y - radius))
        context.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        context.strokePath()

        let targetRadius = Self.ballRadius + 4
        context.setStrokeColor(targetColor.cgColor)
        context.setLineDash(phase: 0, lengths: [3, 3])
        context.strokeEllipse(in: CGRect(x: center.x - targetRadius, y: center.y - targetRadius, width: targetRadius * 2, height: targetRadius * 2))
        context.setLineDash(phase: 0, lengths: [])

        // The ball rolls to the lowered side: right for positive roll, back (down) for a raised front
        let travel = radius - Self.ballRadius
        var dx = roll / Self.fullScaleDegrees * travel
        var dy = pitch / Self.fullScaleDegrees * travel
        let distance = hypot(dx, dy)
        if distance > travel {
            dx *= travel / distance
            dy *= travel / distance
        }
        let level = abs(pitch) <= Self.levelToleranceDegrees && abs(roll) <= Self.levelToleranceDegrees
        context.setFillColor((level ? levelColor : tiltedColor).cgColor)
        context.fillEllipse(in: CGRect(x: center.x + dx - Self.ballRadius, y: center.y + dy - Self.ballRadius,
                                       width: Self.ballRadius * 2, height: Self.ballRadius * 2))
    }
}
