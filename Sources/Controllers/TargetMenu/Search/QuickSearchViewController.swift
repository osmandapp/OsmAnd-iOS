//
//  QuickSearchViewController.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

@objc enum QuickSearchBarAction: Int {
    case none
    case showOnMap
    case selectTarget
}

final class QuickSearchViewController: OASuperViewController {
    private typealias SearchStartedCallback = (OASearchPhrase?) -> Void
    private typealias PublishCallback = (OASearchResultCollection?, Bool) -> Void
    private typealias SearchFinishedCallback = (OASearchPhrase?) -> Bool

    private struct ChipsState: Equatable {
        let searchNearMapCenter: Bool
        let showsFilters: Bool
        let filtersApplied: Bool
    }

    private struct ToolbarState: Equatable {
        let barActionTitle: String?
        let showsSave: Bool
    }

    private static let tabsVerticalInset: CGFloat = 4
    private static let chipsTopInset: CGFloat = 4
    private static let chipsBottomInset: CGFloat = 8
    private static let chipIconSize: CGFloat = 20
    private static let estimatedRowHeight: CGFloat = 48
    private static let collapsibleConstraintPriority = UILayoutPriority(999)
    private static let distanceUpdateInterval: TimeInterval = 0.3
    private static let nearestCitiesLimit = 15
    private static let topIndexBrandPrefix = "top_index_brand"
    private static let searchAroundGroupId = "search_around"
    private static let filtersGroupId = "filters"
    private static let nearMeOptionId = "near_me"
    private static let mapCenterOptionId = "map_center"
    private static let targetSearchTypes: [OAQuickSearchType] = [.START_POINT, .DESTINATION, .INTERMEDIATE, .HOME, .WORK]
    private static let routeTargetSearchTypes: [OAQuickSearchType] = [.START_POINT, .DESTINATION, .INTERMEDIATE]

    @objc var searchNearMapCenter = false {
        didSet { applySearchNearMapCenter() }
    }
    @objc var distanceFromMyLocation: Double = 0
    @objc var searchLocation = CLLocationCoordinate2D() {
        didSet { applySearchLocation() }
    }
    @objc var searchType: OAQuickSearchType = .REGULAR {
        didSet { applySearchType() }
    }
    @objc var tabIndex = 0 {
        didSet {
            if isViewLoaded {
                applyTabIndex()
            }
        }
    }
    @objc var searchQuery = ""
    @objc var fromNavigation = false
    @objc var onCloseCallback: (() -> Void)?

    private var lastUpdate: TimeInterval = 0
    private var paused = false
    private var interruptedSearch = false
    private var cancelPrev = false
    private var runSearchFirstTime = true
    private var poiFilterApplied = false
    private var addressSearch = false
    private var citiesLoaded = false
    private var modalInput = false
    private var citySearchedRect: QuadRect?
    private var storedOriginalLocation: CLLocation?

    private var searchHelper: OAQuickSearchHelper?
    private var searchUICore: OASearchUICore?

    private let searchController = UISearchController(searchResultsController: nil)
    private let headerStackView = UIStackView()
    private let tabsContainerView = UIView()
    private let tabsControl = UISegmentedControl(items: [localizedString("shared_string_explore"),
                                                         localizedString("search_categories"),
                                                         localizedString("shared_string_address")])
    private let chipsContainerView = UIView()
    private let chipsView = StarMapSearchSortFilterChipsView()
    private let contentView = UIView()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let clearButton = UIButton(type: .system)
    private let activityIndicatorView = UIActivityIndicatorView(style: .medium)
    private let presentationDelegate = QuickSearchTransitioningDelegate()
    private var searchIconView: UIView?
    private var processedSearchText = ""
    private var pendingPresentation: (() -> Void)?
    private var chipsState: ChipsState?
    private var toolbarState: ToolbarState?

    private var tblMove: UIPanGestureRecognizer?
    private var dismissEditingTap: UITapGestureRecognizer?

    private var tableController: OAQuickSearchTableController?
    private var pageController: UIPageViewController?
    private var addressViewController: OAAddressTableViewController?
    private var categoriesViewController: CategoriesViewController?
    private var exploreViewController: ExploreViewController?
    private var searchToolbarViewController: OASearchToolbarViewController?

    private var barActionType: QuickSearchBarAction = .none
    private var bottomViewVisible = false

    private let resultPreparationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()
    private var resultPresentationGeneration = 0
    private var preparingResults = false
    private var pendingMoreButton = false
    private var pendingEmptyResult = false

    private var searchText: String {
        searchController.searchBar.text ?? ""
    }

    private var isTargetSearchType: Bool {
        Self.targetSearchTypes.contains(searchType)
    }

    private var tabsVisible: Bool {
        pageController?.parent != nil
    }

    private var showsChips: Bool {
        !tabsVisible && !modalInput
    }

    private var lastSelectedWord: OASearchWord? {
        searchUICore?.getPhrase()?.getLastSelectedWord()
    }

    private var showsFiltersChip: Bool {
        barActionType == .showOnMap && lastSelectedWord?.getType() == .poiType
    }

    private var isPoiFilterApplied: Bool {
        if bottomViewVisible {
            return true
        }
        guard let filter = lastSelectedWord?.result?.object as? OAPOIUIFilter else { return false }
        return !filter.filterByName.isEmpty
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .default
    }

