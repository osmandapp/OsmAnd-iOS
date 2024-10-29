//
//  TracksSearchFilter.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 02.10.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

struct FilterResults {
    var values: [TrackItem] = []
    var count: Int {
        values.count
    }
}

final class TracksSearchFilter: FilterChangedListener {
    private var trackItems: [TrackItem]
    private var callback: (([TrackItem]) -> Void)?
    private var currentFilters: [BaseTrackFilter] = []
    private var filterChangedListeners: [FilterChangedListener] = []
    private var filteredTrackItems: [TrackItem] = []
    private var filterSpecificSearchResults: [TrackFilterType: [TrackItem]] = [:]
    private var currentFolder: TrackFolder?
    
    init(trackItems: [TrackItem], currentFolder: TrackFolder?) {
        self.trackItems = trackItems
        self.currentFolder = currentFolder
        initFilters()
    }
    
    private func initFilters() {
        recreateFilters()
        
        DispatchQueue.global(qos: .utility).async {
            if let dateFilter = self.getFilterByType(.dateCreation) as? DateTrackFilter {
                let minDate = GpxDbHelper.shared.getTracksMinCreateDate()
                let now = Date().timeIntervalSince1970 * 1000
                dateFilter.initialValueFrom = minDate
                dateFilter.initialValueTo = Int64(now)
                dateFilter.valueFrom = minDate
                dateFilter.valueTo = Int64(now)
            }
            
            let trackFilterTypes = TrackFilterType.values()
            let count = trackFilterTypes.size
            for index in 0..<count {
                if let trackFilterType = trackFilterTypes.get(index: index) {
                    let filterType = trackFilterType.filterType
                    switch filterType {
                    case .range:
                        self.updateRangeFilterMaxValue(trackFilterType)
                    case .singleFieldList:
                        if let filter = self.getFilterByType(trackFilterType) as? ListTrackFilter {
                            guard let filterParams = trackFilterType.additionalData as? SingleFieldTrackFilterParams else { continue }
                            let items = GpxDbHelper.shared.getStringIntItemsCollection(
                                columnName: trackFilterType.property?.columnName ?? "",
                                includeEmptyValues: filterParams.includeEmptyValues(),
                                sortByName: filterParams.sortByName(),
                                sortDescending: filterParams.sortDescending()
                            )
                            filter.setFullItemsCollection(collection_: items)
                            if trackFilterType == .folder, let folder = self.currentFolder {
                                filter.firstItem = folder.relativePath
                            }
                        }
                    default:
                        break
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.onFilterChanged()
            }
        }
    }
    
    private func updateRangeFilterMaxValue(_ trackFilterType: TrackFilterType) {
        guard let filter = getFilterByType(trackFilterType) as? RangeTrackFilter<AnyObject> else {
            debugPrint("Cannot parse max value for filter \(trackFilterType): Filter type mismatch or not found")
            return
        }
        
        guard let property = trackFilterType.property else { return }
        let maxValueInDb = GpxDbHelper.shared.getMaxParameterValue(parameter: property)
        if !maxValueInDb.isEmpty {
            filter.setMaxValue(value: maxValueInDb as NSString)
        }
    }
    
    func setCallback(_ newCallback: (([TrackItem]) -> Void)?) {
        callback = newCallback
    }
    
    func performFiltering() -> FilterResults {
        debugPrint("perform tracks filtering")
        var results = FilterResults()
        var filterSpecificSearchResults: [TrackFilterType: [TrackItem]] = [:]
        let filterCount = getAppliedFiltersCount()
        if filterCount == 0 {
            results.values = trackItems
        } else {
            var res: [TrackItem] = []
            for filter in currentFilters {
                filter.doInitFilter()
                filterSpecificSearchResults[filter.trackFilterType] = []
            }
            
            for item in trackItems {
                var notAcceptedFilters: [BaseTrackFilter] = []
                for filter in currentFilters where filter.isEnabled() && !filter.isTrackAccepted(trackItem: item) {
                    notAcceptedFilters.append(filter)
                }
                
                for filter in currentFilters {
                    let tmpNotAcceptedFilters = notAcceptedFilters.filter { $0 !== filter }
                    if tmpNotAcceptedFilters.isEmpty {
                        filterSpecificSearchResults[filter.trackFilterType]?.append(item)
                    }
                }
                
                if notAcceptedFilters.isEmpty {
                    res.append(item)
                }
            }
            
            results.values = res
        }
        if let folderFilter = getFilterByType(.folder) as? ListTrackFilter {
            if let folderItems = filterSpecificSearchResults[.folder], folderItems.isEmpty {
                let items = GpxDbHelper.shared.getStringIntItemsCollection(
                    columnName: folderFilter.trackFilterType.property?.columnName ?? "",
                    includeEmptyValues: folderFilter.collectionFilterParams.includeEmptyValues(),
                    sortByName: folderFilter.collectionFilterParams.sortByName(),
                    sortDescending: folderFilter.collectionFilterParams.sortDescending()
                )
                folderFilter.setFullItemsCollection(collection_: items)
            } else if let ignoreFoldersItems = filterSpecificSearchResults[.folder] {
                folderFilter.updateFullCollection(items: ignoreFoldersItems)
            }
        }
        
        debugPrint("found \(results.count) tracks")
        setFilteredTrackItems(results.values)
        return results
    }
    
    func publishResults(results: FilterResults) {
        callback?(results.values)
    }
    
    func getAppliedFiltersCount() -> Int {
        getAppliedFilters().count
    }
    
    func getCurrentFilters() -> [BaseTrackFilter] {
        currentFilters
    }
    
    func getAppliedFilters() -> [BaseTrackFilter] {
        currentFilters.filter { $0.isEnabled() }
    }
    
    func getNameFilter() -> TextTrackFilter? {
        getFilterByType(.name) as? TextTrackFilter
    }
    
    func addFiltersChangedListener(_ listener: FilterChangedListener) {
        if !filterChangedListeners.contains(where: { $0 === listener }) {
            if let updatedList = KCollectionUtils.shared.addToList(original: filterChangedListeners, element: listener) as? [FilterChangedListener] {
                filterChangedListeners = updatedList
            }
        }
    }
    
    func removeFiltersChangedListener(_ listener: FilterChangedListener) {
        if filterChangedListeners.contains(where: { $0 === listener }) {
            if let updatedList = KCollectionUtils.shared.removeFromList(original: filterChangedListeners, element: listener) as? [FilterChangedListener] {
                filterChangedListeners = updatedList
            }
        }
    }
    
    func resetCurrentFilters() {
        initFilters()
    }
    
    func getFilterByType(_ type: TrackFilterType) -> BaseTrackFilter? {
        for filter in currentFilters where filter.trackFilterType == type {
            return filter
        }
        
        return nil
    }
    
    func recreateFilters() {
        var newFilters: [BaseTrackFilter] = []
        for trackFilterType in TrackFilterType.entries {
            newFilters.append(TrackFiltersHelper.shared.createFilter(trackFilterType: trackFilterType, filterChangedListener: self))
        }
        currentFilters = newFilters
    }
    
    func initSelectedFilters(_ selectedFilters: [BaseTrackFilter]?) {
        guard let selectedFilters else { return }
        initFilters()
        for filter in getCurrentFilters() {
            for selectedFilter in selectedFilters where filter.trackFilterType == selectedFilter.trackFilterType {
                filter.doInitWithValue(value: selectedFilter)
            }
        }
    }
    
    func onFilterChanged() {
        for listener in filterChangedListeners {
            listener.onFilterChanged()
        }
    }
    
    func resetFilteredItems() {
        filteredTrackItems = []
    }
    
    func getFilteredTrackItems() -> [TrackItem] {
        filteredTrackItems
    }
    
    func setFilteredTrackItems(_ trackItems: [TrackItem]) {
        filteredTrackItems = trackItems
    }
    
    func setAllItems(_ trackItems: [TrackItem]) {
        self.trackItems = trackItems
    }
    
    func getAllItems() -> [TrackItem] {
        trackItems
    }
    
    func setCurrentFolder(_ currentFolder: TrackFolder) {
        self.currentFolder = currentFolder
    }
    
    func getFilterSpecificSearchResults() -> [TrackFilterType: [TrackItem]] {
        filterSpecificSearchResults
    }
}

extension TracksSearchFilter {
    static func getDisplayMinValue(filter: RangeTrackFilter<AnyObject>) -> Int {
        let formattedValue = getFormattedValue(measureUnitType: filter.trackFilterType.measureUnitType, value: String(filter.ceilMinValue()))
        return Int(formattedValue.valueSrc)
    }
    
    static func getDisplayMaxValue(filter: RangeTrackFilter<AnyObject>) -> Int {
        let formattedValue = getFormattedValue(measureUnitType: filter.trackFilterType.measureUnitType, value: filter.ceilMaxValue())
        return Int(formattedValue.valueSrc)
    }
    
    static func getDisplayValueFrom(filter: RangeTrackFilter<AnyObject>) -> Int {
        let formattedValue = getFormattedValue(measureUnitType: filter.trackFilterType.measureUnitType, value: String(describing: filter.valueFrom))
        return Int(formattedValue.valueSrc)
    }
    
    static func getDisplayValueTo(filter: RangeTrackFilter<AnyObject>) -> Int {
        let formattedValue = getFormattedValue(measureUnitType: filter.trackFilterType.measureUnitType, value: filter.ceilValueTo())
        return Int(formattedValue.valueSrc)
    }
    
    static func getFormattedValue(measureUnitType: MeasureUnitType, value: String) -> FormattedValue {
        let metricsConstants = OAAppSettings.sharedManager().metricSystem.get()
        let formattedString: String?
        switch measureUnitType {
        case .speed:
            formattedString = OAOsmAndFormatter.getFormattedSpeed(Float(value) ?? 0.0)
        case .altitude:
            formattedString = OAOsmAndFormatter.getFormattedAlt(Double(value) ?? 0.0, mc: metricsConstants)
        case .distance:
            formattedString = OAOsmAndFormatter.getFormattedDistance(Float(value) ?? 0.0)
        case .timeDuration:
            let durationValue = Float(value) ?? 0.0
            return FormattedValue(valueSrc: durationValue / 1000 / 60, value: String(format: "%.2f", durationValue / 1000 / 60), unit: "")
        default:
            let defaultValue = Float(value) ?? 0.0
            return FormattedValue(valueSrc: defaultValue, value: String(format: "%.0f", defaultValue), unit: "")
        }
        
        if let formattedString {
            let components = formattedString.components(separatedBy: " ")
            if components.count > 1 {
                let numberPart = components.dropLast().joined().replacingOccurrences(of: " ", with: "")
                let valueSrc = Float(numberPart) ?? 0.0
                let unit = components.last ?? ""
                return FormattedValue(valueSrc: valueSrc, value: String(format: "%.0f", valueSrc), unit: unit)
            }
        }
        
        return FormattedValue(valueSrc: 0, value: "0", unit: "")
    }

    static func mapEOAMetricsConstantToMetricsConstants(_ eoaConstant: EOAMetricsConstant) -> MetricsConstants {
        switch eoaConstant {
        case .KILOMETERS_AND_METERS:
            return .kilometersAndMeters
        case .MILES_AND_FEET:
            return .milesAndFeet
        case .MILES_AND_YARDS:
            return .milesAndYards
        case .MILES_AND_METERS:
            return .milesAndMeters
        case .NAUTICAL_MILES_AND_METERS:
            return .nauticalMilesAndMeters
        case .NAUTICAL_MILES_AND_FEET:
            return .nauticalMilesAndFeet
        @unknown default:
            return .kilometersAndMeters
        }
    }
}
