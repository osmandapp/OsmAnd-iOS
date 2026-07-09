//
//  PlanRouteMenuActionCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

// MARK: - PlanRouteMenuActionCell

final class PlanRouteMenuActionCell: UITableViewCell {
    static let reuseId = "PlanRouteMenuActionCell"

    private static let iconSize: CGFloat = 24

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let iconView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(model: PlanRoutePointMenuViewController.RowModel) {
        let titleColor: UIColor
        if model.isDestructive {
            titleColor = .textColorDisruptive
        } else if model.isEnabled {
            titleColor = .textColorPrimary
        } else {
            titleColor = .textColorSecondary
        }
        titleLabel.text = model.title
        titleLabel.textColor = titleColor

        subtitleLabel.text = model.subtitle
        subtitleLabel.isHidden = model.subtitle == nil

        iconView.image = model.icon?.withRenderingMode(.alwaysTemplate)
        let iconColor: UIColor
        if model.isDestructive {
            iconColor = .iconColorDisruptive
        } else if model.isEnabled {
            iconColor = .iconColorActive
        } else {
            iconColor = .iconColorTertiary
        }
        iconView.tintColor = iconColor
        isUserInteractionEnabled = model.isEnabled || model.isDestructive
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .default

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.numberOfLines = 1

        subtitleLabel.font = .scaledSystemFont(ofSize: 13)
        subtitleLabel.textColor = .textColorSecondary
        subtitleLabel.numberOfLines = 1

        iconView.contentMode = .scaleAspectFit

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        [textStack, iconView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: iconView.leadingAnchor, constant: -8),

            iconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize)
        ])
    }
}
