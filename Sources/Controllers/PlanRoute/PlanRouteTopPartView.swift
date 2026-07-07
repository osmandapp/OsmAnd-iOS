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
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var onTap: (() -> Void)?

    private let statusIconView = UIImageView()
    private let firstLineLabel = UILabel()
    private let secondLineLabel = UILabel()
    private let textStackView = UIStackView()
    private var lastRenderSignature: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with info: PlanRouteInfo) {
        let totalDistance = formattedDistance(info.totalDistance)
        let uphill = formattedDistance(info.uphill)
        let downhill = formattedDistance(info.downhill)
        let mapCenterDistance = formattedDistance(info.mapCenterDistance)
        let duration = info.showsTime ? formattedDuration(info.duration) : ""
        let arrivalTime = info.arrivalTime.map { formattedTime($0) } ?? ""
        let bearing = "\(Int(info.bearing))"
        let signature = [
            totalDistance,
            duration,
            arrivalTime,
            uphill,
            downhill,
            mapCenterDistance,
            bearing,
            info.showsTime ? "1" : "0"
        ].joined(separator: "|")
        guard lastRenderSignature != signature else { return }
        lastRenderSignature = signature
        firstLineLabel.attributedText = makeFirstLine(info,
                                                      totalDistance: totalDistance,
                                                      duration: duration,
                                                      arrivalTime: arrivalTime)
        secondLineLabel.attributedText = makeSecondLine(uphill: uphill,
                                                        downhill: downhill,
                                                        mapCenterDistance: mapCenterDistance,
                                                        bearing: bearing)
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

    private func makeFirstLine(_ info: PlanRouteInfo,
                               totalDistance: String,
                               duration: String,
                               arrivalTime: String) -> NSAttributedString {
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        let primary: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.textColorPrimary]
        let secondary: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.textColorSecondary]

        let result = NSMutableAttributedString()
        let distanceParts = totalDistance.components(separatedBy: " ")
        let distanceNumber = distanceParts.dropLast().joined(separator: " ")
        let distanceUnit = " " + (distanceParts.last ?? "")
        result.append(NSAttributedString(string: distanceNumber, attributes: primary))
        result.append(NSAttributedString(string: distanceUnit, attributes: secondary))

        guard info.showsTime else { return result }

        result.append(NSAttributedString(string: "  •  ", attributes: secondary))
        result.append(NSAttributedString(string: duration, attributes: secondary))
        if !arrivalTime.isEmpty {
            result.append(NSAttributedString(string: " (\(arrivalTime))", attributes: secondary))
        }
        return result
    }

    private func makeSecondLine(uphill: String,
                                downhill: String,
                                mapCenterDistance: String,
                                bearing: String) -> NSAttributedString {
        let subheadFont = UIFont.preferredFont(forTextStyle: .subheadline)
        let attributes: [NSAttributedString.Key: Any] = [.font: subheadFont, .foregroundColor: UIColor.textColorSecondary]

        let result = NSMutableAttributedString()
        result.append(symbolAttachment("arrow.up.right", font: subheadFont))
        result.append(NSAttributedString(string: " \(uphill)   ", attributes: attributes))
        result.append(symbolAttachment("arrow.down.right", font: subheadFont))
        result.append(NSAttributedString(string: " \(downhill)", attributes: attributes))
        result.append(NSAttributedString(string: "   |   ", attributes: attributes))
        result.append(NSAttributedString(string: "\(mapCenterDistance) • \(bearing)°", attributes: attributes))
        return result
    }

    private func symbolAttachment(_ name: String, font: UIFont) -> NSAttributedString {
        let attachment = NSTextAttachment()
        let configuration = UIImage.SymbolConfiguration(font: font)
        attachment.image = UIImage(systemName: name, withConfiguration: configuration)?.withTintColor(.textColorSecondary, renderingMode: .alwaysOriginal)
        return NSAttributedString(attachment: attachment)
    }

    private func formattedDistance(_ meters: Double) -> String {
        OAOsmAndFormatter.getFormattedDistance(Float(meters)) ?? ""
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        OAOsmAndFormatter.getFormattedTimeInterval(duration, shortFormat: true)
    }

    private func formattedTime(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }

    @objc private func onViewTapped() {
        onTap?()
    }
}
