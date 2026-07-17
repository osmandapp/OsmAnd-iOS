//
//  StarMapSearchViewController.swift
//  OsmAnd Maps
//
//  Created by Codex on 06.06.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

enum StarMapSearchProgressHUD {
    private static let tag = 0xA57001
    
    static func show(on view: UIView) {
        if Thread.isMainThread {
            MBProgressHUD.hide(for: view, animated: false)
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            hud?.removeFromSuperViewOnHide = true
        } else {
            DispatchQueue.main.async { show(on: view) }
        }
    }
    static func hide(from view: UIView, animated: Bool) {
        if Thread.isMainThread {
            MBProgressHUD.hide(for: view, animated: animated)
        } else {
            DispatchQueue.main.async { MBProgressHUD.hide(for: view, animated: animated) }
        }
    }
}

final class StarMapSearchViewController: UIViewController {
    
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
        static let smallPadding: CGFloat = 8
        static let resultRowMinHeight: CGFloat = 68
        static let iconSize: CGFloat = 24
        static let recentChipsHeaderMinHeight: CGFloat = 56
        static var contentPadding: CGFloat = 16
    }
    
    private static let FEATURED_CATALOGS_COUNT = 5
    private static let RISE_SET_PRELOAD_COUNT = 32
    private static let FEATURED_CATALOG_WIDS = [
        "Q14530",
        "Q857461",
        "Q2661779",
        "Q55712879",
        "Q3247327"
    ]
    
    var onObjectSelected: ((SkyObject) -> Void)?
    var onDismiss: (() -> Void)?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }
    
    private let plugin: AstronomyPlugin
    private let dataProvider: AstroDataProvider
    private let nightMode: Bool
    
    private let mainStack = UIStackView()
    private let fullSearchContainer = UIView()
    private let fullSearchStack = UIStackView()
    private let searchRecycler = UITableView(frame: .zero, style: .insetGrouped)
    private let resultsContainer = UIView()
    private let emptyView = StarMapSearchEmptyView()
    private let recentChipsScroll = UIScrollView()
    private let recentChipsContainer = UIStackView()
    private let filtersHeaderStack = UIStackView()
    private let sortFilterChipsView = StarMapSearchSortFilterChipsView()
    private let sortFilterChipsProvider = StarMapSearchSortFilterChipsProvider()
    
    private var searchState = StarMapSearchState()
    private var preparedEntries: [StarMapSearchEntry] = []
    private var visibleEntries: [StarMapSearchEntry] = []
    private var preparedCatalogEntries: [StarMapCatalogEntry] = []
    private var visibleCatalogEntries: [StarMapCatalogEntry] = []
    private var widToDisplayName: [String: String] = [:]
    private var starConstellationNameByObjectId: [String: String] = [:]
    private var filterAndSortRequestId = 0
    private var currentMode: ScreenMode = .EXPLORE
    private var currentFullSearchMode: FullSearchMode = .INPUT
    private var suppressQueryDispatch = false
    private var catalogsBackState: CatalogsBackState?
    private var dismissOnBrowseBack = false
    private var launchesInFullSearchMode = false
    private var pendingInitialQuickPreset: StarMapSearchQuickPresetType?
    private var pendingInitialCatalogWid: String?
    private var redFilterEnabled = false
    private var pendingBrowseScrollOffsetRestore: CGPoint?
    private var isFilteringResults = false
    
    private var searchFiltersHeaderStackTopConstraint: NSLayoutConstraint?
    
    private weak var parentStarMapController: StarMapViewController?
    
    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.delegate = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = OAUtilities.isIPhone()
        controller.searchBar.placeholder = localizedString("shared_string_search")
        controller.searchBar.delegate = self
        return controller
    }()

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
        onScroll: { [weak self] scrollView in
            self?.updateSortFilterBarTopConstraint(scrollView)
        },
        onEntrySelected: { [weak self] entry in
            self?.onSearchEntrySelected(entry)
        },
        contextMenuProvider: { [weak self] entry in
            self?.contextMenuProvider(for: entry)
        }
    )
    private lazy var catalogsAdapter = StarMapCatalogsAdapter(
        tableView: searchRecycler,
        snapshot: .empty,
        onScroll: { [weak self] scrollView in
            self?.updateSortFilterBarTopConstraint(scrollView)
        },
        onCatalogSelected: { [weak self] entry in
            self?.onCatalogSelected(entry)
        }
    )
    private lazy var exploreAdapter = StarMapSearchExploreAdapter(
        tableView: searchRecycler,
        snapshot: .empty,
        onScroll: { [weak self] scrollView in
            self?.updateSortFilterBarTopConstraint(scrollView)
        },
        onWatchNow: { [weak self] in
            self?.pushFullSearchFromExplore(.WATCH_NOW, catalogWid: nil)
        },
        onCategory: { [weak self] preset in
            self?.pushFullSearchFromExplore(preset, catalogWid: nil)
        },
        onMyData: { [weak self] preset in
            self?.openMyData(preset)
        },
        onCatalog: { [weak self] entry in
            self?.pushFullSearchFromExplore(.CATALOG_WID, catalogWid: entry.catalog.wid)
        },
        onViewAllCatalogs: { [weak self] in
            self?.pushFullSearchFromExplore(.CATALOGS, catalogWid: nil)
        }
    )
    private lazy var searchPreparedDataFactory = StarMapSearchPreparedDataFactory(dataProvider: dataProvider, nightMode: nightMode)
    private lazy var searchHelper = StarMapSearchHelper()
    
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
    
    static func newFullSearchInstance(quickPreset: StarMapSearchQuickPresetType,
                                      catalogWid: String? = nil,
                                      parent: StarMapViewController,
                                      plugin: AstronomyPlugin) -> StarMapSearchViewController {
        let controller = StarMapSearchViewController(parent: parent, plugin: plugin)
        controller.launchesInFullSearchMode = true
        controller.pendingInitialQuickPreset = quickPreset
        if quickPreset == .CATALOG_WID, let catalogWid, !catalogWid.isEmpty {
            controller.pendingInitialCatalogWid = catalogWid
        }
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBg
        definesPresentationContext = true
        
        // On iPad the search panel is inset from the screen edge.
        // Apply the same horizontal layout margins to the VC, navigation controller, and nav bar
        // so navbar items, search bar, filters, and table content align via layoutMarginsGuide.
        if OAUtilities.isIPad() {
            navigationController?.view.directionalLayoutMargins = .init(top: 0, leading: Layout.contentPadding, bottom: 0, trailing: Layout.contentPadding)
            navigationController?.navigationBar.directionalLayoutMargins = .init(top: 0, leading: Layout.contentPadding, bottom: 0, trailing: Layout.contentPadding)
            view.directionalLayoutMargins = .init(top: 0, leading: Layout.contentPadding, bottom: 0, trailing: Layout.contentPadding)
            searchRecycler.directionalLayoutMargins = .init(top: 0, leading: Layout.contentPadding, bottom: 0, trailing: Layout.contentPadding)
        } else if let parentStarMapController {
            searchRecycler.directionalLayoutMargins = parentStarMapController.systemMinimumLayoutMargins
        }
        
        if launchesInFullSearchMode {
            currentMode = .FULL_SEARCH
        }
        
        setupNavigationBar()
        
        bindViews()
        
        refreshPreparedEntries()
        setupSearchRecycler()
        setupListeners()
        renderRecentChips()
        applyRedFilter(enabled: redFilterEnabled)
        if launchesInFullSearchMode {
            let preset = pendingInitialQuickPreset ?? .NONE
            let catalogWid = pendingInitialCatalogWid
            pendingInitialQuickPreset = nil
            pendingInitialCatalogWid = nil
            currentMode = .FULL_SEARCH
            clearCatalogsBackState()
            openFullSearch(preset, catalogWid: catalogWid)
            return
        }
        if let initialCatalogWid = pendingInitialCatalogWid {
            pendingInitialCatalogWid = nil
            currentMode = .FULL_SEARCH
            clearCatalogsBackState()
            openFullSearch(.CATALOG_WID, catalogWid: initialCatalogWid)
            return
        }
        applyMode(currentMode, requestKeyboard: currentMode == .FULL_SEARCH && currentFullSearchMode == .INPUT)
        applyFiltersAndSort(scrollToTop: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let headerStackHeight = filtersHeaderStack.frame.height + (sortFilterChipsView.isHidden ? .leastNormalMagnitude : Layout.contentPadding)
        
        if exploreAdapter.topInsetHeight != headerStackHeight || searchAdapter.topInsetHeight != headerStackHeight || catalogsAdapter.topInsetHeight != headerStackHeight {
            
            exploreAdapter.topInsetHeight = headerStackHeight
            searchAdapter.topInsetHeight = headerStackHeight
            catalogsAdapter.topInsetHeight = headerStackHeight
            
            searchRecycler.reloadData()
        }
        
        if currentMode == .EXPLORE {
            updateTableHeader()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncDialogVisibilityWithFragmentState()
        if currentMode == .EXPLORE {
            updateTableAdapter()
        }
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = true
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
        if let view = navigationController?.view {
            AstroRedFilter.apply(enabled, to: view)
        }
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
        resultsContainer.directionalLayoutMargins = searchRecycler.directionalLayoutMargins

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: view.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            fullSearchStack.leadingAnchor.constraint(equalTo: fullSearchContainer.leadingAnchor),
            fullSearchStack.trailingAnchor.constraint(equalTo: fullSearchContainer.trailingAnchor),
            fullSearchStack.topAnchor.constraint(equalTo: fullSearchContainer.topAnchor),
            fullSearchStack.bottomAnchor.constraint(equalTo: fullSearchContainer.bottomAnchor)
        ])

        mainStack.addArrangedSubview(fullSearchContainer)
        setupFullSearchContent()
        setupExploreHeader()
    }

    private func setupFullSearchContent() {

        searchRecycler.keyboardDismissMode = .onDrag
        searchRecycler.rowHeight = UITableView.automaticDimension
        searchRecycler.estimatedRowHeight = Layout.resultRowMinHeight
        searchRecycler.separatorStyle = .singleLine

        sortFilterChipsView.dataSource = sortFilterChipsProvider
        sortFilterChipsView.delegate = sortFilterChipsProvider
        sortFilterChipsProvider.onChange = { [weak self] in
            self?.applyFiltersAndSort(scrollToTop: true)
        }
        let sortFilterSize = sortFilterChipsView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        sortFilterChipsView.frame.size = sortFilterSize

        searchRecycler.translatesAutoresizingMaskIntoConstraints = false
        filtersHeaderStack.axis = .vertical
        filtersHeaderStack.spacing = Layout.contentPadding
        filtersHeaderStack.translatesAutoresizingMaskIntoConstraints = false

        sortFilterChipsView.translatesAutoresizingMaskIntoConstraints = false
        
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.isHidden = true
        emptyView.onAction = { [weak self] in
            self?.handleEmptyStateAction()
        }

        filtersHeaderStack.addArrangedSubview(sortFilterChipsView)

        searchRecycler.addSubview(filtersHeaderStack)
        searchRecycler.bringSubviewToFront(filtersHeaderStack)
        searchFiltersHeaderStackTopConstraint = filtersHeaderStack.topAnchor.constraint(
            equalTo: searchRecycler.safeAreaLayoutGuide.topAnchor
        )
        searchFiltersHeaderStackTopConstraint?.isActive = true
        
        resultsContainer.addSubview(searchRecycler)
        resultsContainer.addSubview(emptyView)
        fullSearchStack.addArrangedSubview(resultsContainer)
        
        NSLayoutConstraint.activate([
            searchRecycler.leadingAnchor.constraint(equalTo: resultsContainer.leadingAnchor),
            searchRecycler.trailingAnchor.constraint(equalTo: resultsContainer.trailingAnchor),
            searchRecycler.topAnchor.constraint(equalTo: resultsContainer.topAnchor),
            searchRecycler.bottomAnchor.constraint(equalTo: resultsContainer.bottomAnchor),
            
            filtersHeaderStack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            filtersHeaderStack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

            emptyView.leadingAnchor.constraint(equalTo: resultsContainer.layoutMarginsGuide.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: resultsContainer.layoutMarginsGuide.trailingAnchor),
            emptyView.topAnchor.constraint(equalTo: filtersHeaderStack.bottomAnchor, constant: Layout.contentPadding)
        ])
    }

    private func setupExploreHeader() {
        recentChipsContainer.axis = .horizontal
        recentChipsContainer.distribution = .fillProportionally
        recentChipsContainer.spacing = Layout.smallPadding
        recentChipsContainer.translatesAutoresizingMaskIntoConstraints = false
        recentChipsContainer.layoutMargins = UIEdgeInsets(top: 0, left: searchRecycler.layoutMargins.left, bottom: Layout.contentPadding + 6, right: searchRecycler.layoutMargins.right)
        recentChipsContainer.isLayoutMarginsRelativeArrangement = true
        
        recentChipsScroll.showsVerticalScrollIndicator = false
        recentChipsScroll.showsHorizontalScrollIndicator = false
        recentChipsScroll.addSubview(recentChipsContainer)
        
        NSLayoutConstraint.activate([
            recentChipsContainer.leadingAnchor.constraint(equalTo: recentChipsScroll.contentLayoutGuide.leadingAnchor),
            recentChipsContainer.trailingAnchor.constraint(lessThanOrEqualTo: recentChipsScroll.contentLayoutGuide.trailingAnchor),
            recentChipsContainer.topAnchor.constraint(equalTo: recentChipsScroll.contentLayoutGuide.topAnchor),
            recentChipsContainer.bottomAnchor.constraint(equalTo: recentChipsScroll.contentLayoutGuide.bottomAnchor),
            recentChipsContainer.heightAnchor.constraint(equalTo: recentChipsScroll.frameLayoutGuide.heightAnchor)
        ])
    }

    // MARK: - Navigation

    private func setupNavigationBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        if #available(iOS 16.0, *) {
            navigationItem.preferredSearchBarPlacement = .stacked
        }
        
        updateNavigationBar()
    }

    private func updateSearchFiltersHeaderVisibility() {
        let isExplore = currentMode == .EXPLORE
        sortFilterChipsView.isHidden = isExplore
        
        filtersHeaderStack.setNeedsLayout()
        filtersHeaderStack.layoutIfNeeded()
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
            syncSearchQuery()

        case .FULL_SEARCH:
            switch currentFullSearchMode {
            case .BROWSE:
                navigationItem.leftBarButtonItem = makeBarButton(
                    image: UIImage(systemName: "chevron.left"),
                    accessibilityLabel: localizedString("shared_string_back"),
                    action: #selector(backPressed)
                )
                navigationItem.title = getBrowseTitle()
                navigationItem.largeTitleDisplayMode = searchState.quickPresetType == .WATCH_NOW ? .never : .always
                syncSearchQuery()

            case .INPUT:
                navigationItem.leftBarButtonItem = makeBarButton(
                    image: UIImage(systemName: "chevron.left"),
                    accessibilityLabel: localizedString("shared_string_back"),
                    action: #selector(backPressed)
                )
                navigationItem.title = searchState.hasBrowseContext() ? getBrowseTitle() : localizedString("shared_string_explore")
                syncSearchQuery()
            }
        }
        updateSearchFiltersHeaderVisibility()
    }

    private func makeBarButton(image: UIImage?, accessibilityLabel: String, action: Selector) -> UIBarButtonItem {
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: action)
        button.accessibilityLabel = accessibilityLabel
        return button
    }

    private func syncSearchQuery() {
        suppressQueryDispatch = true
        searchController.searchBar.text = searchState.query.isEmpty ? nil : searchState.query
        suppressQueryDispatch = false
    }

    // MARK: - Table

    private func setupSearchRecycler() {
        searchRecycler.backgroundColor = .viewBg
        updateTableAdapter()
    }

    private func updateTableAdapter() {
        if currentMode == .EXPLORE {
            exploreAdapter.submitSnapshot(buildExploreSnapshot())
            searchRecycler.dataSource = exploreAdapter
            searchRecycler.delegate = exploreAdapter
        } else {
            if shouldShowCatalogEntries() {
                catalogsAdapter.submitSnapshot(StarMapCatalogsAdapter.Snapshot(entries: visibleCatalogEntries))
                searchRecycler.dataSource = catalogsAdapter
                searchRecycler.delegate = catalogsAdapter
            } else {
                let categoryPreset = searchState.categoryPreset()
                searchAdapter.submitSnapshot(StarMapSearchResultsAdapter.Snapshot(entries: visibleEntries,
                                                                                  categoryPreset: categoryPreset,
                                                                                  useExploreRowLayout: false))
                searchRecycler.dataSource = searchAdapter
                searchRecycler.delegate = searchAdapter
            }
        }
        updateTableHeader()
        searchRecycler.reloadData()
    }

    private func updateResultsAdapter() {
        updateTableAdapter()
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
    
    private func updateTableHeader() {
        guard currentMode == .EXPLORE, !searchState.recentChips.isEmpty else {
            searchRecycler.tableHeaderView = nil
            return
        }
        
        let width = searchRecycler.bounds.width

        var height = recentChipsScroll.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        
        height = max(Layout.recentChipsHeaderMinHeight, ceil(height))
        
        recentChipsScroll.frame = CGRect(x: 0, y: 0, width: width, height: height)
        searchRecycler.tableHeaderView = recentChipsScroll
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

    private func pushFullSearchFromExplore(_ quickPresetType: StarMapSearchQuickPresetType,
                                           catalogWid: String? = nil) {
        guard let parent = parentStarMapController else { return }
        let controller = StarMapSearchViewController.newFullSearchInstance(
            quickPreset: quickPresetType,
            catalogWid: catalogWid,
            parent: parent,
            plugin: plugin
        )
        controller.onObjectSelected = onObjectSelected
        controller.onDismiss = onDismiss
        controller.applyRedFilter(enabled: redFilterEnabled)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func popOrDismiss() {
        if let navigationController,
           navigationController.viewControllers.count > 1,
           navigationController.viewControllers.last === self {
            navigationController.popViewController(animated: true)
        } else if let onDismiss {
            onDismiss()
        } else {
            dismiss(animated: true)
        }
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
        emptyView.isHidden = true
        searchRecycler.isHidden = false
        updateTableAdapter()
        updateNavigationBar()
    }

    private func showBrowseMode(resetCollapseState: Bool = true) {
        if resetCollapseState {
            resetResultsScrollState(scrollToTop: true)
        }
        currentFullSearchMode = .BROWSE
        syncSearchQuery()
        updateTableAdapter()
        updateSortFilterBar()
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
        syncSearchQuery()
        updateTableAdapter()
        updateSortFilterBar()
        updateEmptyStateContent()
        updateEmptyStateVisibility()
        updateNavigationBar()
    }

    @discardableResult private func handleBackPressedInternal() -> Bool {
        guard currentMode == .FULL_SEARCH else { return false }

        if currentFullSearchMode == .BROWSE {
            if dismissOnBrowseBack {
                popOrDismiss()
                return true
            }
            if restoreCatalogsListIfNeeded() {
                return true
            }
            handleBrowseBackNavigation()
            return true
        }
        
        searchState.query = ""
        syncSearchQuery()
        searchController.isActive = false

        if searchState.hasBrowseContext() {
            showBrowseMode()
        } else if launchesInFullSearchMode {
            popOrDismiss()
        } else {
            applyMode(.EXPLORE, requestKeyboard: false)
        }
        return true
    }

    private func handleBrowseBackNavigation() {
        if launchesInFullSearchMode {
            popOrDismiss()
            return
        }
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
    }

    // MARK: - Data

    private func setupListeners() {
        syncRecentChipsWithSession()
    }

    private func syncDialogVisibilityWithFragmentState() {
        applyRedFilter(enabled: parentStarMapController?.isSearchRedFilterEnabled() ?? redFilterEnabled)
    }

    private func refreshPreparedEntries() {
        let preparedData = searchPreparedDataFactory.create(parent: parentStarMapController)
        preparedEntries = preparedData.entries
        preparedCatalogEntries = preparedData.catalogEntries
        widToDisplayName = preparedData.widToDisplayName
        starConstellationNameByObjectId = preparedData.starConstellationNameByObjectId
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
        updateEmptyStateVisibility()
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
        let config = parentStarMapController?.searchStarMapConfig() ?? plugin.astroSettings.getStarMapConfig()
        let myDataItems: [(StarMapExploreRowConfig, Int)] = [
            (StarMapExploreRowConfig(quickPresetType: .MY_DATA_FAVORITES, iconRes: "ic_custom_bookmark", titleRes: "favorites_item", subtitleRes: nil), config.favorites.count),
            (StarMapExploreRowConfig(quickPresetType: .MY_DATA_DAILY_PATH, iconRes: "ic_custom_target_path_on", titleRes: "astro_daily_path", subtitleRes: nil), config.celestialPaths.count),
            (StarMapExploreRowConfig(quickPresetType: .MY_DATA_DIRECTIONS, iconRes: "ic_custom_target_direction_on", titleRes: "astro_directions", subtitleRes: nil), config.directions.count)
        ]
        let featuredCatalogs = getFeaturedCatalogEntries()
        var catalogRows: [StarMapExploreRow] = featuredCatalogs.map { .catalog($0) }
        catalogRows.append(.viewAllCatalogs(count: getBrowsableCatalogEntries().count))

        var sections: [(StarMapExploreSection, [StarMapExploreRow])] = []
        sections.append(contentsOf: [
            (.watchNow, [.watchNow]),
            (.categories, categories.map { .category($0) }),
            (.myData, myDataItems.map { .myData(config: $0.0, count: $0.1) }),
            (.catalogs, catalogRows)
        ])
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
        controller.onDismiss = onDismiss
        controller.applyRedFilter(enabled: redFilterEnabled)
        navigationController?.pushViewController(controller, animated: true)
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
        updateSortFilterBar()
        updateEmptyStateContent()
        StarMapSearchProgressHUD.show(on: view)
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

        if requestId == filterAndSortRequestId {
            StarMapSearchProgressHUD.hide(from: view, animated: true)
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

    private func updateSortFilterBar() {
        sortFilterChipsProvider.configure(
            searchState: searchState,
            configuration: .make(
                catalogMode: shouldShowCatalogEntries(),
                showMyDataSortModes: false,
                showsShowAllVisibility: !shouldHideShowAllTypeFilter(),
                showsCategoriesSection: !searchState.isCategoryPreset()
            )
        )
        sortFilterChipsView.reloadData()
    }
    
    private func updateSortFilterBarTopConstraint(_ scrollView: UIScrollView) {
        let inset = scrollView.safeAreaInsets.top + scrollView.contentOffset.y
        let min = min(inset, 0)
        searchFiltersHeaderStackTopConstraint?.constant = abs(min)
    }

    // MARK: - Empty State

    private func updateEmptyStateContent() {
        emptyView.configure(with: .searchNoResults)
    }

    private func updateEmptyStateVisibility() {
        if isFilteringResults {
            emptyView.isHidden = true
            searchRecycler.isHidden = false
            return
        }
        let shouldShowEmptyState = currentMode == .FULL_SEARCH && getCurrentResultsCount() == 0
        emptyView.isHidden = !shouldShowEmptyState
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
        if searchState.hasBrowseContext() {
            let preset = searchState.quickPresetType
            let catalogWid = searchState.quickPresetCatalogWid
            searchState.prepareForExploreEntry(preset, catalogWid: catalogWid)
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
        plugin.saveRecentSearchChips()
        renderRecentChips()
    }

    private func syncRecentChipsWithSession() {
        if plugin.recentSearchChips.isEmpty {
            plugin.recentSearchChips = plugin.astroSettings.getRecentChips()
        }
        if plugin.recentSearchChips.isEmpty {
            plugin.recentSearchChips.append(contentsOf: searchState.recentChips)
            plugin.saveRecentSearchChips()
        } else {
            searchState.replaceRecentChips(plugin.recentSearchChips)
        }
    }

    private func renderRecentChips() {
        func displayTitle(_ fullName: String) -> String {
            let title = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            let maxLength = 10

            guard title.count > maxLength else { return title }

            return title.prefix(maxLength) + localizedString("shared_string_ellipsis")
        }
        for view in recentChipsContainer.arrangedSubviews {
            recentChipsContainer.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        if searchState.recentChips.isEmpty {
            if currentMode == .EXPLORE {
                exploreAdapter.submitSnapshot(buildExploreSnapshot())
                searchRecycler.reloadData()
            }
            return
        }
        for recentChip in searchState.recentChips {
            var config = UIButton.Configuration.filled()
            config.cornerStyle = .capsule
            config.title = displayTitle(recentChip.label)
            config.titleLineBreakMode = .byTruncatingTail
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.preferredFont(forTextStyle: .subheadline)
                outgoing.foregroundColor = .filterChipTextDefault
                return outgoing
            }
            config.baseBackgroundColor = .filterChipBGDefault
            config.baseForegroundColor = .filterChipIconDefault
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)

            let chipButton = UIButton(configuration: config)
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
            updateTableHeader()
            exploreAdapter.submitSnapshot(buildExploreSnapshot())
            searchRecycler.reloadData()
        }
    }

    // MARK: - Selection

    private func onSearchEntrySelected(_ entry: StarMapSearchEntry) {
        addRecentChip(entry)
        let select = { [weak self] in self?.onObjectSelected?(entry.objectRef) }
        if parentStarMapController != nil, OAUtilities.isIPad() {
            select()
        } else {
            navigationController?.dismiss(animated: true) { select() }
        }
    }

    private func onCatalogSelected(_ entry: StarMapCatalogEntry) {
        pushFullSearchFromExplore(.CATALOG_WID, catalogWid: entry.catalog.wid)
    }

    // MARK: - Actions

    @objc private func backPressed() {
        if searchState.hasBrowseContext(),
           searchController.isActive || !searchState.query.isEmpty {
            searchState.query = ""
            syncSearchQuery()
            searchController.isActive = false
            applyFiltersAndSort(scrollToTop: true)
            return
        }
        guard !handleBackPressedInternal() else { return }
        popOrDismiss()
    }

    @objc private func close() {
        if let onDismiss {
            onDismiss()
        } else {
            dismiss(animated: true)
        }
    }
    
    deinit {
        StarMapSearchProgressHUD.hide(from: view, animated: true)
    }
}

extension StarMapSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !suppressQueryDispatch, currentMode == .FULL_SEARCH else { return }
        searchState.query = searchText
        applyFiltersAndSort(scrollToTop: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        guard OAUtilities.isIPad() else { return }
        guard searchBar.text?.isEmpty == true, searchController.isActive else { return }
        searchController.isActive = false
    }
}

extension StarMapSearchViewController: UISearchControllerDelegate {
    func didPresentSearchController(_ searchController: UISearchController) {
        guard currentMode == .EXPLORE else { return }
        openFullSearch(.NONE, catalogWid: nil, fromSearchBarActivation: true)
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        guard OAUtilities.isIPhone() else { return }
        guard currentMode == .FULL_SEARCH, !searchState.hasBrowseContext() else { return }
        _ = handleBackPressedInternal()
    }
}

extension StarMapSearchViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === navigationController?.interactivePopGestureRecognizer else {
            return true
        }
        return (navigationController?.viewControllers.count ?? 0) > 1
    }
}
