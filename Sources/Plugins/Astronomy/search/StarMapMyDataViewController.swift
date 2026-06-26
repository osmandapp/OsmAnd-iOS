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
        static let myDataSegmentedControlHeight: CGFloat = 36
        static let resultRowMinHeight: CGFloat = 72
        static let buttonHeight: CGFloat = 44
    }

    private static let RISE_SET_PRELOAD_COUNT = 32

    var onObjectSelected: ((SkyObject) -> Void)?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }

    private let plugin: AstronomyPlugin
    private let dataProvider: AstroDataProvider
    private let nightMode: Bool

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
    private let myDataSegmentedControlContainer = UIView()
    private let myDataSegmentedControl = UISegmentedControl()
    private let sortFilterChipsView = SearchSortFilterChipsView()
    private let sortFilterChipsProvider = StarMapSearchSortFilterChipsProvider()
    private let resultsContainer = UIView()
    private let searchRecycler = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyStateContainer = UIStackView()
    private let emptyStateIcon = UIImageView()
    private let emptyStateTitle = UILabel()
    private let emptyStateDescription = UILabel()
    private let emptyStateResetButton = UIButton(type: .system)

    private weak var parentStarMapController: StarMapViewController?

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
        bindViews()
        setupNavigationBar()
        definesPresentationContext = true
        searchState.prepareForExploreEntry(currentTab.quickPresetType, catalogWid: nil)
        refreshPreparedEntries()
        setupSearchRecycler()
        updateSortFilterBar()
        updateEmptyStateContent()
        applyRedFilter(enabled: redFilterEnabled)
        applyFiltersAndSort(scrollToTop: false)
    }

    func applyRedFilter(enabled: Bool) {
        redFilterEnabled = enabled
        guard isViewLoaded else { return }
        AstroRedFilter.apply(enabled, to: navigationController?.view ?? view)
    }

    // MARK: - Layout

    private func bindViews() {
        mainStack.axis = .vertical
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)

        setupMyDataSegmentedControl()
        setupSortFilterChips()
        setupEmptyState()
        setupResultsContainer()

        mainStack.addArrangedSubview(myDataSegmentedControlContainer)
        mainStack.addArrangedSubview(sortFilterChipsView)
        mainStack.addArrangedSubview(resultsContainer)

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupMyDataSegmentedControl() {
        let tabTitles = [
            localizedString("favorites_item"),
            localizedString("astro_daily_path"),
            localizedString("astro_directions")
        ]
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
            myDataSegmentedControl.topAnchor.constraint(
                equalTo: myDataSegmentedControlContainer.topAnchor,
                constant: Layout.smallPadding
            ),
            myDataSegmentedControl.bottomAnchor.constraint(
                equalTo: myDataSegmentedControlContainer.bottomAnchor,
                constant: -Layout.smallPadding
            ),
            myDataSegmentedControl.heightAnchor.constraint(equalToConstant: Layout.myDataSegmentedControlHeight)
        ])
    }

    private func styleMyDataSegmentedControl() {
        myDataSegmentedControl.selectedSegmentTintColor = .white
        myDataSegmentedControl.backgroundColor = UIColor(
            red: 118 / 255,
            green: 118 / 255,
            blue: 128 / 255,
            alpha: 0.12
        )
        let font = UIFont.scaledSystemFont(ofSize: 13, weight: .semibold, maximumSize: 17)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: StarMapSearchLightPalette.primaryText,
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
        updateSortFilterBar()
        updateEmptyStateContent()
        sortFilterChipsView.setSortProgressVisible(true)
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
            sortFilterChipsView.setSortProgressVisible(false)
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

    private func updateSortFilterBar() {
        sortFilterChipsProvider.configure(
            searchState: searchState,
            configuration: .make(
                catalogMode: false,
                isMyData: true,
                showsShowAllVisibility: true,
                showsCategoriesSection: !searchState.isCategoryPreset()
            )
        )
        sortFilterChipsView.reloadData()
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

    // MARK: - Actions

    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func myDataSegmentChanged(_ sender: UISegmentedControl) {
        guard let tab = Tab(rawValue: sender.selectedSegmentIndex), tab != currentTab else { return }
        currentTab = tab
        searchState.prepareForExploreEntry(tab.quickPresetType, catalogWid: nil)
        syncSearchQuery()
        updateSortFilterBar()
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
