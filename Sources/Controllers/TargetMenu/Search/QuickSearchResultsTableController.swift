//
//  QuickSearchResultsTableController.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

extension OASearchResult {
    var spatialCategoryReference: MapObject? {
        guard let spatialResult = sharedResult?.spatialResult, spatialResult.isPoiCategory() else { return nil }
        return spatialResult.getReferenceObject()
    }
}

final class QuickSearchResultsTableController: OAQuickSearchTableController {
    private static let separatedObjectTypes: [EOAObjectType] = [.poiType, .location]
    private static let addressObjectTypes: [EOAObjectType] = [.city, .village, .postcode, .street, .house, .streetIntersection, .boundary]
    private static let pointObjectTypes: [EOAObjectType] = [.favorite, .wpt, .recentObj, .partialLocation]

    override init!(tableView: UITableView!) {
        super.init(tableView: tableView)
        tableView.register(PoiContentTableViewCell.self, forCellReuseIdentifier: PoiContentTableViewCell.reuseIdentifier)
        tableView.register(PointContentTableViewCell.self, forCellReuseIdentifier: PointContentTableViewCell.reuseIdentifier)
        tableView.register(QuickSearchEmptyStateCell.self, forCellReuseIdentifier: QuickSearchEmptyStateCell.reuseIdentifier)
        downloadingCellResourceHelper.showsIconOnPlate = true
    }

    override func updateData(_ data: [[OAQuickSearchListItem]]!, append: Bool) {
        let groups = (data ?? []).flatMap(Self.groupedItems)
        super.updateData(groups.isEmpty ? [[]] : groups, append: append)
    }

