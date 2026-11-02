//
//  InclinometerThresholdsLegendCell.swift
//  OsmAnd Maps
//
//  Created by Eugene Zmeuk on 02.11.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

/// Legend under the inclinometer thresholds slider: the warning and the critical angle
/// side by side, each with its zone colour dot, the title and the value below it.
final class InclinometerThresholdsLegendCell: UITableViewCell {

    static let cellIdentifier = "InclinometerThresholdsLegendCell"

    private static let dotSize: CGFloat = 8
    private static let dotSpacing: CGFloat = 8

    private let warningColumn = LegendColumn()
    private let criticalColumn = LegendColumn()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        let stack = UIStackView(arrangedSubviews: [warningColumn, criticalColumn])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(warningTitle: String, warningValue: String, warningColor: UIColor,
                   criticalTitle: String, criticalValue: String, criticalColor: UIColor) {
        warningColumn.configure(title: warningTitle, value: warningValue, color: warningColor)
        criticalColumn.configure(title: criticalTitle, value: criticalValue, color: criticalColor)
    }

    func updateValues(warning: String, critical: String) {
        warningColumn.valueLabel.text = warning
        criticalColumn.valueLabel.text = critical
    }

    private final class LegendColumn: UIView {

        let dotView = UIView()
        let titleLabel = UILabel()
        let valueLabel = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)
            dotView.layer.cornerRadius = InclinometerThresholdsLegendCell.dotSize / 2
            dotView.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.font = .preferredFont(forTextStyle: .body)
            titleLabel.adjustsFontForContentSizeCategory = true
            titleLabel.textColor = .textColorPrimary
            titleLabel.numberOfLines = 0
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            valueLabel.font = .preferredFont(forTextStyle: .footnote)
            valueLabel.adjustsFontForContentSizeCategory = true
            valueLabel.textColor = .textColorSecondary
            valueLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(dotView)
            addSubview(titleLabel)
            addSubview(valueLabel)
            let dotSize = InclinometerThresholdsLegendCell.dotSize
            NSLayoutConstraint.activate([
                dotView.leadingAnchor.constraint(equalTo: leadingAnchor),
                dotView.widthAnchor.constraint(equalToConstant: dotSize),
                dotView.heightAnchor.constraint(equalToConstant: dotSize),
                dotView.centerYAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor, constant: -dotSize / 2 - 1),
                titleLabel.leadingAnchor.constraint(equalTo: dotView.trailingAnchor, constant: InclinometerThresholdsLegendCell.dotSpacing),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
                titleLabel.topAnchor.constraint(equalTo: topAnchor),
                valueLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                valueLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
                valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
                valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func configure(title: String, value: String, color: UIColor) {
            dotView.backgroundColor = color
            titleLabel.text = title
            valueLabel.text = value
        }
    }
}
