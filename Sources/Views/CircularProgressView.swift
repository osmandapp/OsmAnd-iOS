//
//  CircularProgressView.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 03.09.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//
//  1:1 Swift port of the third-party FFCircularProgressView
//  (FFCircularProgressBar, Fabiano Francesconi, 2013).
//

import UIKit
import QuartzCore

final class CircularProgressView: UIView {

    private let kArrowSizeRatio: CGFloat = 0.12
    private let kStopSizeRatio: CGFloat = 0.3
    private let kTickWidthRatio: CGFloat = 0.3

    private let progressBackgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let iconLayer = CAShapeLayer()

    private var _progress: CGFloat = 0
    private var _lineWidth: CGFloat = 0
    private var _tintColor: UIColor?
    private var _iconView: UIView?

    /// The progress of the view.
    var progress: CGFloat {
        get { _progress }
        set {
            var progress = newValue
            if progress > 1.0 { progress = 1.0 }

            if _progress != progress {
                _progress = progress

                if _progress == 1.0 {
                    animateProgressBackgroundLayerFillColor()
                }

                if _progress == 0.0 {
                    progressBackgroundLayer.fillColor = backgroundColor?.cgColor
                }

                setNeedsDisplay()
            }
        }
    }

    /// The width of the line used to draw the progress view.
    var lineWidth: CGFloat {
        get { _lineWidth }
        set {
            _lineWidth = max(newValue, 1.0)

            progressBackgroundLayer.lineWidth = _lineWidth
            progressLayer.lineWidth = _lineWidth * 2.0
            iconLayer.lineWidth = _lineWidth
        }
    }

    /// The color of the progress view.
    override var tintColor: UIColor! {
        get { _tintColor }
        set {
            _tintColor = newValue
            progressBackgroundLayer.strokeColor = newValue?.cgColor
            progressLayer.strokeColor = newValue?.cgColor
            iconLayer.strokeColor = newValue?.cgColor
        }
    }

    /// The color of the tick view.
    var tickColor: UIColor = .white

    /// Icon view to be rendered instead of default arrow.
    var iconView: UIView? {
        get { _iconView }
        set {
            _iconView?.removeFromSuperview()
            _iconView = newValue
            if let newValue {
                addSubview(newValue)
            }
        }
    }

    /// Bezier path to be rendered instead of icon view or default arrow.
    var iconPath: UIBezierPath?

    /// You can hide the icons which are shown during progress.
    var hideProgressIcons: Bool = false

    /// Make the background layer to spin around its center.
    var isSpinning: Bool = false

    /// Fraction (0.05...1) of the full circle drawn for the spinning background arc.
    /// Default `0.9` reproduces the original FFCircularProgressView behaviour (1.8π sweep).
    var spinningArcFraction: CGFloat = 0.9 {
        didSet {
            spinningArcFraction = min(max(spinningArcFraction, 0.05), 1.0)
            if isSpinning {
                setNeedsDisplay()
            }
        }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear

        _lineWidth = max(frame.size.width * 0.025, 1.0)
        _tintColor = UIColor(red: 0, green: 122.0 / 255.0, blue: 1.0, alpha: 1.0) // ios7Blue
        tickColor = .white

        progressBackgroundLayer.strokeColor = _tintColor?.cgColor
        progressBackgroundLayer.fillColor = backgroundColor?.cgColor
        progressBackgroundLayer.lineCap = .round
        progressBackgroundLayer.lineWidth = _lineWidth
        layer.addSublayer(progressBackgroundLayer)

        progressLayer.strokeColor = _tintColor?.cgColor
        progressLayer.fillColor = nil
        progressLayer.lineCap = .square
        progressLayer.lineWidth = _lineWidth * 2.0
        layer.addSublayer(progressLayer)

        iconLayer.strokeColor = _tintColor?.cgColor
        iconLayer.fillColor = nil
        iconLayer.lineCap = .butt
        iconLayer.lineWidth = _lineWidth
        iconLayer.fillRule = .nonZero
        layer.addSublayer(iconLayer)
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        // Make sure the layers cover the whole view
        progressBackgroundLayer.frame = bounds
        progressLayer.frame = bounds
        iconLayer.frame = bounds

        let center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        // (ObjC computes an unused `radius = (bounds.width - lineWidth) / 2` here - dead store, omitted)

        // Draw background
        drawBackgroundCircle(partial: isSpinning)

        // Draw progress
        let startAngle = -(CGFloat.pi / 2) // 90 degrees
        let endAngle = (progress * 2 * .pi) + startAngle
        let processPath = UIBezierPath()
        processPath.lineCapStyle = .butt
        processPath.lineWidth = _lineWidth

        let radius = (bounds.size.width - _lineWidth * 3) / 2.0
        processPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)

        progressLayer.path = processPath.cgPath

