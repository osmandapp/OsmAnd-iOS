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
        return values.count
    }
}

class TracksSearchFilter: FilterChangedListener {
    private var trackItems: [TrackItem]
    private var callback: (([TrackItem]) -> Void)?
    private var currentFilters: [BaseTrackFilter] = []
    private var filterChangedListeners: [FilterChangedListener] = []
    private var filteredTrackItems: [TrackItem] = []
    private var filterSpecificSearchResults: [TrackFilterType: [TrackItem]] = [:]
    private var currentFolder: TrackFolder?
    
    init(trackItems: [TrackItem], currentFolder: TrackFolder? = nil) {
        self.trackItems = trackItems
        self.currentFolder = currentFolder
        initFilters()
    }
    
    private func initFilters() {
        recreateFilters()
        
        DispatchQueue.global(qos: .background).async {
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
    
    func performFiltering(_ constraint: String) -> FilterResults {
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
        return results
    }
    
    func publishResults(constraint: String, results: FilterResults) {
        if let callback = callback {
            callback(results.values)
        }
    }
    
    func getAppliedFiltersCount() -> Int {
        return getAppliedFilters().count
    }
    
    func getCurrentFilters() -> [BaseTrackFilter] {
        return currentFilters
    }
    
    func getAppliedFilters() -> [BaseTrackFilter] {
        return currentFilters.filter { $0.isEnabled() }
    }
    
    func getNameFilter() -> TextTrackFilter? {
        return getFilterByType(.name) as? TextTrackFilter
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
        //        ?
    }
    
    func filter() {
        if let nameFilter = getNameFilter() {
            //            ?
        }
    }
    
    func getFilterByType(_ type: TrackFilterType) -> BaseTrackFilter? {
        for filter in currentFilters {
            if filter.trackFilterType == type {
                return filter
            }
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
            for selectedFilter in selectedFilters {
                if filter.trackFilterType == selectedFilter.trackFilterType {
                    filter.doInitWithValue(value: selectedFilter)
                }
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
        return filteredTrackItems
    }
    
    func setFilteredTrackItems(_ trackItems: [TrackItem]) {
        filteredTrackItems = trackItems
    }
    
    func setAllItems(_ trackItems: [TrackItem]) {
        self.trackItems = trackItems
    }
    
    func getAllItems() -> [TrackItem] {
        return trackItems
    }
    
    func setCurrentFolder(_ currentFolder: TrackFolder) {
        self.currentFolder = currentFolder
    }
    
    func getFilterSpecificSearchResults() -> [TrackFilterType: [TrackItem]] {
        return filterSpecificSearchResults
    }
}
