//
//  PlanRoutePointCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRoutePointCell: UITableViewCell {

    private static let circleSize: CGFloat = 28
    private static let deleteSize: CGFloat = 24

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

    func configure(with point: PlanRoutePoint, tintColor: UIColor) {
        numberLabel.text = "\(point.index + 1)"
        numberContainer.backgroundColor = tintColor
        titleLabel.text = point.name
        subtitleLabel.text = subtitle(for: point)
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .none
        showsReorderControl = true

        deleteButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.addTarget(self, action: #selector(onDeleteTapped), for: .touchUpInside)

        numberContainer.layer.cornerRadius = Self.circleSize / 2
        numberContainer.layer.borderWidth = 2
        numberContainer.layer.borderColor = UIColor.white.cgColor
        numberLabel.font = .scaledSystemFont(ofSize: 13, weight: .semibold)
        numberLabel.textColor = .white
        numberLabel.textAlignment = .center
        numberLabel.adjustsFontSizeToFitWidth = true
        numberLabel.minimumScaleFactor = 0.5
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberContainer.addSubview(numberLabel)

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .textColorPrimary
        subtitleLabel.font = .scaledSystemFont(ofSize: 13)
        subtitleLabel.textColor = .textColorSecondary

        let textStack = UIStackView(arrangedSubviews: [subtitleLabel, titleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        [deleteButton, numberContainer, textStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            deleteButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: Self.deleteSize),
            deleteButton.heightAnchor.constraint(equalToConstant: Self.deleteSize),

            numberContainer.leadingAnchor.constraint(equalTo: deleteButton.trailingAnchor, constant: 12),
            numberContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            numberContainer.widthAnchor.constraint(equalToConstant: Self.circleSize),
            numberContainer.heightAnchor.constraint(equalToConstant: Self.circleSize),
            numberLabel.centerXAnchor.constraint(equalTo: numberContainer.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: numberContainer.centerYAnchor),
            numberLabel.leadingAnchor.constraint(greaterThanOrEqualTo: numberContainer.leadingAnchor, constant: 2),
            numberLabel.trailingAnchor.constraint(lessThanOrEqualTo: numberContainer.trailingAnchor, constant: -2),

            textStack.leadingAnchor.constraint(equalTo: numberContainer.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8)
        ])
    }

    private func subtitle(for point: PlanRoutePoint) -> String {
        if point.isStart {
            return localizedString("start_point")
        }
        let distance = OAOsmAndFormatter.getFormattedDistance(Float(point.distanceFromPrevious)) ?? ""
        if point.isDestination {
            return "\(distance) • \(localizedString("route_descr_destination"))"
        }
        return "\(distance) • \(Int(point.bearing))°"
    }

    @objc private func onDeleteTapped() {
        onDelete?()
    }
}
