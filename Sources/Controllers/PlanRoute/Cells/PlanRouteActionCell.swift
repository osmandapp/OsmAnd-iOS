//
//  PlanRouteActionCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteActionCell: UITableViewCell {

    private static let leadingInset: CGFloat = 20
    private static let trailingInset: CGFloat = 16
    private static let verticalInset: CGFloat = 14

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
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .default

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.leadingInset),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.trailingInset),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.verticalInset),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.verticalInset)
        ])
    }
}
