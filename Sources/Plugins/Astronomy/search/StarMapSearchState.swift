//
//  StarMapSearchState.swift
//  OsmAnd Maps
//
//  Created by Codex on 06.06.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import UIKit

enum StarMapSearchSortMode: String {
    case NEWEST_FIRST
    case OLDEST_FIRST
    case NAME_ASC
    case NAME_DESC
    case BRIGHTEST_FIRST
    case FAINTEST_FIRST
    case RISES_SOONEST
    case SETS_SOONEST
}

enum StarMapSearchTypeFilter: String {
    case SHOW_ALL
    case VISIBLE_NOW
    case VISIBLE_TONIGHT
}

enum StarMapSearchCategoryFilter: String, CaseIterable, Hashable {
    case ALL
    case SOLAR_SYSTEM
    case CONSTELLATIONS
    case STARS
    case NEBULAS
    case STAR_CLUSTERS
    case DEEP_SKY
}

enum StarMapSearchQuickPresetType: String {
    case NONE
    case WATCH_NOW
    case CATALOGS
    case CATEGORY_SOLAR_SYSTEM
    case CATEGORY_CONSTELLATIONS
    case CATEGORY_STARS
    case CATEGORY_NEBULAS
    case CATEGORY_STAR_CLUSTERS
    case CATEGORY_DEEP_SKY
    case MY_DATA_FAVORITES
    case MY_DATA_DAILY_PATH
    case MY_DATA_DIRECTIONS
    case CATALOG_WID

    var categoryPreset: StarMapSearchCategoryFilter? {
        switch self {
        case .CATEGORY_SOLAR_SYSTEM:
            return .SOLAR_SYSTEM
        case .CATEGORY_CONSTELLATIONS:
            return .CONSTELLATIONS
        case .CATEGORY_STARS:
            return .STARS
        case .CATEGORY_NEBULAS:
            return .NEBULAS
        case .CATEGORY_STAR_CLUSTERS:
            return .STAR_CLUSTERS
        case .CATEGORY_DEEP_SKY:
            return .DEEP_SKY
        default:
            return nil
        }
    }

    var opensInBrowseMode: Bool {
        self != .NONE
    }

    var isMyData: Bool {
        myDataTabIndex != nil
    }

    var myDataTabIndex: Int? {
        switch self {
        case .MY_DATA_FAVORITES:
            return 0
        case .MY_DATA_DAILY_PATH:
            return 1
        case .MY_DATA_DIRECTIONS:
            return 2
        default:
            return nil
        }
    }

    func matches(_ entry: StarMapSearchEntry, catalogWid: String?) -> Bool {
        switch self {
        case .NONE, .WATCH_NOW:
            return true
        case .CATALOGS:
            return false
        case .CATEGORY_SOLAR_SYSTEM:
            return entry.category == .SOLAR_SYSTEM
        case .CATEGORY_CONSTELLATIONS:
            return entry.category == .CONSTELLATIONS
        case .CATEGORY_STARS:
            return entry.category == .STARS
        case .CATEGORY_NEBULAS:
            return entry.category == .NEBULAS
        case .CATEGORY_STAR_CLUSTERS:
            return entry.category == .STAR_CLUSTERS
        case .CATEGORY_DEEP_SKY:
            return entry.category == .DEEP_SKY
        case .MY_DATA_FAVORITES:
            return entry.objectRef.isFavorite
        case .MY_DATA_DAILY_PATH:
            return entry.objectRef.showCelestialPath
        case .MY_DATA_DIRECTIONS:
            return entry.objectRef.showDirection
        case .CATALOG_WID:
            guard let catalogWid, !catalogWid.isEmpty else {
                return false
            }
            return entry.catalogWids.contains(catalogWid)
        }
    }
}

final class StarMapSearchEntry {
    let objectRef: SkyObject
    let displayName: String
    let magnitude: Double
    let category: StarMapSearchCategoryFilter
    let iconRes: String
    let iconColor: UIColor
    let catalogWids: Set<String>
    var nextRise: Date?
    var nextSet: Date?
    var isVisibleTonight = false
    var riseSetCalculated = false
    var visibleTonightCalculated = false

    init(objectRef: SkyObject,
         displayName: String,
         magnitude: Double,
         category: StarMapSearchCategoryFilter,
         iconRes: String,
         iconColor: UIColor,
         catalogWids: Set<String> = []) {
        self.objectRef = objectRef
        self.displayName = displayName
        self.magnitude = magnitude
        self.category = category
        self.iconRes = iconRes
        self.iconColor = iconColor
        self.catalogWids = catalogWids
    }

