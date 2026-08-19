//
//  PlanRouteSegmentGapCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteSegmentGapCell: UITableViewCell {

    private enum Constants {
        static let horizontalInset: CGFloat = 16
        static let topInset: CGFloat = 10
        static let iconSize: CGFloat = 30
        static let iconTitleSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 26
    }

    private let borderView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateBorderColor()
    }

    func configure(title: String) {
        titleLabel.text = title
        accessibilityLabel = title
    }

    private func setupCell() {
        let horizontalInset = Constants.horizontalInset
        let topInset = Constants.topInset
        let iconSize = Constants.iconSize
        let iconTitleSpacing = Constants.iconTitleSpacing
        let cornerRadius = Constants.cornerRadius

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        separatorInset = UIEdgeInsets(top: 0, left: .greatestFiniteMagnitude, bottom: 0, right: 0)
        isAccessibilityElement = true

        borderView.layer.borderWidth = 1
        borderView.layer.cornerRadius = cornerRadius
        updateBorderColor()

        iconView.image = .icCustomSegmentsGap
        iconView.tintColor = .iconColorDefault
        iconView.contentMode = .scaleAspectFit
        iconView.isAccessibilityElement = false

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .textColorSecondary
        titleLabel.adjustsFontForContentSizeCategory = true

        borderView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(borderView)
        [iconView, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            borderView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            borderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topInset),
            borderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            iconView.leadingAnchor.constraint(equalTo: borderView.leadingAnchor, constant: horizontalInset),
            iconView.centerYAnchor.constraint(equalTo: borderView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: iconTitleSpacing),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: borderView.trailingAnchor, constant: -horizontalInset),
            titleLabel.centerYAnchor.constraint(equalTo: borderView.centerYAnchor)
        ])
    }

    private func updateBorderColor() {
        borderView.layer.borderColor = UIColor.customSeparatorSolid.resolvedColor(with: traitCollection).cgColor
    }
}
