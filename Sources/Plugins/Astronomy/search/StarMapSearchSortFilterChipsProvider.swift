//
//  StarMapSearchSortFilterChipsProvider.swift
//  OsmAnd Maps
//
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

struct StarMapSearchSortFilterConfiguration {
    var catalogMode = false
    var showsMyDataSortModes = false
    var showsShowAllVisibility = true
    var showsCategoriesSection = true

    static func make(catalogMode: Bool,
                     isMyData: Bool,
                     showsShowAllVisibility: Bool,
                     showsCategoriesSection: Bool) -> StarMapSearchSortFilterConfiguration {
        StarMapSearchSortFilterConfiguration(
            catalogMode: catalogMode,
            showsMyDataSortModes: isMyData,
            showsShowAllVisibility: showsShowAllVisibility,
            showsCategoriesSection: showsCategoriesSection
        )
    }
}

final class StarMapSearchSortFilterChipsProvider: SearchSortFilterChipsDataSource, SearchSortFilterChipsDelegate {

    var onChange: (() -> Void)?

    private weak var searchState: StarMapSearchState?
    private var configuration = StarMapSearchSortFilterConfiguration()

    func configure(searchState: StarMapSearchState, configuration: StarMapSearchSortFilterConfiguration) {
        self.searchState = searchState
        self.configuration = configuration
        normalizeTypeFilterIfNeeded()
    }

    // MARK: SearchSortFilterChipsDataSource

    func chipGroups(for chipsView: SearchSortFilterChipsView) -> [SearchSortFilterChipGroup] {
        guard let searchState else {
            return []
        }

        if configuration.catalogMode {
            return [makeSortGroup(searchState: searchState)]
        }

        var groups: [SearchSortFilterChipGroup] = [
            makeVisibilityGroup(searchState: searchState)
        ]
        if configuration.showsCategoriesSection {
            groups.append(makeCategoriesGroup(searchState: searchState))
        }
        groups.append(makeSortGroup(searchState: searchState))
        groups.append(makeNakedEyeGroup(searchState: searchState))
        return groups
    }

    // MARK: SearchSortFilterChipsDelegate

    func chipsView(_ chipsView: SearchSortFilterChipsView, didSelectOption optionId: String, inGroup groupId: String) {
        guard let searchState else {
            return
        }
        switch groupId {
        case StarMapSearchSortFilterChipGroupID.visibility:
            if let filter = StarMapSearchTypeFilter(rawValue: optionId) {
                searchState.typeFilter = filter
            }
        case StarMapSearchSortFilterChipGroupID.categories:
            if let category = StarMapSearchCategoryFilter(rawValue: optionId) {
                searchState.toggleCategoryFilter(category)
            }
        case StarMapSearchSortFilterChipGroupID.sort:
            if let mode = StarMapSearchSortMode(rawValue: optionId) {
                searchState.sortMode = mode
            }
        default:
            break
        }
        onChange?()
    }

    func chipsView(_ chipsView: SearchSortFilterChipsView, didToggleGroup groupId: String, isOn: Bool) {
        guard groupId == StarMapSearchSortFilterChipGroupID.nakedEye else {
            return
        }
        searchState?.nakedEyeOnly = isOn
        onChange?()
    }

    // MARK: - Groups

    private enum StarMapSearchSortFilterChipGroupID {
        static let visibility = "visibility"
        static let categories = "categories"
        static let sort = "sort"
        static let nakedEye = "naked_eye"
    }

    private func makeVisibilityGroup(searchState: StarMapSearchState) -> SearchSortFilterChipGroup {
        let filters = StarMapSearchTypeFilter.availableFilters(configuration: configuration)
        var sections: [SearchSortFilterChipSection] = []

        if let showAll = filters.first(where: { $0 == .SHOW_ALL }) {
            sections.append(SearchSortFilterChipSection(options: [
                makeOption(id: showAll.rawValue,
                           title: showAll.localizedTitle,
                           iconName: showAll.iconName,
                           isSelected: searchState.typeFilter == showAll)
            ]))
            let rest = filters.filter { $0 != .SHOW_ALL }
            if !rest.isEmpty {
                sections.append(SearchSortFilterChipSection(options: rest.map { filter in
                    makeOption(id: filter.rawValue,
                               title: filter.localizedTitle,
                               iconName: filter.iconName,
                               isSelected: searchState.typeFilter == filter)
                }))
            }
        } else {
            sections.append(SearchSortFilterChipSection(options: filters.map { filter in
                makeOption(id: filter.rawValue,
                           title: filter.localizedTitle,
                           iconName: filter.iconName,
                           isSelected: searchState.typeFilter == filter)
            }))
        }

        return SearchSortFilterChipGroup(
            id: StarMapSearchSortFilterChipGroupID.visibility,
            chipTitle: visibilityChipTitle(searchState: searchState),
            chipImage: chipImage(searchState.typeFilter.iconName),
            selectionMode: .single,
            sections: sections
        )
    }

