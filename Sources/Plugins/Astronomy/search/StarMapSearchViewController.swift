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

    private enum InputPresentation {
        case EXPLORE_BAR
        case STANDALONE
    }

    private enum HideTarget {
        case EXPLORE
        case BROWSE
    }

    private struct CatalogsBackState {
        let query: String
        let sortMode: StarMapSearchSortMode
        let scrollOffset: CGPoint
    }

    private struct ExploreRowConfig {
        let quickPresetType: StarMapSearchQuickPresetType
        let iconRes: String
        let titleRes: String
        let subtitleRes: String?
    }

    private enum Layout {
        static let contentPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let rowMinHeight: CGFloat = 56
        static let resultRowMinHeight: CGFloat = 72
        static let buttonHeight: CGFloat = 44
        static let iconSize: CGFloat = 24
        static let toolbarHeight: CGFloat = 56
        static let toolbarButtonTouchTarget: CGFloat = 56
        static let toolbarButtonLeadingInset: CGFloat = 0
        static let toolbarButtonTrailingInset: CGFloat = 16
        static let browseTitleExpandedHeight: CGFloat = 64
        static let browseTitleCollapseDistance: CGFloat = 56
        static let inputHeaderHeight: CGFloat = 88
        static let myDataTabsHeight: CGFloat = 56
    }

    private weak var parentStarMapController: StarMapViewController?
    private let plugin: AstronomyPlugin
    private let dataProvider: AstroDataProvider
    private let nightMode: Bool

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
    private lazy var searchPreparedDataFactory = StarMapSearchPreparedDataFactory(dataProvider: dataProvider, nightMode: nightMode)
    private lazy var searchHelper = StarMapSearchHelper()

    private var searchState = StarMapSearchState()
    private var preparedEntries: [StarMapSearchEntry] = []
    private var visibleEntries: [StarMapSearchEntry] = []
    private var preparedCatalogEntries: [StarMapCatalogEntry] = []
    private var visibleCatalogEntries: [StarMapCatalogEntry] = []
    private var widToDisplayName: [String: String] = [:]

    private let mainStack = UIStackView()
    private let exploreContainer = UIView()
    private let exploreHeaderStack = UIStackView()
    private let exploreScrollView = UIScrollView()
    private let exploreContentStack = UIStackView()
    private let fullSearchContainer = UIView()
    private let fullSearchStack = UIStackView()
    private let headerStack = UIStackView()
    private let browseToolbar = UIView()
    private let inputToolbar = UIView()
    private let toolbarTitleLabel = UILabel()
    private let browseTitleContainer = UIView()
    private let titleLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let inputBackButton = UIButton(type: .system)
    private let browseSearchButton = UIButton(type: .system)
    private let exploreSearchBar = UITextField()
    private let fullSearchBar = UITextField()
    private let myDataTabs = UIStackView()
    private var myDataTabButtons: [UIButton] = []
    private var myDataTabIndicators: [UIView] = []
    private let searchRecycler = UITableView(frame: .zero, style: .plain)
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
    private let watchNowRow = UIControl()
    private let categoriesContainer = UIStackView()
    private let myDataContainer = UIStackView()
    private let catalogsContainer = UIStackView()
    private let catalogsViewAllRow = UIControl()
    private let catalogsViewAllCount = UILabel()

    private var filterAndSortRequestId = 0
    private var currentMode: ScreenMode = .EXPLORE
    private var currentFullSearchMode: FullSearchMode = .INPUT
    private var currentInputPresentation: InputPresentation = .EXPLORE_BAR
    private var wasInfoHeaderVisible = false
    private var suppressQueryDispatch = false
    private var pendingSearchQueryRestore = false
    private var pendingSearchHideTarget: HideTarget?
    private var catalogsBackState: CatalogsBackState?
    private var dismissOnBrowseBack = false
    private var pendingInitialCatalogWid: String?
    private var redFilterEnabled = false
    private var browseTitleContainerHeightConstraint: NSLayoutConstraint?
    private var pendingBrowseScrollOffsetRestore: CGPoint?
    private var isFilteringResults = false

    var onObjectSelected: ((SkyObject) -> Void)?

    static let TAG = "StarMapSearchDialog"
    private static let FEATURED_CATALOGS_COUNT = 5
    private static let EXPLORE_SECTION_BACKGROUND_TAG = 0xA571
    private static let RISE_SET_PRELOAD_COUNT = 32
    private static let FEATURED_CATALOG_WIDS = [
        "Q14530",
        "Q857461",
        "Q2661779",
        "Q55712879",
        "Q3247327",
        "Q91442269",
        "Q4999741"
    ]

    static func newInstance(initialCatalogWid: String? = nil,
                            parent: StarMapViewController,
                            plugin: AstronomyPlugin) -> StarMapSearchViewController {
        let controller = StarMapSearchViewController(parent: parent, plugin: plugin)
        controller.pendingInitialCatalogWid = initialCatalogWid?.isEmpty == false ? initialCatalogWid : nil
        controller.dismissOnBrowseBack = controller.pendingInitialCatalogWid != nil
        return controller
    }

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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = StarMapSearchLightPalette.groupedBackground
        bindViews()
        refreshPreparedEntries()
        setupSearchRecycler()
        setupExploreContent()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncDialogVisibilityWithFragmentState()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            filterAndSortRequestId += 1
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }

    func applyRedFilter(enabled: Bool) {
        redFilterEnabled = enabled
        guard isViewLoaded else {
            return
        }
        AstroRedFilter.apply(enabled, to: view)
    }

    private func bindViews() {
        mainStack.axis = .vertical
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)

        exploreContainer.translatesAutoresizingMaskIntoConstraints = false
        exploreContainer.backgroundColor = StarMapSearchLightPalette.groupedBackground
        exploreHeaderStack.axis = .vertical
        exploreHeaderStack.spacing = Layout.smallPadding
        exploreHeaderStack.backgroundColor = StarMapSearchLightPalette.listBackground
        exploreHeaderStack.layoutMargins = UIEdgeInsets(top: Layout.contentPadding, left: Layout.contentPadding, bottom: Layout.contentPadding, right: Layout.contentPadding)
        exploreHeaderStack.isLayoutMarginsRelativeArrangement = true
        exploreHeaderStack.translatesAutoresizingMaskIntoConstraints = false
        exploreScrollView.translatesAutoresizingMaskIntoConstraints = false
        exploreScrollView.backgroundColor = StarMapSearchLightPalette.groupedBackground
        exploreContentStack.axis = .vertical
        exploreContentStack.spacing = Layout.contentPadding
        exploreContentStack.translatesAutoresizingMaskIntoConstraints = false
        exploreContainer.addSubview(exploreHeaderStack)
        exploreContainer.addSubview(exploreScrollView)
        exploreScrollView.addSubview(exploreContentStack)

        fullSearchContainer.translatesAutoresizingMaskIntoConstraints = false
        fullSearchContainer.backgroundColor = StarMapSearchLightPalette.listBackground
        fullSearchStack.axis = .vertical
        fullSearchStack.backgroundColor = StarMapSearchLightPalette.listBackground
        fullSearchStack.translatesAutoresizingMaskIntoConstraints = false
        fullSearchContainer.addSubview(fullSearchStack)
        resultsContainer.translatesAutoresizingMaskIntoConstraints = false
        resultsContainer.backgroundColor = StarMapSearchLightPalette.listBackground

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            exploreHeaderStack.leadingAnchor.constraint(equalTo: exploreContainer.leadingAnchor),
            exploreHeaderStack.trailingAnchor.constraint(equalTo: exploreContainer.trailingAnchor),
            exploreHeaderStack.topAnchor.constraint(equalTo: exploreContainer.topAnchor),

            exploreScrollView.leadingAnchor.constraint(equalTo: exploreContainer.leadingAnchor),
            exploreScrollView.trailingAnchor.constraint(equalTo: exploreContainer.trailingAnchor),
            exploreScrollView.topAnchor.constraint(equalTo: exploreHeaderStack.bottomAnchor),
            exploreScrollView.bottomAnchor.constraint(equalTo: exploreContainer.bottomAnchor),

            exploreContentStack.leadingAnchor.constraint(equalTo: exploreScrollView.contentLayoutGuide.leadingAnchor, constant: Layout.contentPadding),
            exploreContentStack.trailingAnchor.constraint(equalTo: exploreScrollView.contentLayoutGuide.trailingAnchor, constant: -Layout.contentPadding),
            exploreContentStack.topAnchor.constraint(equalTo: exploreScrollView.contentLayoutGuide.topAnchor, constant: Layout.contentPadding),
            exploreContentStack.bottomAnchor.constraint(equalTo: exploreScrollView.contentLayoutGuide.bottomAnchor, constant: -Layout.contentPadding),
            exploreContentStack.widthAnchor.constraint(equalTo: exploreScrollView.frameLayoutGuide.widthAnchor, constant: -2 * Layout.contentPadding),

            fullSearchStack.leadingAnchor.constraint(equalTo: fullSearchContainer.leadingAnchor),
            fullSearchStack.trailingAnchor.constraint(equalTo: fullSearchContainer.trailingAnchor),
            fullSearchStack.topAnchor.constraint(equalTo: fullSearchContainer.topAnchor),
            fullSearchStack.bottomAnchor.constraint(equalTo: fullSearchContainer.bottomAnchor)
        ])

        mainStack.addArrangedSubview(exploreContainer)
        mainStack.addArrangedSubview(fullSearchContainer)
        setupFullSearchHeader()
        setupExploreHeader()
        setupEmptyState()
    }

    private func setupFullSearchHeader() {
        headerStack.axis = .vertical
        headerStack.alignment = .fill
        headerStack.spacing = 0
        headerStack.backgroundColor = appBarBackgroundColor()

        backButton.setImage(AstroIcon.template("ic_arrow_back"), for: .normal)
        backButton.setTitle(nil, for: .normal)
        backButton.accessibilityLabel = localizedString("shared_string_back")
        backButton.addTarget(self, action: #selector(backPressed), for: .touchUpInside)
        backButton.tintColor = StarMapSearchLightPalette.toolbarIcon

        inputBackButton.setImage(AstroIcon.template("ic_arrow_back"), for: .normal)
        inputBackButton.setTitle(nil, for: .normal)
        inputBackButton.accessibilityLabel = localizedString("shared_string_back")
        inputBackButton.addTarget(self, action: #selector(backPressed), for: .touchUpInside)
        inputBackButton.tintColor = StarMapSearchLightPalette.toolbarIcon

        browseSearchButton.setImage(AstroIcon.template("ic_action_search_dark"), for: .normal)
        browseSearchButton.setTitle(nil, for: .normal)
        browseSearchButton.accessibilityLabel = localizedString("shared_string_search")
        browseSearchButton.addTarget(self, action: #selector(switchToInputModeAction), for: .touchUpInside)
        browseSearchButton.tintColor = StarMapSearchLightPalette.toolbarIcon

        titleLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        titleLabel.textColor = StarMapSearchLightPalette.primaryText
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        browseTitleContainer.translatesAutoresizingMaskIntoConstraints = false
        browseTitleContainer.backgroundColor = appBarBackgroundColor()
        browseTitleContainer.clipsToBounds = true
        browseTitleContainer.addSubview(titleLabel)
        let titleContainerHeight = browseTitleContainer.heightAnchor.constraint(equalToConstant: Layout.browseTitleExpandedHeight)
        browseTitleContainerHeightConstraint = titleContainerHeight
        NSLayoutConstraint.activate([
            titleContainerHeight,
            titleLabel.leadingAnchor.constraint(equalTo: browseTitleContainer.leadingAnchor, constant: Layout.contentPadding),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: browseTitleContainer.trailingAnchor, constant: -Layout.contentPadding),
            titleLabel.topAnchor.constraint(equalTo: browseTitleContainer.topAnchor, constant: Layout.smallPadding)
        ])

        setupBrowseToolbar()
        setupInputToolbar()
        setupMyDataTabs()
        headerStack.addArrangedSubview(browseToolbar)
        headerStack.addArrangedSubview(inputToolbar)
        headerStack.addArrangedSubview(browseTitleContainer)
        headerStack.addArrangedSubview(myDataTabs)

        fullSearchBar.delegate = self
        fullSearchBar.placeholder = localizedString("astro_search_input_hint")
        fullSearchBar.attributedPlaceholder = NSAttributedString(
            string: localizedString("astro_search_input_hint"),
            attributes: [.foregroundColor: StarMapSearchLightPalette.secondaryText]
        )
        fullSearchBar.borderStyle = .none
        fullSearchBar.backgroundColor = .clear
        fullSearchBar.font = UIFont.preferredFont(forTextStyle: .title3)
        fullSearchBar.textColor = StarMapSearchLightPalette.primaryText
        fullSearchBar.returnKeyType = .search
        fullSearchBar.clearButtonMode = .whileEditing
        fullSearchBar.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)

        searchRecycler.keyboardDismissMode = .onDrag
        searchRecycler.rowHeight = UITableView.automaticDimension
        searchRecycler.estimatedRowHeight = Layout.resultRowMinHeight
        searchRecycler.separatorStyle = .none
        searchRecycler.backgroundColor = StarMapSearchLightPalette.listBackground

        sortFilterBar.axis = .horizontal
        sortFilterBar.alignment = .center
        sortFilterBar.distribution = .fill
        sortFilterBar.spacing = 0
        sortFilterBar.backgroundColor = StarMapSearchLightPalette.listBackground
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

        fullSearchStack.addArrangedSubview(headerStack)
        fullSearchStack.addArrangedSubview(sortFilterBar)
        fullSearchStack.addArrangedSubview(resultsContainer)
    }

    private func setupBrowseToolbar() {
        browseToolbar.translatesAutoresizingMaskIntoConstraints = false
        browseToolbar.backgroundColor = appBarBackgroundColor()
        browseToolbar.heightAnchor.constraint(equalToConstant: Layout.toolbarHeight).isActive = true

        toolbarTitleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        toolbarTitleLabel.textColor = StarMapSearchLightPalette.primaryText
        toolbarTitleLabel.numberOfLines = 1
        toolbarTitleLabel.adjustsFontForContentSizeCategory = true
        toolbarTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        backButton.translatesAutoresizingMaskIntoConstraints = false
        browseSearchButton.translatesAutoresizingMaskIntoConstraints = false
        browseToolbar.addSubview(backButton)
        browseToolbar.addSubview(toolbarTitleLabel)
        browseToolbar.addSubview(browseSearchButton)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: browseToolbar.leadingAnchor, constant: Layout.toolbarButtonLeadingInset),
            backButton.centerYAnchor.constraint(equalTo: browseToolbar.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: Layout.toolbarButtonTouchTarget),
            backButton.heightAnchor.constraint(equalToConstant: Layout.toolbarButtonTouchTarget),

            browseSearchButton.trailingAnchor.constraint(equalTo: browseToolbar.trailingAnchor, constant: -Layout.toolbarButtonTrailingInset),
            browseSearchButton.centerYAnchor.constraint(equalTo: browseToolbar.centerYAnchor),
            browseSearchButton.widthAnchor.constraint(equalToConstant: Layout.toolbarButtonTouchTarget),
            browseSearchButton.heightAnchor.constraint(equalToConstant: Layout.toolbarButtonTouchTarget),

            toolbarTitleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor),
            toolbarTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: browseSearchButton.leadingAnchor, constant: -Layout.smallPadding),
            toolbarTitleLabel.centerYAnchor.constraint(equalTo: browseToolbar.centerYAnchor)
        ])

        headerStack.layoutMargins = .zero
        headerStack.isLayoutMarginsRelativeArrangement = false
    }

    private func setupInputToolbar() {
        inputToolbar.translatesAutoresizingMaskIntoConstraints = false
        inputToolbar.backgroundColor = appBarBackgroundColor()
        inputToolbar.heightAnchor.constraint(equalToConstant: Layout.inputHeaderHeight).isActive = true

        inputBackButton.translatesAutoresizingMaskIntoConstraints = false
        fullSearchBar.translatesAutoresizingMaskIntoConstraints = false
        inputToolbar.addSubview(inputBackButton)
        inputToolbar.addSubview(fullSearchBar)
        NSLayoutConstraint.activate([
            inputBackButton.leadingAnchor.constraint(equalTo: inputToolbar.leadingAnchor, constant: Layout.toolbarButtonLeadingInset),
            inputBackButton.centerYAnchor.constraint(equalTo: inputToolbar.centerYAnchor),
            inputBackButton.widthAnchor.constraint(equalToConstant: Layout.toolbarButtonTouchTarget),
            inputBackButton.heightAnchor.constraint(equalToConstant: Layout.toolbarButtonTouchTarget),

            fullSearchBar.leadingAnchor.constraint(equalTo: inputBackButton.trailingAnchor),
            fullSearchBar.trailingAnchor.constraint(equalTo: inputToolbar.trailingAnchor, constant: -Layout.contentPadding),
            fullSearchBar.centerYAnchor.constraint(equalTo: inputToolbar.centerYAnchor),
            fullSearchBar.heightAnchor.constraint(equalToConstant: Layout.toolbarHeight)
        ])
    }

    private func setupMyDataTabs() {
        myDataTabs.axis = .horizontal
        myDataTabs.alignment = .fill
        myDataTabs.distribution = .fillEqually
        myDataTabs.spacing = 0
        myDataTabs.backgroundColor = appBarBackgroundColor()
        myDataTabs.heightAnchor.constraint(equalToConstant: Layout.myDataTabsHeight).isActive = true
        myDataTabs.isHidden = true

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

    private func appBarBackgroundColor() -> UIColor {
        StarMapSearchLightPalette.appBarBackground
    }

    private func setupExploreHeader() {
        let searchSurface = UIControl()
        searchSurface.backgroundColor = appBarBackgroundColor()
        searchSurface.layer.cornerRadius = 10
        searchSurface.addTarget(self, action: #selector(openExploreInputSearch), for: .touchUpInside)

        let closeButton = UIButton(type: .system)
        closeButton.setImage(AstroIcon.template("ic_action_close"), for: .normal)
        closeButton.tintColor = StarMapSearchLightPalette.toolbarIcon
        closeButton.accessibilityLabel = localizedString("shared_string_close")
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        let title = UILabel()
        title.text = localizedString("shared_string_search")
        title.font = UIFont.preferredFont(forTextStyle: .title2)
        title.textColor = StarMapSearchLightPalette.primaryText

        let searchButton = UIButton(type: .system)
        searchButton.setImage(AstroIcon.template("ic_action_search_dark"), for: .normal)
        searchButton.tintColor = StarMapSearchLightPalette.toolbarIcon
        searchButton.accessibilityLabel = localizedString("shared_string_search")
        searchButton.addTarget(self, action: #selector(openExploreInputSearch), for: .touchUpInside)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchSurface.translatesAutoresizingMaskIntoConstraints = false
        searchSurface.addSubview(closeButton)
        searchSurface.addSubview(title)
        searchSurface.addSubview(searchButton)
        NSLayoutConstraint.activate([
            searchSurface.heightAnchor.constraint(equalToConstant: 64),
            closeButton.leadingAnchor.constraint(equalTo: searchSurface.leadingAnchor, constant: Layout.contentPadding),
            closeButton.centerYAnchor.constraint(equalTo: searchSurface.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            searchButton.trailingAnchor.constraint(equalTo: searchSurface.trailingAnchor, constant: -Layout.contentPadding),
            searchButton.centerYAnchor.constraint(equalTo: searchSurface.centerYAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: 44),
            searchButton.heightAnchor.constraint(equalToConstant: 44),
            title.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: Layout.smallPadding),
            title.trailingAnchor.constraint(lessThanOrEqualTo: searchButton.leadingAnchor, constant: -Layout.smallPadding),
            title.centerYAnchor.constraint(equalTo: searchSurface.centerYAnchor)
        ])
        exploreHeaderStack.addArrangedSubview(searchSurface)

        exploreSearchBar.delegate = self
        exploreSearchBar.placeholder = localizedString("astro_search_input_hint")
        exploreSearchBar.attributedPlaceholder = NSAttributedString(
            string: localizedString("astro_search_input_hint"),
            attributes: [.foregroundColor: StarMapSearchLightPalette.secondaryText]
        )
        exploreSearchBar.textColor = StarMapSearchLightPalette.primaryText

        recentChipsContainer.axis = .horizontal
        recentChipsContainer.spacing = Layout.smallPadding
        recentChipsContainer.translatesAutoresizingMaskIntoConstraints = false
        recentChipsScroll.addSubview(recentChipsContainer)
        NSLayoutConstraint.activate([
            recentChipsContainer.leadingAnchor.constraint(equalTo: recentChipsScroll.contentLayoutGuide.leadingAnchor),
            recentChipsContainer.trailingAnchor.constraint(equalTo: recentChipsScroll.contentLayoutGuide.trailingAnchor),
            recentChipsContainer.topAnchor.constraint(equalTo: recentChipsScroll.contentLayoutGuide.topAnchor),
            recentChipsContainer.bottomAnchor.constraint(equalTo: recentChipsScroll.contentLayoutGuide.bottomAnchor),
            recentChipsContainer.heightAnchor.constraint(equalTo: recentChipsScroll.frameLayoutGuide.heightAnchor)
        ])
        recentChipsScroll.heightAnchor.constraint(equalToConstant: 38).isActive = true
        exploreHeaderStack.addArrangedSubview(recentChipsScroll)
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

    private func setupSearchRecycler() {
        searchRecycler.dataSource = searchAdapter
        searchRecycler.delegate = searchAdapter
    }

    private func setupExploreContent() {
        setupWatchNowRow()
        setupCategoryRows()
        setupMyDataRows()
        setupCatalogRows()
    }

    private func setupWatchNowRow() {
        configureExploreRow(watchNowRow,
                            iconName: "ic_action_telescope",
                            title: localizedString("astro_explore_watch_now"),
                            subtitle: localizedString("astro_explore_watch_now_subtitle"),
                            count: nil)
        watchNowRow.backgroundColor = StarMapSearchLightPalette.listBackground
        watchNowRow.layer.cornerRadius = 10
        watchNowRow.layer.masksToBounds = true
        watchNowRow.addTarget(self, action: #selector(watchNowPressed), for: .touchUpInside)
        exploreContentStack.addArrangedSubview(watchNowRow)
    }

    private func setupListeners() {
        syncRecentChipsWithSession()
    }

    private func updateBrowseToolbarAppearance() {
        titleLabel.textColor = StarMapSearchLightPalette.primaryText
        toolbarTitleLabel.textColor = StarMapSearchLightPalette.primaryText
        backButton.tintColor = StarMapSearchLightPalette.toolbarIcon
        inputBackButton.tintColor = StarMapSearchLightPalette.toolbarIcon
        browseSearchButton.tintColor = StarMapSearchLightPalette.toolbarIcon
    }

    private func attachSearchResultsPanel() {
        updateResultsAdapter()
    }

    private func getSearchView(_ presentation: InputPresentation) -> UITextField {
        presentation == .EXPLORE_BAR ? exploreSearchBar : fullSearchBar
    }

    private func getActiveSearchView() -> UITextField? {
        currentMode == .FULL_SEARCH ? fullSearchBar : exploreSearchBar
    }

    private func applySearchSoftInputMode() {}

    private func restoreSearchSoftInputMode() {}

    private func syncDialogVisibilityWithFragmentState() {
        applyRedFilter(enabled: parentStarMapController?.isSearchRedFilterEnabled() ?? redFilterEnabled)
    }

    private func restoreUiState(_ savedInstanceState: [String: Any]?) {
        searchState.restore(savedInstanceState)
    }

    private func setupCategoryRows() {
        categoriesContainer.axis = .vertical
        categoriesContainer.spacing = 0
        categoriesContainer.removeArrangedSubviews()
        configureExploreSectionCard(categoriesContainer)
        let categories = [
            ExploreRowConfig(quickPresetType: .CATEGORY_SOLAR_SYSTEM, iconRes: "ic_action_planet_outlined", titleRes: "astro_solar_system", subtitleRes: nil),
            ExploreRowConfig(quickPresetType: .CATEGORY_CONSTELLATIONS, iconRes: "ic_action_constellations", titleRes: "astro_constellations", subtitleRes: nil),
            ExploreRowConfig(quickPresetType: .CATEGORY_STARS, iconRes: "ic_action_stars", titleRes: "astro_stars", subtitleRes: nil),
            ExploreRowConfig(quickPresetType: .CATEGORY_NEBULAS, iconRes: "ic_action_nebulas", titleRes: "astro_nebulas", subtitleRes: nil),
            ExploreRowConfig(quickPresetType: .CATEGORY_STAR_CLUSTERS, iconRes: "ic_action_star_clusters", titleRes: "astro_star_clusters", subtitleRes: nil),
            ExploreRowConfig(quickPresetType: .CATEGORY_DEEP_SKY, iconRes: "ic_action_galaxy", titleRes: "astro_deep_sky", subtitleRes: "astro_explore_deep_sky_subtitle")
        ]
        for (index, config) in categories.enumerated() {
            addExploreRow(container: categoriesContainer,
                          iconRes: config.iconRes,
                          title: localizedString(config.titleRes),
                          subtitle: config.subtitleRes.map(localizedString),
                          count: nil,
                          showDivider: index != categories.count - 1) { [weak self] in
                self?.openFullSearch(config.quickPresetType, catalogWid: nil)
            }
        }
        exploreContentStack.addArrangedSubview(categoriesContainer)
    }

    private func bindExploreSearchBarListeners() {}

    private func setupMyDataRows() {
        myDataContainer.axis = .vertical
        myDataContainer.spacing = 0
        myDataContainer.removeArrangedSubviews()
        configureExploreSectionCard(myDataContainer)
        myDataContainer.addArrangedSubview(sectionHeaderView(localizedString("astro_explore_my_data")))
        let config = parentStarMapController?.getSearchStarMapConfig() ?? AstronomyPluginSettings.load().starMap
        let items: [(ExploreRowConfig, Int)] = [
            (ExploreRowConfig(quickPresetType: .MY_DATA_FAVORITES, iconRes: "ic_action_bookmark_filled", titleRes: "favorites_item", subtitleRes: nil), config.favorites.count),
            (ExploreRowConfig(quickPresetType: .MY_DATA_DAILY_PATH, iconRes: "ic_action_target_path_on", titleRes: "astro_daily_path", subtitleRes: nil), config.celestialPaths.count),
            (ExploreRowConfig(quickPresetType: .MY_DATA_DIRECTIONS, iconRes: "ic_action_target_direction_on", titleRes: "astro_directions", subtitleRes: nil), config.directions.count)
        ]
        for (index, item) in items.enumerated() {
            addExploreRow(container: myDataContainer,
                          iconRes: item.0.iconRes,
                          title: localizedString(item.0.titleRes),
                          subtitle: nil,
                          count: item.1,
                          showDivider: index != items.count - 1) { [weak self] in
                self?.openFullSearch(item.0.quickPresetType, catalogWid: nil)
            }
        }
        exploreContentStack.addArrangedSubview(myDataContainer)
    }

    private func setupCatalogRows() {
        catalogsContainer.axis = .vertical
        catalogsContainer.spacing = 0
        catalogsContainer.removeArrangedSubviews()
        configureExploreSectionCard(catalogsContainer)
        catalogsContainer.addArrangedSubview(sectionHeaderView(localizedString("astro_catalogs")))
        let featuredCatalogs = getFeaturedCatalogEntries()
        for entry in featuredCatalogs {
            addExploreRow(container: catalogsContainer,
                          iconRes: "ic_action_book_info",
                          iconColor: StarMapSearchLightPalette.defaultIcon,
                          title: entry.displayName,
                          subtitle: nil,
                          count: nil,
                          showDivider: true) { [weak self] in
                self?.clearCatalogsBackState()
                self?.openFullSearch(.CATALOG_WID, catalogWid: entry.catalog.wid)
            }
        }
        configureCatalogsViewAllRow()
        catalogsViewAllRow.addTarget(self, action: #selector(catalogsViewAllPressed), for: .touchUpInside)
        catalogsContainer.addArrangedSubview(catalogsViewAllRow)
        exploreContentStack.addArrangedSubview(catalogsContainer)
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

    private func addExploreRow(container: UIStackView,
                               iconRes: String,
                               iconColor: UIColor = .systemBlue,
                               title: String,
                               subtitle: String?,
                               count: Int?,
                               showDivider: Bool = true,
                               onClick: (() -> Void)?) {
        let row = UIControl()
        configureExploreRow(row,
                            iconName: iconRes,
                            iconColor: iconColor,
                            title: title,
                            subtitle: subtitle,
                            count: count,
                            showDivider: showDivider)
        if let onClick {
            row.addAction(UIAction { _ in onClick() }, for: .touchUpInside)
        }
        container.addArrangedSubview(row)
    }

    private func configureExploreRow(_ row: UIControl,
                                     iconName: String,
                                     iconColor: UIColor = .systemBlue,
                                     title: String,
                                     subtitle: String?,
                                     count: Int?,
                                     showDivider: Bool = false) {
        row.subviews.forEach { $0.removeFromSuperview() }
        row.backgroundColor = .clear
        row.layer.cornerRadius = 0
        row.isUserInteractionEnabled = true

        let iconView = UIImageView(image: AstroIcon.template(iconName))
        iconView.tintColor = iconColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = StarMapSearchLightPalette.primaryText
        titleLabel.font = UIFont.preferredFont(forTextStyle: .body)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = StarMapSearchLightPalette.secondaryText
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        subtitleLabel.numberOfLines = 2
        subtitleLabel.isHidden = subtitle?.isEmpty != false

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let countLabel = UILabel()
        countLabel.text = count.map(String.init)
        countLabel.textColor = StarMapSearchLightPalette.secondaryText
        countLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        countLabel.isHidden = count == nil

        let stack = UIStackView(arrangedSubviews: [iconView, textStack, countLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Layout.contentPadding
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isUserInteractionEnabled = false
        row.addSubview(stack)
        let divider = UIView()
        divider.backgroundColor = StarMapSearchLightPalette.separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.isUserInteractionEnabled = false
        divider.isHidden = !showDivider
        row.addSubview(divider)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.rowMinHeight),
            iconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Layout.iconSize),
            stack.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: Layout.contentPadding),
            stack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -Layout.contentPadding),
            stack.topAnchor.constraint(equalTo: row.topAnchor, constant: Layout.smallPadding),
            stack.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -Layout.smallPadding),
            divider.leadingAnchor.constraint(equalTo: textStack.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -Layout.contentPadding),
            divider.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale)
        ])
    }

    private func configureExploreSectionCard(_ stack: UIStackView) {
        stack.subviews.filter { $0.tag == Self.EXPLORE_SECTION_BACKGROUND_TAG }.forEach { $0.removeFromSuperview() }
        let backgroundView = UIView()
        backgroundView.tag = Self.EXPLORE_SECTION_BACKGROUND_TAG
        backgroundView.backgroundColor = StarMapSearchLightPalette.listBackground
        backgroundView.isUserInteractionEnabled = false
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        stack.layer.cornerRadius = 10
        stack.layer.masksToBounds = true
        stack.insertSubview(backgroundView, at: 0)
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: stack.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: stack.bottomAnchor)
        ])
    }

    private func sectionHeaderView(_ text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.isUserInteractionEnabled = false
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true

        let label = UILabel()
        label.text = text
        label.textColor = StarMapSearchLightPalette.primaryText
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Layout.contentPadding),
            label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -Layout.contentPadding),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: Layout.contentPadding),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Layout.smallPadding)
        ])
        return container
    }

    private func configureCatalogsViewAllRow() {
        catalogsViewAllRow.subviews.forEach { $0.removeFromSuperview() }
        catalogsViewAllRow.backgroundColor = .clear
        catalogsViewAllRow.isUserInteractionEnabled = true

        let titleLabel = UILabel()
        titleLabel.text = localizedString("shared_string_view_all")
        titleLabel.textColor = .systemBlue
        titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        catalogsViewAllCount.text = String(getBrowsableCatalogEntries().count)
        catalogsViewAllCount.textColor = StarMapSearchLightPalette.secondaryText
        catalogsViewAllCount.font = UIFont.preferredFont(forTextStyle: .body)
        catalogsViewAllCount.translatesAutoresizingMaskIntoConstraints = false

        catalogsViewAllRow.addSubview(titleLabel)
        catalogsViewAllRow.addSubview(catalogsViewAllCount)
        NSLayoutConstraint.activate([
            catalogsViewAllRow.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.rowMinHeight),
            titleLabel.leadingAnchor.constraint(equalTo: catalogsViewAllRow.leadingAnchor, constant: Layout.contentPadding),
            titleLabel.centerYAnchor.constraint(equalTo: catalogsViewAllRow.centerYAnchor),
            catalogsViewAllCount.trailingAnchor.constraint(equalTo: catalogsViewAllRow.trailingAnchor, constant: -Layout.contentPadding),
            catalogsViewAllCount.centerYAnchor.constraint(equalTo: catalogsViewAllRow.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: catalogsViewAllCount.leadingAnchor, constant: -Layout.smallPadding)
        ])
    }

    private func openFullSearch(_ quickPresetType: StarMapSearchQuickPresetType, catalogWid: String?) {
        searchState.prepareForExploreEntry(quickPresetType, catalogWid: catalogWid)
        currentFullSearchMode = searchState.shouldOpenInBrowseMode() ? .BROWSE : .INPUT
        prepareForFreshResultLoad()
        applyMode(.FULL_SEARCH, requestKeyboard: currentFullSearchMode == .INPUT)
        applyFiltersAndSort(scrollToTop: true)
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
                showInputMode(.STANDALONE, requestKeyboard: requestKeyboard)
            }
        }
    }

    private func renderBrowseHeader() {
        let title = getBrowseTitle()
        titleLabel.text = title
        toolbarTitleLabel.text = title
        updateBrowseHeaderLayout()
    }

    private func updateBrowseHeaderLayout() {
        let compactHeader = isMyDataMode()
        let inputMode = currentFullSearchMode == .INPUT
        let collapsibleHeader = shouldUseCollapsibleBrowseTitle()
        browseTitleContainer.isHidden = inputMode || !collapsibleHeader
        toolbarTitleLabel.isHidden = inputMode || (!compactHeader && !collapsibleHeader)
        browseSearchButton.isHidden = inputMode || compactHeader
        if compactHeader {
            toolbarTitleLabel.alpha = 1
            titleLabel.alpha = 0
            titleLabel.transform = .identity
            browseTitleContainerHeightConstraint?.constant = 0
        } else if collapsibleHeader {
            updateBrowseTitleCollapse(scrollOffset: currentSearchScrollOffset(), animated: false)
        }
        updateMyDataTabs()
    }

    private func shouldUseCollapsibleBrowseTitle() -> Bool {
        currentMode == .FULL_SEARCH && currentFullSearchMode == .BROWSE && !isMyDataMode()
    }

    private func currentSearchScrollOffset() -> CGFloat {
        max(0, searchRecycler.contentOffset.y + searchRecycler.adjustedContentInset.top)
    }

    private func onResultsScrolled(_ scrollView: UIScrollView) {
        guard shouldUseCollapsibleBrowseTitle() else {
            return
        }
        let offset = max(0, scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
        updateBrowseTitleCollapse(scrollOffset: offset, animated: false)
    }

    private func updateBrowseTitleCollapse(scrollOffset: CGFloat, animated: Bool) {
        guard shouldUseCollapsibleBrowseTitle() else {
            return
        }
        let progress = min(1, max(0, scrollOffset / Layout.browseTitleCollapseDistance))
        let largeTitleAlpha = max(0, 1 - progress * 1.35)
        let toolbarTitleAlpha = min(1, max(0, (progress - 0.2) / 0.8))
        let titleTranslation = -Layout.browseTitleExpandedHeight * 0.35 * progress
        let applyChanges = { [self] in
            browseTitleContainerHeightConstraint?.constant = Layout.browseTitleExpandedHeight * (1 - progress)
            titleLabel.alpha = largeTitleAlpha
            titleLabel.transform = CGAffineTransform(translationX: 0, y: titleTranslation)
            toolbarTitleLabel.alpha = toolbarTitleAlpha
            view.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: applyChanges)
        } else {
            applyChanges()
        }
    }

    private func resetBrowseTitleCollapseState(scrollToTop: Bool) {
        pendingBrowseScrollOffsetRestore = nil
        if scrollToTop {
            resetSearchRecyclerScrollPosition()
        }
        browseTitleContainerHeightConstraint?.constant = Layout.browseTitleExpandedHeight
        titleLabel.alpha = 1
        titleLabel.transform = .identity
        toolbarTitleLabel.alpha = isMyDataMode() ? 1 : 0
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
        updateBrowseTitleCollapse(scrollOffset: currentSearchScrollOffset(), animated: false)
    }

    private func isMyDataMode() -> Bool {
        searchState.quickPresetType.isMyData
    }

    private func getSelectedMyDataTabIndex() -> Int? {
        searchState.quickPresetType.myDataTabIndex
    }

    private func updateMyDataTabs() {
        let visible = currentMode == .FULL_SEARCH && currentFullSearchMode == .BROWSE && isMyDataMode()
        myDataTabs.isHidden = !visible
        guard visible, let selectedIndex = getSelectedMyDataTabIndex() else {
            return
        }
        for (index, button) in myDataTabButtons.enumerated() {
            let selected = index == selectedIndex
            button.setTitleColor(selected ? .systemBlue : StarMapSearchLightPalette.secondaryText, for: .normal)
            if index < myDataTabIndicators.count {
                myDataTabIndicators[index].isHidden = !selected
            }
        }
    }

    private func showExploreMode() {
        resetBrowseTitleCollapseState(scrollToTop: true)
        view.backgroundColor = StarMapSearchLightPalette.listBackground
        exploreContainer.isHidden = false
        fullSearchContainer.isHidden = true
        exploreSearchBar.text = nil
        view.endEditing(true)
    }

    private func showBrowseMode(resetCollapseState: Bool = true) {
        if resetCollapseState {
            resetBrowseTitleCollapseState(scrollToTop: true)
        }
        exploreContainer.isHidden = true
        fullSearchContainer.isHidden = false
        currentFullSearchMode = .BROWSE
        currentInputPresentation = searchState.hasBrowseContext() ? .STANDALONE : .EXPLORE_BAR
        view.backgroundColor = appBarBackgroundColor()
        browseToolbar.isHidden = false
        inputToolbar.isHidden = true
        headerStack.layoutMargins = .zero
        renderBrowseHeader()
        syncSearchQuery()
        fullSearchBar.resignFirstResponder()
        updateResultsAdapter()
        updateSortControls()
        updateFilterControls()
        updateEmptyStateContent()
        updateEmptyStateVisibility()
    }

    private func switchToInputMode() {
        showInputMode(.STANDALONE, requestKeyboard: true)
    }

    private func showInputMode(_ presentation: InputPresentation, requestKeyboard: Bool) {
        resetBrowseTitleCollapseState(scrollToTop: true)
        exploreContainer.isHidden = true
        fullSearchContainer.isHidden = false
        currentFullSearchMode = .INPUT
        currentInputPresentation = presentation
        view.backgroundColor = appBarBackgroundColor()
        browseToolbar.isHidden = true
        inputToolbar.isHidden = false
        headerStack.layoutMargins = .zero
        browseTitleContainer.isHidden = true
        toolbarTitleLabel.isHidden = true
        myDataTabs.isHidden = true
        syncSearchQuery()
        updateResultsAdapter()
        updateSortControls()
        updateFilterControls()
        updateEmptyStateContent()
        updateEmptyStateVisibility()
        if requestKeyboard {
            fullSearchBar.becomeFirstResponder()
        }
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

    private func configureSearchView(_ presentation: InputPresentation, requestKeyboard: Bool) {
        showInputMode(presentation, requestKeyboard: requestKeyboard)
    }

    private func handleSearchViewShown(_ presentation: InputPresentation) {
        currentInputPresentation = presentation
    }

    private func handleSearchViewHidden(_ presentation: InputPresentation) {
        pendingSearchHideTarget = searchState.hasBrowseContext() ? .BROWSE : .EXPLORE
    }

    private func syncSearchQuery() {
        suppressQueryDispatch = true
        fullSearchBar.text = searchState.query
        suppressQueryDispatch = false
    }

    private func refreshPreparedEntries() {
        let preparedData = searchPreparedDataFactory.create(parent: parentStarMapController)
        preparedEntries = preparedData.entries
        preparedCatalogEntries = preparedData.catalogEntries
        widToDisplayName = preparedData.widToDisplayName
        searchHelper.updateComputationContext(preparedData.computationContext)
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

    private func updateResultsAdapter() {
        if shouldShowCatalogEntries() {
            catalogsAdapter.submitSnapshot(StarMapCatalogsAdapter.Snapshot(entries: visibleCatalogEntries))
            searchRecycler.dataSource = catalogsAdapter
            searchRecycler.delegate = catalogsAdapter
        } else {
            let categoryPreset = searchState.categoryPreset()
            searchAdapter.submitSnapshot(StarMapSearchResultsAdapter.Snapshot(entries: visibleEntries,
                                                                              categoryPreset: categoryPreset,
                                                                              infoHeaderCategory: shouldShowInfoHeader() ? categoryPreset : nil,
                                                                              useExploreRowLayout: isMyDataMode()))
            searchRecycler.dataSource = searchAdapter
            searchRecycler.delegate = searchAdapter
        }
        searchRecycler.reloadData()
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

    private func getCurrentResultsCount() -> Int {
        shouldShowCatalogEntries() ? visibleCatalogEntries.count : visibleEntries.count
    }

    private func updateInfoCard() {
        let isInfoHeaderVisible = shouldShowInfoHeader()
        wasInfoHeaderVisible = isInfoHeaderVisible
    }

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
        updateBrowseTitleCollapse(scrollOffset: currentSearchScrollOffset(), animated: false)
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
            iconName = "ic_action_sort_date_1"
        case .OLDEST_FIRST:
            text = localizedString("astro_sort_oldest_first")
            iconName = "ic_action_sort_date_31"
        case .NAME_ASC:
            text = localizedString("sort_name_ascending")
            iconName = "ic_action_sort_by_name_ascending"
        case .NAME_DESC:
            text = localizedString("sort_name_descending")
            iconName = "ic_action_sort_by_name_descending"
        case .BRIGHTEST_FIRST:
            text = localizedString("astro_sort_brightest_first")
            iconName = "ic_action_sort_brightest"
        case .FAINTEST_FIRST:
            text = localizedString("astro_sort_faintest_first")
            iconName = "ic_action_sort_faintest"
        case .RISES_SOONEST:
            text = localizedString("astro_sort_rises_soonest")
            iconName = "ic_action_sort_rises"
        case .SETS_SOONEST:
            text = localizedString("astro_sort_sets_soonest")
            iconName = "ic_action_sort_sets"
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
        configuration.image = AstroIcon.template("ic_action_filter_dark")
        configuration.imagePlacement = .trailing
        configuration.baseForegroundColor = .systemBlue
        configuration.imagePadding = Layout.smallPadding
        filterButton.configuration = configuration
        filterButton.menu = createFilterMenu()
    }

    private func shouldHideShowAllTypeFilter() -> Bool {
        searchState.quickPresetType == .WATCH_NOW
    }

    private func normalizeTypeFilterForCurrentPreset() {
        if shouldHideShowAllTypeFilter() && searchState.typeFilter == .SHOW_ALL {
            searchState.typeFilter = .VISIBLE_TONIGHT
        }
    }

    private func shouldShowWatchNowClearFiltersAction() -> Bool {
        searchState.quickPresetType == .WATCH_NOW && searchState.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func updateEmptyStateContent() {
        if isMyDataMode() {
            let iconName: String
            let titleKey: String
            let descriptionKey: String
            switch searchState.quickPresetType {
            case .MY_DATA_DIRECTIONS:
                iconName = "ic_action_bookmark"
                titleKey = "astro_my_data_no_directions_title"
                descriptionKey = "astro_my_data_no_directions_description"
            case .MY_DATA_DAILY_PATH:
                iconName = "ic_action_target_path_off"
                titleKey = "astro_my_data_no_daily_paths_title"
                descriptionKey = "astro_my_data_no_daily_paths_description"
            default:
                iconName = "ic_action_bookmark"
                titleKey = "astro_my_data_no_favorites_title"
                descriptionKey = "astro_my_data_no_favorites_description"
            }
            emptyStateIcon.image = AstroIcon.template(iconName)
            emptyStateTitle.text = localizedString(titleKey)
            emptyStateDescription.text = localizedString(descriptionKey)
            emptyStateResetButton.setTitle(localizedString("astro_go_to_map"), for: .normal)
        } else {
            emptyStateIcon.image = AstroIcon.template("ic_action_ufo")
            emptyStateTitle.text = localizedString("nothing_found")
            emptyStateDescription.text = localizedString("astro_search_empty_description")
            emptyStateResetButton.setTitle(localizedString(shouldShowWatchNowClearFiltersAction() ? "shared_string_clear_filters" : "shared_string_reset"), for: .normal)
        }
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
        if isMyDataMode() {
            dismiss(animated: true)
        } else if shouldShowWatchNowClearFiltersAction() {
            resetWatchNowFilters()
        } else {
            resetAllSearchParams()
        }
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
                showInputMode(.STANDALONE, requestKeyboard: false)
            } else if currentMode == .FULL_SEARCH {
                showBrowseMode()
            }
        } else {
            searchState.reset()
            currentFullSearchMode = .INPUT
            syncSearchQuery()
            if currentMode == .FULL_SEARCH {
                showInputMode(.STANDALONE, requestKeyboard: false)
            }
        }
        applyFiltersAndSort(scrollToTop: true)
    }

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
                    self.showInputMode(.EXPLORE_BAR, requestKeyboard: true)
                    self.applyFiltersAndSort(scrollToTop: true)
                }
            }, for: .touchUpInside)
            recentChipsContainer.addArrangedSubview(chipButton)
        }
    }

    private func onSearchEntrySelected(_ entry: StarMapSearchEntry) {
        addRecentChip(entry)
        dismiss(animated: true) { [weak self] in
            self?.onObjectSelected?(entry.objectRef)
        }
    }

    private func onCatalogSelected(_ entry: StarMapCatalogEntry) {
        catalogsBackState = CatalogsBackState(query: searchState.query,
                                              sortMode: searchState.sortMode,
                                              scrollOffset: searchRecycler.contentOffset)
        openFullSearch(.CATALOG_WID, catalogWid: entry.catalog.wid)
    }

    private func createSortMenu() -> UIMenu {
        if shouldShowCatalogEntries() {
            return UIMenu(title: localizedString("sort_by"), children: [
                sortAction(title: localizedString("sort_name_ascending"), mode: .NAME_ASC),
                sortAction(title: localizedString("sort_name_descending"), mode: .NAME_DESC)
            ])
        }
        var actions = [
            sortAction(title: localizedString("sort_name_ascending"), mode: .NAME_ASC),
            sortAction(title: localizedString("sort_name_descending"), mode: .NAME_DESC),
            sortAction(title: localizedString("astro_sort_brightest_first"), mode: .BRIGHTEST_FIRST),
            sortAction(title: localizedString("astro_sort_faintest_first"), mode: .FAINTEST_FIRST),
            sortAction(title: localizedString("astro_sort_rises_soonest"), mode: .RISES_SOONEST),
            sortAction(title: localizedString("astro_sort_sets_soonest"), mode: .SETS_SOONEST)
        ]
        if isMyDataMode() {
            actions.append(sortAction(title: localizedString("astro_sort_newest_first"), mode: .NEWEST_FIRST))
            actions.append(sortAction(title: localizedString("astro_sort_oldest_first"), mode: .OLDEST_FIRST))
        }
        return UIMenu(title: localizedString("sort_by"), children: actions)
    }

    private func sortAction(title: String, mode: StarMapSearchSortMode) -> UIAction {
        UIAction(title: title, state: searchState.sortMode == mode ? .on : .off) { [weak self] _ in
            self?.searchState.sortMode = mode
            self?.updateSortControls()
            self?.applyFiltersAndSort(scrollToTop: true)
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

    private func createPopupDisplayData() {}

    private func createPopupHeaderItem() {}

    private func createRadioPopupItem() {}

    private func createCheckPopupItem() {}

    private func dismissSortPopup() {}

    private func dismissFilterPopup() {}

    private func dismissPopups() {}

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField === exploreSearchBar {
            openFullSearch(.NONE, catalogWid: nil)
            return false
        }
        if currentFullSearchMode == .BROWSE {
            switchToInputMode()
        }
        return true
    }

    @objc private func searchTextChanged() {
        guard !suppressQueryDispatch else {
            return
        }
        searchState.query = fullSearchBar.text ?? ""
        applyFiltersAndSort(scrollToTop: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc private func backPressed() {
        if !handleBackPressedInternal() {
            dismiss(animated: true)
        }
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    @objc private func watchNowPressed() {
        openFullSearch(.WATCH_NOW, catalogWid: nil)
    }

    @objc private func openExploreInputSearch() {
        openFullSearch(.NONE, catalogWid: nil)
    }

    @objc private func switchToInputModeAction() {
        switchToInputMode()
    }

    @objc private func catalogsViewAllPressed() {
        openFullSearch(.CATALOGS, catalogWid: nil)
    }

    @objc private func myDataTabPressed(_ sender: UIControl) {
        let preset: StarMapSearchQuickPresetType
        switch sender.tag {
        case 0:
            preset = .MY_DATA_FAVORITES
        case 1:
            preset = .MY_DATA_DAILY_PATH
        case 2:
            preset = .MY_DATA_DIRECTIONS
        default:
            return
        }
        searchState.prepareForExploreEntry(preset, catalogWid: nil)
        showBrowseMode()
        applyFiltersAndSort(scrollToTop: true)
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
