//
//  PlanRouteProfileGroupCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteProfileGroupCell: UITableViewCell {

    private static let horizontalInset: CGFloat = 16
    private static let minimumHeight: CGFloat = 53
    private static let verticalInset: CGFloat = 11
    private static let iconSize: CGFloat = 30
    private static let iconTitleSpacing: CGFloat = 26
    private static let titleLeadingInset = horizontalInset + iconSize + iconTitleSpacing
    private static let optionsButtonSize: CGFloat = 30

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let distanceLabel = UILabel()
    private let optionsButton = UIButton(type: .system)
    private let labelsStackView = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory else { return }
        updateLabelsLayout()
    }

    func configure(title: String, distanceText: String, icon: UIImage?, tintColor: UIColor, menu: UIMenu) {
        iconView.image = icon?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = tintColor
        titleLabel.text = title
        distanceLabel.text = distanceText
        optionsButton.menu = menu
        distanceLabel.isAccessibilityElement = false
        titleLabel.accessibilityLabel = [title, distanceText].joined(separator: ", ")
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .none
        separatorInset = UIEdgeInsets(top: 0,
                                      left: Self.titleLeadingInset,
                                      bottom: 0,
                                      right: Self.horizontalInset)

        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        distanceLabel.font = .scaledSystemFont(ofSize: 17)
        distanceLabel.textColor = .textColorSecondary
        distanceLabel.numberOfLines = 0
        distanceLabel.adjustsFontForContentSizeCategory = true
        distanceLabel.lineBreakMode = .byWordWrapping
        distanceLabel.setContentHuggingPriority(.required, for: .horizontal)
        distanceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        distanceLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        labelsStackView.spacing = 8
        labelsStackView.addArrangedSubview(titleLabel)
        labelsStackView.addArrangedSubview(distanceLabel)
        updateLabelsLayout()

        var configuration = UIButton.Configuration.plain()
        configuration.image = .icCustomOverflowMenuStroke
        configuration.baseForegroundColor = .iconColorDefault
        configuration.background.backgroundColor = .clear
        configuration.contentInsets = .zero
        optionsButton.configuration = configuration
        optionsButton.showsMenuAsPrimaryAction = true
        optionsButton.accessibilityLabel = localizedString("shared_string_options")
        optionsButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        iconView.isAccessibilityElement = false

        [iconView, labelsStackView, optionsButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.horizontalInset),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: Self.verticalInset),
            iconView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -Self.verticalInset),
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize),

            labelsStackView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: Self.iconTitleSpacing),
            labelsStackView.trailingAnchor.constraint(equalTo: optionsButton.leadingAnchor, constant: -12),
            labelsStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            labelsStackView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 10),
            labelsStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            optionsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.horizontalInset),
            optionsButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            optionsButton.widthAnchor.constraint(equalToConstant: Self.optionsButtonSize),
            optionsButton.heightAnchor.constraint(equalToConstant: Self.optionsButtonSize),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumHeight)
        ])
    }

    private func updateLabelsLayout() {
        let usesVerticalLayout = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        labelsStackView.axis = usesVerticalLayout ? .vertical : .horizontal
        labelsStackView.alignment = usesVerticalLayout ? .fill : .firstBaseline
        labelsStackView.distribution = usesVerticalLayout ? .fillProportionally : .fill
    }
}
