//
//  PlanRoutePointCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRoutePointCell: UITableViewCell {

    private static let horizontalInset: CGFloat = 16
    private static let minimumHeight: CGFloat = 68
    private static let verticalInset: CGFloat = 12
    private static let circleSize: CGFloat = 28
    private static let deleteButtonSize: CGFloat = 30
    private static let deleteNumberSpacing: CGFloat = 26
    private static let numberTextSpacing: CGFloat = 16
    private static let textLeadingInset = horizontalInset + deleteButtonSize + deleteNumberSpacing + circleSize + numberTextSpacing

    var onDelete: (() -> Void)?

    private let deleteButton = UIButton(type: .system)
    private let numberLabel = UILabel()
    private let numberContainer = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with point: PlanRoutePoint, tintColor: UIColor, showsFullWidthSeparator: Bool) {
        separatorInset = showsFullWidthSeparator
            ? .zero
            : UIEdgeInsets(top: 0,
                           left: Self.textLeadingInset,
                           bottom: 0,
                           right: Self.horizontalInset)
        numberLabel.text = "\(point.indexInSegment + 1)"
        numberContainer.backgroundColor = tintColor
        titleLabel.text = point.name
        subtitleLabel.text = subtitle(for: point)
        numberLabel.isAccessibilityElement = false
        subtitleLabel.isAccessibilityElement = false
        titleLabel.accessibilityLabel = [numberLabel.text, titleLabel.text, subtitleLabel.text]
            .compactMap { $0 }.joined(separator: ", ")
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .none
        showsReorderControl = true

        deleteButton.setImage(.icCustomDelete, for: .normal)
        deleteButton.addTarget(self, action: #selector(onDeleteTapped), for: .touchUpInside)
        deleteButton.accessibilityLabel = localizedString("shared_string_delete")

        numberContainer.layer.cornerRadius = Self.circleSize / 2
        numberContainer.layer.borderWidth = 2
        numberContainer.layer.borderColor = UIColor.white.cgColor
        numberLabel.font = .scaledSystemFont(ofSize: 13, weight: .semibold)
        numberLabel.textColor = .white
        numberLabel.textAlignment = .center
        numberLabel.adjustsFontForContentSizeCategory = true
        numberLabel.adjustsFontSizeToFitWidth = true
        numberLabel.minimumScaleFactor = 0.5
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberContainer.addSubview(numberLabel)

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        subtitleLabel.font = .scaledSystemFont(ofSize: 15)
        subtitleLabel.textColor = .textColorSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        let textStack = UIStackView(arrangedSubviews: [subtitleLabel, titleLabel])
        textStack.axis = .vertical
        textStack.distribution = .fillProportionally
        textStack.spacing = 2

        [deleteButton, numberContainer, textStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        let textTopConstraint = textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.verticalInset)
        let textBottomConstraint = textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.verticalInset)

        NSLayoutConstraint.activate([
            deleteButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.horizontalInset),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: Self.deleteButtonSize),
            deleteButton.heightAnchor.constraint(equalToConstant: Self.deleteButtonSize),

            numberContainer.leadingAnchor.constraint(equalTo: deleteButton.trailingAnchor, constant: Self.deleteNumberSpacing),
            numberContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            numberContainer.widthAnchor.constraint(equalToConstant: Self.circleSize),
            numberContainer.heightAnchor.constraint(equalToConstant: Self.circleSize),
            numberLabel.centerXAnchor.constraint(equalTo: numberContainer.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: numberContainer.centerYAnchor),
            numberLabel.leadingAnchor.constraint(greaterThanOrEqualTo: numberContainer.leadingAnchor, constant: 2),
            numberLabel.trailingAnchor.constraint(lessThanOrEqualTo: numberContainer.trailingAnchor, constant: -2),

            textStack.leadingAnchor.constraint(equalTo: numberContainer.trailingAnchor, constant: Self.numberTextSpacing),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.horizontalInset),
            textTopConstraint,
            textBottomConstraint,
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumHeight)
        ])
    }

    private func subtitle(for point: PlanRoutePoint) -> String {
        if point.isStart {
            return localizedString("start_point")
        }
        let distance = OAOsmAndFormatter.getFormattedDistance(Float(point.distanceFromStart)) ?? ""
        if point.isDestination {
            return "\(distance) • \(localizedString("route_descr_destination"))"
        }
        return "\(distance) • \(Int(point.bearing))°"
    }

    @objc private func onDeleteTapped() {
        onDelete?()
    }
}
