//
//  StarMapTimeControlCard.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 08.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class StarMapTimeControlCard: UIView {
    static let height: CGFloat = 48
    private static let cornerRadius: CGFloat = 24

    var onTimeButtonTapped: (() -> Void)?
    var onResetTapped: (() -> Void)?

    private let timeButton = StarMapPlainButton()
    private let resetButton = StarMapPlainButton()
    private let mainStack = UIStackView()
    
    private var active: Bool = false
    private var nightMode: Bool = false
    
    private weak var glassBackgroundView: UIVisualEffectView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTimeTitle(_ title: String) {
        timeButton.setTitle(title, for: .normal)
    }

    func setResetVisible(_ visible: Bool) {
        resetButton.isHidden = !visible
        mainStack.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: resetButton.isHidden ? 16 : 0)
    }

    func updateTheme(nightMode: Bool, active: Bool, pressed: Bool = false) {
        self.nightMode = nightMode
        self.active = active
        
        timeButton.updateTheme(nightmod: nightMode, active: active)
        resetButton.updateTheme(nightmod: nightMode, active: active)
        
        glassBackgroundView?.overrideUserInterfaceStyle = nightMode ? .dark : .light
        
        if pressed {
            backgroundColor = StarMapControlTheme.pressedBackground(nightMode: nightMode, alpha: StarMapControlTheme.defaultBackgroundAlpha)
        } else {
            backgroundColor = active
            ? StarMapControlTheme.activeBackground(alpha: StarMapControlTheme.defaultBackgroundAlpha)
            : StarMapControlTheme.defaultBackground(nightMode: nightMode, alpha: StarMapControlTheme.defaultBackgroundAlpha)
        }
        
        layer.borderWidth = nightMode ? 2 : 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        glassBackgroundView?.frame = bounds
    }

    private func setupContent() {
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

        timeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        timeButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        timeButton.setImage(AstroIcon.template("ic_action_time"), for: .normal)
        timeButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        timeButton.addTarget(self, action: #selector(timeButtonTapped), for: .touchUpInside)
        timeButton.heightAnchor.constraint(equalToConstant: Self.height).isActive = true
        timeButton.onHighlightChange = { [weak self] isHighlighted in
            guard let self else { return }
            updateTheme(nightMode: nightMode, active: active, pressed: isHighlighted)
        }

        resetButton.setImage(.icCustomReset, for: .normal)
        resetButton.accessibilityLabel = localizedString("shared_string_reset")
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        resetButton.isHidden = true
        resetButton.widthAnchor.constraint(equalToConstant: Self.height).isActive = true
        resetButton.heightAnchor.constraint(equalToConstant: Self.height).isActive = true

        mainStack.addArrangedSubview(timeButton)
        mainStack.addArrangedSubview(resetButton)
        mainStack.axis = .horizontal
        mainStack.alignment = .center
        mainStack.spacing = 0
        mainStack.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)
        mainStack.isLayoutMarginsRelativeArrangement = true
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Self.height),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func timeButtonTapped() {
        onTimeButtonTapped?()
    }

    @objc private func resetButtonTapped() {
        onResetTapped?()
    }
}
