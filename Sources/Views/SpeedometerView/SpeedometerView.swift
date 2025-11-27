//
//  SpeedometerView.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 16.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
final class CarPlayConfig: NSObject {
    var isLeftSideDriving = false
}

@objcMembers
final class SpeedometerView: OATextInfoWidget {
    
    @IBOutlet private weak var centerPositionXConstraint: NSLayoutConstraint!
    @IBOutlet private weak var centerPositionYConstraint: NSLayoutConstraint!
    @IBOutlet private weak var leftPositionConstraint: NSLayoutConstraint!
    @IBOutlet private weak var rightPositionConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var contentStackView: UIStackView!
    
    @IBOutlet private weak var speedometerSpeedView: SpeedometerSpeedView! {
        didSet {
            speedometerSpeedView.isHidden = true
        }
    }
    @IBOutlet private weak var speedLimitEUView: SpeedLimitView! {
        didSet {
            speedLimitEUView.speedLimitRegion = .EU
            speedLimitEUView.isHidden = true
        }
    }
    @IBOutlet private weak var speedLimitNAMView: SpeedLimitView! {
        didSet {
            speedLimitNAMView.speedLimitRegion = .NAM
            speedLimitNAMView.isHidden = true
        }
    }
    let settings = OAAppSettings.sharedManager()
    
    var sizeStyle: EOAWidgetSizeStyle = .medium
    var didChangeIsVisible: (() -> Void)?
    
    var carPlayConfig: CarPlayConfig?
    var isPreview = false
    
    static var initView: SpeedometerView? {
        UINib(nibName: String(describing: self), bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as? SpeedometerView
    }
    
    var isDrivingRegionNAM: Bool {
        let drivingRegion = settings.drivingRegion.get()
        return drivingRegion == EOADrivingRegion.DR_US || drivingRegion == EOADrivingRegion.DR_CANADA
    }
    
    private lazy var speedViewWrapper = SpeedLimitWrapper()
    
    override var intrinsicContentSize: CGSize {
        let fittingSize = contentStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGSize(width: fittingSize.width, height: getCurrentSpeedViewMaxHeightWidth())
    }
    
    override func isTextInfo() -> Bool {
        false
    }
    
    private var didRunSpeedTests = false
    
    @discardableResult
    override func updateInfo() -> Bool {
        guard settings.showSpeedometer.get() else {
            isHidden = true
            return false
        }
        updateComponents()
        
        if !didRunSpeedTests {
            didRunSpeedTests = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self else { return }
               // runSpeedLogicVisualTests()
                runSimpleSpeedTests()
//                runSimpleSpeedTests1()
                isHidden = false
                didChangeIsVisible?()
               // let speedLimit: Int = Int(speedViewWrapper.speedLimit())
              //  print("[test] speedLimit: \(speedLimit)")
//                updateSpeedometerSpeedView(speedLimit: speedLimit)
//                updateSpeedLimitView(speedLimit: speedLimit)
//                var isChangedVisible = false
//                if !speedometerSpeedView.isHidden && isHidden {
//                    isChangedVisible = true
//                }
//                isHidden = speedometerSpeedView.isHidden
//                if isChangedVisible {
//                    didChangeIsVisible?()
//                }
            }
        }
        
        return true
    }
    
//    @discardableResult
//    override func updateInfo() -> Bool {
//        guard settings.showSpeedometer.get() else {
//            isHidden = true
//            return false
//        }
//        updateComponents()
//        let speedLimit: Float = Float(speedViewWrapper.speedLimit())
//        updateSpeedometerSpeedView(speedLimit: speedLimit)
//        updateSpeedLimitView(speedLimit: Int(speedLimit))
//        var isChangedVisible = false
//        if !speedometerSpeedView.isHidden && isHidden {
//            isChangedVisible = true
//        }
//        isHidden = speedometerSpeedView.isHidden
//        if isChangedVisible {
//            didChangeIsVisible?()
//        }
//        
//        return true
//    }
    
//    func runSpeedLogicVisualTests() {
//        let speedLimit: Float = 60
//        let tolerance0: Float = 0      // Допуск 0
//        let tolerance5: Float = 5      // Допуск +5 км/ч
//        let tolerance5Minus: Float = -5 // Допуск -5 км/ч (если нужен)
//
//        // Массив тестовых случаев: (скорость, допуск)
//        let testCases: [(speed: Float, tolerance: Float)] = [
//            // Допуск 0
////            (60, tolerance0), // белый
////            (61, tolerance0), // красный
////
////            // Допуск +5
////            (59, tolerance5), // белый
////            (60, tolerance5), // жёлтый
////            (62, tolerance5), // жёлтый
////            (66, tolerance5), // красный
//
//            // Допуск -5 (отрицательный, для теста)
//            (55, tolerance5Minus), // красный
//            (56, tolerance5Minus), // красный
//            (50, tolerance5Minus), // жёлтый
//            (54, tolerance5Minus), // жёлтый
//            (49, tolerance5Minus), // белый
//            (48, tolerance5Minus) // белый
//        ]
//
//        var delay = 0.0
//        for test in testCases {
//            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
//                guard let self else { return }
//
//                self.isHidden = false
//                
//                OAAppSettings.sharedManager().speedLimitExceedKmh.set(Double(test.tolerance))
//                
//               // var tolerance = Float(OAAppSettings.sharedManager().speedLimitExceedKmh.get())
//                
//                // Обновляем скорость и лимит
//                print("Speed: \(test.speed) km/h, tolerance: \(test.tolerance)")
//                updateSpeedometerSpeedView(speedLimit: speedLimit, mockSpeed: test.speed / 3.6)
//                updateSpeedLimitView(speedLimit: Int(speedLimit))
//                
//                // Обновляем состояние с учётом текущего допускa
////                updateCurrentState(speedLimit: speedLimit, tolerance: test.tolerance)
//                
//                // Задержка между тестами — визуальная проверка
//               
//            }
//            delay += 5.0 // пауза 2 секунды между тестами
//        }
//    }

    
    func runSimpleSpeedTests() {
        let speedLimit: Float = 50

        let sequence: [Float] = [
            0,      // 0 км/ч — стоим
            10,     // 36 км/ч
            14,     // 50 км/ч
            16,     // 58 км/ч — превышение
            13,     // 46.8 км/ч — обратно к лимиту
            20,     // 72 км/ч — превышение
            11,     // 39.6 км/ч — нормально
            12,     // 43.2 км/ч — нормально
            15,     // 46.8 км/ч — обратно к лимиту
            18      // 64.8 км/ч — превышение
        ]

        var delay = 0.0
        for s in sequence {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                self.isHidden = false
                updateSpeedometerSpeedView(speedLimit: speedLimit, mockSpeed: s)
                updateSpeedLimitView(speedLimit: Int(speedLimit))
            }
            delay += 1.5
        }
    }
    