    @objc init() {
        super.init(nibName: nil, bundle: nil)
        presentationDelegate.onOutsideTap = { [weak self] in
            self?.dismissSearch(animated: true)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func loadView() {
        view = UIView()
    }

    override func registerObservers() {
        let locationServices = OsmAndApp.swiftInstance().locationServices
        _ = addObserver(OAAutoObserverProxy(self, withHandler: #selector(updateDistanceAndDirection), andObserve: locationServices?.updateLocationObserver))
        _ = addObserver(OAAutoObserverProxy(self, withHandler: #selector(updateDistanceAndDirection), andObserve: locationServices?.updateHeadingObserver))
    }

    override func isNavbarVisible() -> Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBg
        setupNavigationItem()
        setupSearchController()
        setupHeader()
        setupContent()

        let dismissEditingTap = UITapGestureRecognizer(target: self, action: #selector(dismissTextEditing))
        dismissEditingTap.cancelsTouchesInView = false
        dismissEditingTap.delegate = self
        view.addGestureRecognizer(dismissEditingTap)
        self.dismissEditingTap = dismissEditingTap

        let tableController = OAQuickSearchTableController(tableView: tableView)
        tableController?.delegate = self
        tableController?.searchType = searchType
        if searchNearMapCenter {
            tableController?.setMapCenter(searchLocation)
        } else {
            tableController?.resetMapCenterSearch()
        }
        self.tableController = tableController

        let pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageController.dataSource = self
        pageController.delegate = self
        self.pageController = pageController

        let addressViewController = OAAddressTableViewController(frame: .zero)
        addressViewController?.delegate = self
        addressViewController?.tableDelegate = self
        addressViewController?.searchType = searchType
        if searchNearMapCenter {
            addressViewController?.setMapCenter(searchLocation)
        } else {
            addressViewController?.resetMapCenterSearch()
        }
        self.addressViewController = addressViewController

        let categoriesViewController = CategoriesViewController()
        categoriesViewController.delegate = self
        self.categoriesViewController = categoriesViewController

        let exploreViewController = ExploreViewController()
        exploreViewController.delegate = self
        exploreViewController.searchLocation = searchLocation
        exploreViewController.searchNearMapCenter = searchNearMapCenter
        self.exploreViewController = exploreViewController

        pageController.setViewControllers([exploreViewController], direction: .forward, animated: false)

        let tblMove = UIPanGestureRecognizer(target: self, action: #selector(moveGestureDetected))
        tblMove.delegate = self
        self.tblMove = tblMove

        applyTabIndex()
        setupSearch()
        updateHint()

        showSearchIcon()
        showTabs()
    }

    override func viewWillAppear(_ animated: Bool) {
        paused = false
        setupView()
        registerForKeyboardNotifications()
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)

        if let resultCollection = currentResultCollection() {
            updateSearchResult(resultCollection, append: false)
            if interruptedSearch || isSearchMoreAvailable(searchUICore?.getPhrase()) {
                addMoreButton()
            }
        }
        if !searchQuery.isEmpty {
            updateTextField(searchQuery)
        }
        chipsState = nil
        toolbarState = nil
        updateHeader()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showSearchIcon()
        focusSearchField()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        paused = true
        cancelResultPreparation()
        unregisterKeyboardNotifications()
        if let navigationController, let topViewController = navigationController.topViewController, topViewController !== self {
            navigationController.setToolbarHidden(true, animated: animated)
            if !topViewController.isNavbarVisible() {
                navigationController.setNavigationBarHidden(true, animated: animated)
            }
        }
        OARootViewController.instance().keyCommandUpdateObserver.handleObservedEvent(from: nil, withKey: kCommandSearchScreenClose)
    }

    @objc func makeNavigationController() -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: self)
        navigationController.modalPresentationStyle = .custom
        navigationController.transitioningDelegate = presentationDelegate
        navigationController.modalPresentationCapturesStatusBarAppearance = true
        return navigationController
    }

    @objc(dismissSearchAnimated:completion:)
    func dismissSearch(animated: Bool, completion: (() -> Void)? = nil) {
        guard let presentingViewController = (navigationController ?? self).presentingViewController else {
            completion?()
            return
        }
        presentingViewController.dismiss(animated: animated, completion: completion)
    }

    @objc func setupBarActionView(_ type: QuickSearchBarAction) {
        barActionType = type
        updateHeader()
    }

    @objc func showToolbar() {
        showToolbar(nil)
    }

    @objc func showToolbar(_ filter: OAPOIUIFilter?) {
        let toolbar: OASearchToolbarViewController
        if let searchToolbarViewController {
            toolbar = searchToolbarViewController
        } else {
            toolbar = OASearchToolbarViewController(nibName: "OASearchToolbarViewController", bundle: nil)
            toolbar.searchDelegate = self
            searchToolbarViewController = toolbar
        }
        toolbar.setFilter(filter)
        if let filter, filter.filterId != BY_NAME_FILTER_ID {
            toolbar.toolbarTitle = filter.filterId.hasPrefix(Self.topIndexBrandPrefix) ? filter.filterByName : filter.name
        } else {
            toolbar.toolbarTitle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        OARootViewController.instance().mapPanel.showToolbar(toolbar)
    }

    private func setupNavigationItem() {
        navigationItem.title = localizedString("shared_string_search")
        navigationItem.largeTitleDisplayMode = .never
        let backButton = UIBarButtonItem(image: UIImage.icNavbarChevron.imageFlippedForRightToLeftLayoutDirection(),
                                         style: .plain,
                                         target: self,
                                         action: #selector(onBackButtonPressed))
        backButton.accessibilityLabel = localizedString("shared_string_back")
        backButton.tintColor = .iconColorActive
        navigationItem.leftBarButtonItem = backButton

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .viewBg
        appearance.shadowColor = nil
        appearance.titleTextAttributes = [.foregroundColor: UIColor.textColorPrimary]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.compactScrollEdgeAppearance = appearance
    }

    private func setupSearchController() {
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false

        let searchBar = searchController.searchBar
        searchBar.delegate = self
        searchBar.autocorrectionType = .no
        searchBar.spellCheckingType = .no
        searchBar.tintColor = .iconColorActive

        var clearConfiguration = UIButton.Configuration.plain()
        clearConfiguration.image = UIImage(systemName: "xmark.circle.fill")
        clearConfiguration.baseForegroundColor = .iconColorSecondary
        clearConfiguration.contentInsets = .zero
        clearButton.configuration = clearConfiguration
        clearButton.sizeToFit()
        clearButton.accessibilityLabel = localizedString("shared_string_clear")
        clearButton.addTarget(self, action: #selector(onClearButtonPressed), for: .touchUpInside)

        let searchTextField = searchBar.searchTextField
        searchTextField.clearButtonMode = .never
        searchTextField.rightView = clearButton
        searchTextField.rightViewMode = .never

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        if #available(iOS 26.0, *) {
            navigationItem.searchBarPlacementAllowsToolbarIntegration = false
            navigationItem.preferredSearchBarPlacement = .stacked
        }
        definesPresentationContext = true
    }

    private func setupHeader() {
        tabsControl.setTitleTextAttributes([.font: UIFont.scaledSystemFont(ofSize: 14)], for: .normal)
        tabsControl.setTitleTextAttributes([.font: UIFont.scaledSystemFont(ofSize: 14)], for: .selected)
        tabsControl.addTarget(self, action: #selector(tabChanged(_:)), for: .valueChanged)
        tabsControl.translatesAutoresizingMaskIntoConstraints = false
        tabsContainerView.preservesSuperviewLayoutMargins = true
        tabsContainerView.addSubview(tabsControl)

        chipsView.dataSource = self
        chipsView.delegate = self
        chipsView.translatesAutoresizingMaskIntoConstraints = false
        chipsContainerView.preservesSuperviewLayoutMargins = true
        chipsContainerView.isHidden = true
        chipsContainerView.addSubview(chipsView)

        headerStackView.axis = .vertical
        headerStackView.preservesSuperviewLayoutMargins = true
        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        headerStackView.addArrangedSubview(tabsContainerView)
        headerStackView.addArrangedSubview(chipsContainerView)
        view.addSubview(headerStackView)

        let tabsBottom = tabsControl.bottomAnchor.constraint(equalTo: tabsContainerView.bottomAnchor, constant: -Self.tabsVerticalInset)
        tabsBottom.priority = Self.collapsibleConstraintPriority
        let chipsBottom = chipsView.bottomAnchor.constraint(equalTo: chipsContainerView.bottomAnchor, constant: -Self.chipsBottomInset)
        chipsBottom.priority = Self.collapsibleConstraintPriority
        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabsControl.topAnchor.constraint(equalTo: tabsContainerView.topAnchor, constant: Self.tabsVerticalInset),
            tabsControl.leadingAnchor.constraint(equalTo: tabsContainerView.layoutMarginsGuide.leadingAnchor),
            tabsControl.trailingAnchor.constraint(equalTo: tabsContainerView.layoutMarginsGuide.trailingAnchor),
            tabsBottom,
            chipsView.topAnchor.constraint(equalTo: chipsContainerView.topAnchor, constant: Self.chipsTopInset),
            chipsView.leadingAnchor.constraint(equalTo: chipsContainerView.layoutMarginsGuide.leadingAnchor),
            chipsView.trailingAnchor.constraint(equalTo: chipsContainerView.layoutMarginsGuide.trailingAnchor),
            chipsBottom
        ])
    }

    private func setupContent() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tableView.backgroundColor = .viewBg
        tableView.separatorColor = SeparatorAppearance.color
        tableView.tintColor = .iconColorActive
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Self.estimatedRowHeight
        tableView.alwaysBounceVertical = true
        tableView.isHidden = true
        tableView.frame = contentView.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(tableView)
    }

    private func setupSearch() {
        let appSettings = OAAppSettings.sharedManager()
        let locale = appSettings.settingPrefMapLanguage.get()
        let transliterate = appSettings.settingMapLanguageTranslit.get()
        searchHelper = OAQuickSearchHelper.instance()
        searchUICore = searchHelper?.getCore()

        stopAddressSearch()
        setResultCollection(nil)
        if searchQuery.isEmpty {
            searchUICore?.resetPhrase()
        }

        let settings = searchUICore?.getSearchSettings()?
            .setOriginalLocation(CLLocation(latitude: searchLocation.latitude, longitude: searchLocation.longitude))?
            .setLang(locale, transliterateIfMissing: transliterate)
        searchUICore?.update(settings)

        searchUICore?.onSearchStart = { [weak self] in
            self?.cancelPrev = false
        }
        searchUICore?.onResultsComplete = { [weak self] in
            DispatchQueue.main.async {
                guard let self, !self.paused else { return }
                if self.searchUICore?.isSearchMoreAvailable(self.searchUICore?.getPhrase()) == true {
                    self.addMoreButton()
                }
                self.updateBarActionView()
                self.showSearchIcon()
            }
        }
    }

    private func setupView() {
        let appSettings = OAAppSettings.sharedManager()
        let locale = appSettings.settingPrefMapLanguage.get()
        let transliterate = appSettings.settingMapLanguageTranslit.get()
        let settings = searchUICore?.getSearchSettings()?.setLang(locale, transliterateIfMissing: transliterate)
        searchUICore?.update(settings)
    }

    private func applySearchNearMapCenter() {
        guard isViewLoaded else { return }
        if searchNearMapCenter {
            exploreViewController?.searchLocation = searchLocation
            exploreViewController?.searchNearMapCenter = true
            addressViewController?.setMapCenter(searchLocation)
            tableController?.setMapCenter(searchLocation)
        } else {
            exploreViewController?.searchNearMapCenter = false
            addressViewController?.resetMapCenterSearch()
            tableController?.resetMapCenterSearch()
        }
        updateChips()
    }

    private func applySearchLocation() {
        exploreViewController?.searchLocation = searchLocation
        let settings = searchUICore?.getSearchSettings()?
            .setOriginalLocation(CLLocation(latitude: searchLocation.latitude, longitude: searchLocation.longitude))
        searchUICore?.update(settings)
    }

    private func applySearchType() {
        addressViewController?.searchType = searchType
        tableController?.searchType = searchType
        updateBarActionView()
    }

    private func applyTabIndex() {
        tabsControl.selectedSegmentIndex = tabIndex
        tabChanged(nil)
    }

    private func updateTabsVisibility(_ show: Bool) {
        if show && !tabsVisible {
            showTabs()
        } else if !show && tabsVisible {
            hideTabs()
        }
        updateBarActionView()
    }

    private func showTabs() {
        guard let pageController else { return }
        addChild(pageController)
        pageController.view.frame = contentView.bounds
        pageController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(pageController.view)
        tableView.isHidden = true
        pageController.didMove(toParent: self)
        updateHeader()
    }

    private func hideTabs() {
        tableView.isHidden = false
        pageController?.willMove(toParent: nil)
        pageController?.view.removeFromSuperview()
        pageController?.removeFromParent()
        updateHeader()
    }

    @objc private func tabChanged(_ sender: Any?) {
        moveGestureDetected()
        if let pageController, let exploreViewController, let categoriesViewController, let addressViewController {
            switch tabsControl.selectedSegmentIndex {
            case 0:
                pageController.setViewControllers([exploreViewController], direction: .reverse, animated: true)
            case 1:
                searchHelper?.refreshCustomPoiFilters()
                let direction: UIPageViewController.NavigationDirection = pageController.viewControllers?.first === exploreViewController ? .forward : .reverse
                pageController.setViewControllers([categoriesViewController], direction: direction, animated: true)
            case 2:
                pageController.setViewControllers([addressViewController], direction: .forward, animated: true)
            default:
                break
            }
        }
        processTabChange()
    }

    private func processTabChange() {
        addressSearch = tabsControl.selectedSegmentIndex == 2
        updateHint()
        if !(addressSearch && !citiesLoaded) {
            restoreSearch()
        }
    }

    @objc private func onBackButtonPressed() {
        guard modalInput else {
            dismissSearch(animated: true, completion: onCloseCallback)
            return
        }
        restoreInputLayout()
        resetSearch()
        if addressSearch && tabsVisible {
            reloadCities()
        }
    }

    @objc private func onClearButtonPressed() {
        clearLastWord()
    }

    @objc private func onBarActionButtonPressed() {
        guard barActionType == .selectTarget || barActionType == .showOnMap,
              let searchPhrase = searchUICore?.getPhrase() else { return }

        if searchPhrase.isNoSelectedType() || searchPhrase.isLastWord(.poiType) {
            var filter: OAPOIUIFilter?
            let lastSelectedObject = searchPhrase.getLastSelectedWord()?.result?.object
            if searchPhrase.isNoSelectedType() {
                if let unselectedPoiType = searchUICore?.getUnselectedPoiType() {
                    filter = OAPOIUIFilter(basePoiType: unselectedPoiType, idSuffix: "")
                    if let customName = searchUICore?.getCustomNameFilter(), !customName.isEmpty {
                        filter?.filterByName = customName
                    }
                } else {
                    filter = OAPOIFiltersHelper.sharedInstance().getSearchByNamePOIFilter()
                    if let searchWord = searchPhrase.getUnknownWordToSearch(), !searchWord.isEmpty {
                        filter?.filterByName = searchWord
                        filter?.clearCurrentResults()
                    }
                }
            } else if let abstractPoiType = lastSelectedObject as? OAPOIBaseType {
                filter = OAPOIUIFilter(basePoiType: abstractPoiType, idSuffix: "")
                if let unknownWord = searchPhrase.getFirstUnknownSearchWord(), !unknownWord.isEmpty {
                    filter?.filterByName = unknownWord
                }
            } else if let topIndexFilter = lastSelectedObject as? OATopIndexFilter {
                guard let topIndexPoiFilter = createPOIUIFilter(with: topIndexFilter) else { return }
                topIndexPoiFilter.filterByName = topIndexFilter.getValue()
                topIndexPoiFilter.filterByKey = topIndexFilter.getTag()
                filter = topIndexPoiFilter
            } else {
                filter = lastSelectedObject as? OAPOIUIFilter
            }
            if let filter {
                OAPOIFiltersHelper.sharedInstance().replaceSelectedPoiFilters(filter)
            }
            OARootViewController.instance().mapPanel.mapViewController.updatePoiLayer()
            showToolbar(filter)
            dismissSearch(animated: true)
        } else if searchPhrase.isLastWord(.favoriteGroup) {
            guard let group = searchPhrase.getLastSelectedWord()?.result?.object as? OAFavoriteGroup else { return }
            let points = OAFavoritesHelperBridge.shared().favoritePoints(forGroupName: group.name)
            guard !points.isEmpty else { return }
            var topLeft = CLLocationCoordinate2D(latitude: -90, longitude: 180)
            var bottomRight = CLLocationCoordinate2D(latitude: 90, longitude: -180)
            for point in points {
                topLeft.latitude = max(topLeft.latitude, point.latitude)
                topLeft.longitude = min(topLeft.longitude, point.longitude)
                bottomRight.latitude = min(bottomRight.latitude, point.latitude)
                bottomRight.longitude = max(bottomRight.longitude, point.longitude)
            }
            let mapPanel = OARootViewController.instance().mapPanel
            dismissSearch(animated: true) {
                guard let mapPanel else { return }
                mapPanel.displayArea(onMap: topLeft, bottomRight: bottomRight, maxZoom: Float(PREFERRED_FAVORITE_ZOOM), screenBBox: mapPanel.view.bounds.size, bottomInset: 0, leftInset: 0, topInset: 0)
            }
        } else if let word = searchPhrase.getLastSelectedWord(), word.getLocation() != nil {
            tableController?.show(onMap: word.result, searchType: searchType, delegate: self)
        }
    }

    private func openFilters() {
        guard barActionType == .showOnMap,
              let searchPhrase = searchUICore?.getPhrase(),
              searchPhrase.isLastWord(.poiType) else { return }

        let filterByName = searchPhrase.getUnknownSearchPhrase()?.trimmingCharacters(in: .whitespacesAndNewlines)
        let object = searchPhrase.getLastSelectedWord()?.result?.object
        if let model = object as? OAPOIUIFilter {
            if !model.savedFilterByName.isEmpty {
                model.filterByName = model.savedFilterByName
            }
            showFilterScreen(model, filterByName: filterByName)
        } else if let abstractPoiType = object as? OAPOIBaseType {
            guard let custom = OAPOIFiltersHelper.sharedInstance().getFilterById(STD_PREFIX + abstractPoiType.name) else { return }
            custom.clear()
            custom.updateTypes(toAccept:abstractPoiType)
            showFilterScreen(custom, filterByName: filterByName)
        } else if let topIndexFilter = object as? OATopIndexFilter {
            guard let custom = createPOIUIFilter(with: topIndexFilter) else { return }
            showFilterScreen(custom, filterByName: topIndexFilter.getValue())
        }
    }

    @objc private func onSaveFilterButtonPressed() {
        guard let customFilter = OAPOIFiltersHelper.sharedInstance().getCustomPOIFilter() else { return }
        presentOverSearch(createSaveFilterDialog(customFilter, customSaveAction: false))
    }

    private func searchNearMyLocation() {
        guard searchNearMapCenter,
              let myLocation = OsmAndApp.swiftInstance().locationServices?.lastKnownLocation else { return }
        searchLocation = myLocation.coordinate
        distanceFromMyLocation = 0
        searchNearMapCenter = false
        searchAroundLocationChanged()
    }

    private func searchNearMapCenterLocation() {
        guard !searchNearMapCenter,
              let mapCenter = OARootViewController.instance()?.mapPanel?.mapViewController.getMapLocation() else { return }
        if let myLocation = OsmAndApp.swiftInstance().locationServices?.lastKnownLocation {
            distanceFromMyLocation = myLocation.distance(from: mapCenter)
        }
        searchLocation = mapCenter.coordinate
        searchNearMapCenter = true
        searchAroundLocationChanged()
    }

    private func searchAroundLocationChanged() {
        if addressSearch && tabsVisible {
            reloadCities()
        }
        if !searchQuery.isEmpty {
            runSearch()
        }
    }

    private func searchTextChanged() {
        let newQueryText = searchText
        processedSearchText = newQueryText
        hidePoi()
        hideToolbar()
        updateHint()

        let textEmpty = newQueryText.isEmpty
        searchController.searchBar.searchTextField.rightViewMode = textEmpty ? .never : .always
        if textEmpty {
            bottomViewVisible = false
        }
        updateTabsVisibility(textEmpty)
        showSearchIcon()
        if textEmpty && addressSearch {
            startAddressSearch()
        }
        if textEmpty && poiFilterApplied {
            poiFilterApplied = false
            reloadCategories()
        }
        if searchQuery.localizedCaseInsensitiveCompare(newQueryText) != .orderedSame {
            cancelResultPreparation()
            searchQuery = newQueryText
            if searchQuery.isEmpty {
                restoreInputLayout()
                searchUICore?.resetPhrase()
                searchUICore?.cancelSearch(false)
            } else {
                runSearch()
            }
        } else if runSearchFirstTime {
            runSearchFirstTime = false
            runSearch()
        }
    }

    private func showFilterScreen(_ filter: OAPOIUIFilter, filterByName: String?) {
        guard let filterViewController = OAPOIFilterViewController(filter: filter, filterByName: filterByName) else { return }
        filterViewController.delegate = self
        navigationController?.pushViewController(filterViewController, animated: true)
    }

    private func hideToolbar() {
        guard let searchToolbarViewController else { return }
        OARootViewController.instance().mapPanel.hideToolbar(searchToolbarViewController)
    }

    private func resetSearch() {
        updateTextField("")
    }

    private func updateBarActionView() {
        var barActionButtonVisible = !searchText.isEmpty
        if isTargetSearchType {
            let word = lastSelectedWord
            barActionButtonVisible = barActionButtonVisible
                && word?.result != nil
                && word?.getType() != .poiType
                && word?.getType() != .favoriteGroup
        }
        if barActionButtonVisible {
            setupBarActionView(isTargetSearchType ? .selectTarget : .showOnMap)
        } else {
            setupBarActionView(.none)
        }
    }

    private func setBottomViewVisible(_ visible: Bool) {
        bottomViewVisible = visible
        updateHeader()
    }

    private func updateHeader() {
        guard isViewLoaded else { return }
        let tabsHidden = !tabsVisible
        if tabsContainerView.isHidden != tabsHidden {
            tabsContainerView.isHidden = tabsHidden
        }
        let chipsHidden = !showsChips
        if chipsContainerView.isHidden != chipsHidden {
            chipsContainerView.isHidden = chipsHidden
        }
        updateChips()
        updateBottomToolbar(animated: view.window != nil)
    }

    private func updateChips() {
        guard isViewLoaded, showsChips else { return }
        let showsFilters = showsFiltersChip
        let state = ChipsState(searchNearMapCenter: searchNearMapCenter,
                               showsFilters: showsFilters,
                               filtersApplied: showsFilters && isPoiFilterApplied)
        guard state != chipsState else { return }
        chipsState = state
        chipsView.reloadData()
    }

    private func updateBottomToolbar(animated: Bool) {
        guard let navigationController, navigationController.topViewController === self else { return }
        let showsBarAction = barActionType != .none && (!modalInput || lastSelectedWord?.getLocation() != nil)
        let state = ToolbarState(barActionTitle: showsBarAction ? barActionTitle() : nil,
                                 showsSave: bottomViewVisible && !tabsVisible)
        guard state != toolbarState else { return }
        toolbarState = state

        var items: [UIBarButtonItem] = []
        if let barActionTitle = state.barActionTitle {
            let barActionItem = UIBarButtonItem(title: barActionTitle, style: .plain, target: self, action: #selector(onBarActionButtonPressed))
            barActionItem.tintColor = .iconColorActive
            if !state.showsSave {
                if #available(iOS 26.0, *) {
                    barActionItem.style = .prominent
                } else {
                    barActionItem.style = .done
                }
            }
            items.append(barActionItem)
        }
        if state.showsSave {
            let saveItem = UIBarButtonItem(title: localizedString("shared_string_save"), style: .plain, target: self, action: #selector(onSaveFilterButtonPressed))
            saveItem.tintColor = .iconColorActive
            items.append(saveItem)
        }

        switch items.count {
        case 2:
            toolbarItems = [items[0], .flexibleSpace(), items[1]]
        case 1:
            toolbarItems = state.barActionTitle != nil ? [.flexibleSpace(), items[0], .flexibleSpace()] : [.flexibleSpace(), items[0]]
        default:
            toolbarItems = nil
        }
        navigationController.setToolbarHidden(items.isEmpty, animated: animated)
    }

    private func barActionTitle() -> String {
        guard barActionType == .selectTarget else { return localizedString("shared_string_show_on_map") }
        let select = localizedString("shared_string_select")
        guard !searchText.isEmpty, let localeName = lastSelectedWord?.result?.localeName else { return select }
        return "\(select) \(localeName)"
    }

    private func presentOverSearch(_ controller: UIViewController) {
        let presenter: UIViewController = searchController.isActive ? searchController : self
        presenter.present(controller, animated: true)
    }

    private func presentAfterDeactivatingSearch(_ presentation: @escaping () -> Void) {
        guard searchController.isActive else {
            presentation()
            return
        }
        pendingPresentation = presentation
        searchController.isActive = false
    }

    private func focusSearchField() {
        searchController.searchBar.becomeFirstResponder()
    }

    private func showWaitingIndicator() {
        DispatchQueue.main.async {
            let searchTextField = self.searchController.searchBar.searchTextField
            guard searchTextField.leftView !== self.activityIndicatorView else { return }
            self.searchIconView = searchTextField.leftView
            self.activityIndicatorView.startAnimating()
            searchTextField.leftView = self.activityIndicatorView
        }
    }

    private func showSearchIcon() {
        DispatchQueue.main.async {
            let searchTextField = self.searchController.searchBar.searchTextField
            guard searchTextField.leftView === self.activityIndicatorView else { return }
            self.activityIndicatorView.stopAnimating()
            searchTextField.leftView = self.searchIconView
        }
    }

    @objc private func moveGestureDetected() {
        searchController.searchBar.resignFirstResponder()
    }

    @objc private func dismissTextEditing() {
        searchController.searchBar.resignFirstResponder()
    }

    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let tblMove else { return }
        view.addGestureRecognizer(tblMove)
    }

    @objc private func keyboardWillBeHidden(_ notification: Notification) {
        guard let tblMove else { return }
        view.removeGestureRecognizer(tblMove)
    }

    @objc private func updateDistanceAndDirection() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        if paused || cancelPrev || searchNearMapCenter || Date().timeIntervalSince1970 - lastUpdate < Self.distanceUpdateInterval {
            return
        }
        DispatchQueue.main.async {
            self.lastUpdate = Date().timeIntervalSince1970
            self.tableController?.updateDistanceAndDirection()
            self.exploreViewController?.updateDistanceAndDirection()
            self.addressViewController?.updateDistanceAndDirection()
        }
    }

    private func updateHint() {
        searchController.searchBar.placeholder = localizedString(addressSearch ? "type_address" : "search_poi_category_hint")
    }

    private func enterModalInputLayout() {
        modalInput = true
        updateHeader()
    }

    private func restoreInputLayout() {
        modalInput = false
        updateHeader()
    }

    private func restoreSearch() {
        if addressSearch {
            startAddressSearch()
        } else {
            stopAddressSearch()
        }
        if let storedOriginalLocation {
            searchUICore?.update(searchUICore?.getSearchSettings()?.setOriginalLocation(storedOriginalLocation))
            self.storedOriginalLocation = nil
        }
        restoreInputLayout()
    }

    private static func objectTypes(_ types: [EOAObjectType]) -> [OAObjectType] {
        types.map { OAObjectType.withType($0) }
    }

    private func startAddressSearch() {
        let searchTypes = Self.objectTypes([.city, .village, .postcode, .house, .streetIntersection, .street, .location, .partialLocation])
        let settings = searchUICore?.getSearchSettings()?
            .setEmptyQueryAllowed(true)?
            .setAddressSearch(true)?
            .setSortByName(false)?
            .setSearch(searchTypes)?
            .setRadiusLevel(1)
        searchUICore?.update(settings)
    }

    private func startCitySearch() {
        let settings = searchUICore?.getSearchSettings()?
            .setEmptyQueryAllowed(true)?
            .setAddressSearch(true)?
            .setSortByName(true)?
            .setSearch(Self.objectTypes([.city, .village]))?
            .setRadiusLevel(1)
        searchUICore?.update(settings)
        enterModalInputLayout()
    }

    private func startNearestCitySearch() {
        let settings = searchUICore?.getSearchSettings()?
            .setEmptyQueryAllowed(true)?
            .setAddressSearch(true)?
            .setSortByName(false)?
            .setSearch(Self.objectTypes([.city]))?
            .setRadiusLevel(1)
        searchUICore?.update(settings)
    }

    private func startLastCitySearch(_ latLon: CLLocation) {
        let settings = searchUICore?.getSearchSettings()
        storedOriginalLocation = settings?.getOriginalLocation()
        let citySettings = settings?
            .setEmptyQueryAllowed(true)?
            .setAddressSearch(true)?
            .setSortByName(false)?
            .setSearch(Self.objectTypes([.city]))?
            .setOriginalLocation(latLon)?
            .setRadiusLevel(1)
        searchUICore?.update(citySettings)
    }

    private func startPostcodeSearch() {
        let settings = searchUICore?.getSearchSettings()?
            .setSearch(Self.objectTypes([.postcode]))?
            .setEmptyQueryAllowed(false)?
            .setAddressSearch(true)?
            .setSortByName(true)?
            .setRadiusLevel(1)
        searchUICore?.update(settings)
        enterModalInputLayout()
    }

    private func stopAddressSearch() {
        let settings = searchUICore?.getSearchSettings()?
            .resetSearchTypes()?
            .setEmptyQueryAllowed(false)?
            .setSortByName(false)?
            .setAddressSearch(false)?
            .setRadiusLevel(1)
        searchUICore?.update(settings)
    }

    private func reloadCities() {
        if let citySearchedRect, let location = searchUICore?.getSearchSettings()?.getOriginalLocation() {
            let x = Double(KMapUtils.shared.get31TileNumberX(longitude: location.coordinate.longitude))
            let y = Double(KMapUtils.shared.get31TileNumberY(latitude: location.coordinate.latitude))
            if citySearchedRect.contains(x, top: y, right: x, bottom: y) {
                return
            }
        }
        startNearestCitySearch()
        runCoreSearch("", updateResult: false, searchMore: false, onSearchStarted: nil, onPublish: nil) { [weak self] phrase in
            guard let self else { return true }
            let resultCollection = self.currentResultCollection()
            let appSettings = OAAppSettings.sharedManager()
            self.citySearchedRect = phrase?.getRadiusBBox31(toSearch: 1000)

            var lastCity: OASearchResult?
            if let resultCollection {
                let results = resultCollection.getCurrentSearchResults() ?? []
                self.citiesLoaded = !results.isEmpty
                let lastCityId = appSettings.lastSearchedCity
                lastCity = results.first { $0.objectType == .city && ($0.object as? OAAddress)?.addrId == lastCityId }
            }

            var rows: [OAQuickSearchListItem] = []
            let lastCityName = lastCity == nil ? appSettings.lastSearchedCityName : lastCity?.localeName
            if let lastCityName, !lastCityName.isEmpty {
                rows.append(OAQuickSearchButtonListItem(icon: .icActionStreetName,
                                                        attributedText: Self.selectStreetsTitle(cityName: lastCityName)) { [weak self] _ in
                    self?.selectStreets(lastCity: lastCity, lastCityName: lastCityName)
                })
            }
            rows.append(OAQuickSearchButtonListItem(icon: .icActionBuildingNumber, text: localizedString("select_city")) { [weak self] _ in
                guard let self else { return }
                self.searchController.searchBar.placeholder = localizedString("type_city_town")
                self.startCitySearch()
                self.updateTabsVisibility(false)
                self.runCoreSearch("", updateResult: false, searchMore: false)
                self.focusSearchField()
            })
            rows.append(OAQuickSearchButtonListItem(icon: .icActionPostcode, text: localizedString("select_postcode")) { [weak self] _ in
                guard let self else { return }
                self.searchController.searchBar.placeholder = localizedString("type_postcode")
                self.startPostcodeSearch()
                self.updateData([], append: false)
                self.updateTabsVisibility(false)
                self.focusSearchField()
            })
            rows.append(OAQuickSearchButtonListItem(icon: .icCustomLocationMarker, text: localizedString("coords_search")) { [weak self] _ in
                guard let self else { return }
                let latLon = self.searchUICore?.getSearchSettings()?.getOriginalLocation()
                guard let coordinatesViewController = OAQuickSearchCoordinatesViewController(lat: latLon?.coordinate.latitude ?? 0,
                                                                                             lon: latLon?.coordinate.longitude ?? 0) else { return }
                let navigationController = UINavigationController(rootViewController: coordinatesViewController)
                navigationController.modalPresentationStyle = .fullScreen
                self.presentAfterDeactivatingSearch { [weak self] in
                    self?.present(navigationController, animated: true)
                }
            })

            var data: [[OAQuickSearchListItem]] = [rows]
            if let results = resultCollection?.getCurrentSearchResults(), !results.isEmpty {
                var cityRows: [OAQuickSearchListItem] = [OAQuickSearchHeaderListItem(name: localizedString("nearest_cities"))]
                cityRows.append(contentsOf: results.prefix(Self.nearestCitiesLimit).map { OAQuickSearchListItem(searchResult: $0) })
                data.append(cityRows)
            }
            self.addressViewController?.setData(data)
            return true
        }
        restoreSearch()
    }

    private static func selectStreetsTitle(cityName: String) -> NSAttributedString {
        let selectStreets = localizedString("select_street")
        let inCityName = String(format: localizedString("shared_string_in_name"), cityName)
        let title = NSMutableAttributedString(string: "\(selectStreets) \(inCityName)")
        let selectStreetsLength = (selectStreets as NSString).length
        title.addAttribute(.foregroundColor, value: UIColor.textColorActive, range: NSRange(location: 0, length: selectStreetsLength))
        title.addAttribute(.foregroundColor,
                           value: UIColor.textColorSecondary,
                           range: NSRange(location: selectStreetsLength + 1, length: (inCityName as NSString).length))
        return title
    }

    private func selectStreets(lastCity: OASearchResult?, lastCityName: String) {
        if let lastCity {
            completeQuery(with: lastCity)
        } else {
            let appSettings = OAAppSettings.sharedManager()
            let lastCityId = appSettings.lastSearchedCity
            if lastCityId != UInt64.max, let lastCityPoint = appSettings.lastSearchedPoint as CLLocation? {
                startLastCitySearch(lastCityPoint)
                var cityFound = false
                runCoreSearch("", updateResult: false, searchMore: false, onSearchStarted: { _ in }, onPublish: { [weak self] resultCollection, _ in
                    guard let result = resultCollection?.getCurrentSearchResults()?.first(where: {
                        $0.objectType == .city && ($0.object as? OAAddress)?.addrId == lastCityId
                    }) else { return }
                    cityFound = true
                    self?.completeQuery(with: result)
                }, onSearchFinished: { [weak self] _ in
                    if !cityFound {
                        self?.replaceQuery(withText: lastCityName + " ")
                    }
                    return false
                })
                restoreSearch()
            } else {
                replaceQuery(withText: lastCityName + " ")
            }
        }
        focusSearchField()
    }

    private func reloadCategories() {
        categoriesViewController?.reloadData()
    }

    private func hidePoi() {
        OAPOIFiltersHelper.sharedInstance().hidePoiFilters()
        OARootViewController.instance().mapPanel.mapViewController.updatePoiLayer()
    }

    private func updateData(_ rows: [OAQuickSearchListItem], append: Bool) {
        tableController?.updateData([rows], append: append)
    }

    private func updateTextField(_ text: String?) {
        let text = text ?? ""
        processedSearchText = text
        searchController.searchBar.text = text
        searchTextChanged()
    }

    private func addHistoryItem(_ searchResult: OASearchResult) {
        guard OAAppSettings.sharedManager().searchHistory.get(), !fromNavigation else { return }
        var item: OAHistoryItem?
        if searchResult.objectType == .gpxTrack {
            item = OAQuickSearchListItem.trackHistoryItem(searchResult)
        } else if searchResult.location != nil {
            item = OAQuickSearchListItem.historyItem(searchResult)
        }
        if let item {
            OAHistoryHelper.sharedInstance().addPoint(item)
        }
    }

    private func addCategoryHistoryItem(_ searchResult: OASearchResult) {
        guard OAAppSettings.sharedManager().searchHistory.get(),
              let item = OAQuickSearchListItem.categoryHistoryItem(searchResult) else { return }
        OAHistoryHelper.sharedInstance().addPoint(item)
    }

    private func createPOIUIFilter(with topIndexFilter: OATopIndexFilter) -> OAPOIUIFilter? {
        let filtersHelper: OAPOIFiltersHelper = .sharedInstance()
        if let filter = filtersHelper.getFilterById(topIndexFilter.getId()) {
            return filter
        }
        guard let resultCollection = searchHelper?.getResultCollection() else { return nil }
        let acceptedTypes = NSMapTable<OAPOICategory, NSMutableSet>.strongToStrongObjects()
        for result in resultCollection.getCurrentSearchResults() ?? [] {
            guard let poi = result.object as? OAPOI, let poiCategory = poi.type?.category else { continue }
            let subtypes: NSMutableSet
            if let existingSubtypes = acceptedTypes.object(forKey: poiCategory) {
                subtypes = existingSubtypes
            } else {
                subtypes = NSMutableSet()
                acceptedTypes.setObject(subtypes, forKey: poiCategory)
            }
            if let subType = poi.subType {
                subtypes.add(subType)
            }
        }
        return filtersHelper.getFilter(topIndexFilter, acceptedTypes: acceptedTypes)
    }

    private func setResultCollection(_ resultCollection: OASearchResultCollection?) {
        searchHelper?.setResultCollection(resultCollection)
    }

    private func currentResultCollection() -> OASearchResultCollection? {
        searchHelper?.getResultCollection()
    }

    private func runSearch() {
        runSearch(searchQuery)
    }

    private func runSearch(_ text: String) {
        showWaitingIndicator()
        resetRadiusLevel(searchUICore?.getSearchSettings())
        runCoreSearch(text, updateResult: true, searchMore: false)
    }

    private func resetRadiusLevel(_ settings: OASearchSettings?) {
        guard let settings, settings.getRadiusLevel() != 1 else { return }
        searchUICore?.update(settings.setRadiusLevel(1))
    }

    private func runCoreSearch(_ text: String, updateResult: Bool, searchMore: Bool) {
        showWaitingIndicator()
        runCoreSearch(text, updateResult: updateResult, searchMore: searchMore, onSearchStarted: nil, onPublish: { [weak self] resultCollection, append in
            self?.updateSearchResult(resultCollection, append: append)
        }, onSearchFinished: { [weak self] _ in
            guard let self else { return true }
            if let tableController = self.tableController,
               tableController.isShowResult(),
               self.isResultEmpty(),
               let lastSelectedWord = self.searchUICore?.getPhrase()?.getLastSelectedWord() {
                tableController.show(onMap: lastSelectedWord.result, searchType: tableController.searchType, delegate: tableController.delegate)
            }
            return true
        })
    }

    private func runCoreSearch(_ text: String,
                               updateResult: Bool,
                               searchMore: Bool,
                               onSearchStarted: SearchStartedCallback?,
                               onPublish: PublishCallback?,
                               onSearchFinished: SearchFinishedCallback?) {
        cancelResultPreparation()
        updateBarActionView()
        interruptedSearch = false
        cancelPrev = true

        var regionResultCollection: OASearchResultCollection?
        var regionResultApi: NSObject?
        var results: [OASearchResult] = []

        let matcher = OAResultMatcher<OASearchResult>(publishFunc: { [weak self] object in
            guard let self, let result = object?.pointee as? OASearchResult else { return false }
            if result.objectType == .searchStarted {
                self.cancelPrev = false
            }
            if self.paused || self.cancelPrev {
                return false
            }
            switch result.objectType {
            case .searchStarted:
                if let onSearchStarted {
                    DispatchQueue.main.async {
                        onSearchStarted(result.requiredSearchPhrase)
                    }
                }
            case .filterFinished:
                DispatchQueue.main.async {
                    self.updateSearchResult(self.searchUICore?.getCurrentSearchResult(), append: false)
                }
            case .searchFinished:
                DispatchQueue.main.async {
                    guard !self.paused else { return }
                    guard onSearchFinished?(result.requiredSearchPhrase) ?? true else { return }
                    self.showSearchIcon()
                    if self.isResultEmpty() {
                        self.addEmptyResult()
                    }
                    if self.isSearchMoreAvailable(result.requiredSearchPhrase) {
                        self.addMoreButton()
                    } else if let onPublish, self.isResultEmpty() {
                        onPublish(self.currentResultCollection(), false)
                        self.addEmptyResult()
                    }
                }
            case .searchApiFinished:
                let searchApi = result.object
                let regionCollection = regionResultCollection
                let hasRegionCollection = searchApi === regionResultApi && regionCollection != nil
                let apiResults = hasRegionCollection ? (regionCollection?.getCurrentSearchResults() ?? []) : results
                regionResultApi = nil
                regionResultCollection = nil
                results = []
                self.showApiResults(apiResults,
                                    phrase: result.requiredSearchPhrase,
                                    api: searchApi,
                                    hasRegionCollection: hasRegionCollection,
                                    onPublish: onPublish)
            case .searchApiRegionFinished:
                regionResultApi = result.object
                regionResultCollection = self.searchUICore?
                    .createResultCollection(for: result.requiredSearchPhrase, api: regionResultApi)?
                    .add(results, resortAll: true, removeDuplicates: true)
                self.showRegionResults(regionResultCollection, onPublish: onPublish)
            case .partialLocation:
                break
            default:
                results.append(result)
            }
            return true
        }, cancelledFunc: { [weak self] in
            guard let self else { return true }
            return self.paused || self.cancelPrev
        })

        searchUICore?.search(text, delayedExecution: updateResult, matcher: matcher)

        if !searchMore {
            setResultCollection(nil)
            if !updateResult {
                updateSearchResult(nil, append: false)
            }
        }
    }

    private func showApiResults(_ apiResults: [OASearchResult],
                                phrase: OASearchPhrase?,
                                api: NSObject?,
                                hasRegionCollection: Bool,
                                onPublish: PublishCallback?) {
        DispatchQueue.main.async {
            guard !self.paused && !self.cancelPrev else { return }
            let append = self.currentResultCollection() != nil
            let apiCollection = self.searchUICore?.createResultCollection(for: phrase, api: api)
            apiCollection?.add(apiResults, resortAll: true, removeDuplicates: true)
            if append {
                self.setResultCollection(self.currentResultCollection()?.combine(with: apiCollection, resort: true, removeDuplicates: true))
            } else {
                self.setResultCollection(apiCollection)
            }
            if !hasRegionCollection, let onPublish {
                onPublish(self.currentResultCollection(), append)
            }
        }
    }

    private func showRegionResults(_ regionResultCollection: OASearchResultCollection?, onPublish: PublishCallback?) {
        DispatchQueue.main.async {
            guard !self.paused && !self.cancelPrev, let onPublish else { return }
            if let resultCollection = self.currentResultCollection() {
                onPublish(resultCollection.combine(with: regionResultCollection, resort: true, removeDuplicates: true), true)
            } else {
                onPublish(regionResultCollection, false)
            }
        }
    }

    private func completeQuery(with searchResult: OASearchResult) {
        var result = searchResult
        addCategoryHistoryItem(result)
        if let additional = result.object as? OAPOIType,
           additional.isAdditional(),
           let parent = additional.parentType,
           let custom = OAPOIFiltersHelper.sharedInstance().getFilterById(STD_PREFIX + parent.name) {
            custom.clear()
            custom.updateTypes(toAccept:parent)
            custom.filterByName = additional.name.replacingOccurrences(of: "_", with: ":").lowercased(with: .current)

            result = OASearchResult(phrase: searchUICore?.getPhrase())
            result.localeName = custom.name
            result.object = custom
            result.priority = Double(SEARCH_AMENITY_TYPE_PRIORITY)
            result.priorityDistance = 0
            result.objectType = .poiType
        }
        searchUICore?.select(result)
        if addressSearch {
            startAddressSearch()
            if result.objectType == .city, let city = result.object as? OAAddress {
                let appSettings = OAAppSettings.sharedManager()
                appSettings.lastSearchedCity = city.addrId
                appSettings.lastSearchedCityName = result.localeName
                appSettings.lastSearchedPoint = CLLocation(latitude: city.latitude, longitude: city.longitude)
            }
        }
        let text = searchUICore?.getPhrase()?.getText(true) ?? ""
        searchQuery = text
        updateTextField(text)
        resetRadiusLevel(searchUICore?.getSearchSettings())
        runCoreSearch(text, updateResult: false, searchMore: false)
    }

    private func replaceQuery(withText text: String) {
        searchQuery = text
        updateTextField(text)
        resetRadiusLevel(searchUICore?.getSearchSettings())
        runCoreSearch(text, updateResult: false, searchMore: false)
    }

    private func replaceQuery(with filter: OAPOIUIFilter, nameFilter: String?) {
        guard let searchPhrase = searchUICore?.getPhrase(), searchPhrase.isLastWord(.poiType) else { return }
        poiFilterApplied = true
        let result = searchPhrase.getLastSelectedWord()?.result
        result?.object = filter
        result?.localeName = filter.getName()
        searchUICore?.getPhrase()?.syncWordsWithResults()
        var text = filter.getName() + " "
        if let nameFilter, !nameFilter.isEmpty, filter.isStandardFilter {
            text += nameFilter
        }
        searchQuery = text
        updateTextField(text)
        runCoreSearch(text, updateResult: false, searchMore: false)
    }

    private func clearLastWord() {
        guard !searchText.isEmpty else { return }
        updateTextField(searchUICore?.getPhrase()?.getTextWithoutLastWord())
    }

    private func isSearchMoreAvailable(_ phrase: OASearchPhrase?) -> Bool {
        currentResultCollection()?.hasMoreSpatialSearchResults() == true || searchUICore?.isSearchMoreAvailable(phrase) == true
    }

    private func showMoreSpatialSearchResults() -> Bool {
        guard let collection = currentResultCollection(), collection.showMoreSpatialSearchResults() else { return false }
        updateSearchResult(collection, append: false)
        if isSearchMoreAvailable(collection.phrase) {
            addMoreButton()
        }
        return true
    }

    private func increaseSearchRadius() {
        if showMoreSpatialSearchResults() {
            return
        }
        if !interruptedSearch, let settings = searchUICore?.getSearchSettings() {
            searchUICore?.update(settings.setRadiusLevel(settings.getRadiusLevel() + 1))
        }
        let spatialResults = currentResultCollection()?.isSkipSorting() == true
        runCoreSearch(searchQuery, updateResult: false, searchMore: !spatialResults)
    }

    private func addMoreButton() {
        if preparingResults {
            pendingMoreButton = true
            return
        }
        let name = localizedString(currentResultCollection()?.hasMoreSpatialSearchResults() == true ? "show_more" : "search_POI_level_btn")
        let moreListItem = OAQuickSearchMoreListItem(name: name) { [weak self] _ in
            self?.increaseSearchRadius()
        }
        if !paused && !cancelPrev {
            tableController?.add(moreListItem, groupIndex: 0)
            tableController?.reloadData()
        }
    }

    private func addEmptyResult() {
        if preparingResults {
            pendingEmptyResult = true
            return
        }
        let item = OAQuickSearchEmptyResultListItem()
        let phrase = searchUICore?.getPhrase()
        let minimalSearchRadius = searchUICore?.getMinimalSearchRadius(phrase) ?? 0
        if searchUICore?.isSearchMoreAvailable(phrase) == true && minimalSearchRadius != Int32.max {
            let roundedDistance = OAOsmAndFormatter.calculateRoundedDist(Double(minimalSearchRadius))
            let distance = OAOsmAndFormatter.getFormattedDistance(Float(roundedDistance), with: OsmAndFormatterParams.noTrailingZeros) ?? ""
            item.title = "\(localizedString("nothing_found")): \(distance)"
        }
        if !paused && !cancelPrev {
            tableController?.add(item, groupIndex: 0)
            tableController?.reloadData()
        }
    }

    private func cancelResultPreparation() {
        resultPresentationGeneration += 1
        resultPreparationQueue.cancelAllOperations()
        preparingResults = false
        pendingMoreButton = false
        pendingEmptyResult = false
    }

    private func displayPreparedResults(_ results: [OASearchResult], append: Bool) {
        updateData(results.map { OAQuickSearchListItem(searchResult: $0) }, append: append)
    }

    private func updateSearchResult(_ resultCollection: OASearchResultCollection?, append: Bool) {
        cancelResultPreparation()
        guard !paused else { return }
        guard let sharedCollection = resultCollection as? OASharedSearchResultCollection else {
            displayPreparedResults(resultCollection?.getVisibleSpatialSearchResults() ?? [], append: append)
            return
        }
        preparingResults = true
        let generation = resultPresentationGeneration
        let operation = BlockOperation()
        operation.addExecutionBlock { [weak self, weak operation] in
            guard let operation else { return }
            guard let results = sharedCollection.prepareVisibleResults(cancellation: { operation.isCancelled }),
                  !operation.isCancelled else { return }
            DispatchQueue.main.async {
                guard let self,
                      !operation.isCancelled,
                      self.resultPresentationGeneration == generation,
                      !self.paused,
                      !self.cancelPrev else { return }
                self.preparingResults = false
                self.displayPreparedResults(results, append: append)
                if self.pendingEmptyResult {
                    self.addEmptyResult()
                }
                if self.pendingMoreButton {
                    self.addMoreButton()
                }
                self.pendingEmptyResult = false
                self.pendingMoreButton = false
            }
        }
        resultPreparationQueue.addOperation(operation)
    }

    private func createAndRefreshCustomFilter(_ newFilter: OAPOIUIFilter, newName: String?) {
        guard let newName, !newName.isEmpty else { return }
        let filterToSave = OAPOIUIFilter(name: newName, filterId: nil, acceptedTypes: newFilter.getAcceptedTypes())
        if !newFilter.filterByName.isEmpty {
            filterToSave.savedFilterByName = newFilter.filterByName
        }
        guard OAPOIFiltersHelper.sharedInstance().createPoiFilter(filterToSave) else { return }
        searchHelper?.refreshCustomPoiFilters()
        replaceQuery(with: filterToSave, nameFilter: "")
        reloadCategories()
        navigationController?.popToRootViewController(animated: true)
    }

    private func isResultEmpty() -> Bool {
        (currentResultCollection()?.getVisibleSpatialSearchResults() ?? []).isEmpty
    }
}

extension QuickSearchViewController: UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard searchText != processedSearchText else { return }
        searchTextChanged()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        guard let presentation = pendingPresentation else { return }
        pendingPresentation = nil
        presentation()
    }
}

extension QuickSearchViewController: StarMapSearchSortFilterChipsDataSource, StarMapSearchSortFilterChipsDelegate {
    func chipGroups(for chipsView: StarMapSearchSortFilterChipsView) -> [SearchSortFilterChipGroup] {
        var groups = [searchAroundChipGroup()]
        if let chipsState, chipsState.showsFilters {
            groups.append(SearchSortFilterChipGroup(id: Self.filtersGroupId,
                                                    chipTitle: localizedString("shared_string_filters"),
                                                    chipImage: UIImage.icCustomFilter.resizedTemplateImage(with: Self.chipIconSize),
                                                    selectionMode: .toggle,
                                                    isToggleOn: chipsState.filtersApplied))
        }
        return groups
    }

