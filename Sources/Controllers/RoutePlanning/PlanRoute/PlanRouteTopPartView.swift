//
//  PlanRouteTopPartView.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteTopPartView: UIView {
    private static let statusIconSize: CGFloat = 30
    private static let horizontalInset: CGFloat = 20

    var onTap: (() -> Void)?

    private let statusIconView = UIImageView()
    private let firstLineLabel = UILabel()
    private let secondLineLabel = UILabel()
    private let textStackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with info: PlanRouteInfo) {
        firstLineLabel.attributedText = makeFirstLine(info)
        secondLineLabel.attributedText = makeSecondLine(info)
    }

    private func setupView() {
        backgroundColor = .clear

        statusIconView.image = .templateImageNamed("ic_custom_plan_route")
        statusIconView.tintColor = .iconColorActive
        statusIconView.contentMode = .scaleAspectFit
        statusIconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusIconView)

        firstLineLabel.numberOfLines = 1
        firstLineLabel.adjustsFontForContentSizeCategory = true
        secondLineLabel.numberOfLines = 1
        secondLineLabel.adjustsFontForContentSizeCategory = true

        textStackView.axis = .vertical
        textStackView.spacing = 2
        textStackView.alignment = .leading
        textStackView.addArrangedSubview(firstLineLabel)
        textStackView.addArrangedSubview(secondLineLabel)
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textStackView)

        let horizontalInset = Self.horizontalInset
        let statusIconSize = Self.statusIconSize

        NSLayoutConstraint.activate([
            statusIconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalInset),
            statusIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusIconView.widthAnchor.constraint(equalToConstant: statusIconSize),
            statusIconView.heightAnchor.constraint(equalToConstant: statusIconSize),

            textStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStackView.leadingAnchor.constraint(equalTo: statusIconView.trailingAnchor, constant: 12),
            textStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalInset)
        ])

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onViewTapped))
        addGestureRecognizer(tapRecognizer)
    }

    private func makeFirstLine(_ info: PlanRouteInfo) -> NSAttributedString {
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        let primary: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.textColorPrimary]
        let secondary: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.textColorSecondary]

        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: formattedDistance(info.totalDistance), attributes: primary))

        guard info.showsTime else { return result }

        result.append(NSAttributedString(string: "  •  ", attributes: secondary))
        result.append(NSAttributedString(string: formattedDuration(info.duration), attributes: secondary))
        if let arrival = info.arrivalTime {
            result.append(NSAttributedString(string: " (\(formattedTime(arrival)))", attributes: secondary))
        }
        return result
    }

    private func makeSecondLine(_ info: PlanRouteInfo) -> NSAttributedString {
        let subheadFont = UIFont.preferredFont(forTextStyle: .subheadline)
        let attributes: [NSAttributedString.Key: Any] = [.font: subheadFont, .foregroundColor: UIColor.textColorSecondary]

        let result = NSMutableAttributedString()
        result.append(symbolAttachment("arrow.up.right", font: subheadFont))
        result.append(NSAttributedString(string: " \(formattedDistance(info.uphill))   ", attributes: attributes))
        result.append(symbolAttachment("arrow.down.right", font: subheadFont))
        result.append(NSAttributedString(string: " \(formattedDistance(info.downhill))", attributes: attributes))
        result.append(NSAttributedString(string: "   |   ", attributes: attributes))
        result.append(NSAttributedString(string: "\(formattedDistance(info.mapCenterDistance)) • \(Int(info.bearing))°", attributes: attributes))
        return result
    }

    private func symbolAttachment(_ name: String, font: UIFont) -> NSAttributedString {
        let attachment = NSTextAttachment()
        let configuration = UIImage.SymbolConfiguration(font: font)
        attachment.image = UIImage(systemName: name, withConfiguration: configuration)?.withTintColor(.textColorSecondary, renderingMode: .alwaysOriginal)
        return NSAttributedString(attachment: attachment)
    }

    private func formattedDistance(_ meters: Double) -> String {
        OAOsmAndFormatter.getFormattedDistance(Float(meters))
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        OAOsmAndFormatter.getFormattedTimeInterval(duration, shortFormat: true)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    @objc private func onViewTapped() {
        onTap?()
    }
}