    func copy() -> StarMapSearchEntry {
        let entry = StarMapSearchEntry(objectRef: objectRef,
                                       displayName: displayName,
                                       magnitude: magnitude,
                                       category: category,
                                       iconRes: iconRes,
                                       iconColor: iconColor,
                                       catalogWids: catalogWids)
        entry.nextRise = nextRise
        entry.nextSet = nextSet
        entry.isVisibleTonight = isVisibleTonight
        entry.riseSetCalculated = riseSetCalculated
        entry.visibleTonightCalculated = visibleTonightCalculated
        return entry
    }
}

struct StarMapRecentChip: Equatable {
    let label: String
    let objectId: String?

    init(label: String, objectId: String? = nil) {
        self.label = label
        self.objectId = objectId
    }
}

struct StarMapSearchStateSnapshot {
    let query: String
    let sortMode: StarMapSearchSortMode
    let typeFilter: StarMapSearchTypeFilter
    let nakedEyeOnly: Bool
    let quickPresetType: StarMapSearchQuickPresetType
    let quickPresetCatalogWid: String?
    let selectedCategories: Set<StarMapSearchCategoryFilter>

    func filterAndSort(preparedEntries: [StarMapSearchEntry],
                       visibleTonightProvider: (StarMapSearchEntry) -> Bool,
                       riseSortValueProvider: (StarMapSearchEntry) -> Int64,
                       setSortValueProvider: (StarMapSearchEntry) -> Int64,
                       insertionOrderProvider: (StarMapSearchEntry) -> Int?) -> [StarMapSearchEntry] {
        var filteredEntries: [StarMapSearchEntry] = []
        let queryLower = query.lowercased(with: Locale.current)
        let specificCategories = selectedCategories.filter { $0 != .ALL }

        for entry in preparedEntries {
            if !matchesQuickPreset(entry) {
                continue
            }
            if !queryLower.isEmpty && !matchesQuery(entry, queryLower: queryLower) {
                continue
            }
            if !matchesTypeFilter(entry, visibleTonightProvider: visibleTonightProvider) {
                continue
            }
            if nakedEyeOnly && entry.magnitude > 6.0 {
                continue
            }
            if !specificCategories.isEmpty && !specificCategories.contains(entry.category) {
                continue
            }
            filteredEntries.append(entry)
        }

        filteredEntries.sort { lhs, rhs in
            compare(lhs,
                    rhs,
                    riseSortValueProvider: riseSortValueProvider,
                    setSortValueProvider: setSortValueProvider,
                    insertionOrderProvider: insertionOrderProvider)
        }
        return filteredEntries
    }

    private func matchesQuickPreset(_ entry: StarMapSearchEntry) -> Bool {
        quickPresetType.matches(entry, catalogWid: quickPresetCatalogWid)
    }

    private func matchesQuery(_ entry: StarMapSearchEntry, queryLower: String) -> Bool {
        let display = entry.displayName.lowercased(with: Locale.current)
        let localized = (entry.objectRef.localizedName ?? "").lowercased(with: Locale.current)
        let original = entry.objectRef.name.lowercased(with: Locale.current)
        return display.contains(queryLower) || localized.contains(queryLower) || original.contains(queryLower)
    }

    private func matchesTypeFilter(_ entry: StarMapSearchEntry,
                                   visibleTonightProvider: (StarMapSearchEntry) -> Bool) -> Bool {
        switch typeFilter {
        case .SHOW_ALL:
            return true
        case .VISIBLE_NOW:
            return entry.objectRef.altitude > 0
        case .VISIBLE_TONIGHT:
            return visibleTonightProvider(entry)
        }
    }

    private func compare(_ lhs: StarMapSearchEntry,
                         _ rhs: StarMapSearchEntry,
                         riseSortValueProvider: (StarMapSearchEntry) -> Int64,
                         setSortValueProvider: (StarMapSearchEntry) -> Int64,
                         insertionOrderProvider: (StarMapSearchEntry) -> Int?) -> Bool {
        let lhsName = lhs.displayName.lowercased(with: Locale.current)
        let rhsName = rhs.displayName.lowercased(with: Locale.current)
        switch sortMode {
        case .NEWEST_FIRST:
            let lhsOrder = insertionOrderProvider(lhs)
            let rhsOrder = insertionOrderProvider(rhs)
            if (lhsOrder == nil) != (rhsOrder == nil) {
                return lhsOrder != nil
            }
            if (lhsOrder ?? Int.min) != (rhsOrder ?? Int.min) {
                return (lhsOrder ?? Int.min) > (rhsOrder ?? Int.min)
            }
            return lhsName < rhsName
        case .OLDEST_FIRST:
            let lhsOrder = insertionOrderProvider(lhs)
            let rhsOrder = insertionOrderProvider(rhs)
            if (lhsOrder == nil) != (rhsOrder == nil) {
                return lhsOrder != nil
            }
            if (lhsOrder ?? Int.max) != (rhsOrder ?? Int.max) {
                return (lhsOrder ?? Int.max) < (rhsOrder ?? Int.max)
            }
            return lhsName < rhsName
        case .NAME_ASC:
            return lhsName < rhsName
        case .NAME_DESC:
            return lhsName > rhsName
        case .BRIGHTEST_FIRST:
            return lhs.magnitude < rhs.magnitude
        case .FAINTEST_FIRST:
            return lhs.magnitude > rhs.magnitude
        case .RISES_SOONEST:
            let lhsRise = riseSortValueProvider(lhs)
            let rhsRise = riseSortValueProvider(rhs)
            if lhsRise != rhsRise {
                return lhsRise < rhsRise
            }
            return lhsName < rhsName
        case .SETS_SOONEST:
            let lhsSet = setSortValueProvider(lhs)
            let rhsSet = setSortValueProvider(rhs)
            if lhsSet != rhsSet {
                return lhsSet < rhsSet
            }
            return lhsName < rhsName
        }
    }
}

