//
//  StarMapMagnitudeFilterButton.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 08.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class StarMapMagnitudeFilterButton: StarMapButton {
    private static let pillCornerRadius: Int32 = 24
    
    override var isHighlighted: Bool {
        didSet {
            updateTheme()
        }
    }

    private let iconView = UIImageView(image: .icCustomMagnitude)
    private let valueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContent()
        applyPillAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupContent()
        applyPillAppearance()
    }

    func setValue(_ text: String) {
        valueLabel.text = text
    }

    override func updateTheme() {
        super.updateTheme()
        setImage(nil, for: .normal)
        imageView?.isHidden = true
        
        if isHighlighted {
            let color = StarMapControlTheme.foreground(active: false, nightMode: nightMode).withAlphaComponent(0.4)
            iconView.tintColor = color
            valueLabel.textColor = color
        } else {
            let color = StarMapControlTheme.foreground(active: active, nightMode: nightMode)
            iconView.tintColor = color
            valueLabel.textColor = color
        }
        
        layer.borderWidth = nightMode ? 2 : 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if #available(iOS 26.0, *) {
            subviews.compactMap { $0 as? UIVisualEffectView }.forEach {
                $0.frame = bounds
                $0.layer.cornerRadius = bounds.width / 2
            }
        }
    }

    private func setupContent() {
        setImage(nil, for: .normal)
        imageView?.isHidden = true
        
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30)
        ])

        valueLabel.font = .systemFont(ofSize: 15, weight: .bold)
        valueLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [iconView, valueLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        accessibilityLabel = localizedString("astro_min_magnitude")
    }

    private func applyPillAppearance() {
        let helper = OAMapButtonsHelper.sharedInstance()
        var size = helper.getDefaultSizePref().get()
        if size <= 0 { size = MapButtonState.defaultSizeDp }

        var opacity = helper.getDefaultOpacityPref().get()
        if opacity < 0 { opacity = MapButtonState.opaqueAlpha }

        var glassStyle = MapButtonState.defaultGlassStyle
        if #available(iOS 26.0, *) {
            glassStyle = Int32(UIGlassEffect.Style.clear.rawValue)
            opacity = Double(StarMapControlTheme.defaultBackgroundAlpha)
        }

        setCustomAppearanceParams(ButtonAppearanceParams(
            iconName: nil,
            size: Int32(size),
            opacity: opacity,
            cornerRadius: Self.pillCornerRadius,
            glassStyle: glassStyle
        ))
        updateTheme()
    }
}