//    func runSimpleSpeedTests1() {
//        let speedLimit: Float = 64
//
//        let sequence: [Float] = [
//            16,    // превышение
//        ]
//
//        var delay = 0.5
//        for s in sequence {
//            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
//                guard let self else { return }
//                self.isHidden = false
//                updateSpeedometerSpeedView(speedLimit: speedLimit, mockSpeed: s)
//                updateSpeedLimitView(speedLimit: Int(speedLimit))
//            }
//            delay += 0.1
//        }
//    }
    
    func configure() {
        sizeStyle = settings.speedometerSize.get()
        
        updateComponents()
        
        centerPositionYConstraint.isActive = true
        if isPreview {
            isHidden = false
            speedometerSpeedView.layer.cornerRadius = 6
            speedometerSpeedView.configureShadow()
            configureContentStackViewSemanticContentAttribute()
            centerPositionXConstraint.isActive = true
            leftPositionConstraint.isActive = false
            rightPositionConstraint.isActive = false
            configureUserInterfaceStyleWithMapTheme()
        } else {
            isHidden = true
            centerPositionXConstraint.isActive = false
            if let carPlayConfig {
                speedometerSpeedView.layer.cornerRadius = 10
                speedometerSpeedView.animationOrigin = carPlayConfig.isLeftSideDriving ? .left : .right
                contentStackView.semanticContentAttribute = carPlayConfig.isLeftSideDriving ? .forceRightToLeft : .forceLeftToRight
                speedometerSpeedView.configureTextAlignmentContent(isTextAlignmentRight: carPlayConfig.isLeftSideDriving)
                if carPlayConfig.isLeftSideDriving {
                    contentAlignment(isRight: true)
                } else {
                    contentAlignment(isRight: false)
                }
            } else {
                configureContentStackViewSemanticContentAttribute()
                speedometerSpeedView.layer.cornerRadius = 6
                speedometerSpeedView.animationOrigin = isDirectionRTL() ? .left : .right
                speedometerSpeedView.configureShadow()
                leftPositionConstraint.isActive = true
                rightPositionConstraint.isActive = false
                configureUserInterfaceStyleWithMapTheme()
            }
        }
    }
    
    func configureUserInterfaceStyleWith(style: UIUserInterfaceStyle) {
        overrideUserInterfaceStyle = style
        let borderColor: UIColor = style == .light ? .widgetAutoBgStroke.light : .widgetAutoBgStroke.dark
        speedometerSpeedView.layer.borderWidth = 1.0
        speedometerSpeedView.layer.borderColor = borderColor.cgColor
    }
    
    func contentAlignment(isRight: Bool) {
        if isRight {
            rightPositionConstraint.isActive = true
            leftPositionConstraint.isActive = false
        } else {
            leftPositionConstraint.isActive = true
            rightPositionConstraint.isActive = false
        }
    }
    
    private func configureContentStackViewSemanticContentAttribute() {
        contentStackView.semanticContentAttribute = isDirectionRTL() ? .forceRightToLeft : .forceLeftToRight
    }
    
    private func configureUserInterfaceStyleWithMapTheme() {
        overrideUserInterfaceStyle = OAAppSettings.sharedManager().nightMode ? .dark : .light
    }
    
    private func updateComponents() {
        let width = getCurrentSpeedViewMaxHeightWidth()
        speedometerSpeedView.isPreview = isPreview
        speedometerSpeedView.configureWith(widgetSizeStyle: sizeStyle, width: width)
        if isDrivingRegionNAM {
            speedLimitNAMView.isPreview = isPreview
            speedLimitNAMView.configureWith(widgetSizeStyle: sizeStyle, width: width)
        } else {
            speedLimitEUView.isPreview = isPreview
            speedLimitEUView.configureWith(widgetSizeStyle: sizeStyle, width: width)
        }
    }
    
    private func updateSpeedometerSpeedView(speedLimit: Float, mockSpeed: Float? = nil) {
        speedometerSpeedView.updateInfo(speedLimit: speedLimit, mockSpeed: mockSpeed)
    }
    
    private func updateSpeedLimitView(speedLimit: Int) {
        speedLimitEUView.isHidden = true
        speedLimitNAMView.isHidden = true
        
        setupSpeedLimitWith(view: isDrivingRegionNAM ? speedLimitNAMView : speedLimitEUView, speedLimit: speedLimit)
    }
    
    private func setupSpeedLimitWith(view: SpeedLimitView, speedLimit: Int) {
        guard speedLimit > -1 else {
            view.isHidden = true
            return
        }
        let value = String(speedLimit)
        view.isHidden = false
        view.updateWith(value: value)
    }
}