final class StarMapSearchState {
    private static let KEY_QUERY = "query"
    private static let KEY_SORT = "sort"
    private static let KEY_TYPE_FILTER = "type_filter"
    private static let KEY_NAKED_EYE = "naked_eye"
    private static let KEY_CATEGORIES = "categories"
    private static let KEY_QUICK_PRESET = "quick_preset"
    private static let KEY_QUICK_CATALOG = "quick_catalog"
    private static let KEY_RECENT_CHIPS = "recent_chips"
    private static let KEY_RECENT_CHIP_LABELS = "recent_chip_labels"
    private static let KEY_RECENT_CHIP_IDS = "recent_chip_ids"
    private static let MAX_RECENT_CHIPS = 8

    var query = ""
    var sortMode: StarMapSearchSortMode = .NAME_ASC
    var typeFilter: StarMapSearchTypeFilter = .SHOW_ALL
    var nakedEyeOnly = false
    var quickPresetType: StarMapSearchQuickPresetType = .NONE
    var quickPresetCatalogWid: String?
    var selectedCategories: [StarMapSearchCategoryFilter] = [.ALL]
    var recentChips: [StarMapRecentChip] = []

    init(savedInstanceState: [String: Any]? = nil) {
        restore(savedInstanceState)
    }

    func restore(_ savedInstanceState: [String: Any]?) {
        guard let savedInstanceState else {
            return
        }
        query = savedInstanceState[Self.KEY_QUERY] as? String ?? ""
        sortMode = (savedInstanceState[Self.KEY_SORT] as? String).flatMap(StarMapSearchSortMode.init(rawValue:)) ?? .NAME_ASC
        typeFilter = (savedInstanceState[Self.KEY_TYPE_FILTER] as? String).flatMap(StarMapSearchTypeFilter.init(rawValue:)) ?? .SHOW_ALL
        nakedEyeOnly = savedInstanceState[Self.KEY_NAKED_EYE] as? Bool ?? false
        quickPresetType = (savedInstanceState[Self.KEY_QUICK_PRESET] as? String).flatMap(StarMapSearchQuickPresetType.init(rawValue:)) ?? .NONE
        quickPresetCatalogWid = savedInstanceState[Self.KEY_QUICK_CATALOG] as? String

        selectedCategories.removeAll()
        if let categories = savedInstanceState[Self.KEY_CATEGORIES] as? [String] {
            for category in categories {
                if let value = StarMapSearchCategoryFilter(rawValue: category) {
                    selectedCategories.append(value)
                }
            }
        }
        if selectedCategories.isEmpty {
            selectedCategories.append(.ALL)
        }

        recentChips.removeAll()
        let recentChipLabels = savedInstanceState[Self.KEY_RECENT_CHIP_LABELS] as? [String]
        let recentChipIds = savedInstanceState[Self.KEY_RECENT_CHIP_IDS] as? [String]
        if let recentChipLabels {
            for (index, label) in recentChipLabels.enumerated() {
                let normalizedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
                if !normalizedLabel.isEmpty {
                    let objectId = recentChipIds?.indices.contains(index) == true ? recentChipIds?[index] : nil
                    recentChips.append(StarMapRecentChip(label: normalizedLabel,
                                                         objectId: objectId?.isEmpty == false ? objectId : nil))
                }
            }
        } else if let legacyLabels = savedInstanceState[Self.KEY_RECENT_CHIPS] as? [String] {
            for label in legacyLabels {
                let normalizedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
                if !normalizedLabel.isEmpty {
                    recentChips.append(StarMapRecentChip(label: normalizedLabel))
                }
            }
        }
    }

    func selectQuickPreset(_ quickPresetType: StarMapSearchQuickPresetType, catalogWid: String?) {
        self.quickPresetType = quickPresetType
        quickPresetCatalogWid = catalogWid
        query = ""
        if quickPresetType.isMyData {
            sortMode = defaultSortModeForPreset(quickPresetType)
        }
    }

