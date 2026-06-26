//
//  StarMapSearchViewController.swift
//  OsmAnd Maps
//
//  Created by Codex on 06.06.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

enum StarMapSearchLightPalette {
    static let appBarBackground = UIColor(red: 222.0 / 255.0, green: 235.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0)
    static let listBackground = UIColor.white
    static let groupedBackground = UIColor(red: 239.0 / 255.0, green: 239.0 / 255.0, blue: 244.0 / 255.0, alpha: 1.0)
    static let primaryText = UIColor.black
    static let secondaryText = UIColor(red: 128.0 / 255.0, green: 119.0 / 255.0, blue: 143.0 / 255.0, alpha: 1.0)
    static let toolbarIcon = UIColor(red: 102.0 / 255.0, green: 102.0 / 255.0, blue: 102.0 / 255.0, alpha: 1.0)
    static let defaultIcon = UIColor(red: 188.0 / 255.0, green: 184.0 / 255.0, blue: 197.0 / 255.0, alpha: 1.0)
    static let separator = UIColor(red: 224.0 / 255.0, green: 224.0 / 255.0, blue: 224.0 / 255.0, alpha: 1.0)
    static let secondaryButtonBackground = UIColor(red: 238.0 / 255.0, green: 238.0 / 255.0, blue: 241.0 / 255.0, alpha: 1.0)
}

final class StarMapSearchViewController: UIViewController, UITextFieldDelegate {

    private enum ScreenMode {
        case EXPLORE
        case FULL_SEARCH
    }

    private enum FullSearchMode {
        case BROWSE
        case INPUT
    }

    private struct CatalogsBackState {
        let query: String
        let sortMode: StarMapSearchSortMode
        let scrollOffset: CGPoint
    }

    private enum Layout {
        static let contentPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let rowMinHeight: CGFloat = 56
        static let resultRowMinHeight: CGFloat = 72
        static let buttonHeight: CGFloat = 44
        static let iconSize: CGFloat = 24
        static let toolbarHeight: CGFloat = 56
    }

    static let TAG = "StarMapSearchDialog"
    private static let FEATURED_CATALOGS_COUNT = 5
    private static let RISE_SET_PRELOAD_COUNT = 32
    private static let FEATURED_CATALOG_WIDS = [
        "Q14530",
        "Q857461",
        "Q2661779",
        "Q55712879",
        "Q3247327"
//        "Q91442269",
//        "Q4999741"
    ]

