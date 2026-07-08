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
    private static let smallButtonSize: CGFloat = 40

    var onTimeButtonTapped: (() -> Void)?
    var onResetTapped: (() -> Void)?

    private let timeButton = StarMapTimeControlButton()
    private let resetButton = StarMapResetButton()

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

        timeButton.setImage(AstroIcon.template("ic_action_time"), for: .normal)
        timeButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        timeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        timeButton.addTarget(self, action: #selector(timeButtonTapped), for: .touchUpInside)

        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        resetButton.isHidden = true
        resetButton.widthAnchor.constraint(equalToConstant: Self.smallButtonSize).isActive = true
        resetButton.heightAnchor.constraint(equalToConstant: Self.smallButtonSize).isActive = true

        let stack = UIStackView(arrangedSubviews: [timeButton, resetButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 4
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Self.height),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func timeButtonTapped() {
        onTimeButtonTapped?()
    }

    @objc private func resetButtonTapped() {
        onResetTapped?()
    }
}