    func chipsView(_ chipsView: StarMapSearchSortFilterChipsView, didSelectOption optionId: String, inGroup groupId: String) {
        guard groupId == Self.searchAroundGroupId else { return }
        if optionId == Self.nearMeOptionId {
            searchNearMyLocation()
        } else if optionId == Self.mapCenterOptionId {
            searchNearMapCenterLocation()
        }
    }

    func chipsView(_ chipsView: StarMapSearchSortFilterChipsView, didToggleGroup groupId: String, isOn: Bool) {
        guard groupId == Self.filtersGroupId else { return }
        openFilters()
    }

    private func searchAroundChipGroup() -> SearchSortFilterChipGroup {
        var mapCenterDescription: String?
        if let myLocation = OsmAndApp.swiftInstance().locationServices?.lastKnownLocation,
           let mapCenter = OARootViewController.instance()?.mapPanel?.mapViewController.getMapLocation() {
            let distance = OAOsmAndFormatter.getFormattedDistance(Float(myLocation.distance(from: mapCenter))) ?? ""
            mapCenterDescription = String(format: localizedString("search_around_map_center_description"), distance)
        }
        let nearMeOption = StarMapSearchSortFilterChipOption(id: Self.nearMeOptionId,
                                                             title: localizedString("search_near_me"),
                                                             image: nil,
                                                             originalSizeImage: UIImage.icCustomNavigationArrow.withRenderingMode(.alwaysTemplate),
                                                             isSelected: !searchNearMapCenter,
                                                             subtitle: localizedString("search_around_my_location_description"))
        let mapCenterOption = StarMapSearchSortFilterChipOption(id: Self.mapCenterOptionId,
                                                                title: localizedString("shared_string_map_center"),
                                                                image: nil,
                                                                originalSizeImage: UIImage.icCustomMapOutline.withRenderingMode(.alwaysTemplate),
                                                                isSelected: searchNearMapCenter,
                                                                subtitle: mapCenterDescription)
        let selectedOption = searchNearMapCenter ? mapCenterOption : nearMeOption
        return SearchSortFilterChipGroup(id: Self.searchAroundGroupId,
                                         chipTitle: selectedOption.title,
                                         chipImage: selectedOption.originalSizeImage?.resizedTemplateImage(with: Self.chipIconSize),
                                         selectionMode: .single,
                                         sections: [StarMapSearchSortFilterChipSection(options: [nearMeOption, mapCenterOption])])
    }
}

extension QuickSearchViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if viewController === exploreViewController {
            return nil
        }
        if viewController === addressViewController {
            return categoriesViewController
        }
        return exploreViewController
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if viewController === addressViewController {
            return nil
        }
        if viewController === categoriesViewController {
            return addressViewController
        }
        return categoriesViewController
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        let prevTabIndex = tabsControl.selectedSegmentIndex
        let currentViewController = pageViewController.viewControllers?.first
        if currentViewController === exploreViewController {
            tabsControl.selectedSegmentIndex = 0
        } else if currentViewController === categoriesViewController {
            tabsControl.selectedSegmentIndex = 1
        } else {
            tabsControl.selectedSegmentIndex = 2
        }
        if prevTabIndex != tabsControl.selectedSegmentIndex {
            processTabChange()
        }
    }
}

