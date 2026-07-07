//
//  PlanRouteProfileGroupCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteProfileGroupCell: UITableViewCell {
    static let cellReuseId = "PlanRouteProfileGroupCell"

    private static let iconSize: CGFloat = 24
    private static let optionsButtonSize: CGFloat = 30

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let distanceLabel = UILabel()
    private let optionsButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, distanceText: String, icon: UIImage?, tintColor: UIColor, menu: UIMenu) {
        iconView.image = icon?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = tintColor
        titleLabel.text = title
        distanceLabel.text = distanceText
        optionsButton.menu = menu
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .none

        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .textColorPrimary

        distanceLabel.font = .scaledSystemFont(ofSize: 17)
        distanceLabel.textColor = .textColorSecondary
        distanceLabel.setContentHuggingPriority(.required, for: .horizontal)

        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage.templateImageNamed("ic_custom_overflow_menu_stroke")
        configuration.baseForegroundColor = .iconColorDefault
        configuration.background.backgroundColor = .clear
        configuration.contentInsets = .zero
        optionsButton.configuration = configuration
        optionsButton.showsMenuAsPrimaryAction = true

        [iconView, titleLabel, distanceLabel, optionsButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 10),

            distanceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            distanceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            optionsButton.leadingAnchor.constraint(equalTo: distanceLabel.trailingAnchor, constant: 12),
            optionsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            optionsButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            optionsButton.widthAnchor.constraint(equalToConstant: Self.optionsButtonSize),
            optionsButton.heightAnchor.constraint(equalToConstant: Self.optionsButtonSize)
        ])
    }
}
