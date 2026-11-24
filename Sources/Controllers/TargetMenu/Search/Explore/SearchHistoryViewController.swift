//
//  SearchHistoryViewController.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class SearchHistoryViewController: OABaseNavbarViewController {
    private enum SortMode: String, CaseIterable {
        case recent
        case nearest
        case mapCenter

        var title: String {
            switch self {
            case .recent:
                return localizedString("shared_string_recent")
            case .nearest:
                return localizedString("shared_string_nearest")
            case .mapCenter:
                return localizedString("sort_by_nearest_to_map_center")
            }
        }
    }

    private enum Source: String, CaseIterable {
        case all
        case search
        case navigation

        var title: String {
            switch self {
            case .all:
                return localizedString("shared_string_all")
            case .search:
                return localizedString("shared_string_search")
            case .navigation:
                return localizedString("shared_string_navigation")
            }
        }

        var icon: UIImage {
            switch self {
            case .all:
                return .icCustomHistory
            case .search:
                return .icCustomSearch
            case .navigation:
                return .icCustomNavigation
            }
        }
    }

    private struct RecordsSection {
        let title: String?
        var records: [SearchHistoryRecord]
    }

    private static let sortGroupId = "sort"
    private static let sourceGroupId = "source"
    private static let chipIconSize: CGFloat = 20
    private static let sortIconPointSize: CGFloat = 15
    private static let chipsTopInset: CGFloat = 8
    private static let chipsSpacing: CGFloat = 8
    private static let chipsBottomInset: CGFloat = 16
    private static let distanceUpdateInterval: TimeInterval = 0.3
    private static let lastWeekDays = 7

    var onSelectItem: ((OAHistoryItem) -> Void)?

    private let settings: OAAppSettings = OAAppSettings.sharedManager()
    private let historyQueue = DispatchQueue(label: "net.osmand.search.history", qos: .userInitiated)
    private let chipsHeaderView = UIView()
    private let chipsStackView = UIStackView()
    private let filterChipsView = StarMapSearchSortFilterChipsView()
    private let categoryChipsView = StarMapSearchSortFilterChipsView()
    private let searchController = UISearchController(searchResultsController: nil)
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("LLLLyyyy")
        return formatter
    }()

    private var sortMode: SortMode = .recent
    private var selectedSource: Source = .all
    private var searchText = ""
    private var records: [SearchHistoryRecord] = []
    private var categoryNames: [String] = []
    private var selectedCategoryNames: Set<String> = []
    private var hasRecords = false
    private var isLoaded = false
    private var sections: [RecordsSection] = []
    private var locationReference = SearchLocationReference(searchNearMapCenter: false, searchLocation: kCLLocationCoordinate2DInvalid)
    private var loadGeneration = 0
    private var lastDistanceUpdate: TimeInterval = 0

    init() {
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
        initTableData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = PointContentConfiguration.estimatedRowHeight
        tableView.sectionHeaderTopPadding = 0
        tableView.keyboardDismissMode = .onDrag
        tableView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(_:))))
        setupSearchController()
        setupChips()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadHistory()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateChipsHeaderSize()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard isViewLoaded else { return }
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            filterChipsView.reloadData()
            categoryChipsView.reloadData()
            view.setNeedsLayout()
        }
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            tableView.reloadData()
        }
    }

    override func registerObservers() {
        let app: OsmAndAppProtocol = OsmAndApp.swiftInstance()
        let selector = #selector(onLocationServicesUpdate)
        addObserver(OAAutoObserverProxy(self, withHandler: selector, andObserve: app.locationServices.updateLocationObserver))
        addObserver(OAAutoObserverProxy(self, withHandler: selector, andObserve: app.locationServices.updateHeadingObserver))
    }

    override func registerCells() {
        tableView.register(PointContentTableViewCell.self, forCellReuseIdentifier: PointContentTableViewCell.reuseIdentifier)
        tableView.register(HorizontalEmptyCell.self, forCellReuseIdentifier: HorizontalEmptyCell.reuseIdentifier)
    }

    override func tableStyle() -> UITableView.Style {
        .insetGrouped
    }

    override func getTitle() -> String! {
        localizedString("shared_string_history")
    }

    override func getRightNavbarButtons() -> [UIBarButtonItem]! {
        guard let button = createRightNavbarButton(nil, iconName: "ic_custom_settings_outlined", action: #selector(onRightNavbarButtonPressed), menu: nil) else { return [] }
        button.accessibilityLabel = localizedString("shared_string_settings")
        return [button]
    }

    override func onRightNavbarButtonPressed() {
        openHistorySettings()
    }

    override func useCustomTableViewHeader() -> Bool {
        true
    }

    override func hideFirstHeader() -> Bool {
        sections.first?.title == nil
    }

    override func sectionsCount() -> Int {
        max(1, sections.count)
    }

    override func getTitleForHeader(_ section: Int) -> String? {
        sections.indices.contains(section) ? sections[section].title : nil
    }

    override func rowsCount(_ section: Int) -> Int {
        guard sections.indices.contains(section) else { return isLoaded && (isHistoryDisabled || !query.isEmpty) ? 1 : 0 }
        return sections[section].records.count
    }

    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        guard let record = record(at: indexPath) else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HorizontalEmptyCell.reuseIdentifier, for: indexPath) as? HorizontalEmptyCell else { return UITableViewCell() }
            if isHistoryDisabled {
                cell.configure(title: localizedString("history_is_turned_off"),
                               description: localizedString("search_and_navigation_history_disabled_descr"),
                               icon: .icCustomHistoryDisabled48,
                               iconTint: .iconColorDefault,
                               actionTitle: localizedString("open_history_settings"),
                               action: { [weak self] in self?.openHistorySettings() })
            } else {
                cell.configure(title: localizedString("nothing_found"),
                               description: "",
                               icon: .icCustomSearch,
                               iconTint: .iconColorDefault)
            }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: PointContentTableViewCell.reuseIdentifier, for: indexPath)
        cell.contentConfiguration = PointContentConfiguration(icon: SearchHistoryItemPresenter.icon(for: record, traitCollection: traitCollection),
                                                              title: record.title,
                                                              iconStyle: .plate,
                                                              secondaryContent: secondaryContent(for: record))
        PointContentConfiguration.applyHighlightableBackground(to: cell)
        return cell
    }

    override func onRowSelected(_ indexPath: IndexPath!) {
        guard let record = record(at: indexPath) else { return }
        onSelectItem?(record.item)
    }

    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearchHistoryEnabled: Bool {
        settings.searchHistory.get()
    }

    private var isNavigationHistoryEnabled: Bool {
        settings.navigationHistory.get()
    }

    private var isHistoryDisabled: Bool {
        !isSearchHistoryEnabled && !isNavigationHistoryEnabled
    }

    private var isSourceMenuDisabled: Bool {
        !isSearchHistoryEnabled || !isNavigationHistoryEnabled
    }

    private var effectiveSource: Source {
        if isSearchHistoryEnabled && !isNavigationHistoryEnabled {
            return .search
        }
        if !isSearchHistoryEnabled && isNavigationHistoryEnabled {
            return .navigation
        }
        return selectedSource
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = localizedString("shared_string_search")
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        if #available(iOS 26.0, *) {
            navigationItem.searchBarPlacementAllowsToolbarIntegration = false
            navigationItem.preferredSearchBarPlacement = .stacked
        }
        definesPresentationContext = true
    }

    private func setupChips() {
        filterChipsView.dataSource = self
        filterChipsView.delegate = self
        categoryChipsView.dataSource = self
        categoryChipsView.delegate = self
        categoryChipsView.isHidden = true
        chipsStackView.axis = .vertical
        chipsStackView.spacing = Self.chipsSpacing
        chipsStackView.translatesAutoresizingMaskIntoConstraints = false
        chipsStackView.addArrangedSubview(filterChipsView)
        chipsStackView.addArrangedSubview(categoryChipsView)
        chipsHeaderView.preservesSuperviewLayoutMargins = true
        chipsHeaderView.addSubview(chipsStackView)
        NSLayoutConstraint.activate([
            chipsStackView.topAnchor.constraint(equalTo: chipsHeaderView.topAnchor, constant: Self.chipsTopInset),
            chipsStackView.leadingAnchor.constraint(equalTo: chipsHeaderView.layoutMarginsGuide.leadingAnchor),
            chipsStackView.trailingAnchor.constraint(equalTo: chipsHeaderView.layoutMarginsGuide.trailingAnchor),
            chipsStackView.bottomAnchor.constraint(equalTo: chipsHeaderView.bottomAnchor, constant: -Self.chipsBottomInset)
        ])
        filterChipsView.reloadData()
        tableView.tableHeaderView = chipsHeaderView
    }

    private func updateChipsHeaderSize() {
        let width = tableView.bounds.width
        guard width > 0 else { return }
        let height = chipsHeaderView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                                                             withHorizontalFittingPriority: .required,
                                                             verticalFittingPriority: .fittingSizeLevel).height
        guard chipsHeaderView.frame.width != width || abs(chipsHeaderView.frame.height - height) > 0.5 else { return }
        chipsHeaderView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        tableView.tableHeaderView = chipsHeaderView
    }

    private func reloadHistory() {
        loadGeneration += 1
        let generation = loadGeneration
        guard !isHistoryDisabled else {
            records = []
            updateDisplayedRecords()
            return
        }

        let source = effectiveSource
        historyQueue.async { [weak self] in
            let items = OAHistoryHelper.sharedInstance().points(fromSearch: source != .navigation, fromNavigation: source != .search, limit: 0) ?? []
            let presenter = SearchHistoryItemPresenter()
            let records = items.compactMap { presenter.record(for: $0) }
            DispatchQueue.main.async { [weak self] in
                guard let self, generation == loadGeneration else { return }
                self.records = records
                updateDisplayedRecords()
            }
        }
    }

    private func updateDisplayedRecords() {
        isLoaded = true
        let query = self.query
        let matchingRecords = query.isEmpty ? records : records.filter { matches($0, query: query) }
        hasRecords = !matchingRecords.isEmpty
        updateCategories(for: matchingRecords)
        let filteredRecords = selectedCategoryNames.isEmpty ? matchingRecords : matchingRecords.filter { selectedCategoryNames.contains($0.categoryName) }
        locationReference = makeLocationReference()
        sections = makeSections(for: sortedRecords(filteredRecords))
        filterChipsView.reloadData()
        categoryChipsView.reloadData()
        categoryChipsView.isHidden = categoryNames.isEmpty
        view.setNeedsLayout()
        tableView.reloadData()
    }

    private func matches(_ record: SearchHistoryRecord, query: String) -> Bool {
        [record.title, record.item.typeName, record.typeText, record.categoryName].contains { $0?.localizedCaseInsensitiveContains(query) == true }
    }

    private func updateCategories(for records: [SearchHistoryRecord]) {
        var counts: [String: Int] = [:]
        var order: [String] = []
        for record in records where !record.categoryName.isEmpty {
            if counts[record.categoryName] == nil {
                order.append(record.categoryName)
            }
            counts[record.categoryName, default: 0] += 1
        }
        categoryNames = order.enumerated()
            .sorted { lhs, rhs in
                let lhsCount = counts[lhs.element] ?? 0
                let rhsCount = counts[rhs.element] ?? 0
                return lhsCount == rhsCount ? lhs.offset < rhs.offset : lhsCount > rhsCount
            }
            .map(\.element)
        selectedCategoryNames.formIntersection(categoryNames)
    }

    private func makeLocationReference() -> SearchLocationReference {
        guard sortMode == .mapCenter,
              let mapCenter = OARootViewController.instance()?.mapPanel?.mapViewController.getMapLocation() else {
            return SearchLocationReference(searchNearMapCenter: false, searchLocation: kCLLocationCoordinate2DInvalid)
        }
        return SearchLocationReference(searchNearMapCenter: true, searchLocation: mapCenter.coordinate)
    }

    private func sortedRecords(_ records: [SearchHistoryRecord]) -> [SearchHistoryRecord] {
        guard sortMode != .recent else {
            return records.sorted { ($0.item.date ?? .distantPast) > ($1.item.date ?? .distantPast) }
        }
        guard let origin = locationReference.location else { return records }
        return records
            .map { record in (record, record.coordinate.map { origin.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) } ?? .greatestFiniteMagnitude) }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    private func makeSections(for records: [SearchHistoryRecord]) -> [RecordsSection] {
        guard sortMode == .recent else {
            return records.isEmpty ? [] : [RecordsSection(title: nil, records: records)]
        }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        var sections: [RecordsSection] = []
        for record in records {
            let title = sectionTitle(for: record.item.date ?? .distantPast, todayStart: todayStart, calendar: calendar)
            if sections.last?.title == title {
                sections[sections.count - 1].records.append(record)
            } else {
                sections.append(RecordsSection(title: title, records: [record]))
            }
        }
        return sections
    }

    private func sectionTitle(for date: Date, todayStart: Date, calendar: Calendar) -> String {
        let itemStart = calendar.startOfDay(for: date)
        if itemStart >= todayStart {
            return localizedString("today")
        }
        if let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart),
           itemStart >= yesterdayStart, itemStart < todayStart {
            return localizedString("yesterday")
        }
        if let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart),
           let lastWeekStart = calendar.date(byAdding: .day, value: -Self.lastWeekDays, to: todayStart),
           itemStart >= lastWeekStart, itemStart < yesterdayStart {
            return localizedString("last_week")
        }
        let month = monthFormatter.string(from: date)
        return OAUtilities.capitalizeFirstLetter(month) ?? month
    }

    private func record(at indexPath: IndexPath?) -> SearchHistoryRecord? {
        guard let indexPath,
              sections.indices.contains(indexPath.section),
              sections[indexPath.section].records.indices.contains(indexPath.row) else { return nil }
        return sections[indexPath.section].records[indexPath.row]
    }

    private func secondaryContent(for record: SearchHistoryRecord) -> PointSecondaryContent {
        SearchHistoryItemPresenter.secondaryContent(for: record, locationReference: locationReference, showsDate: sortMode != .recent)
    }

    private func openHistorySettings() {
        guard let controller = OAGlobalSettingsViewController(settingsType: EOAHistory) else { return }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func scrollToTop() {
        tableView.setContentOffset(CGPoint(x: 0, y: -tableView.adjustedContentInset.top), animated: false)
    }

    @objc private func onLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let indexPath = tableView.indexPathForRow(at: gesture.location(in: tableView)),
              let record = record(at: indexPath),
              let controller = OAHistorySettingsViewController(settingsType: record.item.fromNavigation ? EOAHistorySettingsTypeNavigation : EOAHistorySettingsTypeSearch, editing: true) else { return }
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func onLocationServicesUpdate() {
        DispatchQueue.main.async { [weak self] in
            self?.updateDistanceAndDirection()
        }
    }

    private func updateDistanceAndDirection() {
        let now = Date().timeIntervalSince1970
        guard isViewLoaded,
              view.window != nil,
              sortMode != .mapCenter,
              now - lastDistanceUpdate >= Self.distanceUpdateInterval,
              !tableView.isDragging,
              !tableView.isDecelerating else { return }
        lastDistanceUpdate = now
        if sortMode == .nearest,
           !tableView.visibleCells.contains(where: \.isHighlighted),
           let records = sections.first?.records {
            let sorted = sortedRecords(records)
            if !sorted.elementsEqual(records, by: { $0.item === $1.item }) {
                sections = makeSections(for: sorted)
                tableView.reloadData()
                return
            }
        }
        tableView.indexPathsForVisibleRows?.forEach { indexPath in
            guard let record = record(at: indexPath),
                  let cell = tableView.cellForRow(at: indexPath),
                  var configuration = cell.contentConfiguration as? PointContentConfiguration else { return }
            configuration.secondaryContent = secondaryContent(for: record)
            cell.contentConfiguration = configuration
        }
    }
}

