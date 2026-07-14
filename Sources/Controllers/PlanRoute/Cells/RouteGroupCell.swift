//
//  RouteGroupCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class RouteGroupCell: UITableViewCell {

    private static let leadingInset: CGFloat = 20
    private static let iconSize: CGFloat = 24
    private static let iconTitleGap: CGFloat = 16
    private static let trailingInset: CGFloat = 16
    private static let distanceGap: CGFloat = 8
    private static let titleLeadingInset: CGFloat = leadingInset + iconSize + iconTitleGap

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let distanceLabel = UILabel()
    private var titleLeadingWithIcon: NSLayoutConstraint!
    private var titleLeadingWithoutIcon: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(group: PlanRouteProfileGroup) {
        let mode = group.appMode
        if let mode {
            iconView.image = mode.getIcon()?.withRenderingMode(.alwaysTemplate)
            titleLabel.text = mode.toHumanString()
        } else {
            iconView.image = .templateImageNamed("ic_custom_straight_line")
            titleLabel.text = localizedString("plan_route_straight_line")
        }
        iconView.isHidden = false
        iconView.tintColor = .iconColorActive
        distanceLabel.text = formattedDistance(group.distance)
        titleLeadingWithIcon.isActive = true
        titleLeadingWithoutIcon.isActive = false
        separatorInset = UIEdgeInsets(top: 0, left: Self.titleLeadingInset, bottom: 0, right: 0)
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = [titleLabel.text, distanceLabel.text].compactMap { $0 }.joined(separator: ", ")
    }

    func configureWholeSegment(segment: PlanRouteSegment) {
        iconView.isHidden = true
        titleLabel.text = localizedString("plan_route_change_for_whole_segment")
        distanceLabel.text = formattedDistance(segment.distance)
        titleLeadingWithIcon.isActive = false
        titleLeadingWithoutIcon.isActive = true
        separatorInset = UIEdgeInsets(top: 0, left: Self.leadingInset, bottom: 0, right: 0)
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = [titleLabel.text, distanceLabel.text].compactMap { $0 }.joined(separator: ", ")
    }

    private func setupCell() {
        backgroundColor = .groupBg
        accessoryType = .disclosureIndicator
        selectionStyle = .default

        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .textColorPrimary

        distanceLabel.font = .scaledSystemFont(ofSize: 17)
        distanceLabel.textColor = .textColorSecondary
        distanceLabel.setContentHuggingPriority(.required, for: .horizontal)

        [iconView, titleLabel, distanceLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        titleLeadingWithIcon = titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: Self.iconTitleGap)
        titleLeadingWithoutIcon = titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.leadingInset)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.leadingInset),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize),

            titleLeadingWithIcon,
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),

            distanceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: Self.distanceGap),
            distanceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.trailingInset),
            distanceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    private func formattedDistance(_ meters: Double) -> String {
        OAOsmAndFormatter.getFormattedDistance(Float(meters)) ?? ""
    }
}
