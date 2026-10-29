//
//  PlanRouteActionCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteActionCell: UITableViewCell {

    private static let contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 16)
    private static let minimumHeight: CGFloat = 52

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, subtitle: String? = nil, isDestructive: Bool, showsDisclosure: Bool = false) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
        if isDestructive {
            titleLabel.textColor = .textColorDisruptive
        } else {
            titleLabel.textColor = showsDisclosure ? .textColorPrimary : .iconColorActive
        }
        accessoryType = showsDisclosure ? .disclosureIndicator : .none
        editingAccessoryType = accessoryType
        let contentInsets = Self.contentInsets
        separatorInset = UIEdgeInsets(top: 0, left: contentInsets.leading, bottom: 0, right: contentInsets.trailing)
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityValue = subtitle
        accessibilityTraits = .button
    }

    func configureForContinuation(title: String = localizedString("plan_route_continue_with_different_type"), mode: OAApplicationMode?) {
        let modeTitle = mode?.toHumanString() ?? localizedString("plan_route_straight_line")
        let subtitle = String(format: localizedString("ltr_or_rtl_combine_via_colon"), localizedString("shared_string_next"), modeTitle)
        configure(title: title,
                  subtitle: subtitle,
                  isDestructive: false,
                  showsDisclosure: true)
    }

    private func setupCell() {
        let contentInsets = Self.contentInsets
        let minimumHeight = Self.minimumHeight
        backgroundColor = .groupBg
        selectionStyle = .default

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.font = .scaledSystemFont(ofSize: 15)
        subtitleLabel.textColor = .textColorSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.adjustsFontForContentSizeCategory = true

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: contentInsets.leading),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -contentInsets.trailing),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: contentInsets.top),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -contentInsets.bottom),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumHeight)
        ])
    }
}
