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
    func exploreDidRequestAllPopularPlaces()
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
        case wikiMap(OAResourceSwiftItem)
        case historyItem(OAHistoryItem)
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

    @objc var searchLocation = kCLLocationCoordinate2DInvalid {
        didSet {
            guard oldValue.latitude != searchLocation.latitude || oldValue.longitude != searchLocation.longitude else { return }
            popularPlacesSearcher.cancel()
            popularPlaces = []
            wikiMapItems = []
            if viewIfLoaded?.window != nil {
                startLoadingPopularPlaces()
            }
            reload(.popularPlaces)
        }
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let settings: OAAppSettings = OAAppSettings.sharedManager()
    private let popularPlacesSearcher = PopularPlacesSearcher()
    private let downloadingHelper = DownloadingCellResourceHelper()
    private let historyQueue = DispatchQueue(label: "net.osmand.explore.history", qos: .userInitiated)

    private var rows: [[Row]] = Section.allCases.map { _ in [] }
    private var popularPlaces: [PopularPlace] = []
    private var wikiMapItems: [OAResourceSwiftItem] = []
    private var historyItems: [OAHistoryItem] = []
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
                configuration.secondaryContent = popularPlaceSecondaryContent(for: place.poi)
                cell.contentConfiguration = configuration
            case .historyItem(let item):
                guard var configuration = cell.contentConfiguration as? PointContentConfiguration else { return }
                configuration.secondaryContent = historySecondaryContent(for: item)
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
                return popularPlaces.map { .popularPlace($0) } + [.showAllPopularPlaces]
            }
            if !popularPlacesSearcher.isDataSourceAvailable {
                return [.noInternet]
            }
            if popularPlacesSearcher.isLoading {
                return [.popularPlacesLoading]
            }
            return [.noPopularPlaces] + wikiMapItems.map { .wikiMap($0) }
        case .history:
            guard isHistoryEnabled() else { return [.historyDisabled] }
            return historyItems.map { .historyItem($0) } + [.viewAllHistory]
        }
    }

    private func row(at indexPath: IndexPath) -> Row? {
        guard rows.indices.contains(indexPath.section), rows[indexPath.section].indices.contains(indexPath.row) else { return nil }
        return rows[indexPath.section][indexPath.row]
    }

    private func startLoadingPopularPlaces() {
        guard !isCollapsed(.popularPlaces),
              popularPlacesSearcher.isDataSourceAvailable,
              !popularPlacesSearcher.isLoading,
              let center = popularPlacesCenter() else { return }
        popularPlacesSearcher.load(center: center, limit: Self.popularPlacesCount) { [weak self] places in
            guard let self else { return }
            popularPlaces = places
            wikiMapItems = popularPlaces.isEmpty ? OAResourcesUISwiftHelper.findWikiMapRegions(at: center) ?? [] : []
            reload(.popularPlaces)
        }
    }

    private func popularPlacesCenter() -> CLLocationCoordinate2D? {
        if CLLocationCoordinate2DIsValid(searchLocation) {
            return searchLocation
        }
        return OARootViewController.instance()?.mapPanel?.mapViewController.getMapLocation().coordinate
    }

    private func reloadHistory(animated: Bool = false) {
        historyGeneration += 1
        let generation = historyGeneration
        guard !isCollapsed(.history), isHistoryEnabled() else {
            historyItems = []
            reload(.history, animated: animated)
            return
        }

        let searchHistoryEnabled = settings.searchHistory.get()
        let navigationHistoryEnabled = settings.navigationHistory.get()
        historyQueue.async { [weak self] in
            let helper: OAHistoryHelper = OAHistoryHelper.sharedInstance()
            let items = searchHistoryEnabled
                ? helper.getPointsHavingTypes(helper.searchTypes, exceptNavigation: !navigationHistoryEnabled, limit: Self.historyItemsLimit)
                : helper.getPointsFromNavigation(Self.historyItemsLimit)
            DispatchQueue.main.async { [weak self] in
                guard let self, generation == historyGeneration else { return }
                historyItems = items ?? []
                reload(.history, animated: animated)
            }
        }
    }

    private func distanceAndDirection(latitude: Double, longitude: Double) -> (distance: String?, direction: CGFloat, color: UIColor) {
        if searchNearMapCenter && CLLocationCoordinate2DIsValid(searchLocation) {
            let center = CLLocation(latitude: searchLocation.latitude, longitude: searchLocation.longitude)
            let meters = OADistanceAndDirectionsUpdater.distance(from: center, toDestinationLatitude: latitude, destinationLongitude: longitude)
            let azimuth = OARootViewController.instance()?.mapPanel?.mapViewController.azimuth() ?? 0
            let direction = OADistanceAndDirectionsUpdater.directionAngle(from: center,
                                                                          sourceDirection: CLLocationDirection(azimuth),
                                                                          toDestinationLatitude: latitude,
                                                                          destinationLongitude: longitude)
            return (OAOsmAndFormatter.getFormattedDistance(Float(meters)), direction, .iconColorDirectionMapCenter)
        }

        guard let location = OsmAndApp.swiftInstance()?.locationServices?.lastKnownLocation else { return (nil, 0, .iconColorDirectionActive) }
        let meters = OADistanceAndDirectionsUpdater.distance(from: location, toDestinationLatitude: latitude, destinationLongitude: longitude)
        let direction = OADistanceAndDirectionsUpdater.directionAngle(from: location, toDestinationLatitude: latitude, destinationLongitude: longitude)
        return (OAOsmAndFormatter.getFormattedDistance(Float(meters)), direction, .iconColorDirectionActive)
    }

    private func popularPlaceSecondaryContent(for poi: OAPOI) -> PointSecondaryContent {
        let metrics = distanceAndDirection(latitude: poi.latitude, longitude: poi.longitude)
        return PointSecondaryContent(formattedDistance: metrics.distance,
                                     direction: metrics.direction,
                                     directionColor: metrics.color,
                                     address: nil,
                                     date: nil,
                                     trailingText: poi.type?.nameLocalized)
    }

    private func historySecondaryContent(for item: OAHistoryItem) -> PointSecondaryContent {
        let metrics = distanceAndDirection(latitude: item.latitude, longitude: item.longitude)
        let typeName = item.typeName ?? ""
        return PointSecondaryContent(formattedDistance: metrics.distance,
                                     direction: metrics.direction,
                                     directionColor: metrics.color,
                                     address: typeName.isEmpty ? localizedString("shared_string_history") : typeName,
                                     date: nil)
    }

    private func popularPlaceConfiguration(for place: PopularPlace) -> PoiContentConfiguration {
        let poi = place.poi
        let name = poi.getName(settings.settingPrefMapLanguage.get(), transliterate: settings.settingMapLanguageTranslit.get()) ?? poi.nameLocalized ?? poi.name ?? ""
        let openingHours = OAPOIHelper.sharedInstance().getShortFormattedOpeningHours(place.detailedPoi)
        var openingHoursColor: UIColor?
        if !openingHours.isEmpty, let parser = OAOpeningHoursParser(string: place.detailedPoi.openingHours) {
            openingHoursColor = parser.isOpenedForTime() ? .accentsGreen : .textColorDisruptive
        }
        let imageURL = settings.wikiShowImagePreviews.get() ? poi.wikiIconUrl.flatMap { URL(string: $0) } : nil
        return PoiContentConfiguration(style: .compact,
                                       title: name,
                                       icon: poi.icon(),
                                       imageURL: imageURL,
                                       secondaryContent: popularPlaceSecondaryContent(for: poi),
                                       address: place.address,
                                       openingHours: openingHours,
                                       openingHoursColor: openingHoursColor)
    }

    private func actionCell(at indexPath: IndexPath, title: String) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as? OASimpleTableViewCell else { return UITableViewCell() }
        cell.selectionStyle = .default
        cell.leftIconVisibility(false)
        cell.descriptionVisibility(false)
        cell.titleLabel.text = title
        cell.titleLabel.textColor = .textColorActive
        cell.accessibilityTraits = .button
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
        guard let controller = OAHistorySettingsViewController(settingsType: EOAHistorySettingsTypeSearch, editing: false) else { return }
        dismiss(animated: true)
        OARootViewController.instance()?.navigationController?.pushViewController(controller, animated: true)
    }

    private func openAllHistory() {
        let searchHistoryEnabled = settings.searchHistory.get()
        let navigationHistoryEnabled = settings.navigationHistory.get()
        let controller: UIViewController?
        if searchHistoryEnabled && navigationHistoryEnabled {
            controller = OAGlobalSettingsViewController(settingsType: EOAHistory)
        } else {
            controller = OAHistorySettingsViewController(settingsType: searchHistoryEnabled ? EOAHistorySettingsTypeSearch : EOAHistorySettingsTypeNavigation, editing: false)
        }
        guard let controller else { return }
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func onLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let indexPath = tableView.indexPathForRow(at: gesture.location(in: tableView)),
              case .historyItem(let item) = row(at: indexPath),
              let controller = OAHistorySettingsViewController(settingsType: item.fromNavigation ? EOAHistorySettingsTypeNavigation : EOAHistorySettingsTypeSearch, editing: true) else { return }
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
            cell.contentConfiguration = popularPlaceConfiguration(for: place)
            cell.backgroundConfiguration = PointContentConfiguration.backgroundConfiguration()
            return cell
        case .historyItem(let item):
            let cell = tableView.dequeueReusableCell(withIdentifier: PointContentTableViewCell.reuseIdentifier, for: indexPath)
            cell.contentConfiguration = PointContentConfiguration(icon: item.icon(), title: item.name ?? "", secondaryContent: historySecondaryContent(for: item))
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
                           description: wikiMapItems.isEmpty ? "" : localizedString("wiki_menu_download_descr"),
                           icon: .icCustomWikipedia,
                           iconTint: .iconColorDefault)
            return cell
        case .wikiMap(let item):
            return downloadingHelper.getOrCreateCell(item.resourceId(), swiftResourceItem: item) ?? UITableViewCell()
        case .historyDisabled:
            guard let cell = emptyCell(at: indexPath) else { return UITableViewCell() }
            cell.configure(title: localizedString("search_history_disabled"),
                           description: localizedString("enable_search_history"),
                           icon: .icCustomHistoryDisabled48,
                           iconTint: .iconColorDefault,
                           actionTitle: localizedString("shared_string_settings"),
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
            delegate?.exploreDidRequestAllPopularPlaces()
        case .wikiMap(let item):
            downloadingHelper.onCellClicked(item.resourceId())
        case .historyItem(let item):
            delegate?.exploreDidSelectHistoryItem(item)
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
            popularPlacesSearcher.invalidate()
            wikiMapItems = []
            startLoadingPopularPlaces()
            reload(.popularPlaces)
        }
    }
}
