//
//  SpeedometerSpeedView.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 20.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

final class SpeedometerSpeedView: UIView {
    @IBOutlet private weak var topConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var withConstraint: NSLayoutConstraint!
    @IBOutlet private weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var valueSpeedLabel: UILabel!
    @IBOutlet private weak var unitSpeedLabel: UILabel!
    
    var isPreview = false
    /// The side from which the animation starts (and ends). Default is right.
    var animationOrigin: CircleAnimationOrigin = .right
    
    /// km/h or mph
    private(set) var cachedSpeedLimit: Float = -1.0
    
    private let LOW_SPEED_THRESHOLD_MPS = 6.0
    private let UPDATE_THRESHOLD_MPS = 0.1
    private let LOW_SPEED_UPDATE_THRESHOLD_MPS = 0.015 // Update more often while walking/running
    private let previewValueDefault: Int = 85
    /// Offsets the circle's center beyond the screen for a smoother start/end.
    private let offset: CGFloat = 20.0
    private let contentView = UIView()
    
    private var widgetSizeStyle: EOAWidgetSizeStyle = .medium
    /// Meters per seconds (m/s)
    private var cachedSpeed = -1.0
    /// km/h or mph
    private var cachedFormattedSpeed: Float = -1.0
    private var cachedMetricSystem = -1
    
    private var circleLayer: CAShapeLayer?
    private var isCircleRevealAnimationActive = false
    private var currentSpeedometerState: SpeedometerState = .normal
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        insertSubview(contentView, at: 0)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    func configureWith(widgetSizeStyle: EOAWidgetSizeStyle, width: CGFloat) {
        self.widgetSizeStyle = widgetSizeStyle
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = layer.cornerRadius
        layer.masksToBounds = false
        withConstraint.constant = width
        valueSpeedLabel.font = .systemFont(ofSize: speedValueFontSize, weight: .semibold)
        configureConstraints()
        
        if isPreview {
            valueSpeedLabel.text = String(previewValueDefault)
            isHidden = false
        }
    }
    
    func updateInfo(speedLimit: Float) {
        guard let lastKnownLocation = OsmAndApp.swiftInstance().locationServices?.lastKnownLocation else {
            resetState()
            stopSpeedometerSpeedAnimation(animated: false)
            isHidden = true
            return
        }
        // meters per seconds
        let currentSpeed = lastKnownLocation.speed
        if currentSpeed >= 0 {
            let updateThreshold = cachedSpeed < LOW_SPEED_THRESHOLD_MPS ? LOW_SPEED_UPDATE_THRESHOLD_MPS : UPDATE_THRESHOLD_MPS
            if isUpdateNeeded() || abs(currentSpeed - cachedSpeed) > updateThreshold || cachedSpeed == -1 || cachedSpeedLimit != speedLimit {
                cachedSpeed = currentSpeed
                cachedSpeedLimit = speedLimit
                updateSpeedValueAndUnit(with: Float(cachedSpeed))
                
                let cachedSpeedometerState = currentSpeedometerState
                updateCurrentState(with: speedLimit)
                
                let speedExceed = cachedSpeed > 0
                && speedLimit > 0
                && cachedFormattedSpeed > 0
                && currentSpeedometerState == .exceedingLimit
                
                if (speedExceed || currentSpeedometerState == .tolerance), !isCircleRevealAnimationActive, cachedSpeedometerState != currentSpeedometerState {
                    startSpeedometerSpeedAnimation()
                } else if !speedExceed || cachedFormattedSpeed < speedLimit {
                    stopSpeedometerSpeedAnimation(animated: cachedSpeedometerState != currentSpeedometerState)
                }
            } else {
                updateCurrentState(with: speedLimit)
                if !isCircleRevealAnimationActive {
                    updateSpeedometerSpeedView(animated: false)
                }
            }
            isHidden = false
        } else if cachedSpeed != 0.0 {
            cachedSpeed = 0
            resetState()
            updateSpeedValueAndUnit(with: Float(cachedSpeed))
            stopSpeedometerSpeedAnimation(animated: false)
            isHidden = false
        } else {
            resetState()
            stopSpeedometerSpeedAnimation(animated: false)
            isHidden = true
        }
    }
    
    func configureTextAlignmentContent(isTextAlignmentRight: Bool) {
        let textAlignment: NSTextAlignment = isTextAlignmentRight ? .right : .left
        valueSpeedLabel.textAlignment = textAlignment
        unitSpeedLabel.textAlignment = textAlignment
    }
    
    func configureShadow() {
        layer.shadowOpacity = 1
        layer.shadowRadius = 5
        layer.shadowOffset = .init(width: 0, height: 2)
        layer.shadowColor = UIColor.black.withAlphaComponent(0.30).cgColor
    }
    
