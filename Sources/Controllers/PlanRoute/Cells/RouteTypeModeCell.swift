//
//  RouteTypeModeCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class RouteTypeModeCell: UITableViewCell {
    static let reuseId = "RouteTypeModeCell"

    private static let checkmarkSize: CGFloat = 20
    private static let iconSize: CGFloat = 24
    private static let gap: CGFloat = 8
    private static let leadingInset: CGFloat = 16
    private static let verticalPadding: CGFloat = 12

    private let checkmarkView = UIImageView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, icon: UIImage?, tintColor: UIColor, isSelected: Bool) {
        iconView.image = icon?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = tintColor
        titleLabel.text = title
        checkmarkView.image = isSelected ? .templateImageNamed("ic_checkmark_default") : nil
        accessoryType = .none
        let inset = Self.leadingInset + Self.checkmarkSize + Self.gap + Self.iconSize + Self.gap
        separatorInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: Self.leadingInset)
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .default

        checkmarkView.contentMode = .scaleAspectFit
        checkmarkView.tintColor = .iconColorActive
        checkmarkView.isAccessibilityElement = false

        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 0

        [checkmarkView, iconView, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            checkmarkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.leadingInset),
            checkmarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkView.widthAnchor.constraint(equalToConstant: Self.checkmarkSize),
            checkmarkView.heightAnchor.constraint(equalToConstant: Self.checkmarkSize),

            iconView.leadingAnchor.constraint(equalTo: checkmarkView.trailingAnchor, constant: Self.gap),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: Self.gap),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -Self.leadingInset),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: Self.verticalPadding),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -Self.verticalPadding),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 52)
        ])
    }
}
