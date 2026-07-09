//
//  StarMapArControlCard.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 09.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class StarMapArControlCard: UIView {
    static let width: CGFloat = 48
    private static let cornerRadius: CGFloat = 24
    private static let innerButtonSize: CGFloat = 40
    private static let sliderHeight: CGFloat = 150
    private static let stackSpacing: CGFloat = 4

    var onArTapped: (() -> Void)?
    var onResetTapped: (() -> Void)?
    var onTransparencyChanged: ((Int) -> Void)?

    private let arButton = StarMapPlainIconButton()
    private let resetButton = StarMapPlainIconButton()
    private let transparencySlider = UISlider()
    private let sliderContainer = UIView()
    private let cameraControlsStack = UIStackView()
    private let rootStack = UIStackView()

    private var nightMode = OADayNightHelper.instance().isNightMode()
    private var arActive = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContent()
        updateTheme(nightMode: nightMode, arActive: false)
        setCameraControlsVisible(false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setArActive(_ active: Bool) {
        arActive = active
        arButton.active = active
        updateTheme(nightMode: nightMode, arActive: active)
    }

    func setCameraControlsVisible(_ visible: Bool) {
        cameraControlsStack.isHidden = !visible
    }

    func setTransparencyValue(_ value: Int) {
        transparencySlider.value = Float(max(0, min(100, value)))
    }

    func updateTheme(nightMode: Bool, arActive: Bool) {
        self.nightMode = nightMode
        self.arActive = arActive

        StarMapGlassBackground.apply(
            to: self,
            active: arActive,
            nightMode: nightMode,
            cornerRadius: Self.cornerRadius
        )
        backgroundColor = StarMapControlTheme.defaultBackground(nightMode: nightMode, alpha: 0.5)

        resetButton.nightMode = nightMode
        resetButton.active = false
        
        updateArButtonAppearance()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
        if #available(iOS 26.0, *) {
            subviews.compactMap { $0 as? UIVisualEffectView }.forEach {
                $0.frame = bounds
                $0.layer.cornerRadius = Self.cornerRadius
            }
        }
    }

    private func setupContent() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = Self.cornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.16
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 2)

        configurePlainButton(
            arButton,
            iconName: "ic_custom_view_in_ar",
            accessibilityLabel: localizedString("astro_ar"),
            action: #selector(arButtonTapped)
        )
        configurePlainButton(
            resetButton,
            iconName: "ic_custom_reset",
            accessibilityLabel: localizedString("shared_string_reset"),
            action: #selector(resetButtonTapped)
        )

        transparencySlider.minimumValue = 0
        transparencySlider.maximumValue = 100
        transparencySlider.value = Float(StarMapCameraHelper.defaultTransparency)
        transparencySlider.transform = CGAffineTransform(rotationAngle: -.pi / 2)
        transparencySlider.translatesAutoresizingMaskIntoConstraints = false
        transparencySlider.addTarget(self, action: #selector(transparencyChanged), for: .valueChanged)

        sliderContainer.translatesAutoresizingMaskIntoConstraints = false
        sliderContainer.addSubview(transparencySlider)

        cameraControlsStack.axis = .vertical
        cameraControlsStack.alignment = .center
        cameraControlsStack.spacing = 9
        cameraControlsStack.addArrangedSubview(sliderContainer)
        cameraControlsStack.addArrangedSubview(resetButton)

        rootStack.axis = .vertical
        rootStack.alignment = .center
        rootStack.spacing = Self.stackSpacing
        rootStack.layoutMargins = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        rootStack.isLayoutMarginsRelativeArrangement = true
        rootStack.addArrangedSubview(arButton)
        rootStack.addArrangedSubview(cameraControlsStack)
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rootStack)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.width),

            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rootStack.topAnchor.constraint(equalTo: topAnchor),
            rootStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            arButton.widthAnchor.constraint(equalToConstant: Self.innerButtonSize),
            arButton.heightAnchor.constraint(equalToConstant: Self.innerButtonSize),

            sliderContainer.widthAnchor.constraint(equalToConstant: Self.width),
            sliderContainer.heightAnchor.constraint(equalToConstant: Self.sliderHeight),

            transparencySlider.centerXAnchor.constraint(equalTo: sliderContainer.centerXAnchor),
            transparencySlider.centerYAnchor.constraint(equalTo: sliderContainer.centerYAnchor),
            transparencySlider.widthAnchor.constraint(equalToConstant: Self.sliderHeight),
            transparencySlider.heightAnchor.constraint(equalToConstant: 40),

            resetButton.widthAnchor.constraint(equalToConstant: Self.innerButtonSize),
            resetButton.heightAnchor.constraint(equalToConstant: Self.innerButtonSize)
        ])

        setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    private func configurePlainButton(
        _ button: StarMapPlainIconButton,
        iconName: String,
        accessibilityLabel: String,
        action: Selector
    ) {
        button.setIcon(iconName, accessibilityLabel: accessibilityLabel)
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    private func updateArButtonAppearance() {
        let iconName = arActive ? "ic_custom_view_in_ar_filled" : "ic_custom_view_in_ar"
        arButton.setIcon(iconName, accessibilityLabel: localizedString("astro_ar"))
        arButton.nightMode = nightMode
        arButton.active = arActive
    }

    @objc private func arButtonTapped() {
        onArTapped?()
    }

    @objc private func resetButtonTapped() {
        onResetTapped?()
    }

    @objc private func transparencyChanged() {
        onTransparencyChanged?(Int(transparencySlider.value))
    }
}