        if progress == 1.0 {
            drawTick()
        } else if progress > 0 && progress < 1.0 {
            if !hideProgressIcons {
                drawStop()
            }
        } else {
            if iconView == nil && iconPath == nil {
                if !hideProgressIcons {
                    drawArrow()
                }
            } else if let iconPath {
                iconLayer.path = iconPath.cgPath
                iconLayer.fillColor = nil
            }
        }
    }

    // MARK: - Drawing helpers

    private func drawBackgroundCircle(partial: Bool) {
        let startAngle = -(CGFloat.pi / 2) // 90 degrees
        var endAngle = (2 * CGFloat.pi) + startAngle
        let center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        let radius = (bounds.size.width - _lineWidth) / 2

        // Draw background
        let processBackgroundPath = UIBezierPath()
        processBackgroundPath.lineWidth = _lineWidth
        processBackgroundPath.lineCapStyle = .round

        // Recompute the end angle to make it at 90% of the progress (default arc fraction)
        if partial {
            endAngle = (2 * CGFloat.pi * spinningArcFraction) + startAngle
        }

        processBackgroundPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)

        progressBackgroundLayer.path = processBackgroundPath.cgPath
    }

    private func drawTick() {
        let radius = min(frame.size.width, frame.size.height) / 2

        /*
         First draw a tick that looks like this:

         A---F
         |   |
         |   E-------D
         |           |
         B-----------C

         (Remember: (0,0) is top left)
         */
        let tickPath = UIBezierPath()
        let tickWidth = radius * kTickWidthRatio
        tickPath.move(to: CGPoint(x: 0, y: 0))                            // A
        tickPath.addLine(to: CGPoint(x: 0, y: tickWidth * 2))             // B
        tickPath.addLine(to: CGPoint(x: tickWidth * 3, y: tickWidth * 2)) // C
        tickPath.addLine(to: CGPoint(x: tickWidth * 3, y: tickWidth))     // D
        tickPath.addLine(to: CGPoint(x: tickWidth, y: tickWidth))         // E
        tickPath.addLine(to: CGPoint(x: tickWidth, y: 0))                 // F
        tickPath.close()

        // Now rotate it through -45 degrees...
        tickPath.apply(CGAffineTransform(rotationAngle: -.pi / 4))

        // ...and move it into the right place.
        tickPath.apply(CGAffineTransform(translationX: radius * 0.46, y: 1.02 * radius))

        iconLayer.path = tickPath.cgPath
        iconLayer.fillColor = tickColor.cgColor
        progressBackgroundLayer.fillColor = progressLayer.strokeColor
    }

    private func drawStop() {
        let radius = bounds.size.width / 2
        let ratio = kStopSizeRatio
        let sideSize = bounds.size.width * ratio

        let stopPath = UIBezierPath()
        stopPath.move(to: CGPoint(x: 0, y: 0))
        stopPath.addLine(to: CGPoint(x: sideSize, y: 0.0))
        stopPath.addLine(to: CGPoint(x: sideSize, y: sideSize))
        stopPath.addLine(to: CGPoint(x: 0.0, y: sideSize))
        stopPath.close()

        // ...and move it into the right place.
        stopPath.apply(CGAffineTransform(translationX: radius * (1 - ratio), y: radius * (1 - ratio)))

        iconLayer.path = stopPath.cgPath
        iconLayer.strokeColor = progressLayer.strokeColor
        iconLayer.fillColor = tintColor?.cgColor
    }

    private func drawArrow() {
        let radius = bounds.size.width / 2
        let ratio = kArrowSizeRatio
        let segmentSize = bounds.size.width * ratio

        // Draw icon
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0.0, y: 0.0))
        path.addLine(to: CGPoint(x: segmentSize * 2.0, y: 0.0))
        path.addLine(to: CGPoint(x: segmentSize * 2.0, y: segmentSize))
        path.addLine(to: CGPoint(x: segmentSize * 3.0, y: segmentSize))
        path.addLine(to: CGPoint(x: segmentSize, y: segmentSize * 3.3))
        path.addLine(to: CGPoint(x: -segmentSize, y: segmentSize))
        path.addLine(to: CGPoint(x: 0.0, y: segmentSize))
        path.addLine(to: CGPoint(x: 0.0, y: 0.0))
        path.close()

        path.apply(CGAffineTransform(translationX: -segmentSize / 2.0, y: -segmentSize / 1.2))
        path.apply(CGAffineTransform(translationX: radius * (1 - ratio), y: radius * (1 - ratio)))
        iconLayer.path = path.cgPath
        iconLayer.fillColor = nil
    }

    // MARK: - Animations

    private func animateProgressBackgroundLayerFillColor() {
        let colorAnimation = CABasicAnimation(keyPath: "fillColor")

        colorAnimation.duration = 0.5
        colorAnimation.repeatCount = 1.0
        colorAnimation.isRemovedOnCompletion = false

        colorAnimation.fromValue = progressBackgroundLayer.backgroundColor
        colorAnimation.toValue = progressLayer.strokeColor

        colorAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)

        progressBackgroundLayer.add(colorAnimation, forKey: "colorAnimation")
    }

    /// Make the background layer to spin around its center. This should be called in the main thread.
    func startSpinProgressBackgroundLayer() {
        isSpinning = true
        drawBackgroundCircle(partial: true)

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = Double.pi * 2.0
        rotationAnimation.duration = 1
        rotationAnimation.isCumulative = true
        rotationAnimation.repeatCount = .infinity
        progressBackgroundLayer.add(rotationAnimation, forKey: "rotationAnimation")
    }

    /// Stop the spinning of the background layer. This should be called in the main thread.
    /// WARN: This implementation removes all animations from the background layer.
    func stopSpinProgressBackgroundLayer() {
        drawBackgroundCircle(partial: false)

        progressBackgroundLayer.removeAllAnimations()
        isSpinning = false
    }
}

// Port of FFCircularProgressView+Extension.swift
extension CircularProgressView {
    func createTickPath() {
        let radius: CGFloat = min(frame.size.width, frame.size.height) / 2
        let path = UIBezierPath()
        let tickWidth: CGFloat = radius * 0.3
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: tickWidth * 2))
        path.addLine(to: CGPoint(x: tickWidth * 3, y: tickWidth * 2))
        path.addLine(to: CGPoint(x: tickWidth * 3, y: tickWidth))
        path.addLine(to: CGPoint(x: tickWidth, y: tickWidth))
        path.addLine(to: CGPoint(x: tickWidth, y: 0))
        path.close()

        path.apply(CGAffineTransform(rotationAngle: -(.pi / 4)))
        path.apply(CGAffineTransform(translationX: radius * 0.46, y: 1.02 * radius))

        iconPath = path
    }
}