    private func makeCategoriesGroup(searchState: StarMapSearchState) -> SearchSortFilterChipGroup {
        let allSection = SearchSortFilterChipSection(options: [
            makeOption(id: StarMapSearchCategoryFilter.ALL.rawValue,
                       title: StarMapSearchCategoryFilter.ALL.localizedTitle,
                       iconName: getCategoryIconRes(.ALL),
                       isSelected: searchState.selectedCategories.contains(.ALL))
        ])
        let specificSection = SearchSortFilterChipSection(options: StarMapSearchCategoryFilter.specific.map { category in
            makeOption(id: category.rawValue,
                       title: category.localizedTitle,
                       iconName: getCategoryIconRes(category),
                       isSelected: searchState.selectedCategories.contains(category))
        })

        return SearchSortFilterChipGroup(
            id: StarMapSearchSortFilterChipGroupID.categories,
            chipTitle: categoriesChipTitle(searchState: searchState),
            chipImage: chipImage(categoriesChipIcon(searchState: searchState)),
            selectionMode: .multiple,
            sections: [allSection, specificSection]
        )
    }

    private func makeSortGroup(searchState: StarMapSearchState) -> SearchSortFilterChipGroup {
        let sections = StarMapSearchSortMode.menuSections(configuration: configuration).map { modes in
            SearchSortFilterChipSection(options: modes.map { mode in
                makeOption(id: mode.rawValue,
                           title: mode.localizedTitle,
                           iconName: mode.iconName,
                           isSelected: searchState.sortMode == mode)
            })
        }

        return SearchSortFilterChipGroup(
            id: StarMapSearchSortFilterChipGroupID.sort,
            chipTitle: searchState.sortMode.localizedTitle,
            chipImage: chipImage(searchState.sortMode.iconName),
            selectionMode: .single,
            sections: sections
        )
    }

    private func makeNakedEyeGroup(searchState: StarMapSearchState) -> SearchSortFilterChipGroup {
        SearchSortFilterChipGroup(
            id: StarMapSearchSortFilterChipGroupID.nakedEye,
            chipTitle: localizedString("astro_filter_naked_eye"),
            chipImage: chipImage("ic_custom_show"),
            selectionMode: .toggle,
            isToggleOn: searchState.nakedEyeOnly
        )
    }

    // MARK: - Helpers

    private func makeOption(id: String, title: String, iconName: String, isSelected: Bool) -> SearchSortFilterChipOption {
        SearchSortFilterChipOption(
            id: id,
            title: title,
            image: chipImage(iconName),
            isSelected: isSelected
        )
    }

    private func chipImage(_ iconName: String?) -> UIImage? {
        iconName.flatMap { AstroIcon.template($0)?.resizedTemplateImage(with: 20) }
    }

    private func normalizeTypeFilterIfNeeded() {
        guard let searchState else {
            return
        }
        if !configuration.showsShowAllVisibility && searchState.typeFilter == .SHOW_ALL {
            searchState.typeFilter = .VISIBLE_TONIGHT
        }
    }

    private func categoriesChipTitle(searchState: StarMapSearchState) -> String {
        let defaultLabel = localizedString("search_categories")
        let specific = searchState.selectedCategories.filter { $0 != .ALL }
        switch specific.count {
        case 0:
            return defaultLabel
        case 1:
            return specific[0].localizedTitle
        default:
            return "\(defaultLabel) (\(specific.count))"
        }
    }

    private func categoriesChipIcon(searchState: StarMapSearchState) -> String {
        let specific = searchState.selectedCategories.filter { $0 != .ALL }
        if specific.count == 1 {
            return getCategoryIconRes(specific[0])
        }
        return "ic_custom_list"
    }

