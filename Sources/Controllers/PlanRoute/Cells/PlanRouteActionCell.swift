//
//  PlanRouteActionCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteActionCell: UITableViewCell {

    private static let contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 16)

    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isDestructive: Bool) {
        titleLabel.text = title
        titleLabel.textColor = isDestructive ? .textColorDisruptive : .iconColorActive
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = .button
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .default

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.contentInsets.leading),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.contentInsets.trailing),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.contentInsets.top),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.contentInsets.bottom)
        ])
    }
}