    private func updateCurrentState(with speedLimit: Float) {
        guard speedLimit != -1 else {
            currentSpeedometerState = .normal
            return
        }
        
        //  tolerance (km/h or mph)
        var tolerance = Float(OAAppSettings.sharedManager().speedLimitExceedKmh.get())
        if OASpeedConstant.imperial(OAAppSettings.sharedManager().speedSystem.get()) {
            tolerance /= 1.6
        }
        
        let overspeedThreshold = speedLimit + tolerance
        
        if tolerance > 0 {
            if cachedFormattedSpeed >= overspeedThreshold {
                currentSpeedometerState = .exceedingLimit
            } else if cachedFormattedSpeed >= speedLimit {
                currentSpeedometerState = .tolerance
            } else {
                currentSpeedometerState = .normal
            }
        } else if tolerance == 0 {
            if cachedFormattedSpeed > speedLimit {
                currentSpeedometerState = .exceedingLimit
            } else {
                currentSpeedometerState = .normal
            }
        } else {
            if cachedFormattedSpeed >= overspeedThreshold {
                currentSpeedometerState = .exceedingLimit
            } else if cachedFormattedSpeed >= speedLimit + 2 * tolerance {
                currentSpeedometerState = .tolerance
            } else {
                currentSpeedometerState = .normal
            }
        }
    }
    
    private func resetState() {
        cachedFormattedSpeed = -1
        cachedSpeedLimit = -1.0
        currentSpeedometerState = .normal
    }
    
    private func updateSpeedValueAndUnit(with value: Float) {
        let valueUnitArray: NSMutableArray = []
        OAOsmAndFormatter.getFormattedSpeed(value, valueUnitArray: valueUnitArray)
        if let result = getValueAndUnit(with: valueUnitArray) {
            if let formattedValue = Float(result.value) {
                cachedFormattedSpeed = formattedValue
            } else {
                debugPrint("updateSpeedValueAndUnit -> Invalid number")
            }
            
            valueSpeedLabel.text = result.value
            unitSpeedLabel.text = result.unit.uppercased()
        }
    }
    
    private func isUpdateNeeded() -> Bool {
        var res = false
        let metricSystem: EOAMetricsConstant = OAAppSettings.sharedManager().metricSystem.get()
        res = cachedMetricSystem != metricSystem.rawValue
        if res {
            cachedMetricSystem = metricSystem.rawValue
        }
        return res
    }
    
    private func getValueAndUnit(with valueUnitArray: NSMutableArray) -> (value: String, unit: String)? {
        guard valueUnitArray.count == 2,
              let value = valueUnitArray[0] as? String,
              let unit = valueUnitArray[1] as? String else {
            return nil
        }
        return (value: value, unit: unit)
    }
    
    private func configureConstraints() {
        topConstraint.constant = speedValueTopPadding
        bottomConstraint.constant = speedValueBottomPadding
        leadingConstraint.constant = speedValueLeadingTrailingPadding
        trailingConstraint.constant = leadingConstraint.constant
        stackView.spacing = speedValueStackViewSpacing
    }
}

