//
//  CoordinateFormatHelper.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 11.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

enum CoordinateFormatHelper {
    static let exampleLat = 50.43855
    static let exampleLon = 30.50124

    static func resolve(_ ids: [String]) -> [CoordinateFormat] {
        ids.compactMap { BuiltInCoordinateFormat.resolve($0) }
    }

    static func summary(_ format: CoordinateFormat, primary: Bool) -> String {
        if let epsgCode = format.epsgCode {
            return "EPSG:\(epsgCode)"
        }

        let example = exampleString(format)
        if primary {
            return "\(localizedString("coordinate_format_primary")) • \(example)"
        }
        if format.id == CoordinateFormatIds.builtinUtm {
            return "UTM • \(example)"
        }
        if format.id == CoordinateFormatIds.builtinOlc {
            return "OLC • \(example)"
        }
        return example
    }

    static func exampleString(_ format: CoordinateFormat) -> String {
        guard let legacy = format.legacyFormat else { return "—" }
        let location = OsmAndApp.swiftInstance().locationServices?.lastKnownLocation
        let lat = location?.coordinate.latitude ?? exampleLat
        let lon = location?.coordinate.longitude ?? exampleLon
        return OAOsmAndFormatter.getFormattedCoordinates(withLat: lat, lon: lon, outputFormat: legacy) ?? "—"
    }

    static func makeDescriptionHeader(width: CGFloat) -> UIView {
        let horizontalInset: CGFloat = 36 + OAUtilities.getLeftMargin()
        let top: CGFloat = 12
        let bottom: CGFloat = 8

        let header = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 1))

        let text = localizedString("coordinate_format_description")
        let attr = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .footnote),
                .foregroundColor: UIColor.textColorSecondary
            ]
        )
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = attr
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .natural
        label.adjustsFontForContentSizeCategory = true
        header.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: horizontalInset),
            label.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -horizontalInset),
            label.topAnchor.constraint(equalTo: header.topAnchor, constant: top),
            label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -bottom)
        ])

        relayoutHeader(header, width: width)
        return header
    }

    static func relayoutHeader(_ header: UIView, width: CGFloat) {
        let target = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let height = header.systemLayoutSizeFitting(
            target,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        header.frame.size = CGSize(width: width, height: height)
    }
}