extension QuickSearchViewController: OAQuickSearchTableDelegate {
    func didSelect(_ result: OASearchResult) {
        if result.objectType == .suggestion {
            let query = result.localeName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            replaceQuery(withText: query + " ")
        } else {
            completeQuery(with: result)
        }
    }

    func didShow(onMap result: OASearchResult) {
        hideToolbar()
        addHistoryItem(result)
        dismissSearch(animated: true)
    }

    func closeSearch() {
        hideToolbar()
        dismissSearch(animated: true)
    }
}

extension QuickSearchViewController: OAAddressTableDelegate {
    func reloadAddressData() {
        reloadCities()
    }
}

extension QuickSearchViewController: CategoriesViewControllerDelegate {
    func categoriesDidSelectResult(_ result: OASearchResult) {
        didSelect(result)
    }

    func categoriesDidRequestAddFilter() {
        guard let filter = OAPOIFiltersHelper.sharedInstance().getCustomPOIFilter() else { return }
        filter.clear()
        let customPOIScreen = OACustomPOIViewController(filter: filter)
        customPOIScreen.delegate = self
        navigationController?.pushViewController(customPOIScreen, animated: true)
    }

    func categoriesDidRequestRearrangeFilters(_ filters: [OAPOIUIFilter]) {
        guard let rearrangeCategoriesScreen = OARearrangeCustomFiltersViewController(filters: filters) else { return }
        navigationController?.pushViewController(rearrangeCategoriesScreen, animated: true)
    }