// MARK: - Size Metrics
extension SpeedometerSpeedView {
    private var speedValueTopPadding: CGFloat {
        switch widgetSizeStyle {
        case .small, .medium: 3
        case .large: 6
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    private var speedValueBottomPadding: CGFloat {
        switch widgetSizeStyle {
        case .small: 8
        case .medium: 9
        case .large: 12
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    private var speedValueLeadingTrailingPadding: CGFloat {
        switch widgetSizeStyle {
        case .small: 10
        case .medium, .large: 12
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    private var speedValueStackViewSpacing: CGFloat {
        switch widgetSizeStyle {
        case .small: 3
        case .medium, .large: 6
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    private var speedValueFontSize: CGFloat {
        switch widgetSizeStyle {
        case .small: 22
        case .medium: 33
        case .large: 50
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
}

// MARK: - Animations
extension SpeedometerSpeedView {
    
    /// Determines from which side of the screen the circular animation starts (and ends).
    enum CircleAnimationOrigin {
        case right // Animation starts from the right edge (current option)
        case left  // Animation starts from the left edge
    }
    
    private class AnimationCompletionDelegate: NSObject, CAAnimationDelegate {
        var completion: () -> Void
        
        init(completion: @escaping () -> Void) {
            self.completion = completion
        }
        
        func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
            if flag {
                completion()
            }
        }
    }
    
    /// Animates the appearance of the red/yellow circle and the change of the text color.
    private func startSpeedometerSpeedAnimation(duration: TimeInterval = 1.0) {
        startCircleRevealAnimation(duration: duration)
        animateText(valueColor: currentSpeedometerState.valueColor, unitColor: currentSpeedometerState.unitsColor, duration: duration)
    }
    
    private func stopSpeedometerSpeedAnimation(animated: Bool) {
        guard let circleLayer else {
            updateSpeedometerSpeedView(animated: animated)
            isCircleRevealAnimationActive = false
            return
        }

        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = circleLayer.presentation()?.opacity ?? circleLayer.opacity
        fadeOut.toValue = 0.0
        fadeOut.duration = 1.0
        fadeOut.timingFunction = CAMediaTimingFunction(name: .easeOut)
        fadeOut.fillMode = .forwards
        fadeOut.isRemovedOnCompletion = false

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            circleLayer.removeAllAnimations()
            circleLayer.removeFromSuperlayer()
            self.circleLayer = nil
            self.updateSpeedometerSpeedView(animated: animated)
            self.isCircleRevealAnimationActive = false
        }
        circleLayer.add(fadeOut, forKey: "fadeOut")
        CATransaction.commit()
        
        updateSpeedometerSpeedView(animated: animated)
        isCircleRevealAnimationActive = false
    }
    
    private func updateSpeedometerSpeedView(animated: Bool = true) {
        updateSpeedometerBackground()
        if animated {
            animateText(valueColor: currentSpeedometerState.valueColor, unitColor: currentSpeedometerState.unitsColor, duration: 1.0)
        } else {
            valueSpeedLabel.textColor = currentSpeedometerState.valueColor
            unitSpeedLabel.textColor = currentSpeedometerState.unitsColor
        }
    }
    
    private func updateSpeedometerBackground() {
        UIView.animate(withDuration: 1.0) {
            self.backgroundColor = self.currentSpeedometerState.backgroundColor
        }
    }
    
    /// Animates the change of the text color.
    private func animateText(valueColor: UIColor,
                             unitColor: UIColor,
                             duration: TimeInterval) {
        UIView.transition(with: valueSpeedLabel, duration: duration, options: .transitionCrossDissolve, animations: {
            self.valueSpeedLabel.textColor = valueColor
        }, completion: nil)
        UIView.transition(with: unitSpeedLabel, duration: duration, options: .transitionCrossDissolve, animations: {
            self.unitSpeedLabel.textColor = unitColor
        }, completion: nil)
    }
    
    private func calculateAnimationParameters() -> (startPoint: CGPoint, endRadius: CGFloat) {
        let centerX: CGFloat
        let furthestX: CGFloat
        
        switch animationOrigin {
        case .right:
            // Center: from the right side + offset
            centerX = bounds.width + offset
            // The farthest point is the left edge (x = 0)
            furthestX = 0
            
        case .left:
            // Center: from the left side - offset
            centerX = -offset
            // The farthest point is the right edge (x = self.bounds.width)
            furthestX = bounds.width
        }
        
        let startPoint = CGPoint(x: centerX, y: bounds.height / 2)
        
        // Calculate the radius: distance from the center to the farthest corner
        // (for example, the top-left or top-right corner)
        let dx = startPoint.x - furthestX
        let dy = startPoint.y - 0 // Distance to the top edge (y = 0)
        let endRadius = sqrt(pow(dx, 2) + pow(dy, 2))
        
        return (startPoint, endRadius)
    }
    
    private func startCircleRevealAnimation(duration: TimeInterval) {
        circleLayer?.removeFromSuperlayer()
        
        let newCircleLayer = CAShapeLayer()
        newCircleLayer.fillColor = currentSpeedometerState.backgroundColor.cgColor
        newCircleLayer.opacity = 0.0
        contentView.layer.insertSublayer(newCircleLayer, at: 0)
        self.circleLayer = newCircleLayer
        
        let (startPoint, endRadius) = calculateAnimationParameters()
        
        let initialPath = UIBezierPath(arcCenter: startPoint, radius: 0, startAngle: 0, endAngle: 2 * .pi, clockwise: true).cgPath
        let finalPath = UIBezierPath(arcCenter: startPoint, radius: endRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true).cgPath
        
        newCircleLayer.path = initialPath
        
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = initialPath
        pathAnimation.toValue = finalPath
        
        let alphaAnimation = CABasicAnimation(keyPath: "opacity")
        alphaAnimation.fromValue = 0.0
        alphaAnimation.toValue = 1.0
        
        let animationGroup = CAAnimationGroup()
        animationGroup.duration = duration
        animationGroup.animations = [pathAnimation, alphaAnimation]
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        let animationDelegate = AnimationCompletionDelegate { [weak self] in
            guard let self else { return }
            circleLayer?.removeFromSuperlayer()
            circleLayer = nil
            isCircleRevealAnimationActive = false
            backgroundColor = currentSpeedometerState.backgroundColor
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        newCircleLayer.path = finalPath
        newCircleLayer.opacity = 1.0
        CATransaction.commit()
        
        animationGroup.delegate = animationDelegate
        newCircleLayer.add(animationGroup, forKey: "revealAnimation")
        isCircleRevealAnimationActive = true
    }
}