    func prepareForExploreEntry(_ quickPresetType: StarMapSearchQuickPresetType, catalogWid: String?) {
        query = ""
        sortMode = defaultSortModeForPreset(quickPresetType)
        typeFilter = quickPresetType == .WATCH_NOW ? .VISIBLE_TONIGHT : .SHOW_ALL
        nakedEyeOnly = false
        self.quickPresetType = quickPresetType
        quickPresetCatalogWid = catalogWid
        selectedCategories.removeAll()
        selectedCategories.append(categoryPreset() ?? .ALL)
    }

    func shouldOpenInBrowseMode() -> Bool {
        quickPresetType.opensInBrowseMode
    }

    func hasBrowseContext() -> Bool {
        quickPresetType != .NONE
    }

    func isCategoryPreset() -> Bool {
        quickPresetType.categoryPreset != nil
    }

    func categoryPreset() -> StarMapSearchCategoryFilter? {
        quickPresetType.categoryPreset
    }

    func snapshot() -> StarMapSearchStateSnapshot {
        StarMapSearchStateSnapshot(query: query,
                                   sortMode: sortMode,
                                   typeFilter: typeFilter,
                                   nakedEyeOnly: nakedEyeOnly,
                                   quickPresetType: quickPresetType,
                                   quickPresetCatalogWid: quickPresetCatalogWid,
                                   selectedCategories: Set(selectedCategories))
    }

    func filterAndSort(preparedEntries: [StarMapSearchEntry],
                       visibleTonightProvider: (StarMapSearchEntry) -> Bool,
                       riseSortValueProvider: (StarMapSearchEntry) -> Int64,
                       setSortValueProvider: (StarMapSearchEntry) -> Int64,
                       insertionOrderProvider: (StarMapSearchEntry) -> Int?) -> [StarMapSearchEntry] {
        snapshot().filterAndSort(preparedEntries: preparedEntries,
                                 visibleTonightProvider: visibleTonightProvider,
                                 riseSortValueProvider: riseSortValueProvider,
                                 setSortValueProvider: setSortValueProvider,
                                 insertionOrderProvider: insertionOrderProvider)
    }

    func reset() {
        query = ""
        sortMode = .NAME_ASC
        typeFilter = .SHOW_ALL
        nakedEyeOnly = false
        quickPresetType = .NONE
        quickPresetCatalogWid = nil
        selectedCategories.removeAll()
        selectedCategories.append(.ALL)
    }

    func addRecentChip(label: String, objectId: String) {
        let normalizedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedLabel.isEmpty {
            return
        }
        recentChips.removeAll {
            $0.objectId == objectId || $0.label.caseInsensitiveCompare(normalizedLabel) == .orderedSame
        }
        recentChips.insert(StarMapRecentChip(label: normalizedLabel, objectId: objectId), at: 0)
        while recentChips.count > Self.MAX_RECENT_CHIPS {
            recentChips.removeLast()
        }
    }

    func replaceRecentChips(_ chips: [StarMapRecentChip]) {
        recentChips.removeAll()
        recentChips.append(contentsOf: chips.prefix(Self.MAX_RECENT_CHIPS))
    }

    func toggleCategoryFilter(_ categoryFilter: StarMapSearchCategoryFilter) {
        if categoryFilter == .ALL {
            selectedCategories.removeAll()
            selectedCategories.append(.ALL)
            return
        }

        selectedCategories.removeAll { $0 == .ALL }
        if selectedCategories.contains(categoryFilter) {
            selectedCategories.removeAll { $0 == categoryFilter }
        } else {
            selectedCategories.append(categoryFilter)
        }
        if selectedCategories.isEmpty {
            selectedCategories.append(.ALL)
        }
    }
    
    private func defaultSortModeForPreset(_ quickPresetType: StarMapSearchQuickPresetType) -> StarMapSearchSortMode {
        switch quickPresetType {
        case .WATCH_NOW:
            return .BRIGHTEST_FIRST
        case .MY_DATA_FAVORITES, .MY_DATA_DAILY_PATH, .MY_DATA_DIRECTIONS:
            return .NEWEST_FIRST
        default:
            return .NAME_ASC
        }
    }
}

func mapStarMapSearchCategory(_ obj: SkyObject) -> StarMapSearchCategoryFilter {
    switch obj.type {
    case .SUN, .MOON, .PLANET:
        return .SOLAR_SYSTEM
    case .CONSTELLATION:
        return .CONSTELLATIONS
    case .STAR:
        return .STARS
    case .NEBULA:
        return .NEBULAS
    case .OPEN_CLUSTER, .GLOBULAR_CLUSTER:
        return .STAR_CLUSTERS
    default:
        return .DEEP_SKY
    }
}