    func categoriesDidRequestDeleteFilters(_ filters: [OAPOIUIFilter]) {
        let removeFiltersScreen = OADeleteCustomFiltersViewController(filters: filters)
        removeFiltersScreen.delegate = self
        navigationController?.pushViewController(removeFiltersScreen, animated: true)
    }
}

extension QuickSearchViewController: ExploreViewControllerDelegate {
    func exploreDidSelectHistoryItem(_ item: OAHistoryItem) {
        if item.hType == .poiType || item.hType == .poiFilter {
            if let searchResult = OASearchHistoryAPI.searchResult(for: item) {
                navigationController?.popToViewController(self, animated: true)
                completeQuery(with: searchResult)
            }
            return
        }
        if item.hType == .gpxFile {
            if let searchResult = OASearchHistoryAPI.searchResult(for: item) {
                tableController?.show(onMap: searchResult, searchType: searchType, delegate: self)
            }
            return
        }
        if searchType == .REGULAR {
            let appSettings = OAAppSettings.sharedManager()
            OAQuickSearchTableController.showHistoryItem(onMap: item,
                                                         lang: appSettings.settingPrefMapLanguage.get(),
                                                         transliterate: appSettings.settingMapLanguageTranslit.get(),
                                                         preferredZoom: item.preferredZoom())
        } else if isTargetSearchType {
            let pointDescription = OAPointDescription(type: POINT_TYPE_LOCATION, typeName: item.typeName, name: item.name)
            let location = CLLocation(latitude: item.latitude, longitude: item.longitude)
            if Self.routeTargetSearchTypes.contains(searchType) {
                OARootViewController.instance().mapPanel.setRouteTargetPoint(searchType == .DESTINATION,
                                                                             intermediate: searchType == .INTERMEDIATE,
                                                                             latitude: item.latitude,
                                                                             longitude: item.longitude,
                                                                             pointDescription: pointDescription)
            } else if searchType == .HOME {
                OATargetPointsHelper.sharedInstance().setHomePoint(location, description: pointDescription)
            } else if searchType == .WORK {
                OATargetPointsHelper.sharedInstance().setWorkPoint(location, description: pointDescription)
            }
        }
        dismissSearch(animated: true)
    }

