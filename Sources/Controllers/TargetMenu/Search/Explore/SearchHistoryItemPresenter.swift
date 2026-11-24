//
//  SearchHistoryItemPresenter.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

struct SearchHistoryRecord {
    let item: OAHistoryItem
    let categoryName: String
    let typeText: String
}

struct SearchHistoryItemPresenter {
    private static let administrativeCategory = "administrative"
    private static let typeNameSeparator = " • "

    private let poiTypesByName: [String: OAPOIType]

    init() {
        poiTypesByName = OAPOIHelper.sharedInstance().getAllTranslatedNames(false)
    }

    static func icon(for item: OAHistoryItem, traitCollection: UITraitCollection) -> UIImage? {
        if item.fromNavigation {
            return tinted(.icCustomFinishFlag, traitCollection: traitCollection)
        }
        if item.hType == .location {
            return tinted(.icCustomCoordinatesLocation, traitCollection: traitCollection)
        }
        return item.icon()
    }

    static func secondaryContent(for record: SearchHistoryRecord, locationReference: SearchLocationReference, showsDate: Bool = false) -> PointSecondaryContent {
        let content = locationReference.secondaryContent(latitude: record.item.latitude,
                                                         longitude: record.item.longitude,
                                                         address: record.typeText)
        guard showsDate, record.item.fromNavigation, let date = record.item.date else { return content }
        return PointSecondaryContent(formattedDistance: content.formattedDistance,
                                     direction: content.direction,
                                     directionColor: content.directionColor,
                                     address: content.address,
                                     date: OAOsmAndFormatter.getFormattedDate(date.timeIntervalSince1970))
    }

    func record(for item: OAHistoryItem) -> SearchHistoryRecord {
        let categoryName = categoryName(for: item)
        let typeName = item.typeName ?? ""
        let typeText = item.fromNavigation ? localizedString("route_descr_destination") : typeName.isEmpty ? categoryName : typeName
        return SearchHistoryRecord(item: item, categoryName: categoryName, typeText: typeText)
    }

    private static func tinted(_ image: UIImage, traitCollection: UITraitCollection) -> UIImage {
        image.withTintColor(UIColor.iconColorDefault.resolvedColor(with: traitCollection), renderingMode: .alwaysOriginal)
    }

    private func categoryName(for item: OAHistoryItem) -> String {
        switch item.hType {
        case .poi:
            guard let category = poiCategory(for: item) else { return localizedString("poi") }
            return category.name == Self.administrativeCategory ? localizedString("shared_string_address") : category.nameLocalized ?? localizedString("poi")
        case .address:
            return localizedString("shared_string_address")
        case .favorite:
            return localizedString("shared_string_favorite")
        case .wpt:
            return localizedString("shared_string_waypoint")
        case .location:
            return localizedString("shared_string_location")
        default:
            return localizedString("route_descr_destination")
        }
    }

    private func poiCategory(for item: OAHistoryItem) -> OAPOICategory? {
        guard let typeName = item.typeName?.components(separatedBy: Self.typeNameSeparator).first?.trimmingCharacters(in: .whitespaces),
              !typeName.isEmpty else { return nil }
        return poiTypesByName[typeName.lowercased()]?.category
    }
}
