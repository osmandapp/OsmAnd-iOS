//
//  StarMapMyDataViewController.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 25.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class StarMapMyDataViewController: UIViewController {

    enum Tab: Int, CaseIterable {
        case favorites = 0
        case dailyPath = 1
        case directions = 2

        var quickPresetType: StarMapSearchQuickPresetType {
            switch self {
            case .favorites:
                return .MY_DATA_FAVORITES
            case .dailyPath:
                return .MY_DATA_DAILY_PATH
            case .directions:
                return .MY_DATA_DIRECTIONS
            }
        }

        init?(quickPresetType: StarMapSearchQuickPresetType) {
            switch quickPresetType {
            case .MY_DATA_FAVORITES:
                self = .favorites
            case .MY_DATA_DAILY_PATH:
                self = .dailyPath
            case .MY_DATA_DIRECTIONS:
                self = .directions
            default:
                return nil
            }
        }
    }

    private enum Layout {
        static let contentPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let toolbarHeight: CGFloat = 56
        static let myDataTabsHeight: CGFloat = 56
        static let resultRowMinHeight: CGFloat = 72
        static let buttonHeight: CGFloat = 44
    }

    private static let RISE_SET_PRELOAD_COUNT = 32

    var onObjectSelected: ((SkyObject) -> Void)?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }
    
    private lazy var inlineSearchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = localizedString("astro_search_input_hint")
        bar.delegate = self
        bar.searchBarStyle = .minimal
        bar.autocapitalizationType = .none
        bar.returnKeyType = .search
        bar.showsCancelButton = true
        return bar
    }()

    private lazy var searchNavButton = UIBarButtonItem(
        image: .icCustomSearch,
        style: .plain,
        target: self,
        action: #selector(showInlineSearch)
    )
    
    private lazy var backNavButton = UIBarButtonItem(
        image: .icCustomSearch,
        style: .plain,
        target: self,
        action: #selector(showInlineSearch)
    )

    private lazy var searchAdapter = StarMapSearchResultsAdapter(
        nightMode: nightMode,
        snapshot: .empty,
        widToDisplayName: { [weak self] in self?.widToDisplayName ?? [:] },
        eventTextProvider: { [weak self] entry in
            self?.searchHelper.resolveEventText(entry) ?? NSAttributedString(string: "")
        },
        onScroll: { _ in },
        onEntrySelected: { [weak self] entry in self?.onSearchEntrySelected(entry) }
    )

    private lazy var searchPreparedDataFactory = StarMapSearchPreparedDataFactory(
        dataProvider: dataProvider,
        nightMode: nightMode
    )
    private lazy var searchHelper = StarMapSearchHelper()
    
    private let plugin: AstronomyPlugin
    private let dataProvider: AstroDataProvider
    private let nightMode: Bool
    private weak var parentStarMapController: StarMapViewController?

    private var isSearchAttached = false
    private var searchState = StarMapSearchState()
    private var currentTab: Tab
    private var preparedEntries: [StarMapSearchEntry] = []
    private var visibleEntries: [StarMapSearchEntry] = []
    private var widToDisplayName: [String: String] = [:]
    private var filterAndSortRequestId = 0
    private var isFilteringResults = false
    private var suppressQueryDispatch = false
    private var redFilterEnabled = false

    private let mainStack = UIStackView()
    private let myDataTabs = UIStackView()
    private var myDataTabButtons: [UIButton] = []
    private var myDataTabIndicators: [UIView] = []
    private let sortFilterBar = UIStackView()
    private let sortButton = UIButton(type: .system)
    private let filterButton = UIButton(type: .system)
    private let sortProgress = UIActivityIndicatorView(style: .medium)
    private let resultsContainer = UIView()
    private let searchRecycler = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyStateContainer = UIStackView()
    private let emptyStateIcon = UIImageView()
    private let emptyStateTitle = UILabel()
    private let emptyStateDescription = UILabel()
    private let emptyStateResetButton = UIButton(type: .system)

    private init(parent: StarMapViewController,
                 plugin: AstronomyPlugin,
                 initialTab: Tab) {
        parentStarMapController = parent
        self.plugin = plugin
        dataProvider = plugin.dataProvider
        nightMode = OADayNightHelper.instance().isNightMode()
        currentTab = initialTab
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func newInstance(initialTab: Tab = .favorites,
                          initialPreset: StarMapSearchQuickPresetType? = nil,
                          parent: StarMapViewController,
                          plugin: AstronomyPlugin) -> StarMapMyDataViewController {
        let tab = initialPreset.flatMap(Tab.init(quickPresetType:)) ?? initialTab
        return StarMapMyDataViewController(parent: parent, plugin: plugin, initialTab: tab)
    }

    func applyRedFilter(enabled: Bool) {
        redFilterEnabled = enabled
        guard isViewLoaded else { return }
        AstroRedFilter.apply(enabled, to: navigationController?.view ?? view)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBg
        bindViews()
        setupNavigationBar()
        definesPresentationContext = true
        searchState.prepareForExploreEntry(currentTab.quickPresetType, catalogWid: nil)
        refreshPreparedEntries()
        setupSearchRecycler()
        updateMyDataTabs()
        updateSortControls()
        updateFilterControls()
        updateEmptyStateContent()
        applyRedFilter(enabled: redFilterEnabled)
        applyFiltersAndSort(scrollToTop: false)
    }

    // MARK: - Layout

    private func bindViews() {
        mainStack.axis = .vertical
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)

        setupMyDataTabs()
        setupSortFilterBar()
        setupEmptyState()
        setupResultsContainer()

        mainStack.addArrangedSubview(myDataTabs)
        mainStack.addArrangedSubview(sortFilterBar)
        mainStack.addArrangedSubview(resultsContainer)

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupMyDataTabs() {
        myDataTabs.axis = .horizontal
        myDataTabs.alignment = .fill
        myDataTabs.distribution = .fillEqually
        myDataTabs.spacing = 0
        myDataTabs.backgroundColor = .viewBg
        myDataTabs.heightAnchor.constraint(equalToConstant: Layout.myDataTabsHeight).isActive = true

        let tabTitles = [
            localizedString("favorites_item"),
            localizedString("astro_daily_path"),
            localizedString("astro_directions")
        ]
        myDataTabButtons.removeAll()
        myDataTabIndicators.removeAll()

        for (index, title) in tabTitles.enumerated() {
            let tabContainer = UIControl()
            tabContainer.tag = index
            tabContainer.addTarget(self, action: #selector(myDataTabPressed(_:)), for: .touchUpInside)

            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
            button.isUserInteractionEnabled = false
            button.translatesAutoresizingMaskIntoConstraints = false

            let indicator = UIView()
            indicator.backgroundColor = .systemBlue
            indicator.translatesAutoresizingMaskIntoConstraints = false

            tabContainer.translatesAutoresizingMaskIntoConstraints = false
            tabContainer.addSubview(button)
            tabContainer.addSubview(indicator)
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor),
                button.topAnchor.constraint(equalTo: tabContainer.topAnchor),
                button.bottomAnchor.constraint(equalTo: indicator.topAnchor),
                indicator.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor),
                indicator.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor),
                indicator.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
                indicator.heightAnchor.constraint(equalToConstant: 3)
            ])

            myDataTabs.addArrangedSubview(tabContainer)
            myDataTabButtons.append(button)
            myDataTabIndicators.append(indicator)
        }
    }

    private func setupSortFilterBar() {
        sortFilterBar.axis = .horizontal
        sortFilterBar.alignment = .center
        sortFilterBar.distribution = .fill
        sortFilterBar.spacing = 0
        sortFilterBar.backgroundColor = StarMapSearchLightPalette.listBackground
        sortFilterBar.layoutMargins = UIEdgeInsets(
            top: 0,
            left: Layout.contentPadding,
            bottom: 0,
            right: Layout.contentPadding
        )
        sortFilterBar.isLayoutMarginsRelativeArrangement = true
        sortFilterBar.heightAnchor.constraint(equalToConstant: Layout.toolbarHeight).isActive = true

        configureMenuButton(sortButton)
        configureMenuButton(filterButton)

        let spacer = UIView()
        sortProgress.hidesWhenStopped = true
        sortProgress.color = .systemBlue
        sortFilterBar.addArrangedSubview(sortButton)
        sortFilterBar.addArrangedSubview(sortProgress)
        sortFilterBar.addArrangedSubview(spacer)
        sortFilterBar.addArrangedSubview(filterButton)
    }

    private func setupResultsContainer() {
        resultsContainer.translatesAutoresizingMaskIntoConstraints = false
        resultsContainer.backgroundColor = StarMapSearchLightPalette.listBackground

        searchRecycler.translatesAutoresizingMaskIntoConstraints = false
        searchRecycler.keyboardDismissMode = .onDrag
        searchRecycler.rowHeight = UITableView.automaticDimension
        searchRecycler.estimatedRowHeight = Layout.resultRowMinHeight
        searchRecycler.separatorStyle = .none
        searchRecycler.backgroundColor = StarMapSearchLightPalette.listBackground

        emptyStateContainer.translatesAutoresizingMaskIntoConstraints = false
        resultsContainer.addSubview(searchRecycler)
        resultsContainer.addSubview(emptyStateContainer)

        NSLayoutConstraint.activate([
            searchRecycler.leadingAnchor.constraint(equalTo: resultsContainer.leadingAnchor),
            searchRecycler.trailingAnchor.constraint(equalTo: resultsContainer.trailingAnchor),
            searchRecycler.topAnchor.constraint(equalTo: resultsContainer.topAnchor),
            searchRecycler.bottomAnchor.constraint(equalTo: resultsContainer.bottomAnchor),

            emptyStateContainer.leadingAnchor.constraint(
                equalTo: resultsContainer.leadingAnchor,
                constant: Layout.contentPadding
            ),
            emptyStateContainer.trailingAnchor.constraint(
                equalTo: resultsContainer.trailingAnchor,
                constant: -Layout.contentPadding
            ),
            emptyStateContainer.centerYAnchor.constraint(equalTo: resultsContainer.centerYAnchor)
        ])
    }

    private func setupEmptyState() {
        emptyStateContainer.axis = .vertical
        emptyStateContainer.alignment = .center
        emptyStateContainer.spacing = Layout.smallPadding
        emptyStateContainer.backgroundColor = .clear
        emptyStateContainer.layoutMargins = UIEdgeInsets(
            top: 0,
            left: Layout.contentPadding,
            bottom: 0,
            right: Layout.contentPadding
        )
        emptyStateContainer.isLayoutMarginsRelativeArrangement = true

        emptyStateIcon.contentMode = .scaleAspectFit
        emptyStateIcon.tintColor = StarMapSearchLightPalette.defaultIcon
        emptyStateIcon.heightAnchor.constraint(equalToConstant: 64).isActive = true
        emptyStateIcon.widthAnchor.constraint(equalToConstant: 64).isActive = true

        emptyStateTitle.font = UIFont.preferredFont(forTextStyle: .headline)
        emptyStateTitle.textColor = StarMapSearchLightPalette.primaryText
        emptyStateDescription.font = UIFont.preferredFont(forTextStyle: .subheadline)
        emptyStateDescription.textColor = StarMapSearchLightPalette.secondaryText
        emptyStateDescription.numberOfLines = 0
        emptyStateDescription.textAlignment = .center

        emptyStateResetButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight).isActive = true
        emptyStateResetButton.translatesAutoresizingMaskIntoConstraints = false
        emptyStateResetButton.addTarget(self, action: #selector(emptyStateAction), for: .touchUpInside)

        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .small
        configuration.baseBackgroundColor = StarMapSearchLightPalette.secondaryButtonBackground
        configuration.baseForegroundColor = .systemBlue
        emptyStateResetButton.configuration = configuration

        emptyStateContainer.addArrangedSubview(emptyStateIcon)
        emptyStateContainer.addArrangedSubview(emptyStateTitle)
        emptyStateContainer.addArrangedSubview(emptyStateDescription)
        emptyStateContainer.addArrangedSubview(emptyStateResetButton)
        emptyStateResetButton.widthAnchor.constraint(
            equalTo: emptyStateContainer.widthAnchor,
            constant: -2 * Layout.contentPadding
        ).isActive = true
        emptyStateContainer.isHidden = true
    }

    private func setupSearchRecycler() {
        searchRecycler.dataSource = searchAdapter
        searchRecycler.delegate = searchAdapter
    }

    private func configureMenuButton(_ button: UIButton) {
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = false
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .systemBlue
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        configuration.imagePadding = Layout.smallPadding
        button.configuration = configuration
    }

    // MARK: - Navigation

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backPressed)
        )
        navigationItem.rightBarButtonItem = searchNavButton
        navigationItem.rightBarButtonItem?.accessibilityLabel = localizedString("shared_string_search")
        navigationItem.leftBarButtonItem?.accessibilityLabel = localizedString("shared_string_back")
        navigationItem.hidesBackButton = false
        navigationItem.title = localizedString("astro_explore_my_data")
        navigationItem.largeTitleDisplayMode = .never
    }

    private func syncSearchQuery() {
        suppressQueryDispatch = true
        inlineSearchBar.text = searchState.query
        suppressQueryDispatch = false
    }

    // MARK: - Data

    private func refreshPreparedEntries() {
        let preparedData = searchPreparedDataFactory.create(parent: parentStarMapController)
        preparedEntries = preparedData.entries
        widToDisplayName = preparedData.widToDisplayName
        searchHelper.updateComputationContext(preparedData.computationContext)
    }

    private func updateResultsAdapter() {
        searchAdapter.submitSnapshot(
            StarMapSearchResultsAdapter.Snapshot(
                entries: visibleEntries,
                categoryPreset: nil,
                infoHeaderCategory: nil,
                useExploreRowLayout: true
            )
        )
        searchRecycler.reloadData()
    }

    private func applyFiltersAndSort(scrollToTop: Bool) {
        let requestId = filterAndSortRequestId + 1
        filterAndSortRequestId = requestId
        isFilteringResults = true
        let stateSnapshot = searchState.snapshot()
        let preparedEntriesSnapshot = preparedEntries
        updateResultsAdapter()
        updateSortControls()
        updateFilterControls()
        updateEmptyStateContent()
        updateSortProgressVisibility(true)
        emptyStateContainer.isHidden = true
        searchRecycler.isHidden = false

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let insertionOrderById = self.getMyDataInsertionOrderMap(stateSnapshot.quickPresetType)
            let filteredEntries = stateSnapshot.filterAndSort(
                preparedEntries: preparedEntriesSnapshot.map { $0.copy() },
                visibleTonightProvider: self.searchHelper.getVisibleTonight,
                riseSortValueProvider: self.searchHelper.getRiseSortValue,
                setSortValueProvider: self.searchHelper.getSetSortValue,
                insertionOrderProvider: { entry in insertionOrderById[entry.objectRef.id] }
            )
            self.searchHelper.preloadRiseSet(filteredEntries.prefix(Self.RISE_SET_PRELOAD_COUNT))
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      viewIfLoaded?.window != nil,
                      requestId == filterAndSortRequestId else {
                    return
                }
                visibleEntries = filteredEntries
                updateResultsAdapter()
                finishApplyFilters(scrollToTop: scrollToTop, requestId: requestId)
            }
        }
    }

    private func finishApplyFilters(scrollToTop: Bool, requestId: Int) {
        if scrollToTop {
            let topOffset = CGPoint(x: 0, y: -searchRecycler.adjustedContentInset.top)
            if searchRecycler.contentOffset != topOffset {
                searchRecycler.setContentOffset(topOffset, animated: false)
            }
        }
        isFilteringResults = false
        updateEmptyStateVisibility()
        if requestId == filterAndSortRequestId {
            updateSortProgressVisibility(false)
        }
    }

    private func getMyDataInsertionOrderMap(_ quickPresetType: StarMapSearchQuickPresetType) -> [String: Int] {
        let config = parentStarMapController?.getSearchStarMapConfig() ?? AstronomyPluginSettings.load().starMap
        let ids: [String]
        switch quickPresetType {
        case .MY_DATA_FAVORITES:
            ids = config.favorites.map(\.id)
        case .MY_DATA_DAILY_PATH:
            ids = config.celestialPaths.map(\.id)
        case .MY_DATA_DIRECTIONS:
            ids = config.directions.map(\.id)
        default:
            ids = []
        }
        var result: [String: Int] = [:]
        for (index, id) in ids.enumerated() {
            result[id] = index
        }
        return result
    }

    // MARK: - UI updates

    private func updateMyDataTabs() {
        for (index, button) in myDataTabButtons.enumerated() {
            let selected = index == currentTab.rawValue
            button.setTitleColor(
                selected ? .systemBlue : StarMapSearchLightPalette.secondaryText,
                for: .normal
            )
            if index < myDataTabIndicators.count {
                myDataTabIndicators[index].isHidden = !selected
            }
        }
    }

    private func updateSortProgressVisibility(_ isVisible: Bool) {
        if isVisible {
            sortProgress.startAnimating()
        } else {
            sortProgress.stopAnimating()
        }
    }

    private func updateSortControls() {
        let text: String
        let iconName: String
        switch searchState.sortMode {
        case .NEWEST_FIRST:
            text = localizedString("astro_sort_newest_first")
            iconName = "ic_custom_sort_date_newest"
        case .OLDEST_FIRST:
            text = localizedString("astro_sort_oldest_first")
            iconName = "ic_custom_sort_date_oldest"
        case .NAME_ASC:
            text = localizedString("sort_name_ascending")
            iconName = "ic_custom_sort_name_ascending"
        case .NAME_DESC:
            text = localizedString("sort_name_descending")
            iconName = "ic_custom_sort_name_descending"
        case .BRIGHTEST_FIRST:
            text = localizedString("astro_sort_brightest_first")
            iconName = "ic_custom_sort_brightest"
        case .FAINTEST_FIRST:
            text = localizedString("astro_sort_faintest_first")
            iconName = "ic_custom_sort_faintest"
        case .RISES_SOONEST:
            text = localizedString("astro_sort_rises_soonest")
            iconName = "ic_custom_sort_rises"
        case .SETS_SOONEST:
            text = localizedString("astro_sort_sets_soonest")
            iconName = "ic_custom_sort_sets"
        }
        var configuration = sortButton.configuration ?? UIButton.Configuration.plain()
        configuration.title = text
        configuration.image = AstroIcon.template(iconName)
        configuration.imagePlacement = .leading
        configuration.baseForegroundColor = .systemBlue
        configuration.imagePadding = Layout.smallPadding
        sortButton.configuration = configuration
        sortButton.menu = createSortMenu()
    }

    private func updateFilterControls() {
        var configuration = filterButton.configuration ?? UIButton.Configuration.plain()
        configuration.title = String(
            format: localizedString("filter_tracks_count"),
            searchState.calculateFilterCount()
        )
        configuration.image = .icCustomFilter
        configuration.imagePlacement = .trailing
        configuration.baseForegroundColor = .systemBlue
        configuration.imagePadding = Layout.smallPadding
        filterButton.configuration = configuration
        filterButton.menu = createFilterMenu()
    }

    private func updateEmptyStateContent() {
        let iconName: String
        let titleKey: String
        let descriptionKey: String
        switch currentTab {
        case .directions:
            iconName = "ic_custom_bookmark_outlined"
            titleKey = "astro_my_data_no_directions_title"
            descriptionKey = "astro_my_data_no_directions_description"
        case .dailyPath:
            iconName = "ic_custom_target_path_off"
            titleKey = "astro_my_data_no_daily_paths_title"
            descriptionKey = "astro_my_data_no_daily_paths_description"
        case .favorites:
            iconName = "ic_custom_bookmark_outlined"
            titleKey = "astro_my_data_no_favorites_title"
            descriptionKey = "astro_my_data_no_favorites_description"
        }
        emptyStateIcon.image = AstroIcon.template(iconName)
        emptyStateTitle.text = localizedString(titleKey)
        emptyStateDescription.text = localizedString(descriptionKey)
        emptyStateResetButton.setTitle(localizedString("astro_go_to_map"), for: .normal)
    }

    private func updateEmptyStateVisibility() {
        if isFilteringResults {
            emptyStateContainer.isHidden = true
            searchRecycler.isHidden = false
            return
        }
        let shouldShowEmptyState = visibleEntries.isEmpty
        emptyStateContainer.isHidden = !shouldShowEmptyState
        searchRecycler.isHidden = shouldShowEmptyState
    }

    // MARK: - Menus

    private func createSortMenu() -> UIMenu {
        UIMenu(title: localizedString("sort_by"), children: [
            sortAction(title: localizedString("sort_name_ascending"), mode: .NAME_ASC),
            sortAction(title: localizedString("sort_name_descending"), mode: .NAME_DESC),
            sortAction(title: localizedString("astro_sort_brightest_first"), mode: .BRIGHTEST_FIRST),
            sortAction(title: localizedString("astro_sort_faintest_first"), mode: .FAINTEST_FIRST),
            sortAction(title: localizedString("astro_sort_rises_soonest"), mode: .RISES_SOONEST),
            sortAction(title: localizedString("astro_sort_sets_soonest"), mode: .SETS_SOONEST),
            sortAction(title: localizedString("astro_sort_newest_first"), mode: .NEWEST_FIRST),
            sortAction(title: localizedString("astro_sort_oldest_first"), mode: .OLDEST_FIRST)
        ])
    }

    private func sortAction(title: String, mode: StarMapSearchSortMode) -> UIAction {
        UIAction(title: title, state: searchState.sortMode == mode ? .on : .off) { [weak self] _ in
            self?.searchState.sortMode = mode
            self?.updateSortControls()
            self?.applyFiltersAndSort(scrollToTop: true)
        }
    }

    private func createFilterMenu() -> UIMenu {
        var children: [UIMenuElement] = [
            typeFilterAction(title: localizedString("astro_filter_show_all"), filter: .SHOW_ALL),
            typeFilterAction(title: localizedString("astro_filter_visible_now"), filter: .VISIBLE_NOW),
            typeFilterAction(title: localizedString("astro_filter_visible_tonight"), filter: .VISIBLE_TONIGHT),
            UIAction(
                title: localizedString("astro_filter_naked_eye"),
                state: searchState.nakedEyeOnly ? .on : .off
            ) { [weak self] _ in
                self?.searchState.nakedEyeOnly.toggle()
                self?.applyFiltersAndSort(scrollToTop: true)
            }
        ]
        let categoryActions = [
            categoryFilterAction(title: localizedString("shared_string_all"), category: .ALL),
            categoryFilterAction(title: localizedString("astro_solar_system"), category: .SOLAR_SYSTEM),
            categoryFilterAction(title: localizedString("astro_constellations"), category: .CONSTELLATIONS),
            categoryFilterAction(title: localizedString("astro_stars"), category: .STARS),
            categoryFilterAction(title: localizedString("astro_nebulas"), category: .NEBULAS),
            categoryFilterAction(title: localizedString("astro_star_clusters"), category: .STAR_CLUSTERS),
            categoryFilterAction(title: localizedString("astro_deep_sky"), category: .DEEP_SKY)
        ]
        children.append(
            UIMenu(
                title: localizedString("favourites_edit_dialog_category"),
                options: .displayInline,
                children: categoryActions
            )
        )
        return UIMenu(title: localizedString("shared_string_type"), children: children)
    }

    private func typeFilterAction(title: String, filter: StarMapSearchTypeFilter) -> UIAction {
        UIAction(title: title, state: searchState.typeFilter == filter ? .on : .off) { [weak self] _ in
            self?.searchState.typeFilter = filter
            self?.applyFiltersAndSort(scrollToTop: true)
        }
    }

    private func categoryFilterAction(title: String, category: StarMapSearchCategoryFilter) -> UIAction {
        UIAction(title: title, state: searchState.selectedCategories.contains(category) ? .on : .off) { [weak self] _ in
            self?.searchState.toggleCategoryFilter(category)
            self?.applyFiltersAndSort(scrollToTop: true)
        }
    }

    // MARK: - Actions

    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func myDataTabPressed(_ sender: UIControl) {
        guard let tab = Tab(rawValue: sender.tag), tab != currentTab else { return }
        currentTab = tab
        searchState.prepareForExploreEntry(tab.quickPresetType, catalogWid: nil)
        syncSearchQuery()
        updateMyDataTabs()
        updateEmptyStateContent()
        applyFiltersAndSort(scrollToTop: true)
    }

    @objc private func emptyStateAction() {
        dismiss(animated: true)
    }

    private func onSearchEntrySelected(_ entry: StarMapSearchEntry) {
        dismiss(animated: true) { [weak self] in
            self?.onObjectSelected?(entry.objectRef)
        }
    }
    
    @objc private func showInlineSearch() {
        navigationItem.title = nil
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil
        navigationItem.titleView = inlineSearchBar
        
        inlineSearchBar.alpha = 0
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.inlineSearchBar.alpha = 1
            self.navigationController?.navigationBar.layoutIfNeeded()
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.inlineSearchBar.setShowsCancelButton(true, animated: true)
            self.inlineSearchBar.becomeFirstResponder()
        }
    }
    
    private func hideInlineSearch() {
        
        UIView.animate(withDuration: 0.2, animations: {
            self.inlineSearchBar.alpha = 0
            self.navigationController?.navigationBar.layoutIfNeeded()
            self.view.layoutIfNeeded()
        }) { _ in
            
            self.navigationItem.titleView = nil
            self.setupNavigationBar()
            
            self.inlineSearchBar.resignFirstResponder()
            self.inlineSearchBar.text = nil
            
            self.suppressQueryDispatch = true
            self.suppressQueryDispatch = false
            self.searchState.query = ""
            self.applyFiltersAndSort(scrollToTop: true)
        }
    }
}

// MARK: - UISearchBarDelegate

extension StarMapMyDataViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !suppressQueryDispatch else { return }
        searchState.query = searchText
        applyFiltersAndSort(scrollToTop: true)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        hideInlineSearch()
    }
}
