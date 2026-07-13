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
        case favorites
        case dailyPath
        case directions

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
        static let myDataSegmentedControlHeight: CGFloat = 36
        static let resultRowMinHeight: CGFloat = 72
    }

    private static let RISE_SET_PRELOAD_COUNT = 32

    var onObjectSelected: ((SkyObject) -> Void)?
    var onDismiss: (() -> Void)?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }

    private let plugin: AstronomyPlugin
    private let dataProvider: AstroDataProvider
    private let nightMode: Bool
    
    private let mainStack = UIStackView()
    private let myDataSegmentedControlContainer = UIView()
    private let myDataSegmentedControl = UISegmentedControl()
    private let sortFilterContainer = UIView()
    private let sortFilterChipsView = StarMapSearchSortFilterChipsView()
    private let sortFilterChipsProvider = StarMapSearchSortFilterChipsProvider()
    private let resultsContainer = UIView()
    private let searchRecycler = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyView = StarMapSearchEmptyView()

    private var searchState = StarMapSearchState()
    private var currentTab: Tab
    private var preparedEntries: [StarMapSearchEntry] = []
    private var visibleEntries: [StarMapSearchEntry] = []
    private var widToDisplayName: [String: String] = [:]
    private var starConstellationNameByObjectId: [String: String] = [:]
    private var filterAndSortRequestId = 0
    private var isFilteringResults = false
    private var suppressQueryDispatch = false
    private var redFilterEnabled = false
    private var isSearchActive = false

    private weak var parentStarMapController: StarMapViewController?
    
    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.delegate = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = OAUtilities.isIPhone()
        controller.searchBar.placeholder = localizedString("shared_string_search")
        controller.searchBar.delegate = self
        controller.searchBar.searchBarStyle = .prominent
        return controller
    }()

    private lazy var searchNavButton = UIBarButtonItem(
        image: UIImage(systemName: "magnifyingglass"),
        style: .plain,
        target: self,
        action: #selector(showSearch)
    )

    private lazy var searchAdapter = StarMapSearchResultsAdapter(
        tableView: searchRecycler,
        snapshot: .empty,
        widToDisplayName: { [weak self] in
            self?.widToDisplayName ?? [:]
        },
        starConstellationNameForObject: { [weak self] object in
            guard let self else { return nil }
            return starConstellationNameByObjectId[object.id]
        },
        eventTextProvider: { [weak self] entry in
            self?.searchHelper.resolveEventText(entry) ?? NSAttributedString(string: "")
        },
        visibilityAttributedTextProvider: { [weak self] entry in
            self?.searchHelper.resolveConstellationVisibilityAttributedText(entry) ?? NSAttributedString(string: "")
        },
        onScroll: { _ in },
        onEntrySelected: { [weak self] entry in
            self?.onSearchEntrySelected(entry)
        },
        contextMenuProvider: { [weak self] entry in
            self?.contextMenuProvider(for: entry)
        }
    )

    private lazy var searchPreparedDataFactory = StarMapSearchPreparedDataFactory(
        dataProvider: dataProvider,
        nightMode: nightMode
    )
    private lazy var searchHelper = StarMapSearchHelper()

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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBg
        definesPresentationContext = true
        
        bindViews()
        setupNavigationBar()
        searchState.prepareForExploreEntry(currentTab.quickPresetType, catalogWid: nil)
        refreshPreparedEntries()
        setupSearchRecycler()
        updateSortFilterBar()
        updateEmptyStateContent()
        applyRedFilter(enabled: redFilterEnabled)
        applyFiltersAndSort(scrollToTop: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    func applyRedFilter(enabled: Bool) {
        redFilterEnabled = enabled
        guard isViewLoaded else { return }
        
        if let view = navigationController?.view {
            AstroRedFilter.apply(enabled, to: view)
        }
    }

    // MARK: - Layout

    private func bindViews() {
        mainStack.axis = .vertical
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)

        setupMyDataSegmentedControl()
        setupSortFilterChips()
        setupResultsContainer()
        
        sortFilterChipsView.translatesAutoresizingMaskIntoConstraints = false
        sortFilterContainer.translatesAutoresizingMaskIntoConstraints = false
        
        sortFilterContainer.addSubview(sortFilterChipsView)

        mainStack.addArrangedSubview(myDataSegmentedControlContainer)
        mainStack.addArrangedSubview(sortFilterContainer)
        mainStack.addArrangedSubview(resultsContainer)
        
        mainStack.setCustomSpacing(16, after: sortFilterContainer)

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            sortFilterChipsView.leadingAnchor.constraint(equalTo: sortFilterContainer.leadingAnchor, constant: Layout.contentPadding),
            sortFilterChipsView.trailingAnchor.constraint(equalTo: sortFilterContainer.trailingAnchor, constant: -Layout.contentPadding),
            sortFilterChipsView.topAnchor.constraint(equalTo: sortFilterContainer.topAnchor),
            sortFilterChipsView.bottomAnchor.constraint(equalTo: sortFilterContainer.bottomAnchor)
        ])
    }

    private func setupMyDataSegmentedControl() {
        let tabTitles = [
            "favorites_item",
            "astro_daily_path",
            "astro_directions"
        ].map { localizedString($0) }
        for (index, title) in tabTitles.enumerated() {
            myDataSegmentedControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        myDataSegmentedControl.selectedSegmentIndex = currentTab.rawValue
        myDataSegmentedControl.addTarget(self, action: #selector(myDataSegmentChanged(_:)), for: .valueChanged)
        styleMyDataSegmentedControl()

        myDataSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        myDataSegmentedControlContainer.translatesAutoresizingMaskIntoConstraints = false
        myDataSegmentedControlContainer.addSubview(myDataSegmentedControl)

        NSLayoutConstraint.activate([
            myDataSegmentedControl.leadingAnchor.constraint(
                equalTo: myDataSegmentedControlContainer.leadingAnchor,
                constant: Layout.contentPadding
            ),
            myDataSegmentedControl.trailingAnchor.constraint(
                equalTo: myDataSegmentedControlContainer.trailingAnchor,
                constant: -Layout.contentPadding
            ),
            myDataSegmentedControl.topAnchor.constraint(equalTo: myDataSegmentedControlContainer.topAnchor),
            myDataSegmentedControl.bottomAnchor.constraint(equalTo: myDataSegmentedControlContainer.bottomAnchor, constant: -Layout.contentPadding),
            myDataSegmentedControl.heightAnchor.constraint(equalToConstant: Layout.myDataSegmentedControlHeight)
        ])
    }

    private func styleMyDataSegmentedControl() {
        myDataSegmentedControl.selectedSegmentTintColor = .groupBg
        myDataSegmentedControl.backgroundColor = .tertiarySystemFill.withAlphaComponent(0.12)
        let font = UIFont.scaledSystemFont(ofSize: 15, weight: .medium, maximumSize: 17)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.textColorPrimary,
            .font: font
        ]
        myDataSegmentedControl.setTitleTextAttributes(titleAttributes, for: .normal)
        myDataSegmentedControl.setTitleTextAttributes(titleAttributes, for: .selected)
    }

    private func setupSortFilterChips() {
        sortFilterChipsView.dataSource = sortFilterChipsProvider
        sortFilterChipsView.delegate = sortFilterChipsProvider
        sortFilterChipsProvider.onChange = { [weak self] in
            self?.applyFiltersAndSort(scrollToTop: true)
        }
    }

    private func setupResultsContainer() {
        resultsContainer.translatesAutoresizingMaskIntoConstraints = false

        searchRecycler.translatesAutoresizingMaskIntoConstraints = false
        searchRecycler.keyboardDismissMode = .onDrag
        searchRecycler.rowHeight = UITableView.automaticDimension
        searchRecycler.estimatedRowHeight = Layout.resultRowMinHeight
        searchRecycler.separatorStyle = .singleLine
        searchRecycler.sectionHeaderTopPadding = 0

        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.isHidden = true
        emptyView.onAction = { [weak self] in
            if self?.shouldShowSearchNoResultsEmpty() == true {
                self?.resetMyDataFilters()
            } else {
                if self?.parentStarMapController != nil, OAUtilities.isIPad() {
                    self?.onDismiss?()
                } else {
                    self?.navigationController?.dismiss(animated: true)
                }
            }
        }
        resultsContainer.addSubview(searchRecycler)
        resultsContainer.addSubview(emptyView)

        NSLayoutConstraint.activate([
            searchRecycler.leadingAnchor.constraint(equalTo: resultsContainer.leadingAnchor),
            searchRecycler.trailingAnchor.constraint(equalTo: resultsContainer.trailingAnchor),
            searchRecycler.topAnchor.constraint(equalTo: resultsContainer.topAnchor),
            searchRecycler.bottomAnchor.constraint(equalTo: resultsContainer.bottomAnchor),

            emptyView.leadingAnchor.constraint(equalTo: resultsContainer.leadingAnchor, constant: Layout.contentPadding),
            emptyView.trailingAnchor.constraint(equalTo: resultsContainer.trailingAnchor, constant: -Layout.contentPadding),
            emptyView.topAnchor.constraint(equalTo: resultsContainer.topAnchor)
        ])
    }

    private func setupSearchRecycler() {
        searchRecycler.cellLayoutMarginsFollowReadableWidth = false
        searchRecycler.directionalLayoutMargins.leading = Layout.contentPadding
        searchRecycler.directionalLayoutMargins.trailing = Layout.contentPadding
        searchRecycler.backgroundColor = .viewBg
        searchRecycler.dataSource = searchAdapter
        searchRecycler.delegate = searchAdapter
    }

    // MARK: - Navigation

    private func setupNavigationBar() {
        navigationController?.viewRespectsSystemMinimumLayoutMargins = false
        navigationController?.navigationBar.layoutMargins.left = Layout.contentPadding
        navigationController?.navigationBar.layoutMargins.right = Layout.contentPadding
        navigationController?.navigationBar.directionalLayoutMargins.leading = Layout.contentPadding
        navigationController?.navigationBar.directionalLayoutMargins.trailing = Layout.contentPadding
        
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
        
        updateNavigationBarForSearchState()
    }

    private func syncSearchQuery() {
        suppressQueryDispatch = true
        searchController.searchBar.text = searchState.query
        suppressQueryDispatch = false
    }
    
    private func updateNavigationBarForSearchState() {
        if isSearchActive {
            navigationItem.searchController = searchController
            navigationItem.rightBarButtonItem = nil
        } else {
            navigationItem.rightBarButtonItem = searchNavButton
            navigationItem.rightBarButtonItem?.accessibilityLabel = localizedString("shared_string_search")
        }
        navigationItem.hidesSearchBarWhenScrolling = false
        if #available(iOS 16.0, *) {
            navigationItem.preferredSearchBarPlacement = .stacked
        }
    }

    // MARK: - Data
    
    private func resetMyDataFilters() {
        searchState.query = ""
        searchState.typeFilter = .SHOW_ALL
        searchState.nakedEyeOnly = false
        searchState.selectedCategories = [.ALL]
        syncSearchQuery()
        if isSearchActive {
            hideSearch(clearQuery: true)
            return
        }
        applyFiltersAndSort(scrollToTop: true)
    }

    private func refreshPreparedEntries() {
        let preparedData = searchPreparedDataFactory.create(parent: parentStarMapController)
        preparedEntries = preparedData.entries
        widToDisplayName = preparedData.widToDisplayName
        starConstellationNameByObjectId = preparedData.starConstellationNameByObjectId
        searchHelper.updateComputationContext(preparedData.computationContext)
    }

    private func updateResultsAdapter() {
        searchAdapter.submitSnapshot(
            StarMapSearchResultsAdapter.Snapshot(
                entries: visibleEntries,
                categoryPreset: nil,
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
        updateSortFilterBar()
        updateEmptyStateContent()
        StarMapSearchProgressHUD.show(on: view)
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
        updateEmptyStateContent()
        updateEmptyStateVisibility()
        if requestId == filterAndSortRequestId {
            StarMapSearchProgressHUD.hide(from: view, animated: true)
        }
    }

    private func getMyDataInsertionOrderMap(_ quickPresetType: StarMapSearchQuickPresetType) -> [String: Int] {
        let config = parentStarMapController?.searchStarMapConfig() ?? AstronomyPluginSettings.load().starMap
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
    
    private func currentTabHasData() -> Bool {
        let config = parentStarMapController?.searchStarMapConfig() ?? AstronomyPluginSettings.load().starMap
        switch currentTab {
        case .favorites:
            return !config.favorites.isEmpty
        case .dailyPath:
            return !config.celestialPaths.isEmpty
        case .directions:
            return !config.directions.isEmpty
        }
    }

    private func isSearching() -> Bool {
        !searchState.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func contextMenuProvider(for entry: StarMapSearchEntry) -> UIContextMenuConfiguration? {
        guard let parent = parentStarMapController else { return nil }
        
        let handler = parent.makeSearchObjectActionHandler()
        
        return StarMapObjectContextMenuBuilder.makeConfiguration(
            for: entry.objectRef,
            handler: handler,
            onLocate: { [weak self] in
                self?.onSearchEntrySelected(entry)
            },
            onStateChanged: { [weak self] in
                self?.applyFiltersAndSort(scrollToTop: false)
            }
        )
    }

    // MARK: - UI updates

    private func updateSortFilterBar() {
        sortFilterChipsProvider.configure(
            searchState: searchState,
            configuration: .make(
                catalogMode: false,
                showMyDataSortModes: true,
                showsShowAllVisibility: true,
                showsCategoriesSection: !searchState.isCategoryPreset()
            )
        )
        sortFilterChipsView.reloadData()
        sortFilterContainer.isHidden = !(isSearching() || currentTabHasData())
    }

    private func updateEmptyStateContent() {
        if shouldShowSearchNoResultsEmpty() {
            emptyView.configure(with: .searchNoResults)
            return
        }
        
        let config: StarMapSearchEmptyConfig
        switch currentTab {
        case .directions:
            config = .myDataDirections
        case .dailyPath:
            config = .myDataDailyPath
        case .favorites:
            config = .myDataFavorites
        }
        emptyView.configure(with: config)
    }
    
    private func shouldShowSearchNoResultsEmpty() -> Bool {
        currentTabHasData() && visibleEntries.isEmpty
    }

    private func updateEmptyStateVisibility() {
        if isFilteringResults {
            emptyView.isHidden = true
            searchRecycler.isHidden = false
            return
        }
        let shouldShowEmptyState = visibleEntries.isEmpty
        emptyView.isHidden = !shouldShowEmptyState
        searchRecycler.isHidden = shouldShowEmptyState
    }

    // MARK: - Actions

    private func onSearchEntrySelected(_ entry: StarMapSearchEntry) {
        let select = { [weak self] in self?.onObjectSelected?(entry.objectRef) }
        if parentStarMapController != nil, OAUtilities.isIPad() {
            select()
        } else {
            navigationController?.dismiss(animated: true) { select() }
        }
    }
    
    private func hideSearch(clearQuery: Bool) {
        if clearQuery {
            searchState.query = ""
            searchController.searchBar.text = ""
        }
        isSearchActive = false
        updateNavigationBarForSearchState()
        applyFiltersAndSort(scrollToTop: true)
    }

    @objc private func backPressed() {
        if isSearchActive {
            hideSearch(clearQuery: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func myDataSegmentChanged(_ sender: UISegmentedControl) {
        guard let tab = Tab(rawValue: sender.selectedSegmentIndex), tab != currentTab else { return }
        currentTab = tab
        searchState.quickPresetType = tab.quickPresetType
        updateSortFilterBar()
        updateEmptyStateContent()
        applyFiltersAndSort(scrollToTop: true)
    }
    
    @objc private func showSearch() {
        isSearchActive = true
        navigationItem.searchController = searchController
        searchController.isActive = true
        updateNavigationBarForSearchState()
    }
    
    deinit {
        StarMapSearchProgressHUD.hide(from: view, animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension StarMapMyDataViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !suppressQueryDispatch else { return }
        searchState.query = searchText
        applyFiltersAndSort(scrollToTop: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        guard OAUtilities.isIPad() else { return }

        if searchBar.isFirstResponder, searchBar.text?.isEmpty == true {
            hideSearch(clearQuery: true)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if OAUtilities.isIPhone() {
            hideSearch(clearQuery: true)
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension StarMapMyDataViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === navigationController?.interactivePopGestureRecognizer else {
            return true
        }
        return (navigationController?.viewControllers.count ?? 0) > 1
    }
}

extension StarMapMyDataViewController: UISearchControllerDelegate {
    func presentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !searchController.searchBar.isFirstResponder {
                searchController.searchBar.becomeFirstResponder()
            }
        }
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        navigationItem.searchController = nil
        guard OAUtilities.isIPad(), searchController.searchBar.text?.isEmpty == true else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.hideSearch(clearQuery: true)
        }
    }
}
