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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isDestructive: Bool, showsDisclosure: Bool = false) {
        titleLabel.text = title
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
        accessibilityTraits = .button
    }

    private func setupCell() {
        let contentInsets = Self.contentInsets
        let minimumHeight = Self.minimumHeight
        backgroundColor = .groupBg
        selectionStyle = .default

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: contentInsets.leading),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -contentInsets.trailing),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: contentInsets.top),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -contentInsets.bottom),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumHeight)
        ])
    }
}
