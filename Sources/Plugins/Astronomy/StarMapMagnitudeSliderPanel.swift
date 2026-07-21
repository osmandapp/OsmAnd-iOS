//
//  StarMapMagnitudeSliderPanel.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 08.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class StarMapMagnitudeSliderPanel: UIView {
    static let preferredWidth: CGFloat = 240
    private static let cornerRadius: CGFloat = 16

    var onValueChanged: ((Double) -> Void)?

    var isExpanded: Bool {
        !isHidden
    }

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let slider = UISlider()
    private var nightMode = false
    
    private weak var glassBackgroundView: UIVisualEffectView?

    init(maxMagnitude: Double) {
        super.init(frame: .zero)
        setupContent(maxMagnitude: maxMagnitude)
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        glassBackgroundView?.frame = bounds
    }

    func toggle() {
        isHidden.toggle()
        updateTheme(nightMode: nightMode)
    }

    func setMagnitude(_ value: Double) {
        slider.value = Float(value)
        valueLabel.text = String(format: "%.1f", value)
    }

    func updateTheme(nightMode: Bool) {
        self.nightMode = nightMode
        
        glassBackgroundView?.overrideUserInterfaceStyle = nightMode ? .dark : .light
        
        let color: UIColor = nightMode ? .textColorPrimary.dark : .textColorPrimary.light
        titleLabel.textColor = color
        valueLabel.textColor = color
        
        backgroundColor = StarMapControlTheme.defaultBackground(nightMode: nightMode, alpha: StarMapControlTheme.defaultBackgroundAlpha)
        
        layer.borderWidth = nightMode ? 2 : 0
    }

    private func setupContent(maxMagnitude: Double) {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = Self.cornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 5
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.borderColor = StarMapControlTheme.border(nightMode: nightMode).cgColor
        
        glassBackgroundView = StarMapGlassBackground.apply(
            to: self,
            nightMode: nightMode,
            cornerRadius: Self.cornerRadius
        )

        titleLabel.text = localizedString("astro_min_magnitude")
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)

        valueLabel.font = .preferredFont(forTextStyle: .subheadline)

        slider.minimumValue = -1
        slider.maximumValue = Float(maxMagnitude)
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        let header = UIStackView(arrangedSubviews: [titleLabel, UIView(), valueLabel])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8

        let stack = UIStackView(arrangedSubviews: [header, slider])
        stack.axis = .vertical
        stack.spacing = 6
        stack.layoutMargins = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func sliderChanged() {
        let value = Double(slider.value)
        valueLabel.text = String(format: "%.1f", value)
        onValueChanged?(value)
    }
}
