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
    case editHistory
    case selectTarget
}

final class QuickSearchViewController: OASuperViewController {
    private typealias SearchStartedCallback = (OASearchPhrase?) -> Void
    private typealias PublishCallback = (OASearchResultCollection?, Bool) -> Void
    private typealias SearchFinishedCallback = (OASearchPhrase?) -> Bool

    private static let initialSearchToolbarHeight: CGFloat = 44
    private static let barActionViewHeight: CGFloat = 44
    private static let tabsHeight: CGFloat = 40
    private static let bottomViewHeight: CGFloat = 57
    private static let cancelButtonY: CGFloat = 5
    private static let leftImageButtonY: CGFloat = -2
    private static let inputOffset: CGFloat = 40
    private static let minStatusBarHeight: CGFloat = 10
    private static let animationDuration: TimeInterval = 0.25
    private static let distanceUpdateInterval: TimeInterval = 0.3
    private static let nearestCitiesLimit = 15
    private static let topIndexBrandPrefix = "top_index_brand"
    private static let targetSearchTypes: [OAQuickSearchType] = [.START_POINT, .DESTINATION, .INTERMEDIATE, .HOME, .WORK]
    private static let routeTargetSearchTypes: [OAQuickSearchType] = [.START_POINT, .DESTINATION, .INTERMEDIATE]

    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var leftImageButton: UIButton!
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var btnCancel: UIButton!
    @IBOutlet private weak var searchNearCenterView: UIView!
    @IBOutlet private weak var lbSearchNearCenter: UILabel!
    @IBOutlet private weak var btnMyLocation: UIButton!
    @IBOutlet private weak var barActionView: UIView!
    @IBOutlet private weak var barActionLeftImageButton: UIButton!
    @IBOutlet private weak var barActionImageView: UIImageView!
    @IBOutlet private weak var barActionTextButton: UIButton!
    @IBOutlet private weak var barActionImageButton: UIButton!
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var bottomTextBtn: UIButton!
    @IBOutlet private weak var bottomImageBtn: UIButton!
    @IBOutlet private weak var tabs: UISegmentedControl!

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

    private var tblMove: UIPanGestureRecognizer?
    private var dismissEditingTap: UITapGestureRecognizer?
    private let leftImgView = UIImageView(image: .searchIcon)
    private let activityIndicatorView = UIActivityIndicatorView(style: .medium)

    private var tableController: OAQuickSearchTableController?
    private var pageController: UIPageViewController?
    private var addressViewController: OAAddressTableViewController?
    private var categoriesViewController: CategoriesViewController?
    private var exploreViewController: ExploreViewController?
    private var searchToolbarViewController: OASearchToolbarViewController?

    private var barActionType: QuickSearchBarAction = .none
    private var historyEditing = false
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

    private var isTargetSearchType: Bool {
        Self.targetSearchTypes.contains(searchType)
    }

    private var tabsVisible: Bool {
        pageController?.parent != nil
    }

