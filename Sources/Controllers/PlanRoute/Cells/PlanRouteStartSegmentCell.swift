//
//  PlanRouteStartSegmentCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteStartSegmentCell: UITableViewCell {

    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .default

        titleLabel.text = localizedString("gpx_start_new_segment")
        isAccessibilityElement = true
        accessibilityLabel = titleLabel.text
        accessibilityTraits = .button
        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .iconColorActive
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
        ])
    }
}
