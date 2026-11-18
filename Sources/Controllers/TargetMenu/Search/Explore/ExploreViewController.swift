//
//  ExploreViewController.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objc protocol ExploreViewControllerDelegate: AnyObject {
    func exploreDidSelectHistoryItem(_ item: OAHistoryItem)
    func exploreDidSelectPopularPlace(_ poi: OAPOI)
    func exploreDidRequestShowPopularPlacesOnMap()
}

final class ExploreViewController: UIViewController {
    private enum Section: Int, CaseIterable {
        case popularPlaces
        case history
    }

    private enum Row {
        case popularPlace(PopularPlace)
        case showAllPopularPlaces
        case popularPlacesLoading
        case noInternet
        case noPopularPlaces
        case downloadWikiMaps
        case wikiMap(OAResourceSwiftItem)
        case historyItem(SearchHistoryRecord)
        case viewAllHistory
        case historyDisabled
    }

    private static let popularPlacesCount = 3
    private static let historyItemsLimit: Int32 = 25
    private static let topContentInset: CGFloat = 16

    @objc weak var delegate: ExploreViewControllerDelegate?

    @objc var searchNearMapCenter = false {
        didSet {
            if isViewLoaded {
                updateDistanceAndDirection()
            }
        }
    }

    @objc var searchLocation = kCLLocationCoordinate2DInvalid

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let settings: OAAppSettings = OAAppSettings.sharedManager()
    private let popularPlacesSearcher = PopularPlacesSearcher()
    private let downloadingHelper = DownloadingCellResourceHelper()
    private let historyQueue = DispatchQueue(label: "net.osmand.explore.history", qos: .userInitiated)