    var onObjectSelected: ((SkyObject) -> Void)?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }

    private let plugin: AstronomyPlugin
    private let dataProvider: AstroDataProvider
    private let nightMode: Bool
    
    private var searchState = StarMapSearchState()
    private var preparedEntries: [StarMapSearchEntry] = []
    private var visibleEntries: [StarMapSearchEntry] = []
    private var preparedCatalogEntries: [StarMapCatalogEntry] = []
    private var visibleCatalogEntries: [StarMapCatalogEntry] = []
    private var widToDisplayName: [String: String] = [:]
    private var filterAndSortRequestId = 0
    private var currentMode: ScreenMode = .EXPLORE
    private var currentFullSearchMode: FullSearchMode = .INPUT
    private var wasInfoHeaderVisible = false
    private var suppressQueryDispatch = false
    private var pendingSearchQueryRestore = false
    private var catalogsBackState: CatalogsBackState?
    private var dismissOnBrowseBack = false
    private var pendingInitialCatalogWid: String?
    private var redFilterEnabled = false
    private var pendingBrowseScrollOffsetRestore: CGPoint?
    private var isFilteringResults = false

    private let mainStack = UIStackView()
    private let fullSearchContainer = UIView()
    private let fullSearchStack = UIStackView()
    private let searchRecycler = UITableView(frame: .zero, style: .insetGrouped)
    private let sortFilterBar = UIStackView()
    private let sortButton = UIButton(type: .system)
    private let filterButton = UIButton(type: .system)
    private let sortProgress = UIActivityIndicatorView(style: .medium)
    private let resultsContainer = UIView()
    private let emptyStateContainer = UIStackView()
    private let emptyStateIcon = UIImageView()
    private let emptyStateTitle = UILabel()
    private let emptyStateDescription = UILabel()
    private let emptyStateResetButton = UIButton(type: .system)
    private let recentChipsScroll = UIScrollView()
    private let recentChipsContainer = UIStackView()
    
    private weak var parentStarMapController: StarMapViewController?

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.delegate = self
        controller.searchResultsUpdater = self
        controller.searchBar.delegate = self
        controller.searchBar.placeholder = localizedString("astro_search_input_hint")
        controller.searchBar.returnKeyType = .search
        return controller
    }()
    private lazy var searchAdapter = StarMapSearchResultsAdapter(
        nightMode: nightMode,
        snapshot: .empty,
        widToDisplayName: { [weak self] in self?.widToDisplayName ?? [:] },
        eventTextProvider: { [weak self] entry in self?.searchHelper.resolveEventText(entry) ?? NSAttributedString(string: "") },
        onScroll: { [weak self] scrollView in self?.onResultsScrolled(scrollView) },
        onEntrySelected: { [weak self] entry in self?.onSearchEntrySelected(entry) }
    )
    private lazy var catalogsAdapter = StarMapCatalogsAdapter(
        nightMode: nightMode,
        snapshot: .empty,
        onScroll: { [weak self] scrollView in self?.onResultsScrolled(scrollView) },
        onCatalogSelected: { [weak self] entry in self?.onCatalogSelected(entry) }
    )
    private lazy var exploreAdapter = StarMapSearchExploreAdapter(
        snapshot: .empty,
        onScroll: { [weak self] scrollView in self?.onResultsScrolled(scrollView) },
        onWatchNow: { [weak self] in self?.openFullSearch(.WATCH_NOW, catalogWid: nil) },
        onCategory: { [weak self] preset in self?.openFullSearch(preset, catalogWid: nil) },
        onMyData: { [weak self] preset in self?.openMyData(preset) },
        onCatalog: { [weak self] entry in
            self?.clearCatalogsBackState()
            self?.openFullSearch(.CATALOG_WID, catalogWid: entry.catalog.wid)
        },
        onViewAllCatalogs: { [weak self] in self?.openFullSearch(.CATALOGS, catalogWid: nil) }
    )
    private lazy var searchPreparedDataFactory = StarMapSearchPreparedDataFactory(dataProvider: dataProvider, nightMode: nightMode)
    private lazy var searchHelper = StarMapSearchHelper()

    private var navSearchBar: UISearchBar { searchController.searchBar }

    private init(parent: StarMapViewController, plugin: AstronomyPlugin) {
        parentStarMapController = parent
        self.plugin = plugin
        dataProvider = plugin.dataProvider
        nightMode = OADayNightHelper.instance().isNightMode()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func newInstance(initialCatalogWid: String? = nil,
                            parent: StarMapViewController,
                            plugin: AstronomyPlugin) -> StarMapSearchViewController {
        let controller = StarMapSearchViewController(parent: parent, plugin: plugin)
        controller.pendingInitialCatalogWid = initialCatalogWid?.isEmpty == false ? initialCatalogWid : nil
        controller.dismissOnBrowseBack = controller.pendingInitialCatalogWid != nil
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBg
        bindViews()
        setupNavigationBar()
        definesPresentationContext = true
        refreshPreparedEntries()
        setupSearchRecycler()
        setupListeners()
        renderRecentChips()
        applyRedFilter(enabled: redFilterEnabled)
        if let initialCatalogWid = pendingInitialCatalogWid {
            pendingInitialCatalogWid = nil
            clearCatalogsBackState()
            openFullSearch(.CATALOG_WID, catalogWid: initialCatalogWid)
            return
        }
        applyMode(currentMode, requestKeyboard: currentMode == .FULL_SEARCH && currentFullSearchMode == .INPUT)
        applyFiltersAndSort(scrollToTop: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if currentMode == .EXPLORE {
            updateExploreTableHeader()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncDialogVisibilityWithFragmentState()
        if currentMode == .EXPLORE {
            updateTableAdapter()
            updateExploreTableHeader()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            filterAndSortRequestId += 1
        }
    }

    func applyRedFilter(enabled: Bool) {
        redFilterEnabled = enabled
        guard isViewLoaded else {
            return
        }
        AstroRedFilter.apply(enabled, to: navigationController?.view ?? view)
    }

    // MARK: - Layout

    private func bindViews() {
        mainStack.axis = .vertical
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)

        fullSearchContainer.translatesAutoresizingMaskIntoConstraints = false
        fullSearchStack.axis = .vertical
        fullSearchStack.translatesAutoresizingMaskIntoConstraints = false
        fullSearchContainer.addSubview(fullSearchStack)
        resultsContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            fullSearchStack.leadingAnchor.constraint(equalTo: fullSearchContainer.leadingAnchor),
            fullSearchStack.trailingAnchor.constraint(equalTo: fullSearchContainer.trailingAnchor),
            fullSearchStack.topAnchor.constraint(equalTo: fullSearchContainer.topAnchor),
            fullSearchStack.bottomAnchor.constraint(equalTo: fullSearchContainer.bottomAnchor)
        ])

        mainStack.addArrangedSubview(fullSearchContainer)
        setupFullSearchContent()
        setupExploreHeader()
        setupEmptyState()
    }

    private func setupFullSearchContent() {

        searchRecycler.keyboardDismissMode = .onDrag
        searchRecycler.rowHeight = UITableView.automaticDimension
        searchRecycler.estimatedRowHeight = Layout.resultRowMinHeight
        searchRecycler.separatorStyle = .none

        sortFilterBar.axis = .horizontal
        sortFilterBar.alignment = .center
        sortFilterBar.distribution = .fill
        sortFilterBar.spacing = 0
        sortFilterBar.layoutMargins = UIEdgeInsets(top: 0, left: Layout.contentPadding, bottom: 0, right: Layout.contentPadding)
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

        searchRecycler.translatesAutoresizingMaskIntoConstraints = false
        emptyStateContainer.translatesAutoresizingMaskIntoConstraints = false
        resultsContainer.addSubview(searchRecycler)
        resultsContainer.addSubview(emptyStateContainer)
        NSLayoutConstraint.activate([
            searchRecycler.leadingAnchor.constraint(equalTo: resultsContainer.leadingAnchor),
            searchRecycler.trailingAnchor.constraint(equalTo: resultsContainer.trailingAnchor),
            searchRecycler.topAnchor.constraint(equalTo: resultsContainer.topAnchor),
            searchRecycler.bottomAnchor.constraint(equalTo: resultsContainer.bottomAnchor),

            emptyStateContainer.leadingAnchor.constraint(equalTo: resultsContainer.leadingAnchor, constant: Layout.contentPadding),
            emptyStateContainer.trailingAnchor.constraint(equalTo: resultsContainer.trailingAnchor, constant: -Layout.contentPadding),
            emptyStateContainer.centerYAnchor.constraint(equalTo: resultsContainer.centerYAnchor)
        ])

        fullSearchStack.addArrangedSubview(sortFilterBar)
        fullSearchStack.addArrangedSubview(resultsContainer)
    }

    private func setupExploreHeader() {
        recentChipsContainer.axis = .horizontal
        recentChipsContainer.spacing = Layout.smallPadding
        recentChipsContainer.translatesAutoresizingMaskIntoConstraints = false
        recentChipsContainer.layoutMargins = UIEdgeInsets(top: Layout.contentPadding, left: Layout.contentPadding, bottom: Layout.contentPadding, right: Layout.contentPadding)
        recentChipsContainer.isLayoutMarginsRelativeArrangement = true
        recentChipsScroll.addSubview(recentChipsContainer)
        NSLayoutConstraint.activate([
            recentChipsContainer.leadingAnchor.constraint(equalTo: recentChipsScroll.contentLayoutGuide.leadingAnchor),
            recentChipsContainer.trailingAnchor.constraint(equalTo: recentChipsScroll.contentLayoutGuide.trailingAnchor),
            recentChipsContainer.topAnchor.constraint(equalTo: recentChipsScroll.contentLayoutGuide.topAnchor),
            recentChipsContainer.bottomAnchor.constraint(equalTo: recentChipsScroll.contentLayoutGuide.bottomAnchor),
            recentChipsContainer.heightAnchor.constraint(equalTo: recentChipsScroll.frameLayoutGuide.heightAnchor)
        ])
    }

    private func setupEmptyState() {
        emptyStateContainer.axis = .vertical
        emptyStateContainer.alignment = .center
        emptyStateContainer.spacing = Layout.smallPadding
        emptyStateContainer.backgroundColor = .clear
        emptyStateContainer.layoutMargins = UIEdgeInsets(top: 0, left: Layout.contentPadding, bottom: 0, right: Layout.contentPadding)
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
        applyEmptyStateButtonStyle()

        emptyStateContainer.addArrangedSubview(emptyStateIcon)
        emptyStateContainer.addArrangedSubview(emptyStateTitle)
        emptyStateContainer.addArrangedSubview(emptyStateDescription)
        emptyStateContainer.addArrangedSubview(emptyStateResetButton)
        emptyStateResetButton.widthAnchor.constraint(equalTo: emptyStateContainer.widthAnchor, constant: -2 * Layout.contentPadding).isActive = true
        emptyStateContainer.isHidden = true
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

    private func appBarBackgroundColor() -> UIColor {
        .viewBg
    }

    // MARK: - Navigation

    private func setupNavigationBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        if #available(iOS 16.0, *) {
            navigationItem.preferredSearchBarPlacement = .stacked
        }

        navigationController?.navigationBar.prefersLargeTitles = true

        styleSearchBar()
        updateNavigationBar()
    }

    private func styleSearchBar() {
        let bar = searchController.searchBar
        bar.placeholder = localizedString("astro_search_input_hint")
    }

    private func updateNavigationBar() {
        switch currentMode {
        case .EXPLORE:
            navigationItem.leftBarButtonItem = makeBarButton(
                image: UIImage(systemName: "chevron.left"),
                accessibilityLabel: localizedString("shared_string_close"),
                action: #selector(close)
            )
            navigationItem.title = localizedString("shared_string_explore")
            navigationItem.largeTitleDisplayMode = .never
            navSearchBar.text = nil

        case .FULL_SEARCH:
            switch currentFullSearchMode {
            case .BROWSE:
                navigationItem.leftBarButtonItem = makeBarButton(
                    image: UIImage(systemName: "chevron.left"),
                    accessibilityLabel: localizedString("shared_string_back"),
                    action: #selector(backPressed)
                )
                navigationItem.title = getBrowseTitle()
                navigationItem.largeTitleDisplayMode = .always
                syncSearchQuery()

            case .INPUT:
                syncSearchQuery()
            }
        }
    }

    private func makeBarButton(image: UIImage?, accessibilityLabel: String, action: Selector) -> UIBarButtonItem {
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: action)
        button.accessibilityLabel = accessibilityLabel
        return button
    }

    private func syncSearchQuery() {
        suppressQueryDispatch = true
        navSearchBar.text = searchState.query
        suppressQueryDispatch = false
    }

    // MARK: - Table

    private func setupSearchRecycler() {
        updateTableAdapter()
    }

    private func updateTableAdapter() {
        if currentMode == .EXPLORE {
            searchRecycler.separatorStyle = .singleLine
            exploreAdapter.submitSnapshot(buildExploreSnapshot())
            searchRecycler.dataSource = exploreAdapter
            searchRecycler.delegate = exploreAdapter
        } else {
            searchRecycler.separatorStyle = .none
            if shouldShowCatalogEntries() {
                catalogsAdapter.submitSnapshot(StarMapCatalogsAdapter.Snapshot(entries: visibleCatalogEntries))
                searchRecycler.dataSource = catalogsAdapter
                searchRecycler.delegate = catalogsAdapter
            } else {
                let categoryPreset = searchState.categoryPreset()
                searchAdapter.submitSnapshot(StarMapSearchResultsAdapter.Snapshot(entries: visibleEntries,
                                                                                  categoryPreset: categoryPreset,
                                                                                  infoHeaderCategory: shouldShowInfoHeader() ? categoryPreset : nil,
                                                                                  useExploreRowLayout: false))
                searchRecycler.dataSource = searchAdapter
                searchRecycler.delegate = searchAdapter
            }
        }
        searchRecycler.reloadData()
        if currentMode == .EXPLORE {
            updateExploreTableHeader()
        }
    }

    private func updateResultsAdapter() {
        updateTableAdapter()
    }

    private func updateExploreTableHeader() {
        guard currentMode == .EXPLORE, !searchState.recentChips.isEmpty else {
            searchRecycler.tableHeaderView = nil
            return
        }
        let header = recentChipsScroll
        let width = searchRecycler.bounds.width > 0 ? searchRecycler.bounds.width : view.bounds.width
        let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let height = header.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        header.frame = CGRect(x: 0, y: 0, width: width, height: height)
        searchRecycler.tableHeaderView = header
    }

    // MARK: - Mode

    private func openFullSearch(_ quickPresetType: StarMapSearchQuickPresetType,
                                catalogWid: String?,
                                fromSearchBarActivation: Bool = false) {
        searchState.prepareForExploreEntry(quickPresetType, catalogWid: catalogWid)
        currentFullSearchMode = searchState.shouldOpenInBrowseMode() ? .BROWSE : .INPUT

        let shouldRequestKeyboard = currentFullSearchMode == .INPUT && !fromSearchBarActivation
        applyMode(.FULL_SEARCH, requestKeyboard: shouldRequestKeyboard)

        prepareForFreshResultLoad()
        applyFiltersAndSort(scrollToTop: !fromSearchBarActivation)
    }

    private func applyMode(_ mode: ScreenMode, requestKeyboard: Bool) {
        currentMode = mode
        switch mode {
        case .EXPLORE:
            showExploreMode()
        case .FULL_SEARCH:
            if currentFullSearchMode == .BROWSE {
                showBrowseMode()
            } else {
                showInputMode(requestKeyboard: requestKeyboard)
            }
        }
    }

    private func showExploreMode() {
        resetResultsScrollState(scrollToTop: true)
        sortFilterBar.isHidden = true
        emptyStateContainer.isHidden = true
        searchRecycler.isHidden = false
        updateTableAdapter()
        navSearchBar.resignFirstResponder()
        updateNavigationBar()
    }

    private func showBrowseMode(resetCollapseState: Bool = true) {
        if resetCollapseState {
            resetResultsScrollState(scrollToTop: true)
        }
        sortFilterBar.isHidden = false
        searchRecycler.tableHeaderView = nil
        currentFullSearchMode = .BROWSE
        syncSearchQuery()
        navSearchBar.resignFirstResponder()
        updateTableAdapter()
        updateSortControls()
        updateFilterControls()
        updateEmptyStateContent()
        updateEmptyStateVisibility()
        updateNavigationBar()
    }

    private func switchToInputMode() {
        showInputMode(requestKeyboard: true)
    }

    private func showInputMode(requestKeyboard: Bool) {
        resetResultsScrollState(scrollToTop: true)
        currentFullSearchMode = .INPUT
        sortFilterBar.isHidden = false
        searchRecycler.tableHeaderView = nil
        syncSearchQuery()
        updateTableAdapter()
        updateSortControls()
        updateFilterControls()
        updateEmptyStateContent()
        updateEmptyStateVisibility()
        if requestKeyboard {
            searchController.isActive = true
        }
        updateNavigationBar()
    }

    private func handleBackPressedInternal() -> Bool {
        if currentMode == .FULL_SEARCH {
            if currentFullSearchMode == .BROWSE {
                if dismissOnBrowseBack {
                    dismiss(animated: true)
                    return true
                }
                if restoreCatalogsListIfNeeded() {
                    return true
                }
                handleBrowseBackNavigation()
                return true
            }
            if searchState.hasBrowseContext() {
                showBrowseMode()
            } else {
                applyMode(.EXPLORE, requestKeyboard: false)
            }
            return true
        }
        return false
    }

    private func handleBrowseBackNavigation() {
        searchState.reset()
        clearCatalogsBackState()
        applyMode(.EXPLORE, requestKeyboard: false)
        applyFiltersAndSort(scrollToTop: false)
    }

    private func restoreCatalogsListIfNeeded() -> Bool {
        guard let backState = catalogsBackState else {
            return false
        }
        clearCatalogsBackState()
        searchState.prepareForExploreEntry(.CATALOGS, catalogWid: nil)
        searchState.query = backState.query
        searchState.sortMode = backState.sortMode
        currentFullSearchMode = .BROWSE
        pendingBrowseScrollOffsetRestore = backState.scrollOffset
        showBrowseMode(resetCollapseState: false)
        restoreSearchRecyclerScrollPosition(backState.scrollOffset)
        applyFiltersAndSort(scrollToTop: false)
        return true
    }

    private func clearCatalogsBackState() {
        catalogsBackState = nil
    }

    // MARK: - Scroll

    private func currentSearchScrollOffset() -> CGFloat {
        max(0, searchRecycler.contentOffset.y + searchRecycler.adjustedContentInset.top)
    }

    private func onResultsScrolled(_ scrollView: UIScrollView) {
    }

    private func resetResultsScrollState(scrollToTop: Bool) {
        pendingBrowseScrollOffsetRestore = nil
        if scrollToTop {
            resetSearchRecyclerScrollPosition()
        }
    }

    private func resetSearchRecyclerScrollPosition() {
        let topOffset = CGPoint(x: 0, y: -searchRecycler.adjustedContentInset.top)
        restoreSearchRecyclerScrollPosition(topOffset)
    }

    private func restoreSearchRecyclerScrollPosition(_ contentOffset: CGPoint) {
        let topOffset = CGPoint(x: contentOffset.x, y: max(contentOffset.y, -searchRecycler.adjustedContentInset.top))
        if searchRecycler.contentOffset != topOffset {
            searchRecycler.setContentOffset(topOffset, animated: false)
        }
//        updateBrowseTitleCollapse(scrollOffset: currentSearchScrollOffset(), animated: false)
    }

    // MARK: - Data

    private func setupListeners() {
        syncRecentChipsWithSession()
    }

    private func syncDialogVisibilityWithFragmentState() {
        applyRedFilter(enabled: parentStarMapController?.isSearchRedFilterEnabled() ?? redFilterEnabled)
    }

    private func restoreUiState(_ savedInstanceState: [String: Any]?) {
        searchState.restore(savedInstanceState)
    }

    private func refreshPreparedEntries() {
        let preparedData = searchPreparedDataFactory.create(parent: parentStarMapController)
        preparedEntries = preparedData.entries
        preparedCatalogEntries = preparedData.catalogEntries
        widToDisplayName = preparedData.widToDisplayName
        searchHelper.updateComputationContext(preparedData.computationContext)
    }

    private func prepareForFreshResultLoad() {
        isFilteringResults = true
        if shouldShowCatalogEntries() {
            visibleCatalogEntries.removeAll()
        } else {
            visibleEntries.removeAll()
        }
        updateResultsAdapter()
    }

    private func getBrowsableCatalogEntries() -> [StarMapCatalogEntry] {
        preparedCatalogEntries.filter { $0.objectCount > 0 }
    }

    private func getFeaturedCatalogEntries() -> [StarMapCatalogEntry] {
        var entriesByWid: [String: StarMapCatalogEntry] = [:]
        for entry in preparedCatalogEntries {
            entriesByWid[entry.catalog.wid] = entry
        }
        let prioritizedEntries = Self.FEATURED_CATALOG_WIDS.compactMap { entriesByWid[$0] }
        if prioritizedEntries.count >= Self.FEATURED_CATALOGS_COUNT {
            return Array(prioritizedEntries.prefix(Self.FEATURED_CATALOGS_COUNT))
        }
        let selectedWids = Set(prioritizedEntries.map { $0.catalog.wid })
        let fallbackEntries = preparedCatalogEntries.filter { !selectedWids.contains($0.catalog.wid) }
        return Array((prioritizedEntries + fallbackEntries).prefix(Self.FEATURED_CATALOGS_COUNT))
    }

    private func buildExploreSnapshot() -> StarMapSearchExploreAdapter.Snapshot {
        let categories: [StarMapExploreRowConfig] = [
            StarMapExploreRowConfig(quickPresetType: .CATEGORY_SOLAR_SYSTEM, iconRes: "ic_custom_planet_outlined", titleRes: "astro_solar_system", subtitleRes: nil),
            StarMapExploreRowConfig(quickPresetType: .CATEGORY_CONSTELLATIONS, iconRes: "ic_custom_constellations", titleRes: "astro_constellations", subtitleRes: nil),
            StarMapExploreRowConfig(quickPresetType: .CATEGORY_STARS, iconRes: "ic_custom_star_shine", titleRes: "astro_stars", subtitleRes: nil),
            StarMapExploreRowConfig(quickPresetType: .CATEGORY_NEBULAS, iconRes: "ic_custom_nebulas", titleRes: "astro_nebulas", subtitleRes: nil),
            StarMapExploreRowConfig(quickPresetType: .CATEGORY_STAR_CLUSTERS, iconRes: "ic_custom_star_clusters", titleRes: "astro_star_clusters", subtitleRes: nil),
            StarMapExploreRowConfig(quickPresetType: .CATEGORY_DEEP_SKY, iconRes: "ic_custom_galaxy", titleRes: "astro_deep_sky", subtitleRes: "astro_explore_deep_sky_subtitle")
        ]
        let config = parentStarMapController?.getSearchStarMapConfig() ?? AstronomyPluginSettings.load().starMap
        let myDataItems: [(StarMapExploreRowConfig, Int)] = [
            (StarMapExploreRowConfig(quickPresetType: .MY_DATA_FAVORITES, iconRes: "ic_custom_bookmark", titleRes: "favorites_item", subtitleRes: nil), config.favorites.count),
            (StarMapExploreRowConfig(quickPresetType: .MY_DATA_DAILY_PATH, iconRes: "ic_custom_target_path_on", titleRes: "astro_daily_path", subtitleRes: nil), config.celestialPaths.count),
            (StarMapExploreRowConfig(quickPresetType: .MY_DATA_DIRECTIONS, iconRes: "ic_custom_target_direction_on", titleRes: "astro_directions", subtitleRes: nil), config.directions.count)
        ]
        let featuredCatalogs = getFeaturedCatalogEntries()
        var catalogRows: [StarMapExploreRow] = featuredCatalogs.map { .catalog($0) }
        catalogRows.append(.viewAllCatalogs(count: getBrowsableCatalogEntries().count))

        let sections: [(StarMapExploreSection, [StarMapExploreRow])] = [
            (.watchNow, [.watchNow]),
            (.categories, categories.map { .category($0) }),
            (.myData, myDataItems.map { .myData(config: $0.0, count: $0.1) }),
            (.catalogs, catalogRows)
        ]
        return StarMapSearchExploreAdapter.Snapshot(sections: sections)
    }

    private func openMyData(_ preset: StarMapSearchQuickPresetType) {
        guard let parent = parentStarMapController else { return }
        let controller = StarMapMyDataViewController.newInstance(
            initialPreset: preset,
            parent: parent,
            plugin: plugin
        )
        controller.onObjectSelected = onObjectSelected
        controller.applyRedFilter(enabled: redFilterEnabled)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func shouldShowInfoHeader() -> Bool {
        currentMode == .FULL_SEARCH &&
            currentFullSearchMode == .BROWSE &&
            !shouldShowCatalogEntries() &&
            searchState.categoryPreset() != nil
    }

    private func getBrowseTitle() -> String {
        switch searchState.quickPresetType {
        case .WATCH_NOW:
            return localizedString("astro_explore_watch_now")
        case .CATALOGS:
            return localizedString("astro_catalogs")
        case .CATEGORY_SOLAR_SYSTEM:
            return localizedString("astro_solar_system")
        case .CATEGORY_CONSTELLATIONS:
            return localizedString("astro_constellations")
        case .CATEGORY_STARS:
            return localizedString("astro_stars")
        case .CATEGORY_NEBULAS:
            return localizedString("astro_nebulas")
        case .CATEGORY_STAR_CLUSTERS:
            return localizedString("astro_star_clusters")
        case .CATEGORY_DEEP_SKY:
            return localizedString("astro_deep_sky")
        case .MY_DATA_FAVORITES, .MY_DATA_DAILY_PATH, .MY_DATA_DIRECTIONS:
            return localizedString("astro_explore_my_data")
        case .CATALOG_WID:
            return dataProvider.getCatalogs().first { $0.wid == searchState.quickPresetCatalogWid }?.name ?? localizedString("shared_string_search")
        case .NONE:
            return localizedString("shared_string_search")
        }
    }

    private func shouldShowCatalogEntries() -> Bool {
        searchState.quickPresetType == .CATALOGS
    }

    private func getCurrentResultsCount() -> Int {
        shouldShowCatalogEntries() ? visibleCatalogEntries.count : visibleEntries.count
    }

    private func updateInfoCard() {
        let isInfoHeaderVisible = shouldShowInfoHeader()
        wasInfoHeaderVisible = isInfoHeaderVisible
    }

    // MARK: - Filters & Sort

    private func applyFiltersAndSort(scrollToTop: Bool) {
        normalizeTypeFilterForCurrentPreset()
        let requestId = filterAndSortRequestId + 1
        filterAndSortRequestId = requestId
        isFilteringResults = true
        let stateSnapshot = searchState.snapshot()
        let isCatalogsMode = shouldShowCatalogEntries()
        let preparedEntriesSnapshot = preparedEntries
        let preparedCatalogEntriesSnapshot = preparedCatalogEntries
        updateResultsAdapter()
        updateSortControls()
        updateFilterControls()
        updateEmptyStateContent()
        updateSortProgressVisibility(true)
        emptyStateContainer.isHidden = true
        searchRecycler.isHidden = false

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else {
                return
            }
            if isCatalogsMode {
                let filteredCatalogs = self.filterAndSortCatalogs(stateSnapshot: stateSnapshot,
                                                                  preparedCatalogEntries: preparedCatalogEntriesSnapshot)
                DispatchQueue.main.async { [weak self] in
                    guard let self,
                          viewIfLoaded?.window != nil,
                          requestId == filterAndSortRequestId else {
                        return
                    }
                    visibleCatalogEntries = filteredCatalogs
                    updateResultsAdapter()
                    finishApplyFilters(scrollToTop: scrollToTop, requestId: requestId)
                }
            } else {
                let filteredEntries = stateSnapshot.filterAndSort(
                    preparedEntries: preparedEntriesSnapshot.map { $0.copy() },
                    visibleTonightProvider: self.searchHelper.getVisibleTonight,
                    riseSortValueProvider: self.searchHelper.getRiseSortValue,
                    setSortValueProvider: self.searchHelper.getSetSortValue,
                    insertionOrderProvider: { _ in nil }
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
    }

    private func finishApplyFilters(scrollToTop: Bool, requestId: Int) {
        if let restoredScrollOffset = pendingBrowseScrollOffsetRestore {
            pendingBrowseScrollOffsetRestore = nil
            restoreSearchRecyclerScrollPosition(restoredScrollOffset)
        } else if scrollToTop {
            resetSearchRecyclerScrollPosition()
        }
        isFilteringResults = false
        updateEmptyStateVisibility()
//        updateBrowseTitleCollapse(scrollOffset: currentSearchScrollOffset(), animated: false)
        if requestId == filterAndSortRequestId {
            updateSortProgressVisibility(false)
        }
    }

    private func filterAndSortCatalogs(stateSnapshot: StarMapSearchStateSnapshot,
                                       preparedCatalogEntries: [StarMapCatalogEntry]) -> [StarMapCatalogEntry] {
        let queryLower = stateSnapshot.query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(with: Locale.current)
        let filteredEntries = preparedCatalogEntries.filter { entry in
            if entry.objectCount <= 0 {
                return false
            }
            if queryLower.isEmpty {
                return true
            }
            return entry.displayName.lowercased(with: Locale.current).contains(queryLower) ||
                (entry.description ?? "").lowercased(with: Locale.current).contains(queryLower)
        }
        switch stateSnapshot.sortMode {
        case .NAME_DESC:
            return filteredEntries.sorted { $0.displayName.lowercased(with: Locale.current) > $1.displayName.lowercased(with: Locale.current) }
        default:
            return filteredEntries.sorted { $0.displayName.lowercased(with: Locale.current) < $1.displayName.lowercased(with: Locale.current) }
        }
    }

    private func normalizeTypeFilterForCurrentPreset() {
        if shouldHideShowAllTypeFilter() && searchState.typeFilter == .SHOW_ALL {
            searchState.typeFilter = .VISIBLE_TONIGHT
        }
    }

    private func shouldHideShowAllTypeFilter() -> Bool {
        searchState.quickPresetType == .WATCH_NOW
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
        filterButton.isHidden = shouldShowCatalogEntries()
        var configuration = filterButton.configuration ?? UIButton.Configuration.plain()
        configuration.title = String(format: localizedString("filter_tracks_count"), searchState.calculateFilterCount())
        configuration.image = .icCustomFilter
        configuration.imagePlacement = .trailing
        configuration.baseForegroundColor = .systemBlue
        configuration.imagePadding = Layout.smallPadding
        filterButton.configuration = configuration
        filterButton.menu = createFilterMenu()
    }

    private func createSortMenu() -> UIMenu {
        if shouldShowCatalogEntries() {
            return UIMenu(title: localizedString("sort_by"), children: [
                sortAction(title: localizedString("sort_name_ascending"), mode: .NAME_ASC),
                sortAction(title: localizedString("sort_name_descending"), mode: .NAME_DESC)
            ])
        }
        let actions = [
            sortAction(title: localizedString("sort_name_ascending"), mode: .NAME_ASC),
            sortAction(title: localizedString("sort_name_descending"), mode: .NAME_DESC),
            sortAction(title: localizedString("astro_sort_brightest_first"), mode: .BRIGHTEST_FIRST),
            sortAction(title: localizedString("astro_sort_faintest_first"), mode: .FAINTEST_FIRST),
            sortAction(title: localizedString("astro_sort_rises_soonest"), mode: .RISES_SOONEST),
            sortAction(title: localizedString("astro_sort_sets_soonest"), mode: .SETS_SOONEST)
        ]

        return UIMenu(title: localizedString("sort_by"), children: actions)
    }

    private func sortAction(title: String, mode: StarMapSearchSortMode) -> UIAction {
        UIAction(title: title, state: searchState.sortMode == mode ? .on : .off) { [weak self] _ in
            self?.searchState.sortMode = mode
            self?.updateSortControls()
            self?.applyFiltersAndSort(scrollToTop: true)
        }
    }

    private func createFilterMenu() -> UIMenu {
        guard !shouldShowCatalogEntries() else {
            return UIMenu(children: [])
        }
        normalizeTypeFilterForCurrentPreset()
        var children: [UIMenuElement] = []
        if !shouldHideShowAllTypeFilter() {
            children.append(typeFilterAction(title: localizedString("astro_filter_show_all"), filter: .SHOW_ALL))
        }
        children.append(typeFilterAction(title: localizedString("astro_filter_visible_now"), filter: .VISIBLE_NOW))
        children.append(typeFilterAction(title: localizedString("astro_filter_visible_tonight"), filter: .VISIBLE_TONIGHT))
        children.append(UIAction(title: localizedString("astro_filter_naked_eye"), state: searchState.nakedEyeOnly ? .on : .off) { [weak self] _ in
            guard let self else {
                return
            }
            searchState.nakedEyeOnly.toggle()
            applyFiltersAndSort(scrollToTop: true)
        })
        if !searchState.isCategoryPreset() {
            let categoryActions = [
                categoryFilterAction(title: localizedString("shared_string_all"), category: .ALL),
                categoryFilterAction(title: localizedString("astro_solar_system"), category: .SOLAR_SYSTEM),
                categoryFilterAction(title: localizedString("astro_constellations"), category: .CONSTELLATIONS),
                categoryFilterAction(title: localizedString("astro_stars"), category: .STARS),
                categoryFilterAction(title: localizedString("astro_nebulas"), category: .NEBULAS),
                categoryFilterAction(title: localizedString("astro_star_clusters"), category: .STAR_CLUSTERS),
                categoryFilterAction(title: localizedString("astro_deep_sky"), category: .DEEP_SKY)
            ]
            children.append(UIMenu(title: localizedString("favourites_edit_dialog_category"), options: .displayInline, children: categoryActions))
        }
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

    // MARK: - Empty State

    private func updateEmptyStateContent() {
        emptyStateIcon.image = AstroIcon.template("ic_action_ufo")
        emptyStateTitle.text = localizedString("nothing_found")
        emptyStateDescription.text = localizedString("astro_search_empty_description")
        emptyStateResetButton.setTitle(localizedString(shouldShowWatchNowClearFiltersAction() ? "shared_string_clear_filters" : "shared_string_reset"), for: .normal)
    }

    private func applyEmptyStateButtonStyle() {
        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .small
        configuration.baseBackgroundColor = StarMapSearchLightPalette.secondaryButtonBackground
        configuration.baseForegroundColor = .systemBlue
        emptyStateResetButton.configuration = configuration
    }

    private func updateEmptyStateVisibility() {
        if isFilteringResults {
            emptyStateContainer.isHidden = true
            searchRecycler.isHidden = false
            return
        }
        let shouldShowEmptyState = currentMode == .FULL_SEARCH && getCurrentResultsCount() == 0
        emptyStateContainer.isHidden = !shouldShowEmptyState
        searchRecycler.isHidden = shouldShowEmptyState
    }

    private func handleEmptyStateAction() {
        if shouldShowWatchNowClearFiltersAction() {
            resetWatchNowFilters()
        } else {
            resetAllSearchParams()
        }
    }

    private func shouldShowWatchNowClearFiltersAction() -> Bool {
        searchState.quickPresetType == .WATCH_NOW && searchState.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func resetWatchNowFilters() {
        searchState.typeFilter = .VISIBLE_TONIGHT
        searchState.nakedEyeOnly = false
        searchState.selectedCategories.removeAll()
        searchState.selectedCategories.append(.ALL)
        applyFiltersAndSort(scrollToTop: true)
    }

    private func resetAllSearchParams() {
        if shouldShowCatalogEntries() {
            searchState.query = ""
            searchState.sortMode = .NAME_ASC
            currentFullSearchMode = currentMode == .FULL_SEARCH && currentFullSearchMode == .BROWSE ? .BROWSE : .INPUT
            syncSearchQuery()
            if currentMode == .FULL_SEARCH && currentFullSearchMode == .INPUT {
                showInputMode(requestKeyboard: false)
            } else if currentMode == .FULL_SEARCH {
                showBrowseMode()
            }
        } else {
            searchState.reset()
            currentFullSearchMode = .INPUT
            syncSearchQuery()
            if currentMode == .FULL_SEARCH {
                showInputMode(requestKeyboard: false)
            }
        }
        applyFiltersAndSort(scrollToTop: true)
    }

    // MARK: - Recent Chips

    private func addRecentChip(_ entry: StarMapSearchEntry) {
        searchState.addRecentChip(label: entry.displayName, objectId: entry.objectRef.id)
        plugin.recentSearchChips.removeAll()
        plugin.recentSearchChips.append(contentsOf: searchState.recentChips)
        renderRecentChips()
    }

    private func syncRecentChipsWithSession() {
        if plugin.recentSearchChips.isEmpty {
            plugin.recentSearchChips.append(contentsOf: searchState.recentChips)
        } else {
            searchState.replaceRecentChips(plugin.recentSearchChips)
        }
    }

    private func renderRecentChips() {
        recentChipsContainer.removeArrangedSubviews()
        recentChipsScroll.isHidden = searchState.recentChips.isEmpty
        if searchState.recentChips.isEmpty {
            return
        }
        for recentChip in searchState.recentChips {
            var configuration = UIButton.Configuration.filled()
            configuration.cornerStyle = .capsule
            configuration.title = recentChip.label
            configuration.baseBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
            configuration.baseForegroundColor = .systemBlue
            let chipButton = UIButton(configuration: configuration)
            chipButton.translatesAutoresizingMaskIntoConstraints = false
            chipButton.addAction(UIAction { [weak self] _ in
                guard let self else {
                    return
                }
                let selectedEntry = recentChip.objectId.flatMap { objectId in
                    self.preparedEntries.first { $0.objectRef.id == objectId }
                } ?? self.preparedEntries.first {
                    $0.displayName.caseInsensitiveCompare(recentChip.label) == .orderedSame ||
                        $0.objectRef.name.caseInsensitiveCompare(recentChip.label) == .orderedSame
                }
                if let selectedEntry {
                    self.onSearchEntrySelected(selectedEntry)
                } else {
                    self.searchState.selectQuickPreset(.NONE, catalogWid: nil)
                    self.currentFullSearchMode = .INPUT
                    self.searchState.query = recentChip.label
                    self.showInputMode(requestKeyboard: true)
                    self.applyFiltersAndSort(scrollToTop: true)
                }
            }, for: .touchUpInside)
            recentChipsContainer.addArrangedSubview(chipButton)
        }
        if currentMode == .EXPLORE {
            updateExploreTableHeader()
        }
    }

    // MARK: - Selection

    private func onSearchEntrySelected(_ entry: StarMapSearchEntry) {
        addRecentChip(entry)
        navigationController?.dismiss(animated: true) { [weak self] in
            self?.onObjectSelected?(entry.objectRef)
        }
    }

    private func onCatalogSelected(_ entry: StarMapCatalogEntry) {
        catalogsBackState = CatalogsBackState(query: searchState.query,
                                              sortMode: searchState.sortMode,
                                              scrollOffset: searchRecycler.contentOffset)
        openFullSearch(.CATALOG_WID, catalogWid: entry.catalog.wid)
    }

    private func createPopupDisplayData() {}

    private func createPopupHeaderItem() {}

    private func createRadioPopupItem() {}

    private func createCheckPopupItem() {}

    private func dismissSortPopup() {}

    private func dismissFilterPopup() {}

    private func dismissPopups() {}

//    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
//        if textField === exploreSearchBar {
//            openFullSearch(.NONE, catalogWid: nil)
//            return false
//        }
//        if currentFullSearchMode == .BROWSE {
//            switchToInputMode()
//        }
//        return true
//    }
//
//    @objc private func searchTextChanged() {
//        guard !suppressQueryDispatch else {
//            return
//        }
//        searchState.query = fullSearchBar.text ?? ""
//        applyFiltersAndSort(scrollToTop: true)
//    }
//
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//        return true
//    }

    // MARK: - Actions

    @objc private func backPressed() {
        if !handleBackPressedInternal() {
            dismiss(animated: true)
        }
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    @objc private func emptyStateAction() {
        handleEmptyStateAction()
    }
}

private extension UIStackView {
    func removeArrangedSubviews() {
        for view in arrangedSubviews {
            removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}

extension StarMapSearchViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        if currentMode == .EXPLORE {
            openFullSearch(.NONE, catalogWid: nil, fromSearchBarActivation: true)
        } else if currentFullSearchMode == .BROWSE {
            switchToInputMode()
        }
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        guard currentMode == .FULL_SEARCH, currentFullSearchMode == .INPUT else { return }
        if searchState.hasBrowseContext() {
            showBrowseMode()
        } else {
            applyMode(.EXPLORE, requestKeyboard: false)
        }
    }
}

extension StarMapSearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard !suppressQueryDispatch else { return }
        searchState.query = searchController.searchBar.text ?? ""
        if currentMode == .FULL_SEARCH {
            applyFiltersAndSort(scrollToTop: true)
        }
    }
}

extension StarMapSearchViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        if currentFullSearchMode == .BROWSE {
            switchToInputMode()
        }
        return true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if currentMode != .FULL_SEARCH {
            _ = handleBackPressedInternal()
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