extension SearchHistoryViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text ?? ""
        guard text != searchText else { return }
        searchText = text
        updateDisplayedRecords()
    }
}

extension SearchHistoryViewController: StarMapSearchSortFilterChipsDataSource, StarMapSearchSortFilterChipsDelegate {
    func chipGroups(for chipsView: StarMapSearchSortFilterChipsView) -> [SearchSortFilterChipGroup] {
        chipsView === categoryChipsView ? categoryChipGroups() : filterChipGroups()
    }

    func chipsView(_ chipsView: StarMapSearchSortFilterChipsView, didSelectOption optionId: String, inGroup groupId: String) {
        switch groupId {
        case Self.sortGroupId:
            guard let mode = SortMode(rawValue: optionId), mode != sortMode else { return }
            sortMode = mode
            updateDisplayedRecords()
            scrollToTop()
        case Self.sourceGroupId:
            guard let source = Source(rawValue: optionId), source != selectedSource else { return }
            selectedSource = source
            reloadHistory()
            scrollToTop()
        default:
            break
        }
    }

    func chipsView(_ chipsView: StarMapSearchSortFilterChipsView, didToggleGroup groupId: String, isOn: Bool) {
        guard chipsView === categoryChipsView else { return }
        if isOn {
            selectedCategoryNames.insert(groupId)
        } else {
            selectedCategoryNames.remove(groupId)
        }
        updateDisplayedRecords()
        scrollToTop()
    }