    private var rows: [[Row]] = Section.allCases.map { _ in [] }
    private var popularPlaces: [PopularPlace] = []
    private var wikiMapItems: [OAResourceSwiftItem] = []
    private var historyRecords: [SearchHistoryRecord] = []
    private var historyGeneration = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupDownloadingHelper()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startLoadingPopularPlaces()
        reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        popularPlacesSearcher.cancel()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard isViewLoaded, previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        tableView.reloadData()
    }

    @objc func reloadData() {
        reloadHistory()
        reload(.popularPlaces)
    }

    @objc func updateDistanceAndDirection() {
        guard isViewLoaded, !tableView.isDragging, !tableView.isDecelerating else { return }
        tableView.indexPathsForVisibleRows?.forEach { indexPath in
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            switch row(at: indexPath) {
            case .popularPlace(let place):
                guard var configuration = cell.contentConfiguration as? PoiContentConfiguration else { return }
                configuration.secondaryContent = popularPlaceSecondaryContent(for: place)
                cell.contentConfiguration = configuration
            case .historyItem(let record):
                guard var configuration = cell.contentConfiguration as? PointContentConfiguration else { return }
                configuration.secondaryContent = historySecondaryContent(for: record)
                cell.contentConfiguration = configuration
            default:
                break
            }
        }
    }

    private func setupTableView() {
        view.backgroundColor = .viewBg
        tableView.backgroundColor = .viewBg
        tableView.dataSource = self
        tableView.delegate = self
        tableView.alwaysBounceVertical = true
        tableView.contentInset.top = Self.topContentInset
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = PoiContentConfiguration.estimatedRowHeight
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 44
        tableView.register(PoiContentTableViewCell.self, forCellReuseIdentifier: PoiContentTableViewCell.reuseIdentifier)
        tableView.register(PointContentTableViewCell.self, forCellReuseIdentifier: PointContentTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OASimpleTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OASimpleTableViewCell.reuseIdentifier)
        tableView.register(HorizontalEmptyCell.self, forCellReuseIdentifier: HorizontalEmptyCell.reuseIdentifier)
        tableView.register(CollapsibleSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: CollapsibleSectionHeaderView.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(_:))))
    }

    private func setupDownloadingHelper() {
        downloadingHelper.hostViewController = self
        downloadingHelper.setHostTableView(tableView)
        downloadingHelper.delegate = self
        downloadingHelper.rightIconStyle = .hideIconAfterDownloading
    }

    private func isCollapsed(_ section: Section) -> Bool {
        switch section {
        case .popularPlaces:
            return settings.exploreNearbyItemsCollapsed.get()
        case .history:
            return settings.exploreHistoryCollapsed.get()
        }
    }

    private func isHistoryEnabled() -> Bool {
        settings.searchHistory.get() || settings.navigationHistory.get()
    }

    private func toggle(_ section: Section) {
        switch section {
        case .popularPlaces:
            let collapsed = !settings.exploreNearbyItemsCollapsed.get()
            settings.exploreNearbyItemsCollapsed.set(collapsed)
            if collapsed {
                popularPlacesSearcher.cancel()
            } else {
                startLoadingPopularPlaces()
            }
            reload(.popularPlaces, animated: true)
        case .history:
            let collapsed = !settings.exploreHistoryCollapsed.get()
            settings.exploreHistoryCollapsed.set(collapsed)
            (tableView.headerView(forSection: section.rawValue) as? CollapsibleSectionHeaderView)?.setExpanded(!collapsed)
            reloadHistory(animated: true)
        }
    }

    private func reload(_ section: Section, animated: Bool = false) {
        rows[section.rawValue] = buildRows(for: section)
        guard isViewLoaded else { return }
        if animated && tableView.window != nil {
            tableView.reloadSections(IndexSet(integer: section.rawValue), with: .automatic)
        } else {
            tableView.reloadData()
        }
    }

    private func buildRows(for section: Section) -> [Row] {
        guard !isCollapsed(section) else { return [] }
        switch section {
        case .popularPlaces:
            if !popularPlaces.isEmpty {
                return popularPlaces.prefix(Self.popularPlacesCount).map { .popularPlace($0) } + [.showAllPopularPlaces]
            }
            if !popularPlacesSearcher.isDataSourceAvailable {
                return [.noInternet]
            }
            if popularPlacesSearcher.isLoading {
                return [.popularPlacesLoading]
            }
            if wikiMapItems.isEmpty {
                return [.noPopularPlaces]
            }
            return [.downloadWikiMaps] + wikiMapItems.map { .wikiMap($0) }
        case .history:
            guard isHistoryEnabled() else { return [.historyDisabled] }
            return historyRecords.map { .historyItem($0) } + [.viewAllHistory]
        }
    }

    private func row(at indexPath: IndexPath) -> Row? {
        guard rows.indices.contains(indexPath.section), rows[indexPath.section].indices.contains(indexPath.row) else { return nil }
        return rows[indexPath.section][indexPath.row]
    }

    private func startLoadingPopularPlaces() {
        guard !isCollapsed(.popularPlaces), popularPlacesSearcher.isDataSourceAvailable, !popularPlacesSearcher.isLoading else { return }
        popularPlacesSearcher.load(detailedPlacesCount: Self.popularPlacesCount) { [weak self] places in
            guard let self else { return }
            popularPlaces = places
            wikiMapItems = popularPlaces.isEmpty ? OAResourcesUISwiftHelper.findWikiMapRegionsAtCurrentMapLocation() ?? [] : []
            reload(.popularPlaces)
        }
    }

    private func reloadHistory(animated: Bool = false) {
        historyGeneration += 1
        let generation = historyGeneration
        guard !isCollapsed(.history), isHistoryEnabled() else {
            historyRecords = []
            reload(.history, animated: animated)
            return
        }

        let searchHistoryEnabled = settings.searchHistory.get()
        let navigationHistoryEnabled = settings.navigationHistory.get()
        historyQueue.async { [weak self] in
            let items = OAHistoryHelper.sharedInstance().points(fromSearch: searchHistoryEnabled, fromNavigation: navigationHistoryEnabled, limit: Self.historyItemsLimit) ?? []
            let presenter = SearchHistoryItemPresenter()
            let records = items.map { presenter.record(for: $0) }
            DispatchQueue.main.async { [weak self] in
                guard let self, generation == historyGeneration else { return }
                historyRecords = records
                reload(.history, animated: animated)
            }
        }
    }

    private var locationReference: SearchLocationReference {
        SearchLocationReference(searchNearMapCenter: searchNearMapCenter, searchLocation: searchLocation)
    }

    private func popularPlaceSecondaryContent(for place: PopularPlace) -> PointSecondaryContent {
        locationReference.secondaryContent(latitude: place.poi.latitude, longitude: place.poi.longitude, trailingText: place.typeName)
    }

    private func historySecondaryContent(for record: SearchHistoryRecord) -> PointSecondaryContent {
        SearchHistoryItemPresenter.secondaryContent(for: record, locationReference: locationReference)
    }

    private func actionCell(at indexPath: IndexPath, title: String) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as? OASimpleTableViewCell else { return UITableViewCell() }
        cell.selectionStyle = .default
        cell.leftIconVisibility(false)
        cell.descriptionVisibility(false)
        cell.titleLabel.text = title
        cell.titleLabel.font = .preferredFont(forTextStyle: .body)
        cell.titleLabel.textColor = .textColorActive
        cell.accessibilityTraits = .button
        return cell
    }

    private func downloadWikiMapsCell(at indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as? OASimpleTableViewCell else { return UITableViewCell() }
        cell.selectionStyle = .none
        cell.leftIconVisibility(false)
        cell.descriptionVisibility(true)
        cell.titleLabel.text = localizedString("shared_string_download_map")
        cell.titleLabel.font = .preferredFont(forTextStyle: .headline)
        cell.titleLabel.textColor = .textColorPrimary
        cell.descriptionLabel.text = localizedString("wiki_menu_download_descr")
        cell.accessibilityTraits = .header
        return cell
    }

    private func emptyCell(at indexPath: IndexPath) -> HorizontalEmptyCell? {
        tableView.dequeueReusableCell(withIdentifier: HorizontalEmptyCell.reuseIdentifier, for: indexPath) as? HorizontalEmptyCell
    }

    private func retryLoadingPopularPlaces() {
        startLoadingPopularPlaces()
        reload(.popularPlaces)
    }

    private func openHistorySettings() {
        guard let controller = OAGlobalSettingsViewController(settingsType: EOAHistory) else { return }
        dismiss(animated: true)
        OARootViewController.instance()?.navigationController?.pushViewController(controller, animated: true)
    }

    private func openAllPopularPlaces() {
        let controller = PopularPlacesViewController(places: popularPlaces, locationReference: locationReference)
        controller.onSelectPlace = { [weak self] poi in
            self?.delegate?.exploreDidSelectPopularPlace(poi)
        }
        controller.onShowOnMap = { [weak self] in
            self?.delegate?.exploreDidRequestShowPopularPlacesOnMap()
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func openAllHistory() {
        let controller = SearchHistoryViewController()
        controller.onSelectItem = { [weak self] item in
            self?.delegate?.exploreDidSelectHistoryItem(item)
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func onLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let indexPath = tableView.indexPathForRow(at: gesture.location(in: tableView)),
              case .historyItem(let record) = row(at: indexPath),
              let controller = OAHistorySettingsViewController(settingsType: record.item.fromNavigation ? EOAHistorySettingsTypeNavigation : EOAHistorySettingsTypeSearch, editing: true) else { return }
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension ExploreViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = row(at: indexPath) else { return UITableViewCell() }
        switch row {
        case .popularPlace(let place):
            let cell = tableView.dequeueReusableCell(withIdentifier: PoiContentTableViewCell.reuseIdentifier, for: indexPath)
            cell.contentConfiguration = place.contentConfiguration(style: .compact, secondaryContent: popularPlaceSecondaryContent(for: place))
            cell.backgroundConfiguration = PointContentConfiguration.backgroundConfiguration()
            return cell
        case .historyItem(let record):
            let cell = tableView.dequeueReusableCell(withIdentifier: PointContentTableViewCell.reuseIdentifier, for: indexPath)
            cell.contentConfiguration = PointContentConfiguration(icon: SearchHistoryItemPresenter.icon(for: record.item, traitCollection: traitCollection),
                                                                  title: record.item.name ?? "",
                                                                  iconStyle: .plate,
                                                                  secondaryContent: historySecondaryContent(for: record))
            cell.backgroundConfiguration = PointContentConfiguration.backgroundConfiguration()
            return cell
        case .showAllPopularPlaces:
            return actionCell(at: indexPath, title: localizedString("shared_string_show_all"))
        case .viewAllHistory:
            return actionCell(at: indexPath, title: localizedString("shared_string_view_all"))
        case .popularPlacesLoading:
            guard let cell = emptyCell(at: indexPath) else { return UITableViewCell() }
            cell.configure(title: localizedString("shared_string_loading"),
                           description: "",
                           icon: nil,
                           iconTint: nil,
                           isSpinner: true)
            return cell
        case .noInternet:
            guard let cell = emptyCell(at: indexPath) else { return UITableViewCell() }
            cell.configure(title: localizedString("no_inet_connection"),
                           description: localizedString("no_internet_descr"),
                           icon: .icCustomWifiOff,
                           iconTint: .iconColorDefault,
                           actionTitle: localizedString("try_again"),
                           action: { [weak self] in self?.retryLoadingPopularPlaces() })
            return cell
        case .noPopularPlaces:
            guard let cell = emptyCell(at: indexPath) else { return UITableViewCell() }
            cell.configure(title: localizedString("no_places_available"),
                           description: localizedString("no_photos_available_descr"),
                           icon: .icCustomDesert,
                           iconTint: .iconColorDefault)
            return cell
        case .downloadWikiMaps:
            return downloadWikiMapsCell(at: indexPath)
        case .wikiMap(let item):
            return downloadingHelper.getOrCreateCell(item.resourceId(), swiftResourceItem: item) ?? UITableViewCell()
        case .historyDisabled:
            guard let cell = emptyCell(at: indexPath) else { return UITableViewCell() }
            cell.configure(title: localizedString("history_is_turned_off"),
                           description: localizedString("search_and_navigation_history_disabled_descr"),
                           icon: .icCustomHistoryDisabled48,
                           iconTint: .iconColorDefault,
                           actionTitle: localizedString("open_history_settings"),
                           action: { [weak self] in self?.openHistorySettings() })
            return cell
        }
    }
}

extension ExploreViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let section = Section(rawValue: section),
              let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: CollapsibleSectionHeaderView.reuseIdentifier) as? CollapsibleSectionHeaderView else { return nil }
        let title = localizedString(section == .popularPlaces ? "popular_places_nearby" : "shared_string_history")
        header.configure(title: title, isExpanded: !isCollapsed(section)) { [weak self] in
            self?.toggle(section)
        }
        return header
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch row(at: indexPath) {
        case .popularPlace, .showAllPopularPlaces, .wikiMap, .historyItem, .viewAllHistory:
            return indexPath
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch row(at: indexPath) {
        case .popularPlace(let place):
            delegate?.exploreDidSelectPopularPlace(place.poi)
        case .showAllPopularPlaces:
            openAllPopularPlaces()
        case .wikiMap(let item):
            downloadingHelper.onCellClicked(item.resourceId())
        case .historyItem(let record):
            delegate?.exploreDidSelectHistoryItem(record.item)
        case .viewAllHistory:
            openAllHistory()
        default:
            break
        }
    }
}

extension ExploreViewController: DownloadingCellResourceHelperDelegate {
    func onDownloadingCellResourceNeedUpdate(_ task: OADownloadTask?) {
    }

    func onStopDownload(_ resourceItem: OAResourceSwiftItem) {
    }

    func onDownloadTaskFinished(resourceId: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            popularPlacesSearcher.cancel()
            wikiMapItems = []
            startLoadingPopularPlaces()
            reload(.popularPlaces)
        }
    }
}