    private func visibilityChipTitle(searchState: StarMapSearchState) -> String {
        switch searchState.typeFilter {
        case .SHOW_ALL:
            return localizedString("visibility")
        case .VISIBLE_NOW, .VISIBLE_TONIGHT:
            return searchState.typeFilter.localizedTitle
        }
    }
}

// MARK: - Enum presentation

private extension StarMapSearchSortMode {
    var localizedTitle: String {
        switch self {
        case .NEWEST_FIRST: return localizedString("astro_sort_newest_first")
        case .OLDEST_FIRST: return localizedString("astro_sort_oldest_first")
        case .NAME_ASC: return localizedString("sort_name_ascending")
        case .NAME_DESC: return localizedString("sort_name_descending")
        case .BRIGHTEST_FIRST: return localizedString("astro_sort_brightest_first")
        case .FAINTEST_FIRST: return localizedString("astro_sort_faintest_first")
        case .RISES_SOONEST: return localizedString("astro_sort_rises_soonest")
        case .SETS_SOONEST: return localizedString("astro_sort_sets_soonest")
        }
    }

    var iconName: String {
        switch self {
        case .NEWEST_FIRST: return "ic_custom_sort_date_newest"
        case .OLDEST_FIRST: return "ic_custom_sort_date_oldest"
        case .NAME_ASC: return "ic_custom_sort_name_ascending"
        case .NAME_DESC: return "ic_custom_sort_name_descending"
        case .BRIGHTEST_FIRST: return "ic_custom_sort_brightest"
        case .FAINTEST_FIRST: return "ic_custom_sort_faintest"
        case .RISES_SOONEST: return "ic_custom_sort_rises"
        case .SETS_SOONEST: return "ic_custom_sort_sets"
        }
    }

    static func menuSections(configuration: StarMapSearchSortFilterConfiguration) -> [[StarMapSearchSortMode]] {
        if configuration.catalogMode {
            return [[.NAME_ASC, .NAME_DESC]]
        }
        var sections: [[StarMapSearchSortMode]] = [
            [.NAME_ASC, .NAME_DESC],
            [.BRIGHTEST_FIRST, .FAINTEST_FIRST],
            [.RISES_SOONEST, .SETS_SOONEST]
        ]
        if configuration.showsMyDataSortModes {
            sections.append([.NEWEST_FIRST, .OLDEST_FIRST])
        }
        return sections
    }
}

private extension StarMapSearchTypeFilter {
    var localizedTitle: String {
        switch self {
        case .SHOW_ALL: return localizedString("astro_filter_show_all")
        case .VISIBLE_NOW: return localizedString("astro_filter_visible_now")
        case .VISIBLE_TONIGHT: return localizedString("astro_filter_visible_tonight")
        }
    }

    var iconName: String {
        switch self {
        case .SHOW_ALL: return "ic_custom_telescope"
        case .VISIBLE_NOW: return "ic_custom_clock"
        case .VISIBLE_TONIGHT: return "ic_custom_moon_outlined"
        }
    }

    static func availableFilters(configuration: StarMapSearchSortFilterConfiguration) -> [StarMapSearchTypeFilter] {
        var filters: [StarMapSearchTypeFilter] = []
        if configuration.showsShowAllVisibility {
            filters.append(.SHOW_ALL)
        }
        filters.append(contentsOf: [.VISIBLE_NOW, .VISIBLE_TONIGHT])
        return filters
    }
}

private extension StarMapSearchCategoryFilter {
    var localizedTitle: String {
        switch self {
        case .ALL: return localizedString("shared_string_all")
        case .SOLAR_SYSTEM: return localizedString("astro_solar_system")
        case .CONSTELLATIONS: return localizedString("astro_constellations")
        case .STARS: return localizedString("astro_stars")
        case .NEBULAS: return localizedString("astro_nebulas")
        case .STAR_CLUSTERS: return localizedString("astro_star_clusters")
        case .DEEP_SKY: return localizedString("astro_deep_sky")
        }
    }

    static let specific: [StarMapSearchCategoryFilter] = [
        .SOLAR_SYSTEM, .CONSTELLATIONS, .STARS, .NEBULAS, .STAR_CLUSTERS, .DEEP_SKY
    ]
}
