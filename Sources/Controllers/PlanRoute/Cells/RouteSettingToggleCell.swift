//
//  RouteSettingToggleCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class RouteSettingToggleCell: UITableViewCell {

    private static let iconSize: CGFloat = 30
    private static let minimumHeight: CGFloat = 52
    private static let verticalPadding: CGFloat = 11

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let toggle = UISwitch()
    private let controlsStackView = UIStackView()
    private var onToggle: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onToggle = nil
    }

    func configure(title: String, icon: UIImage?, tintColor: UIColor, isOn: Bool, onToggle: @escaping (Bool) -> Void) {
        titleLabel.text = title
        iconView.image = icon?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = tintColor
        toggle.isOn = isOn
        self.onToggle = onToggle
        titleLabel.isAccessibilityElement = false
        iconView.isAccessibilityElement = false
        toggle.accessibilityLabel = title
    }

    private func setupCell() {
        let iconSize = Self.iconSize
        let minimumHeight = Self.minimumHeight
        let verticalPadding = Self.verticalPadding
        backgroundColor = .groupBg
        selectionStyle = .none
        separatorInset = UIEdgeInsets(top: 0, left: 62, bottom: 0, right: 16)

        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        toggle.onTintColor = .accentsGreen
        toggle.setContentCompressionResistancePriority(.required, for: .horizontal)
        toggle.setContentHuggingPriority(.required, for: .horizontal)
        toggle.addTarget(self, action: #selector(onToggleSwitched), for: .valueChanged)

        controlsStackView.axis = .horizontal
        controlsStackView.alignment = .center
        controlsStackView.spacing = 8
        controlsStackView.addArrangedSubview(titleLabel)
        controlsStackView.addArrangedSubview(toggle)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        controlsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)
        contentView.addSubview(controlsStackView)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize),

            controlsStackView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            controlsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            controlsStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            controlsStackView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: verticalPadding),
            controlsStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -verticalPadding),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumHeight)
        ])
    }

    @objc private func onToggleSwitched() {
        onToggle?(toggle.isOn)
    }
}
