//
//  AnalyzeCardCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class AnalyzeCardCell: UITableViewCell {

    let cardView = UIView()

    private enum Layout {
        static let cornerRadius: CGFloat = 24
        static let horizontalInset: CGFloat = 16
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cardView.subviews.forEach { $0.removeFromSuperview() }
    }

    private func setupView() {
        isAccessibilityElement = false
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = .groupBg
        cardView.layer.cornerRadius = Layout.cornerRadius
        cardView.clipsToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.horizontalInset),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.horizontalInset),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