extension SpeedometerView {
    func getCurrentSpeedViewMaxHeightWidth() -> CGFloat {
        switch sizeStyle {
        case .small: 56
        case .medium: 72
        case .large: 96
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
}

/**
 * Defines the visual state of the Speedometer widget based on the current speed.
 * Each case provides the necessary set of colors for the background, speed value, and units
 * by loading them from the Asset Catalogue.
 */
enum SpeedometerState {
    case normal           // Default appearance, no speeding.
    case tolerance        // Speed is within the tolerance threshold of the limit.
    case exceedingLimit   // Speed limit has been exceeded.
    
    /// Returns the background color for the speedometerSpeedView.
    var backgroundColor: UIColor {
        switch self {
        case .normal: .widgetBg
        case .tolerance: .speedometerToleranceBg
        case .exceedingLimit: .speedometerLimitBg
        }
    }
    
    /// Returns the color for the main speed value (the numbers).
    var valueColor: UIColor {
        switch self {
        case .normal: .widgetValue
        case .tolerance: .speedometerToleranceValue
        case .exceedingLimit: .speedometerLimitValue
        }
    }
    
    /// Returns the color for the units text (e.g., "km/h" or "mph").
    var unitsColor: UIColor {
        switch self {
        case .normal: .widgetUnits
        case .tolerance: .speedometerToleranceUnits
        case .exceedingLimit: .speedometerLimitUnits
        }
    }
}