    func exploreDidSelectPopularPlace(_ poi: OAPOI) {
        let searchResult: OASearchResult = OASearchResult(phrase: searchUICore?.getPhrase())
        searchResult.object = poi
        searchResult.objectType = .poi
        searchResult.localeName = poi.nameLocalized?.isEmpty == false ? poi.nameLocalized : poi.name
        searchResult.location = poi.getLocation()
        searchResult.preferredZoom = PREFERRED_POI_ZOOM
        searchResult.cityName = poi.cityName
        tableController?.show(onMap: searchResult, searchType: searchType, delegate: self)
    }

    func exploreDidRequestShowPopularPlacesOnMap() {
        let filtersHelper: OAPOIFiltersHelper = .sharedInstance()
        guard let filter = filtersHelper.getTopWikiPoiFilter() else { return }
        filtersHelper.replaceSelectedPoiFilters(filter)
        OARootViewController.instance().mapPanel.mapViewController.updatePoiLayer()
        showToolbar(filter)
        searchToolbarViewController?.toolbarTitle = localizedString("popular_places")
        dismissSearch(animated: true)
    }
}

extension QuickSearchViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

extension QuickSearchViewController: OAPOIFilterViewDelegate {
    func update(_ filter: OAPOIUIFilter, nameFilter: String) -> Bool {
        searchHelper?.refreshCustomPoiFilters()
        replaceQuery(with: filter, nameFilter: nameFilter)
        return true
    }