    @objc init() {
        super.init(nibName: "QuickSearchViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func applyLocalization() {
        btnCancel.setTitle(localizedString("shared_string_hide"), for: .normal)
        bottomTextBtn.setTitle(localizedString("shared_string_save"), for: .normal)
    }

    override func registerObservers() {
        let locationServices = OsmAndApp.swiftInstance().locationServices
        _ = addObserver(OAAutoObserverProxy(self, withHandler: #selector(updateDistanceAndDirection), andObserve: locationServices?.updateLocationObserver))
        _ = addObserver(OAAutoObserverProxy(self, withHandler: #selector(updateDistanceAndDirection), andObserve: locationServices?.updateHeadingObserver))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let dismissEditingTap = UITapGestureRecognizer(target: self, action: #selector(dismissTextEditing))
        dismissEditingTap.cancelsTouchesInView = false
        dismissEditingTap.delegate = self
        view.addGestureRecognizer(dismissEditingTap)
        self.dismissEditingTap = dismissEditingTap
        tableView.separatorColor = SeparatorAppearance.color

        tableView.contentInsetAdjustmentBehavior = .never
        let tableController = OAQuickSearchTableController(tableView: tableView)
        tableController?.delegate = self
        tableController?.searchType = searchType
        if searchNearMapCenter {
            tableController?.setMapCenter(searchLocation)
        } else {
            tableController?.resetMapCenterSearch()
        }
        self.tableController = tableController

        bottomView.layer.shadowColor = UIColor.black.cgColor
        bottomView.layer.shadowOpacity = 0.3
        bottomView.layer.shadowRadius = 3
        bottomView.layer.shadowOffset = .zero
        bottomView.isHidden = true

        let pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageController.dataSource = self
        pageController.delegate = self
        pageController.view.frame = tableView.frame
        pageController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.pageController = pageController

        let addressViewController = OAAddressTableViewController(frame: pageController.view.bounds)
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

        tabs.setTitle(localizedString("shared_string_explore"), forSegmentAt: 0)
        tabs.setTitle(localizedString("search_categories"), forSegmentAt: 1)
        tabs.setTitle(localizedString("shared_string_address"), forSegmentAt: 2)
        tabs.setTitleTextAttributes([.font: UIFont.scaledSystemFont(ofSize: 14)], for: .normal)
        tabs.setTitleTextAttributes([.font: UIFont.scaledSystemFont(ofSize: 14)], for: .selected)

        let tblMove = UIPanGestureRecognizer(target: self, action: #selector(moveGestureDetected))
        tblMove.delegate = self
        self.tblMove = tblMove

        let leftView = UIView(frame: CGRect(x: 4, y: 0, width: 24, height: textField.bounds.height))
        textField.leftView = leftView
        textField.leftViewMode = .always
        activityIndicatorView.frame = leftView.frame
        leftImgView.contentMode = .center
        leftImgView.frame = leftView.frame
        leftView.addSubview(leftImgView)
        leftView.addSubview(activityIndicatorView)

        applyTabIndex()
        setupSearch()
        updateHint()

        showSearchIcon()
        updateSearchNearMapCenterLabel()
        showTabs()
        if textField.isDirectionRTL() {
            textField.textAlignment = .right
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        paused = false
        setupView()
        registerForKeyboardNotifications()
        super.viewWillAppear(animated)

        if let resultCollection = currentResultCollection() {
            updateSearchResult(resultCollection, append: false)
            if interruptedSearch || isSearchMoreAvailable(searchUICore?.getPhrase()) {
                addMoreButton()
            }
        }
        if !searchQuery.isEmpty {
            updateTextField(searchQuery)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showSearchIcon()
        textField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        paused = true
        cancelResultPreparation()
        unregisterKeyboardNotifications()
        OARootViewController.instance().keyCommandUpdateObserver.handleObservedEvent(from: nil, withKey: kCommandSearchScreenClose)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateNavbar()
    }

    @objc func setupBarActionView(_ type: QuickSearchBarAction, title: String?) {
        switch type {
        case .selectTarget:
            barActionLeftImageButton?.isHidden = true
            barActionImageView?.image = .icCustomLocationMarker
            barActionImageView?.isHidden = false
            let word = searchUICore?.getPhrase()?.getLastSelectedWord()
            UIView.performWithoutAnimation {
                let select = localizedString("shared_string_select")
                var buttonTitle = select
                if let title {
                    buttonTitle = title
                } else if !(textField?.text ?? "").isEmpty, let result = word?.result {
                    buttonTitle = "\(select) \(result.localeName ?? "")"
                }
                barActionTextButton?.setTitle(buttonTitle, for: .normal)
                barActionTextButton?.layoutIfNeeded()
            }
            barActionTextButton?.isHidden = false
            barActionTextButton?.isUserInteractionEnabled = true
            barActionImageButton?.isHidden = true
        case .showOnMap:
            barActionLeftImageButton?.isHidden = true
            barActionImageView?.image = .icCustomMap.withRenderingMode(.alwaysTemplate)
            barActionImageView?.isHidden = false
            let word = searchUICore?.getPhrase()?.getLastSelectedWord()
            UIView.performWithoutAnimation {
                var buttonTitle = localizedString("shared_string_show_on_map")
                if let title {
                    buttonTitle = title
                } else if !(textField?.text ?? "").isEmpty, let result = word?.result {
                    buttonTitle = String(format: localizedString("show_something_on_map"), result.localeName ?? "")
                }
                barActionTextButton?.setTitle(buttonTitle, for: .normal)
                barActionTextButton?.layoutIfNeeded()
            }
            barActionTextButton?.isHidden = false
            barActionTextButton?.isUserInteractionEnabled = true
            barActionImageButton?.setImage(.icSearchFilter, for: .normal)
            barActionImageButton?.isHidden = word?.getType() != .poiType
        case .editHistory:
            barActionImageView?.isHidden = true
            barActionLeftImageButton?.setImage(.icClose, for: .normal)
            barActionLeftImageButton?.isHidden = false
            UIView.performWithoutAnimation {
                barActionTextButton?.setTitle(title, for: .normal)
                barActionTextButton?.layoutIfNeeded()
            }
            barActionTextButton?.isHidden = false
            barActionTextButton?.isUserInteractionEnabled = false
            barActionImageButton?.setImage(.iconRemove, for: .normal)
            barActionImageButton?.isHidden = false
        case .none:
            break
        }
        barActionType = type
        if isViewLoaded {
            view.setNeedsLayout()
        }
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
            toolbar.toolbarTitle = textField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        OARootViewController.instance().mapPanel.showToolbar(toolbar)
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
        updateSearchNearMapCenterLabel()
        view.setNeedsLayout()
    }

    private func applySearchLocation() {
        exploreViewController?.searchLocation = searchLocation
        let settings = searchUICore?.getSearchSettings()?
            .setOriginalLocation(CLLocation(latitude: searchLocation.latitude, longitude: searchLocation.longitude))
        searchUICore?.update(settings)
        if isViewLoaded {
            view.setNeedsLayout()
        }
    }

    private func applySearchType() {
        addressViewController?.searchType = searchType
        tableController?.searchType = searchType
        updateBarActionView()
    }

    private func applyTabIndex() {
        tabs.selectedSegmentIndex = tabIndex
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
        view.addSubview(pageController.view)
        pageController.view.frame = tableView.frame
        tabs.isHidden = false
        tableView.isHidden = true
        pageController.didMove(toParent: self)
    }

    private func hideTabs() {
        tabs?.isHidden = true
        tableView?.isHidden = false
        pageController?.view.removeFromSuperview()
        pageController?.removeFromParent()
    }

    @IBAction private func tabChanged(_ sender: Any?) {
        moveGestureDetected()
        if let pageController, let exploreViewController, let categoriesViewController, let addressViewController {
            switch tabs.selectedSegmentIndex {
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
        addressSearch = tabs.selectedSegmentIndex == 2
        updateHint()
        if !(addressSearch && !citiesLoaded) {
            restoreSearch()
        }
    }

    @IBAction private func leftImgButtonPress(_ sender: Any) {
        restoreInputLayout()
        resetSearch()
        if addressSearch && tabsVisible {
            reloadCities()
        }
    }

    @IBAction private func barActionTextButtonPress(_ sender: Any) {
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
            dismiss(animated: true)
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
            dismiss(animated: true) {
                guard let mapPanel else { return }
                mapPanel.displayArea(onMap: topLeft, bottomRight: bottomRight, maxZoom: Float(PREFERRED_FAVORITE_ZOOM), screenBBox: mapPanel.view.bounds.size, bottomInset: 0, leftInset: 0, topInset: 0)
            }
        } else if let word = searchPhrase.getLastSelectedWord(), word.getLocation() != nil {
            tableController?.show(onMap: word.result, searchType: searchType, delegate: self)
        }
    }

    @IBAction private func barActionLeftImgButtonPress(_ sender: Any) {
        if barActionType == .editHistory {
            finishHistoryEditing()
        }
    }

    @IBAction private func barActionImgButtonPress(_ sender: Any) {
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

    @IBAction private func bottomTextButtonPress(_ sender: Any) {
        guard let customFilter = OAPOIFiltersHelper.sharedInstance().getCustomPOIFilter() else { return }
        present(createSaveFilterDialog(customFilter, customSaveAction: false), animated: true)
    }

    @IBAction private func bottomImageButtonPress(_ sender: Any) {
        setBottomViewVisible(false)
    }

    @IBAction private func btnCancelClicked(_ sender: Any) {
        dismiss(animated: true, completion: onCloseCallback)
    }

    @IBAction private func btnMyLocationClicked(_ sender: Any) {
        guard searchNearMapCenter,
              let newLocation = OsmAndApp.swiftInstance().locationServices?.lastKnownLocation else { return }

        searchLocation = newLocation.coordinate
        searchNearMapCenter = false
        UIView.animate(withDuration: Self.animationDuration) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            if self.addressSearch && self.tabsVisible {
                self.reloadCities()
            }
        }
    }

    @IBAction private func textFieldValueChanged(_ sender: Any?) {
        hidePoi()
        hideToolbar()
        updateHint()

        let newQueryText = textField?.text ?? ""
        let textEmpty = newQueryText.isEmpty
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

        if isViewLoaded {
            view.setNeedsLayout()
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
        guard !historyEditing else { return }
        var barActionButtonVisible = !(textField?.text ?? "").isEmpty
        if isTargetSearchType {
            let word = searchUICore?.getPhrase()?.getLastSelectedWord()
            barActionButtonVisible = barActionButtonVisible
                && word?.result != nil
                && word?.getType() != .poiType
                && word?.getType() != .favoriteGroup
        }
        if barActionButtonVisible {
            setupBarActionView(isTargetSearchType ? .selectTarget : .showOnMap, title: nil)
        } else {
            setupBarActionView(.none, title: nil)
        }
    }

    private func setBottomViewVisible(_ visible: Bool) {
        if visible {
            if !bottomViewVisible {
                bottomView.isHidden = false
                UIView.animate(withDuration: Self.animationDuration) {
                    let bottomMargin = OAUtilities.getBottomMargin()
                    self.bottomView.frame = CGRect(x: 0,
                                                   y: self.view.frame.height - Self.bottomViewHeight - bottomMargin,
                                                   width: self.view.frame.width,
                                                   height: Self.bottomViewHeight + bottomMargin)
                    var tableFrame = self.tableView.frame
                    tableFrame.size.height -= self.bottomView.frame.height
                    self.tableView.frame = tableFrame
                }
            }
            bottomViewVisible = true
        } else {
            if bottomViewVisible {
                UIView.animate(withDuration: Self.animationDuration) {
                    self.bottomView.frame = CGRect(x: 0, y: self.view.frame.height + 1, width: self.view.frame.width, height: Self.bottomViewHeight)
                    var tableFrame = self.tableView.frame
                    tableFrame.size.height = self.view.frame.height - tableFrame.origin.y
                    self.tableView.frame = tableFrame
                } completion: { _ in
                    self.bottomView.isHidden = true
                }
            }
            bottomViewVisible = false
        }
    }

    private func finishHistoryEditing() {
        historyEditing = false
        setupBarActionView(.none, title: nil)
    }

    private func updateNavbar() {
        guard isViewLoaded else { return }
        let lastWord = searchUICore?.getPhrase()?.getLastSelectedWord()
        let hasLastWordWithLocation = lastWord?.getLocation() != nil
        let showBarActionView = barActionType != .none && (!modalInput || hasLastWordWithLocation)
        let showInputView = barActionType != .editHistory
        let showMapCenterSearch = !showBarActionView && searchNearMapCenter && searchQuery.isEmpty && distanceFromMyLocation > 0
        let showTabs = tabsVisible && barActionType != .editHistory
        var topViewFrame = topView.frame
        let statusBarHeight = max(Self.minStatusBarHeight, view.safeAreaInsets.top)
        let margins = view.layoutMargins
        let contentWidth = view.bounds.width - margins.left - margins.right
        let cancelFittingWidth = btnCancel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: btnCancel.bounds.height)).width
        let cancelWidth = max(btnCancel.bounds.width, ceil(cancelFittingWidth) + 8)
        topViewFrame.size.height = (showInputView ? Self.initialSearchToolbarHeight + statusBarHeight : statusBarHeight)
            + (showMapCenterSearch || showBarActionView ? Self.barActionViewHeight : 0)
            + (showTabs ? Self.tabsHeight : 0)

        textField.isHidden = !showInputView
        btnCancel.isHidden = !showInputView || modalInput
        barActionView.isHidden = !showBarActionView
        searchNearCenterView.isHidden = !showMapCenterSearch
        tabs.isHidden = !showTabs

        barActionView.frame = CGRect(x: 0,
                                     y: showInputView ? Self.inputOffset + statusBarHeight : statusBarHeight,
                                     width: topViewFrame.width,
                                     height: barActionView.bounds.height)
        adjustViewPosition(searchNearCenterView, byHeight: showInputView ? Self.inputOffset : 0)

        let actionLeft = max(margins.left, view.safeAreaInsets.left)
        let actionRight = view.bounds.width - max(margins.right, view.safeAreaInsets.right)
        var actionImageFrame = barActionImageView.frame
        actionImageFrame.origin.x = actionLeft
        barActionImageView.frame = actionImageFrame
        var actionLeftButtonFrame = barActionLeftImageButton.frame
        actionLeftButtonFrame.origin.x = actionLeft
        barActionLeftImageButton.frame = actionLeftButtonFrame
        var actionRightButtonFrame = barActionImageButton.frame
        actionRightButtonFrame.origin.x = actionRight - actionRightButtonFrame.width
        barActionImageButton.frame = actionRightButtonFrame
        var actionTextFrame = barActionTextButton.frame
        actionTextFrame.origin.x = actionImageFrame.maxX
        actionTextFrame.size.width = max(0, actionRightButtonFrame.minX - actionTextFrame.origin.x)
        barActionTextButton.frame = actionTextFrame

        var nearbyButtonFrame = btnMyLocation.frame
        nearbyButtonFrame.origin.x = actionRight - nearbyButtonFrame.width
        btnMyLocation.frame = nearbyButtonFrame
        var nearbyLabelFrame = lbSearchNearCenter.frame
        nearbyLabelFrame.origin.x = actionLeft + 10
        nearbyLabelFrame.size.width = max(0, nearbyButtonFrame.origin.x - nearbyLabelFrame.origin.x)
        lbSearchNearCenter.frame = nearbyLabelFrame

        adjustViewPosition(btnCancel, byHeight: Self.cancelButtonY)
        adjustViewPosition(leftImageButton, byHeight: Self.leftImageButtonY)

        if modalInput {
            leftImageButton.isHidden = false
            var buttonFrame = leftImageButton.frame
            buttonFrame.origin.x = max(view.safeAreaInsets.left, margins.left - 8)
            leftImageButton.frame = buttonFrame
            let fieldX = buttonFrame.maxX
            textField.frame = CGRect(x: fieldX,
                                     y: 5 + statusBarHeight,
                                     width: max(0, view.bounds.width - margins.right - fieldX),
                                     height: textField.frame.height)
        } else {
            leftImageButton.isHidden = true
            textField.frame = CGRect(x: margins.left,
                                     y: 5 + statusBarHeight,
                                     width: max(0, contentWidth - cancelWidth - 8),
                                     height: textField.frame.height)
            tabs.frame = CGRect(x: margins.left, y: tabs.frame.origin.y, width: contentWidth, height: tabs.frame.height)
            btnCancel.frame = CGRect(x: view.bounds.width - margins.right - cancelWidth,
                                     y: btnCancel.frame.origin.y,
                                     width: cancelWidth,
                                     height: btnCancel.frame.height)
        }

        topView.frame = topViewFrame
        let bottomOffset = bottomViewVisible ? view.frame.height - bottomView.frame.origin.y : 0
        tableView.frame = CGRect(x: 0,
                                 y: topViewFrame.height,
                                 width: topViewFrame.width,
                                 height: view.frame.height - topViewFrame.height - bottomOffset)
        pageController?.view.frame = tableView.frame
    }

    private func updateSearchNearMapCenterLabel() {
        let distance = OAOsmAndFormatter.getFormattedDistance(Float(distanceFromMyLocation)) ?? ""
        lbSearchNearCenter.text = "\(localizedString("you_searching")) \(distance) \(localizedString("from_location"))"
    }

    private func adjustViewPosition(_ targetView: UIView, byHeight height: CGFloat) {
        var frame = targetView.frame
        frame.origin.y = max(Self.minStatusBarHeight, view.safeAreaInsets.top) + height
        targetView.frame = frame
    }

    private func showWaitingIndicator() {
        DispatchQueue.main.async {
            self.leftImgView.isHidden = true
            self.activityIndicatorView.isHidden = false
            self.activityIndicatorView.startAnimating()
        }
    }

    private func showSearchIcon() {
        DispatchQueue.main.async {
            self.activityIndicatorView.isHidden = true
            self.leftImgView.isHidden = false
        }
    }

    @objc private func moveGestureDetected() {
        textField?.resignFirstResponder()
    }

    @objc private func dismissTextEditing() {
        textField?.resignFirstResponder()
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
        DispatchQueue.main.async {
            if let tblMove = self.tblMove {
                self.view.addGestureRecognizer(tblMove)
            }
            let userInfo = notification.userInfo
            let keyboardFrame = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
            let keyboardHeight = self.view.convert(keyboardFrame, from: nil).height
            let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurve = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0
            guard self.bottomViewVisible else { return }
            UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: animationCurve)) {
                self.bottomView.frame = CGRect(x: 0,
                                               y: self.view.frame.height - keyboardHeight - Self.bottomViewHeight,
                                               width: self.view.frame.width,
                                               height: Self.bottomViewHeight)
            }
        }
    }

    @objc private func keyboardWillBeHidden(_ notification: Notification) {
        DispatchQueue.main.async {
            if let tblMove = self.tblMove {
                self.view.removeGestureRecognizer(tblMove)
            }
            let userInfo = notification.userInfo
            let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurve = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0
            guard self.bottomViewVisible else { return }
            UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: animationCurve)) {
                let bottomMargin = OAUtilities.getBottomMargin()
                self.bottomView.frame = CGRect(x: 0,
                                               y: self.view.frame.height - Self.bottomViewHeight - bottomMargin,
                                               width: self.view.frame.width,
                                               height: Self.bottomViewHeight + bottomMargin)
            }
        }
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
        textField?.placeholder = localizedString(addressSearch ? "type_address" : "search_poi_category_hint")
    }

    private func enterModalInputLayout() {
        modalInput = true
        updateNavbar()
    }

    private func restoreInputLayout() {
        modalInput = false
        updateNavbar()
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
                self.textField.placeholder = localizedString("type_city_town")
                self.startCitySearch()
                self.updateTabsVisibility(false)
                self.runCoreSearch("", updateResult: false, searchMore: false)
                self.textField.becomeFirstResponder()
            })
            rows.append(OAQuickSearchButtonListItem(icon: .icActionPostcode, text: localizedString("select_postcode")) { [weak self] _ in
                guard let self else { return }
                self.textField.placeholder = localizedString("type_postcode")
                self.startPostcodeSearch()
                self.updateData([], append: false)
                self.updateTabsVisibility(false)
                self.textField.becomeFirstResponder()
            })
            rows.append(OAQuickSearchButtonListItem(icon: .icCustomLocationMarker, text: localizedString("coords_search")) { [weak self] _ in
                guard let self else { return }
                let latLon = self.searchUICore?.getSearchSettings()?.getOriginalLocation()
                guard let coordinatesViewController = OAQuickSearchCoordinatesViewController(lat: latLon?.coordinate.latitude ?? 0,
                                                                                             lon: latLon?.coordinate.longitude ?? 0) else { return }
                let navigationController = UINavigationController(rootViewController: coordinatesViewController)
                navigationController.modalPresentationStyle = .fullScreen
                self.present(navigationController, animated: true)
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
        textField.becomeFirstResponder()
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
        textField?.text = text ?? ""
        textFieldValueChanged(textField)
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
        guard !(textField?.text ?? "").isEmpty else { return }
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

extension QuickSearchViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        guard !(textField.text ?? "").isEmpty else { return true }
        updateTextField(searchUICore?.getPhrase()?.getTextWithoutLastWord())
        return false
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        true
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
        let prevTabIndex = tabs.selectedSegmentIndex
        let currentViewController = pageViewController.viewControllers?.first
        if currentViewController === exploreViewController {
            tabs.selectedSegmentIndex = 0
        } else if currentViewController === categoriesViewController {
            tabs.selectedSegmentIndex = 1
        } else {
            tabs.selectedSegmentIndex = 2
        }
        if prevTabIndex != tabs.selectedSegmentIndex {
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
        dismiss(animated: true)
    }

    func closeSearch() {
        hideToolbar()
        dismiss(animated: true)
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
        dismiss(animated: true)
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
        dismiss(animated: true)
    }
}

extension QuickSearchViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        gestureRecognizer !== dismissEditingTap || !(touch.view?.isDescendant(of: textField) ?? false)
    }

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
