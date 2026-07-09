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

    private let timeButton = StarMapTimeControlButton()
    private let resetButton = StarMapResetButton()
    private let mainStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContent()
        updateTheme(nightMode: OADayNightHelper.instance().isNightMode(), active: false)
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

    func updateTheme(nightMode: Bool, active: Bool) {
        StarMapGlassBackground.apply(
            to: self,
            active: active,
            nightMode: nightMode,
            cornerRadius: Self.cornerRadius
        )
        timeButton.nightMode = nightMode
        timeButton.active = active
        resetButton.nightMode = nightMode
        resetButton.active = active
        
        backgroundColor = active
        ? StarMapControlTheme.activeBackground(alpha: 0.5)
        : StarMapControlTheme.defaultBackground(nightMode: nightMode, alpha: 0.5)
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

        timeButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        timeButton.addTarget(self, action: #selector(timeButtonTapped), for: .touchUpInside)
        timeButton.heightAnchor.constraint(equalToConstant: Self.height).isActive = true

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
