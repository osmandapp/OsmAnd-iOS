//
//  RouteSettingNavigationCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class RouteSettingNavigationCell: UITableViewCell {

    private static let iconSize: CGFloat = 30
    private static let minimumHeight: CGFloat = 52
    private static let verticalPadding: CGFloat = 11

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let labelsStackView = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, value: String? = nil, icon: UIImage?, tintColor: UIColor) {
        titleLabel.text = title
        valueLabel.text = value
        valueLabel.isHidden = value?.isEmpty ?? true
        iconView.image = icon?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = tintColor
        isAccessibilityElement = true
        accessibilityLabel = [title, value].compactMap { $0 }.joined(separator: ", ")
        accessibilityTraits = .button
    }

    private func setupCell() {
        let iconSize = Self.iconSize
        let minimumHeight = Self.minimumHeight
        let verticalPadding = Self.verticalPadding
        backgroundColor = .groupBg
        accessoryType = .disclosureIndicator
        selectionStyle = .default
        separatorInset = UIEdgeInsets(top: 0, left: 62, bottom: 0, right: 16)

        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)

        valueLabel.font = .scaledSystemFont(ofSize: 17)
        valueLabel.textColor = .textColorSecondary
        valueLabel.numberOfLines = 0
        valueLabel.lineBreakMode = .byWordWrapping
        valueLabel.textAlignment = .right
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        labelsStackView.axis = .horizontal
        labelsStackView.alignment = .center
        labelsStackView.spacing = 8
        labelsStackView.addArrangedSubview(titleLabel)
        labelsStackView.addArrangedSubview(valueLabel)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)
        contentView.addSubview(labelsStackView)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize),

            labelsStackView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            labelsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            labelsStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            labelsStackView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: verticalPadding),
            labelsStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -verticalPadding),

            valueLabel.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.5),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumHeight)
        ])
    }
}
