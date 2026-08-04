//
//  StatusCardCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class StatusCardCell: UITableViewCell {

    private enum Layout {
        static let cornerRadius: CGFloat = 24
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 20
        static let textSpacing: CGFloat = 6
        static let iconSpacing: CGFloat = 16
        static let trailingSize: CGFloat = 30
        static let actionRowHeight: CGFloat = 50
    }

    private let card = UIView()
    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    private let trailingContainer = UIView()
    private let iconView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let separator = UIView()
    private let actionRow = ElevationActionRow()

    private var descBottomConstraint: NSLayoutConstraint?
    private var actionConstraints: [NSLayoutConstraint] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.image = nil
        actionRow.action = nil
        spinner.stopAnimating()
    }

    func configure(icon: UIImage?,
                   iconTint: UIColor,
                   title: String,
                   description: String,
                   actionTitle: String?,
                   isSpinner: Bool,
                   action: (() -> Void)?) {
        titleLabel.text = title
        descLabel.text = description

        spinner.isHidden = !isSpinner
        iconView.isHidden = isSpinner
        if isSpinner {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
            iconView.image = icon?.withRenderingMode(.alwaysTemplate)
            iconView.tintColor = iconTint
        }

        if let actionTitle, let action {
            actionRow.configure(title: actionTitle)
            actionRow.action = action
            separator.isHidden = false
            actionRow.isHidden = false
            descBottomConstraint?.isActive = false
            NSLayoutConstraint.activate(actionConstraints)
        } else {
            actionRow.action = nil
            separator.isHidden = true
            actionRow.isHidden = true
            NSLayoutConstraint.deactivate(actionConstraints)
            descBottomConstraint?.isActive = true
        }
    }

    private func setupView() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .groupBg
        card.layer.cornerRadius = Layout.cornerRadius
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true

        descLabel.font = .preferredFont(forTextStyle: .subheadline)
        descLabel.textColor = .textColorSecondary
        descLabel.numberOfLines = 0
        descLabel.adjustsFontForContentSizeCategory = true

        iconView.contentMode = .scaleAspectFit
        separator.backgroundColor = .customSeparator

        [titleLabel, descLabel, trailingContainer, separator, actionRow].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }
        [iconView, spinner].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            trailingContainer.addSubview($0)
        }

        let descBottom = descLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -Layout.verticalInset)
        descBottomConstraint = descBottom

        actionConstraints = [
            separator.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: Layout.verticalInset),
            separator.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Layout.horizontalInset),
            separator.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -Layout.horizontalInset),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            actionRow.topAnchor.constraint(equalTo: separator.bottomAnchor),
            actionRow.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            actionRow.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            actionRow.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            actionRow.heightAnchor.constraint(equalToConstant: Layout.actionRowHeight)
        ]

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.horizontalInset),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.horizontalInset),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            trailingContainer.topAnchor.constraint(equalTo: card.topAnchor, constant: Layout.verticalInset),
            trailingContainer.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -Layout.horizontalInset),
            trailingContainer.widthAnchor.constraint(equalToConstant: Layout.trailingSize),
            trailingContainer.heightAnchor.constraint(equalToConstant: Layout.trailingSize),

            iconView.topAnchor.constraint(equalTo: trailingContainer.topAnchor),
            iconView.leadingAnchor.constraint(equalTo: trailingContainer.leadingAnchor),
            iconView.trailingAnchor.constraint(equalTo: trailingContainer.trailingAnchor),
            iconView.bottomAnchor.constraint(equalTo: trailingContainer.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: trailingContainer.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: trailingContainer.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: Layout.verticalInset),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Layout.horizontalInset),
            titleLabel.trailingAnchor.constraint(equalTo: trailingContainer.leadingAnchor, constant: -Layout.iconSpacing),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Layout.textSpacing),
            descLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Layout.horizontalInset),
            descLabel.trailingAnchor.constraint(equalTo: trailingContainer.leadingAnchor, constant: -Layout.iconSpacing)
        ])

        descBottom.isActive = true
    }
}
