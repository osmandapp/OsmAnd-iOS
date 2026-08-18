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
    private static let progressDisplayDelay: TimeInterval = 1

    var onTap: (() -> Void)?

    private let statusIconView = UIImageView()
    private let progressIndicator = UIActivityIndicatorView(style: .medium)
    private let firstLineLabel = UILabel()
    private let secondLineLabel = UILabel()
    private let textStackView = UIStackView()
    private var isCalculatingRoute = false
    private var lastRenderSignature: String?
    private var progressDisplayGeneration = 0
    private var progressDisplayWorkItem: DispatchWorkItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with info: PlanRouteInfo, isCalculatingRoute: Bool) {
        updateCalculationState(isCalculatingRoute)
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

        statusIconView.image = .icCustomPlanRoute
        statusIconView.tintColor = .iconColorActive
        statusIconView.contentMode = .scaleAspectFit
        statusIconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusIconView)

        progressIndicator.color = .iconColorSecondary
        progressIndicator.hidesWhenStopped = true
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(progressIndicator)

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

            progressIndicator.centerXAnchor.constraint(equalTo: statusIconView.centerXAnchor),
            progressIndicator.centerYAnchor.constraint(equalTo: statusIconView.centerYAnchor),

            textStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStackView.leadingAnchor.constraint(equalTo: statusIconView.trailingAnchor, constant: 12),
            textStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalInset)
        ])

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onViewTapped))
        addGestureRecognizer(tapRecognizer)
    }

    private func updateCalculationState(_ isCalculatingRoute: Bool) {
        guard self.isCalculatingRoute != isCalculatingRoute else { return }
        self.isCalculatingRoute = isCalculatingRoute
        progressDisplayWorkItem?.cancel()
        progressDisplayWorkItem = nil
        progressDisplayGeneration += 1

        guard isCalculatingRoute else {
            progressIndicator.stopAnimating()
            statusIconView.isHidden = false
            return
        }

        let progressDisplayGeneration = self.progressDisplayGeneration
        let workItem = DispatchWorkItem { [weak self] in
            guard let self,
                  self.isCalculatingRoute,
                  self.progressDisplayGeneration == progressDisplayGeneration else { return }
            statusIconView.isHidden = true
            progressIndicator.startAnimating()
        }
        progressDisplayWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.progressDisplayDelay, execute: workItem)
    }

    private func makeFirstLine(_ info: PlanRouteInfo,
                               totalDistance: String,
                               duration: String,
                               arrivalTime: String) -> NSAttributedString {
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        let monospacedDigitFont = UIFont.monospacedDigitSystemFont(ofSize: bodyFont.pointSize, weight: .regular)
        let primary: [NSAttributedString.Key: Any] = [.font: monospacedDigitFont, .foregroundColor: UIColor.textColorPrimary]
        let secondary: [NSAttributedString.Key: Any] = [.font: monospacedDigitFont, .foregroundColor: UIColor.textColorSecondary]

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
        let monospacedDigitFont = UIFont.monospacedDigitSystemFont(ofSize: subheadFont.pointSize, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [.font: monospacedDigitFont, .foregroundColor: UIColor.textColorSecondary]

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
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = totalSeconds / 60 % 60
        if hours > 0 {
            let formattedHours = "\(hours) \(localizedString("int_hour"))"
            guard minutes > 0 else { return formattedHours }
            return "\(formattedHours) \(minutes) \(localizedString("shared_string_minute_lowercase"))"
        }
        if minutes > 0 {
            return "\(minutes) \(localizedString("shared_string_minute_lowercase"))"
        }
        return "\(totalSeconds) \(localizedString("units_sec_short"))"
    }

    private func formattedTime(_ date: Date) -> String {
        DateFormatter.shortTimeFormatter.string(from: date)
    }

    @objc private func onViewTapped() {
        onTap?()
    }
}
