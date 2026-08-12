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
    static let unavailablePlaceholder = "—"
    
    private static let searchDebounce: TimeInterval = 0.25
    private static var searchWorkItem: DispatchWorkItem?

    static func resolve(_ ids: [String]) -> [CoordinateFormat] {
        ids.map { id in
            BuiltInCoordinateFormat.resolve(id) ?? EpsgCatalogRepository.shared.resolveFormat(id)
        }
    }

    static func cancelSearch() {
        searchWorkItem?.cancel()
        searchWorkItem = nil
    }
    
    static func search(_ query: String?, completion: @escaping ([CoordinateFormat]) -> Void) {
        cancelSearch()
        let trimmed = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let work = DispatchWorkItem {
            let results = trimmed.isEmpty
                ? EpsgCatalogRepository.shared.listAll()
                : EpsgCatalogRepository.shared.search(trimmed)
            DispatchQueue.main.async {
                completion(results)
            }
        }
        searchWorkItem = work
        if trimmed.isEmpty {
            DispatchQueue.global(qos: .userInitiated).async(execute: work)
        } else {
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + searchDebounce, execute: work)
        }
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

    static func exampleString(_ coordFormat: CoordinateFormat) -> String {
        let location = OsmAndApp.swiftInstance().locationServices?.lastKnownLocation
        let lat = location?.coordinate.latitude ?? exampleLat
        let lon = location?.coordinate.longitude ?? exampleLon
        return format(coordFormat, lat: lat, lon: lon)
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

    static func format(_ format: CoordinateFormat, lat: Double, lon: Double) -> String {
        if format.type == .builtIn, let legacy = format.legacyFormat {
            return OAOsmAndFormatter.getFormattedCoordinates(withLat: lat, lon: lon, outputFormat: legacy)
                ?? unavailablePlaceholder
        }
        if let code = format.epsgCode,
           let point = OAEpsgCoordinateTransformer.sharedInstance().fromLonLat(withCode: code, lon: lon, lat: lat) {
            return formatEpsgPoint(easting: point.easting, northing: point.northing)
        }
        return unavailablePlaceholder
    }

    static func formatEpsgPoint(easting: Double, northing: Double) -> String {
        "\(formatEpsgValue(easting)), \(formatEpsgValue(northing))"
    }

    static func formatEpsgValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? unavailablePlaceholder
    }
}