    func appendItem(_ item: OAQuickSearchListItem) {
        add(item, groupIndex: max(numberOfSections(in: tableView) - 1, 0))
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let emptyStateItem = item(at: indexPath) as? QuickSearchEmptyStateListItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: QuickSearchEmptyStateCell.reuseIdentifier, for: indexPath)
            (cell as? QuickSearchEmptyStateCell)?.configure(with: emptyStateItem)
            return cell
        }
        if let result = item(at: indexPath)?.getSearchResult(), result.objectType == .indexItem {
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
            if let downloadingCell = cell as? DownloadingCell {
                configureMapToDownloadCell(downloadingCell, result: result)
            }
            return cell
        }
        guard let item = item(at: indexPath),
              let result = item.getSearchResult(),
              let configuration = contentConfiguration(for: item, result: result) else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
        let identifier = configuration is PoiContentConfiguration ? PoiContentTableViewCell.reuseIdentifier : PointContentTableViewCell.reuseIdentifier
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        cell.contentConfiguration = configuration
        cell.accessoryType = result.objectType == .poiType ? .disclosureIndicator : .none
        (cell as? PointContentTableViewCell)?.alignsSeparatorWithTrailingMargin = true
        PointContentConfiguration.applyHighlightableBackground(to: cell)
        return cell
    }

    private static func groupedItems(_ items: [OAQuickSearchListItem]) -> [[OAQuickSearchListItem]] {
        let isSuggestion: (OAQuickSearchListItem) -> Bool = { $0.getSearchResult()?.objectType == .suggestion }
        let suggestions = items.filter(isSuggestion)
        if !suggestions.isEmpty {
            return [suggestions] + groupedItems(items.filter { !isSuggestion($0) })
        }
        let isMapToDownload: (OAQuickSearchListItem) -> Bool = { $0.getSearchResult()?.objectType == .indexItem }
        let maps = items.filter(isMapToDownload)
        if !maps.isEmpty {
            var groups = groupedItems(items.filter { !isMapToDownload($0) })
            if let specialItems = groups.first, !specialItems.isEmpty, specialItems.allSatisfy({ $0.getSearchResult()?.objectType == .poiType }) {
                groups[0] += maps
            } else {
                groups.insert(maps, at: 0)
            }
            return groups
        }
        guard let firstType = items.first?.getSearchResult()?.objectType,
              separatedObjectTypes.contains(firstType),
              let splitIndex = items.indices.dropFirst().first(where: { items[$0].getSearchResult()?.objectType != firstType }),
              items[splitIndex].getSearchResult() != nil else { return [items] }
        return [Array(items[..<splitIndex]), Array(items[splitIndex...])]
    }

    private var locationReference: SearchLocationReference {
        SearchLocationReference(searchNearMapCenter: searchNearMapCenter, searchLocation: mapCenterCoordinate)
    }

    private func contentConfiguration(for item: OAQuickSearchListItem, result: OASearchResult) -> UIContentConfiguration? {
        let objectType = result.objectType
        if objectType == .poi, let poi = result.object as? OAPOI {
            return poi.isRouteTrack() ? routeConfiguration(for: item, result: result, poi: poi) : poiConfiguration(for: item, result: result, poi: poi)
        }
        if objectType == .gpxTrack || objectType == .location, let dataItem = result.relatedObject as? GpxDataItem {
            return trackConfiguration(for: item, result: result, dataItem: dataItem)
        }
        if objectType == .poiType {
            return categoryConfiguration(for: item, result: result)
        }
        if objectType == .suggestion {
            return PointContentConfiguration(icon: Self.icon(for: result), title: item.getName() ?? "", iconStyle: .plate, secondaryContent: nil)
        }
        if Self.addressObjectTypes.contains(objectType) {
            return addressConfiguration(for: item, result: result)
        }
        if objectType == .location || Self.pointObjectTypes.contains(objectType) {
            return PointContentConfiguration(icon: Self.icon(for: result),
                                             title: item.getName() ?? "",
                                             iconStyle: .plate,
                                             secondaryContent: secondaryContent(for: result, text: OAQuickSearchListItem.getTypeName(result)))
        }
        return nil
    }

    private func poiConfiguration(for item: OAQuickSearchListItem, result: OASearchResult, poi: OAPOI) -> PoiContentConfiguration {
        let name = item.getName() ?? ""
        let title = name.isEmpty ? poi.getSubTypeStr() : name
        let typeName = poi.getMainSubtypeStr()
        let openingHours = OAPOIHelper.sharedInstance().getShortFormattedOpeningHours(poi)
        var openingHoursColor: UIColor?
        if !openingHours.isEmpty, let parser = OAOpeningHoursParser(string: poi.openingHours) {
            openingHoursColor = parser.isOpenedForTime() ? .accentsGreen : .textColorDisruptive
        }
        let settings: OAAppSettings = OAAppSettings.sharedManager()
        let imageURL = settings.wikiShowImagePreviews.get() ? poi.wikiIconUrl.flatMap { URL(string: $0) } : nil
        return PoiContentConfiguration(style: .compact,
                                       title: title,
                                       icon: poi.icon(),
                                       imageURL: imageURL,
                                       secondaryContent: secondaryContent(for: result, text: typeName == title ? nil : typeName),
                                       address: result.addressName,
                                       openingHours: openingHours,
                                       openingHoursColor: openingHoursColor,
                                       descriptionText: poi.getTagContent("description", lang: PopularPlaceDetails.preferredLocale()),
                                       alternateTitle: result.alternateName)
    }

    private func addressConfiguration(for item: OAQuickSearchListItem, result: OASearchResult) -> PoiContentConfiguration {
        let title = OAQuickSearchTableController.addressTitle(for: result) ?? item.getName() ?? ""
        let typeName = OAQuickSearchTableController.poiTypeName(for: result) ?? OAQuickSearchListItem.getTypeName(result)
        var configuration = PoiContentConfiguration(style: .compact,
                                                    title: title,
                                                    icon: Self.icon(for: result),
                                                    secondaryContent: secondaryContent(for: result,
                                                                                       text: typeName,
                                                                                       trailingText: OAQuickSearchTableController.addressDescription(for: result)),
                                                    address: OAQuickSearchTableController.distanceToCity(for: result),
                                                    alternateTitle: result.alternateName,
                                                    iconTintColor: .iconColorSecondary)
        configuration.secondaryNumberOfLines = 2
        return configuration
    }

    private func routeConfiguration(for item: OAQuickSearchListItem, result: OASearchResult, poi: OAPOI) -> PoiContentConfiguration {
        let name = item.getName() ?? ""
        let statistics = Self.routeStatistics(length: AmenityExtensionsHelper.amenityDistanceMeters(poi),
                                              uphill: AmenityExtensionsHelper.amenityUphillMeters(poi),
                                              downhill: AmenityExtensionsHelper.amenityDownhillMeters(poi))
        return PoiContentConfiguration(style: .route,
                                       title: name.isEmpty ? String(poi.getOsmId()) : name,
                                       icon: poi.icon(),
                                       secondaryContent: secondaryContent(for: result, text: poi.getRouteActivityType()),
                                       address: result.addressName,
                                       shieldImage: OAQuickSearchTableController.routeShield(for: result),
                                       routeStatistics: statistics)
    }

    private func trackConfiguration(for item: OAQuickSearchListItem, result: OASearchResult, dataItem: GpxDataItem) -> PoiContentConfiguration {
        let activity = SearchHistoryItemPresenter.routeActivity(for: dataItem)
        var statistics: PoiRouteStatistics?
        if let analysis = dataItem.getAnalysis() {
            statistics = Self.routeStatistics(length: analysis.totalDistance,
                                              uphill: Float(analysis.diffElevationUp),
                                              downhill: Float(analysis.diffElevationDown))
        }
        let isVisible = OAAppSettings.sharedManager().isGpxVisible(dataItem.gpxFilePath)
        return PoiContentConfiguration(style: .route,
                                       title: item.getName() ?? "",
                                       icon: .icCustomTrip,
                                       secondaryContent: secondaryContent(for: result,
                                                                          text: localizedString("shared_string_gpx_track"),
                                                                          trailingText: activity?.label),
                                       address: dataItem.nearestCity,
                                       iconTintColor: isVisible ? .iconColorActive : .iconColorDefault,
                                       routeStatistics: statistics)
    }

    private func categoryConfiguration(for item: OAQuickSearchListItem, result: OASearchResult) -> PointContentConfiguration {
        let text: String?
        if let reference = result.spatialCategoryReference {
            text = "\(localizedString("shared_string_near")) \(reference.getName())"
        } else if result.object is OAPOIBaseType {
            text = OAQuickSearchTableController.applySynonyms(result)
        } else if let topIndexFilter = result.object as? OATopIndexFilter {
            text = topIndexFilter.getName()
        } else {
            text = nil
        }
        let title = item.getName() ?? ""
        return PointContentConfiguration(icon: Self.categoryIcon(for: result),
                                         title: title,
                                         iconStyle: .plate,
                                         secondaryContent: PointSecondaryContent(formattedDistance: nil, direction: 0, address: text == title ? nil : text, date: nil))
    }

    private func configureMapToDownloadCell(_ cell: DownloadingCell, result: OASearchResult) {
        let resourceItem = OAResourceSwiftItem(item: result.relatedObject)
        let region = resourceItem?.worldRegion()
        let size = (resourceItem?.sizePkg() ?? 0) > 0 ? resourceItem?.formatedSizePkg() : nil
        let secondaryContent: PointSecondaryContent
        if let center = region?.regionCenter, CLLocationCoordinate2DIsValid(center) {
            secondaryContent = locationReference.secondaryContent(latitude: center.latitude,
                                                                  longitude: center.longitude,
                                                                  address: region?.superregion?.localizedName,
                                                                  trailingText: size)
        } else {
            secondaryContent = PointSecondaryContent(formattedDistance: nil, direction: 0, address: region?.superregion?.localizedName, date: nil, trailingText: size)
        }
        let description = secondaryContent.attributedText(separatorColor: .textColorTertiary)
        cell.titleLabel.font = .preferredFont(forTextStyle: .headline)
        cell.titleLabel.numberOfLines = 2
        cell.descriptionLabel.numberOfLines = 1
        cell.descriptionLabel.attributedText = description
        cell.descriptionVisibility(description != nil)
    }

    private func secondaryContent(for result: OASearchResult, text: String?, trailingText: String? = nil) -> PointSecondaryContent {
        guard let location = result.location else {
            return PointSecondaryContent(formattedDistance: nil, direction: 0, address: text, date: nil, trailingText: trailingText)
        }
        return locationReference.secondaryContent(latitude: location.coordinate.latitude,
                                                  longitude: location.coordinate.longitude,
                                                  address: text,
                                                  trailingText: trailingText)
    }

    private static func categoryIcon(for result: OASearchResult) -> UIImage? {
        switch result.object {
        case let poiType as OAPOIBaseType:
            return poiType.icon()
        case let filter as OAPOIUIFilter:
            return filter.searchIcon
        case let filter as OACustomSearchPoiFilter:
            if let iconName = filter.getIconResource() as? String {
                return OAUtilities.getMxIcon(iconName)
            }
            return nil
        case let topIndexFilter as OATopIndexFilter:
            return UIImage(named: topIndexFilter.getIconResource())
        default:
            return icon(for: result)
        }
    }

    private static func routeStatistics(length: Float, uphill: Float, downhill: Float) -> PoiRouteStatistics? {
        guard length > 0, let formattedLength = formattedDistance(length) else { return nil }
        return PoiRouteStatistics(length: formattedLength,
                                  uphill: isSlopeVisible(uphill, length: length) ? formattedDistance(uphill) : nil,
                                  downhill: isSlopeVisible(downhill, length: length) ? formattedDistance(downhill) : nil)
    }

    private static func isSlopeVisible(_ value: Float, length: Float) -> Bool {
        value >= AmenityExtensionsHelper.minUphillDownhillFixedToShow
            && value / length * 100 > AmenityExtensionsHelper.minUphillDownhillPercentToShow
    }

    private static func formattedDistance(_ meters: Float) -> String? {
        OAOsmAndFormatter.getFormattedDistance(meters, with: OsmAndFormatterParams.noTrailingZeros)
    }
}
