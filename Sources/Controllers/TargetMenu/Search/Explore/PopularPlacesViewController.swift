//
//  PopularPlacesViewController.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PopularPlacesViewController: OABaseNavbarViewController {
    private enum SortMode: String, CaseIterable {
        case nearest
        case relevance

        var title: String {
            switch self {
            case .nearest:
                return localizedString("shared_string_nearest")
            case .relevance:
                return localizedString("sort_by_relevance")
            }
        }

        var icon: UIImage {
            switch self {
            case .nearest:
                return .icCustomSortNear
            case .relevance:
                return .icCustomPopularPlaces
            }
        }
    }

    private static let sortGroupId = "sort"
    private static let chipIconSize: CGFloat = 20
    private static let chipsTopInset: CGFloat = 8
    private static let chipsBottomInset: CGFloat = 16
    private static let showOnMapButtonHeight: CGFloat = 44
    private static let showOnMapButtonSideInset: CGFloat = 12
    private static let showOnMapButtonSafeAreaInset: CGFloat = 2
    private static let showOnMapButtonMinBottomInset: CGFloat = 16
    private static let showOnMapButtonListSpacing: CGFloat = 16
    private static let distanceUpdateInterval: TimeInterval = 0.3

    var onSelectPlace: ((OAPOI) -> Void)?
    var onShowOnMap: (() -> Void)?

    private let places: [PopularPlace]
    private let locationReference: SearchLocationReference
    private let detailsLoader = PopularPlaceDetailsLoader()
    private let sortChipsHeaderView = UIView()
    private let sortChipsView = StarMapSearchSortFilterChipsView()
    private let showOnMapButton = UIButton(type: .system)
    private let searchController = UISearchController(searchResultsController: nil)

    private var sortMode: SortMode = .relevance
    private var searchText = ""
    private var displayedPlaces: [PopularPlace] = []
    private var lastDistanceUpdate: TimeInterval = 0

    init(places: [PopularPlace], locationReference: SearchLocationReference) {
        self.places = places
        self.locationReference = locationReference
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
        initTableData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = PoiContentConfiguration.estimatedRowHeight
        tableView.sectionHeaderTopPadding = 0
        tableView.keyboardDismissMode = .onDrag
        tableView.prefetchDataSource = self
        setupSearchController()
        setupSortChips()
        setupShowOnMapButton()
        detailsLoader.onDetailsLoaded = { [weak self] place in
            self?.reconfigureRow(for: place)
        }
        updateDisplayedPlaces()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSortChipsHeaderSize()
        updateContentInsetForShowOnMapButton()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            detailsLoader.cancelAll()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard isViewLoaded,
              previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory else { return }
        sortChipsView.reloadData()
        view.setNeedsLayout()
    }

    override func registerObservers() {
        let app: OsmAndAppProtocol = OsmAndApp.swiftInstance()
        let selector = #selector(onLocationServicesUpdate)
        addObserver(OAAutoObserverProxy(self, withHandler: selector, andObserve: app.locationServices.updateLocationObserver))
        addObserver(OAAutoObserverProxy(self, withHandler: selector, andObserve: app.locationServices.updateHeadingObserver))
    }

    override func registerCells() {
        tableView.register(PoiContentTableViewCell.self, forCellReuseIdentifier: PoiContentTableViewCell.reuseIdentifier)
        tableView.register(HorizontalEmptyCell.self, forCellReuseIdentifier: HorizontalEmptyCell.reuseIdentifier)
    }

    override func tableStyle() -> UITableView.Style {
        .insetGrouped
    }

    override func getTitle() -> String! {
        localizedString("popular_places")
    }

    override func useCustomTableViewHeader() -> Bool {
        true
    }

    override func hideFirstHeader() -> Bool {
        true
    }

    override func sectionsCount() -> Int {
        1
    }

    override func rowsCount(_ section: Int) -> Int {
        displayedPlaces.isEmpty ? 1 : displayedPlaces.count
    }

    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        guard let place = place(at: indexPath) else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HorizontalEmptyCell.reuseIdentifier, for: indexPath) as? HorizontalEmptyCell else { return UITableViewCell() }
            cell.configure(title: localizedString("nothing_found"),
                           description: "",
                           icon: .icCustomSearch,
                           iconTint: .iconColorDefault)
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: PoiContentTableViewCell.reuseIdentifier, for: indexPath)
        cell.contentConfiguration = place.contentConfiguration(style: .detailed, secondaryContent: secondaryContent(for: place))
        cell.backgroundConfiguration = PointContentConfiguration.backgroundConfiguration()
        detailsLoader.request(place)
        return cell
    }

    override func onRowSelected(_ indexPath: IndexPath!) {
        guard let place = place(at: indexPath) else { return }
        onSelectPlace?(place.poi)
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

    private func setupSortChips() {
        sortChipsView.dataSource = self
        sortChipsView.delegate = self
        sortChipsView.translatesAutoresizingMaskIntoConstraints = false
        sortChipsHeaderView.preservesSuperviewLayoutMargins = true
        sortChipsHeaderView.addSubview(sortChipsView)
        NSLayoutConstraint.activate([
            sortChipsView.topAnchor.constraint(equalTo: sortChipsHeaderView.topAnchor, constant: Self.chipsTopInset),
            sortChipsView.leadingAnchor.constraint(equalTo: sortChipsHeaderView.layoutMarginsGuide.leadingAnchor),
            sortChipsView.trailingAnchor.constraint(equalTo: sortChipsHeaderView.layoutMarginsGuide.trailingAnchor),
            sortChipsView.bottomAnchor.constraint(equalTo: sortChipsHeaderView.bottomAnchor, constant: -Self.chipsBottomInset)
        ])
        sortChipsView.reloadData()
        tableView.tableHeaderView = sortChipsHeaderView
    }

    private func setupShowOnMapButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .capsule
        configuration.baseBackgroundColor = .buttonAccentsBlue
        configuration.baseForegroundColor = .white
        configuration.title = localizedString("shared_string_show_on_map")
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Self.showOnMapButtonSideInset, bottom: 0, trailing: Self.showOnMapButtonSideInset)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .scaledSystemFont(ofSize: 17, weight: .regular, maximumSize: 22)
            return outgoing
        }
        showOnMapButton.configuration = configuration
        showOnMapButton.addAction(UIAction { [weak self] _ in
            self?.onShowOnMap?()
        }, for: .touchUpInside)
        showOnMapButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(showOnMapButton)
        let safeAreaBottomConstraint = showOnMapButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Self.showOnMapButtonSafeAreaInset)
        safeAreaBottomConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            showOnMapButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            showOnMapButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
            showOnMapButton.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor),
            showOnMapButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.showOnMapButtonHeight),
            showOnMapButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -Self.showOnMapButtonMinBottomInset),
            safeAreaBottomConstraint
        ])
    }

    private func updateSortChipsHeaderSize() {
        let width = tableView.bounds.width
        guard width > 0 else { return }
        let height = sortChipsHeaderView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                                                                 withHorizontalFittingPriority: .required,
                                                                 verticalFittingPriority: .fittingSizeLevel).height
        guard sortChipsHeaderView.frame.width != width || abs(sortChipsHeaderView.frame.height - height) > 0.5 else { return }
        sortChipsHeaderView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        tableView.tableHeaderView = sortChipsHeaderView
    }

    private func updateContentInsetForShowOnMapButton() {
        let inset = max(0, view.safeAreaLayoutGuide.layoutFrame.maxY - showOnMapButton.frame.minY) + Self.showOnMapButtonListSpacing
        guard abs(tableView.contentInset.bottom - inset) > 0.5 else { return }
        tableView.contentInset.bottom = inset
        tableView.verticalScrollIndicatorInsets.bottom = inset
    }

    private func place(at indexPath: IndexPath?) -> PopularPlace? {
        guard let indexPath, displayedPlaces.indices.contains(indexPath.row) else { return nil }
        return displayedPlaces[indexPath.row]
    }

    private func secondaryContent(for place: PopularPlace) -> PointSecondaryContent {
        locationReference.secondaryContent(latitude: place.poi.latitude,
                                           longitude: place.poi.longitude,
                                           trailingText: place.typeName)
    }

    private func updateDisplayedPlaces() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let sortedPlaces = sorted(places)
        displayedPlaces = query.isEmpty ? sortedPlaces : sortedPlaces.filter { $0.matches(query) }
        detailsLoader.cancelAll()
        tableView.reloadData()
    }

    private func sorted(_ places: [PopularPlace]) -> [PopularPlace] {
        guard sortMode == .nearest,
              let location = locationReference.location ?? OARootViewController.instance()?.mapPanel?.mapViewController.getMapLocation() else { return places }
        return places
            .map { ($0, location.distance(from: CLLocation(latitude: $0.poi.latitude, longitude: $0.poi.longitude))) }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    private func reconfigureRow(for place: PopularPlace) {
        guard let row = displayedPlaces.firstIndex(where: { $0 === place }) else { return }
        let indexPath = IndexPath(row: row, section: 0)
        guard tableView.indexPathsForVisibleRows?.contains(indexPath) == true else { return }
        tableView.reconfigureRows(at: [indexPath])
    }

    @objc private func onLocationServicesUpdate() {
        DispatchQueue.main.async { [weak self] in
            self?.updateDistanceAndDirection()
        }
    }

    private func updateDistanceAndDirection() {
        let now = Date().timeIntervalSince1970
        guard isViewLoaded,
              !locationReference.searchNearMapCenter,
              now - lastDistanceUpdate >= Self.distanceUpdateInterval,
              !tableView.isDragging,
              !tableView.isDecelerating else { return }
        lastDistanceUpdate = now
        if sortMode == .nearest, !tableView.visibleCells.contains(where: \.isHighlighted) {
            let sortedPlaces = sorted(displayedPlaces)
            if !sortedPlaces.elementsEqual(displayedPlaces, by: { $0 === $1 }) {
                displayedPlaces = sortedPlaces
                tableView.reloadData()
                return
            }
        }
        tableView.indexPathsForVisibleRows?.forEach { indexPath in
            guard let place = place(at: indexPath),
                  let cell = tableView.cellForRow(at: indexPath),
                  var configuration = cell.contentConfiguration as? PoiContentConfiguration else { return }
            configuration.secondaryContent = secondaryContent(for: place)
            cell.contentConfiguration = configuration
        }
    }
}