    func remove(_ filter: OAPOIUIFilter) -> Bool {
        guard OAPOIFiltersHelper.sharedInstance().removePoiFilter(filter) else { return false }
        searchHelper?.refreshCustomPoiFilters()
        reloadCategories()
        clearLastWord()
        return true
    }

    func createSaveFilterDialog(_ filter: OAPOIUIFilter, customSaveAction: Bool) -> UIAlertController {
        let saveDialog = UIAlertController(title: localizedString("access_hint_enter_name"),
                                           message: localizedString("new_filter_desc"),
                                           preferredStyle: .alert)
        saveDialog.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        if !customSaveAction {
            saveDialog.addAction(UIAlertAction(title: localizedString("shared_string_save"), style: .default) { [weak self, weak saveDialog] _ in
                self?.search(by: filter, newName: saveDialog?.textFields?.first?.text, willSaved: true)
            })
        }
        saveDialog.addTextField { textField in
            textField.text = filter.name
        }
        return saveDialog
    }

    func search(by filter: OAPOIUIFilter, newName: String?, willSaved: Bool) {
        let result: OASearchResult = OASearchResult(phrase: searchUICore?.getPhrase())
        result.localeName = filter.getName()
        result.object = filter
        result.priority = 0
        result.objectType = .poiType
        searchUICore?.select(result)
        setBottomViewVisible(!willSaved)

        let text = filter.getName() + " "
        searchQuery = text
        updateTextField(text)
        resetRadiusLevel(searchUICore?.getPhrase()?.getSettings())
        runCoreSearch(text, updateResult: false, searchMore: false)

        if willSaved {
            createAndRefreshCustomFilter(filter, newName: newName)
        }
    }
}