    private func filterChipGroups() -> [SearchSortFilterChipGroup] {
        let sortOptions = SortMode.allCases.map { mode in
            StarMapSearchSortFilterChipOption(id: mode.rawValue,
                                              title: mode.title,
                                              image: nil,
                                              originalSizeImage: nil,
                                              isSelected: mode == sortMode)
        }
        let source = effectiveSource
        let sourceOptions = Source.allCases.map { option in
            StarMapSearchSortFilterChipOption(id: option.rawValue,
                                              title: option.title,
                                              image: option.icon.resizedTemplateImage(with: Self.chipIconSize),
                                              originalSizeImage: option.icon.withRenderingMode(.alwaysTemplate),
                                              isSelected: option == source)
        }
        let sortIcon = UIImage(systemName: "arrow.up.arrow.down",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: Self.sortIconPointSize))
        return [
            SearchSortFilterChipGroup(id: Self.sortGroupId,
                                      chipTitle: sortMode.title,
                                      chipImage: sortIcon,
                                      selectionMode: .single,
                                      sections: [StarMapSearchSortFilterChipSection(options: sortOptions)],
                                      menuTitle: localizedString("sort_by"),
                                      isEnabled: !isHistoryDisabled && hasRecords),
            SearchSortFilterChipGroup(id: Self.sourceGroupId,
                                      chipTitle: source.title,
                                      chipImage: source.icon.resizedTemplateImage(with: Self.chipIconSize),
                                      selectionMode: .single,
                                      sections: [StarMapSearchSortFilterChipSection(options: sourceOptions)],
                                      menuTitle: localizedString("shared_string_type"),
                                      isEnabled: !isSourceMenuDisabled)
        ]
    }

    private func categoryChipGroups() -> [SearchSortFilterChipGroup] {
        categoryNames.map { name in
            SearchSortFilterChipGroup(id: name,
                                      chipTitle: name,
                                      chipImage: nil,
                                      selectionMode: .toggle,
                                      isToggleOn: selectedCategoryNames.contains(name))
        }
    }
}