extension PopularPlacesViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.compactMap { place(at: $0) }.forEach { detailsLoader.request($0) }
    }

    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.compactMap { place(at: $0) }.forEach { detailsLoader.cancelRequest(for: $0) }
    }
}

extension PopularPlacesViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text ?? ""
        guard text != searchText else { return }
        searchText = text
        updateDisplayedPlaces()
    }
}

extension PopularPlacesViewController: StarMapSearchSortFilterChipsDataSource, StarMapSearchSortFilterChipsDelegate {
    func chipGroups(for chipsView: StarMapSearchSortFilterChipsView) -> [SearchSortFilterChipGroup] {
        let options = SortMode.allCases.map { mode in
            StarMapSearchSortFilterChipOption(id: mode.rawValue,
                                              title: mode.title,
                                              image: mode.icon.resizedTemplateImage(with: Self.chipIconSize),
                                              originalSizeImage: mode.icon.withRenderingMode(.alwaysTemplate),
                                              isSelected: mode == sortMode)
        }
        return [SearchSortFilterChipGroup(id: Self.sortGroupId,
                                          chipTitle: sortMode.title,
                                          chipImage: sortMode.icon.resizedTemplateImage(with: Self.chipIconSize),
                                          selectionMode: .single,
                                          sections: [StarMapSearchSortFilterChipSection(options: options)])]
    }

    func chipsView(_ chipsView: StarMapSearchSortFilterChipsView, didSelectOption optionId: String, inGroup groupId: String) {
        guard groupId == Self.sortGroupId, let mode = SortMode(rawValue: optionId), mode != sortMode else { return }
        sortMode = mode
        chipsView.reloadData()
        updateDisplayedPlaces()
        tableView.setContentOffset(CGPoint(x: 0, y: -tableView.adjustedContentInset.top), animated: false)
    }

    func chipsView(_ chipsView: StarMapSearchSortFilterChipsView, didToggleGroup groupId: String, isOn: Bool) {
    }
}