extension QuickSearchViewController: OASearchToolbarViewControllerProtocol {
    func searchToolbarOpenSearch(_ filter: OAPOIUIFilter?) {
        if let filter, filter.filterId == BY_NAME_FILTER_ID {
            OAPOIFiltersHelper.sharedInstance().removeSelectedPoiFilter(filter)
        }
        let mapPanel = OARootViewController.instance().mapPanel
        if let filter {
            hideToolbar()
            mapPanel?.openSearch(filter,
                                 location: CLLocation(latitude: searchLocation.latitude, longitude: searchLocation.longitude),
                                 searchQuery: searchQuery)
        } else {
            mapPanel?.openSearch()
        }
    }

    func searchToolbarClose() {
        resetSearch()
        OAPOIFiltersHelper.sharedInstance().clearSelectedPoiFilters()
        let mapPanel = OARootViewController.instance().mapPanel
        mapPanel?.mapViewController.updatePoiLayer()
        hideToolbar()
    }
}

extension QuickSearchViewController: OAPOIFiltersRemoveDelegate {
    func remove(_ filters: [OAPOIUIFilter]) -> Bool {
        let filtersHelper: OAPOIFiltersHelper = .sharedInstance()
        var removed = true
        for filter in filters where !filtersHelper.removePoiFilter(filter) {
            removed = false
        }
        searchHelper?.refreshCustomPoiFilters()
        reloadCategories()
        return removed
    }
}
