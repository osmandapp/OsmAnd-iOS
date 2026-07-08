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

    init(maxMagnitude: Double) {
        super.init(frame: .zero)
        setupContent(maxMagnitude: maxMagnitude)
        isHidden = true
        updateTheme(nightMode: OADayNightHelper.instance().isNightMode())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        StarMapGlassBackground.apply(
            to: self,
            active: false,
            nightMode: nightMode,
            cornerRadius: Self.cornerRadius
        )
        let color = StarMapControlTheme.foreground(active: true, nightMode: nightMode)
        titleLabel.textColor = color
        valueLabel.textColor = color
        
        backgroundColor = StarMapControlTheme.defaultBackground(nightMode: OADayNightHelper.instance().isNightMode(), alpha: 0.5)
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

    private func setupContent(maxMagnitude: Double) {
        translatesAutoresizingMaskIntoConstraints = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.16
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.cornerRadius = Self.cornerRadius

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
