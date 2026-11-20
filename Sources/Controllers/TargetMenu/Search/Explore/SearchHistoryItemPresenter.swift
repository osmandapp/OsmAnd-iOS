//
//  SearchHistoryItemPresenter.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

struct SearchHistoryRecord {
    let item: OAHistoryItem
    let title: String
    let categoryName: String
    let typeText: String
    let coordinate: CLLocationCoordinate2D?
    let object: NSObject?
}

struct SearchHistoryItemPresenter {
    private static let administrativeCategory = "administrative"
    private static let typeNameSeparator = " • "
    private static let addressObjectTypes = Set(([.city, .village, .boundary, .postcode, .street, .house, .streetIntersection] as [EOAObjectType]).compactMap { OAObjectType.toString($0) })

    private let poiTypesByName: [String: OAPOIType]

    init() {
        poiTypesByName = OAPOIHelper.sharedInstance().getAllTranslatedNames(false)
    }

    static func icon(for record: SearchHistoryRecord, traitCollection: UITraitCollection) -> UIImage? {
        if let poiType = record.object as? OAPOIBaseType {
            return poiType.icon()
        }
        if let filter = record.object as? OAPOIUIFilter {
            return filter.searchIcon
        }
        if record.object is GpxDataItem {
            return UIImage.icCustomTrip.withRenderingMode(.alwaysTemplate)
        }
        let item = record.item
        if item.fromNavigation {
            return tinted(.icCustomFinishFlag, traitCollection: traitCollection)
        }
        if item.hType == .location {
            return tinted(.icCustomCoordinatesLocation, traitCollection: traitCollection)
        }
        if let objectType = item.objectType, addressObjectTypes.contains(objectType), let icon = item.icon() {
            return tinted(icon, traitCollection: traitCollection)
        }
        return item.icon()
    }

    static func secondaryContent(for record: SearchHistoryRecord, locationReference: SearchLocationReference, showsDate: Bool = false) -> PointSecondaryContent {
        let content: PointSecondaryContent
        if let coordinate = record.coordinate {
            content = locationReference.secondaryContent(latitude: coordinate.latitude,
                                                         longitude: coordinate.longitude,
                                                         address: record.typeText)
        } else {
            content = PointSecondaryContent(formattedDistance: nil, direction: 0, address: record.typeText, date: nil)
        }
        guard showsDate, record.item.fromNavigation, let date = record.item.date else { return content }
        return PointSecondaryContent(formattedDistance: content.formattedDistance,
                                     direction: content.direction,
                                     directionColor: content.directionColor,
                                     address: content.address,
                                     date: OAOsmAndFormatter.getFormattedDate(date.timeIntervalSince1970))
    }

    func record(for item: OAHistoryItem) -> SearchHistoryRecord? {
        if item.hType == .gpxFile {
            return trackRecord(for: item)
        }
        guard item.hasLocation() else { return poiObjectRecord(for: item) }
        let categoryName = categoryName(for: item)
        let typeText = item.fromNavigation ? localizedString("route_descr_destination") : typeText(for: item, categoryName: categoryName)
        return SearchHistoryRecord(item: item,
                                   title: item.name ?? "",
                                   categoryName: categoryName,
                                   typeText: typeText,
                                   coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude),
                                   object: nil)
    }

    private static func tinted(_ image: UIImage, traitCollection: UITraitCollection) -> UIImage {
        image.withTintColor(UIColor.iconColorDefault.resolvedColor(with: traitCollection), renderingMode: .alwaysOriginal)
    }

    private static func isolatedJoined(_ parts: [String]) -> String {
        guard let first = parts.first else { return "" }
        return ([first] + parts.dropFirst().map { "\u{2068}\($0)\u{2069}" }).joined(separator: typeNameSeparator)
    }

    private static func routeActivity(for dataItem: GpxDataItem) -> RouteActivity? {
        guard let activityId = dataItem.getParameter(parameter: .activityType) as? String, !activityId.isEmpty else { return nil }
        return RouteActivityHelper.shared.findRouteActivity(id: activityId)
    }

    private func trackRecord(for item: OAHistoryItem) -> SearchHistoryRecord? {
        guard let path = item.name, !path.isEmpty, let dataItem = OAGPXDatabase.sharedDb().getGPXItem(path) else { return nil }
        let title = (path as NSString).deletingPathExtension.replacingOccurrences(of: "/", with: Self.typeNameSeparator).trimmingCharacters(in: .whitespaces)
        let categoryName = localizedString("shared_string_gpx_track")
        var details = [categoryName]
        if let activity = Self.routeActivity(for: dataItem) {
            details.append(activity.label)
        }
        if let city = dataItem.nearestCity, !city.isEmpty {
            details.append(city)
        }
        let analysis = dataItem.getAnalysis()
        if let analysis, analysis.totalDistance > 0, let length = OAOsmAndFormatter.getFormattedDistance(analysis.totalDistance) {
            details.append(length)
        }
        if let analysis, analysis.diffElevationUp > 0, let uphill = OAOsmAndFormatter.getFormattedAlt(analysis.diffElevationUp) {
            details.append("↑ " + uphill)
        }
        var coordinate: CLLocationCoordinate2D?
        if let start = analysis?.getLatLonStart() {
            let startCoordinate = CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude)
            if CLLocationCoordinate2DIsValid(startCoordinate) {
                coordinate = startCoordinate
            }
        }
        return SearchHistoryRecord(item: item,
                                   title: title.isEmpty ? path : title,
                                   categoryName: categoryName,
                                   typeText: Self.isolatedJoined(details),
                                   coordinate: coordinate,
                                   object: dataItem)
    }

    private func poiObjectRecord(for item: OAHistoryItem) -> SearchHistoryRecord? {
        guard let result = OASearchHistoryAPI.searchResult(for: item), let poiObject = result.object else { return nil }
        let title = result.localeName ?? item.name ?? ""
        let categoryName = (poiObject as? OAPOICategory)?.nameLocalized ?? localizedString("poi")
        var typeText = ""
        if let poiType = poiObject as? OAPOIType {
            typeText = poiType.parentType?.nameLocalized ?? poiType.category?.nameLocalized ?? ""
        } else if let poiFilter = poiObject as? OAPOIFilter {
            typeText = poiFilter.category?.nameLocalized ?? ""
        }
        return SearchHistoryRecord(item: item,
                                   title: title,
                                   categoryName: categoryName,
                                   typeText: typeText == title ? "" : typeText,
                                   coordinate: nil,
                                   object: poiObject)
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

    private func typeText(for item: OAHistoryItem, categoryName: String) -> String {
        let typeName = item.typeName ?? ""
        let text = typeName.isEmpty ? categoryName : typeName
        guard let address = item.address, !address.isEmpty, !text.contains(address), !text.contains(Self.typeNameSeparator) else { return text }
        return text.isEmpty ? address : text + Self.typeNameSeparator + address
    }

    private func poiCategory(for item: OAHistoryItem) -> OAPOICategory? {
        let poiHelper = OAPOIHelper.sharedInstance()
        if let key = item.poiCategoryKey, !key.isEmpty, let category = poiHelper.getCategories(true).first(where: { $0.name == key }) {
            return category
        }
        if let key = item.poiSubtypeKey, !key.isEmpty, let category = poiHelper.getPoiType(byKey: key)?.category {
            return category
        }
        guard let typeName = item.typeName?.components(separatedBy: Self.typeNameSeparator).first?.trimmingCharacters(in: .whitespaces),
              !typeName.isEmpty else { return nil }
        return poiTypesByName[typeName.lowercased()]?.category
    }
}
