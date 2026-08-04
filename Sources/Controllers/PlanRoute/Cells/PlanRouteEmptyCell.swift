//
//  PlanRouteEmptyCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteEmptyCell: UITableViewCell {

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 20
        static let textSpacing: CGFloat = 6
        static let iconSpacing: CGFloat = 16
        static let iconSize: CGFloat = 30
    }

    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let iconView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, description: String, icon: UIImage?, iconTint: UIColor) {
        titleLabel.text = title
        descriptionLabel.text = description
        iconView.image = icon
        iconView.tintColor = iconTint
        titleLabel.accessibilityLabel = [title, description].joined(separator: ". ")
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .none

        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true

        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        descriptionLabel.textColor = .textColorSecondary
        descriptionLabel.numberOfLines = 0
        descriptionLabel.adjustsFontForContentSizeCategory = true

        iconView.contentMode = .scaleAspectFit
        iconView.isAccessibilityElement = false
        descriptionLabel.isAccessibilityElement = false

        let textStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        textStack.axis = .vertical
        textStack.spacing = Layout.textSpacing

        [textStack, iconView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.verticalInset),
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.horizontalInset),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Layout.verticalInset),

            iconView.leadingAnchor.constraint(equalTo: textStack.trailingAnchor, constant: Layout.iconSpacing),
            iconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.horizontalInset),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.verticalInset),
            iconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Layout.iconSize)
        ])
    }
}
