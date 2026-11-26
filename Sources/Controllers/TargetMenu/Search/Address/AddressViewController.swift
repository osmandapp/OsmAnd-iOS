//
//  AddressViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 25.11.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

protocol AddressViewControllerDelegate: AnyObject {
    func addressDidRequestReload()
    func addressDidRequestStreetSearch(lastCity: OASearchResult?, cityName: String)
    func addressDidRequestCitySearch()
    func addressDidRequestPostcodeSearch()
    func addressDidRequestCoordinatesSearch()
    func addressDidSelectCity(_ city: OASearchResult)
}

final class AddressViewController: UIViewController {
    private enum Action {
        case selectStreet(cityName: String)
        case selectCity
        case postcode
        case coordinates
    }
    
    private enum Row {
        case action(Action)
        case city(OASearchResult)
    }
    
    private static let cellIdentifier = "AddressCell"
    private static let headerIdentifier = "AddressHeader"
    private static let iconSize = CGSize(width: 30, height: 30)
    
    var searchLocation = kCLLocationCoordinate2DInvalid
    weak var delegate: AddressViewControllerDelegate?
    var searchNearMapCenter = false {
        didSet { updateDistanceAndDirection() }
    }
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var lastCity: OASearchResult?
    private var lastCityName: String?
    private var nearestCities: [OASearchResult] = []
    private var rows: [[Row]] = []
    private var locationReference: SearchLocationReference {
        SearchLocationReference(searchNearMapCenter: searchNearMapCenter, searchLocation: searchLocation)
    }
    
    private static func icon(for action: Action) -> UIImage {
        switch action {
        case .selectStreet:
            return .icActionStreetName
        case .selectCity:
            return .icActionBuildingNumber
        case .postcode:
            return .icActionPostcode
        case .coordinates:
            return .icCustomLocationMarker
        }
    }
    
    private static func selectStreetTitle(cityName: String) -> NSAttributedString {
        let inCityName = String(format: localizedString("shared_string_in_name"), cityName)
        let title = "\(localizedString("select_street")) \(inCityName)"
        let attributedTitle = NSMutableAttributedString(string: title, attributes: [.font: UIFont.preferredFont(forTextStyle: .body), .foregroundColor: UIColor.textColorPrimary])
        attributedTitle.addAttribute(.foregroundColor, value: UIColor.textColorActive, range: (title as NSString).range(of: cityName, options: .backwards))
        return attributedTitle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        reloadRows()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.addressDidRequestReload()
    }
    
    func setData(lastCity: OASearchResult?, lastCityName: String?, nearestCities: [OASearchResult]) {
        self.lastCity = lastCity
        self.lastCityName = lastCityName
        self.nearestCities = nearestCities
        if isViewLoaded {
            reloadRows()
        }
    }
    
    func updateLastCity(_ lastCity: OASearchResult) {
        setData(lastCity: lastCity, lastCityName: lastCity.localeName, nearestCities: nearestCities)
    }
    
    func updateDistanceAndDirection() {
        guard isViewLoaded, !tableView.isDragging, !tableView.isDecelerating else { return }
        tableView.indexPathsForVisibleRows?.forEach { indexPath in
            guard case .city(let city) = row(at: indexPath), let cell = tableView.cellForRow(at: indexPath) else { return }
            cell.contentConfiguration = cityConfiguration(for: city)
        }
    }
    
    private func setupTableView() {
        view.backgroundColor = .viewBg
        tableView.backgroundColor = .viewBg
        tableView.separatorColor = SeparatorAppearance.color
        tableView.dataSource = self
        tableView.delegate = self
        tableView.alwaysBounceVertical = true
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
        tableView.register(PoiContentTableViewCell.self, forCellReuseIdentifier: PoiContentTableViewCell.reuseIdentifier)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Self.headerIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func reloadRows() {
        var cityActions: [Row] = []
        if let lastCityName, !lastCityName.isEmpty {
            cityActions.append(.action(.selectStreet(cityName: lastCityName)))
        }

        cityActions.append(.action(.selectCity))
        rows = [cityActions, [.action(.postcode), .action(.coordinates)]]
        if !nearestCities.isEmpty {
            rows.append(nearestCities.map { .city($0) })
        }

        tableView.reloadData()
        if view.window != nil {
            tableView.setContentOffset(CGPoint(x: 0, y: -tableView.adjustedContentInset.top), animated: false)
        }
    }
    
    private func row(at indexPath: IndexPath) -> Row? {
        guard rows.indices.contains(indexPath.section), rows[indexPath.section].indices.contains(indexPath.row) else { return nil }
        return rows[indexPath.section][indexPath.row]
    }
    
    private func contentConfiguration(for action: Action) -> UIListContentConfiguration {
        var content = UIListContentConfiguration.cell()
        switch action {
        case .selectStreet(let cityName):
            content.attributedText = Self.selectStreetTitle(cityName: cityName)
        case .selectCity:
            content.text = localizedString("select_city")
        case .postcode:
            content.text = localizedString("select_postcode")
        case .coordinates:
            content.text = localizedString("coords_search")
        }

        content.textProperties.color = .textColorPrimary
        content.image = Self.icon(for: action).withRenderingMode(.alwaysTemplate).imageFlippedForRightToLeftLayoutDirection()
        content.imageProperties.tintColor = .iconColorActive
        content.imageProperties.maximumSize = Self.iconSize
        content.imageProperties.reservedLayoutSize = Self.iconSize
        return content
    }
    
    private func cityConfiguration(for city: OASearchResult) -> PoiContentConfiguration {
        var configuration = PoiContentConfiguration(style: .compact, title: OAQuickSearchTableController.addressTitle(for: city) ?? OAQuickSearchListItem.getName(city) ?? "", icon: OAQuickSearchTableController.icon(for: city), secondaryContent: citySecondaryContent(for: city), address: OAQuickSearchTableController.distanceToCity(for: city), alternateTitle: city.alternateName, iconTintColor: .iconColorSecondary)
        configuration.secondaryNumberOfLines = 1
        return configuration
    }
    
    private func citySecondaryContent(for city: OASearchResult) -> PointSecondaryContent {
        let typeName = OAQuickSearchTableController.poiTypeName(for: city) ?? OAQuickSearchListItem.getTypeName(city)
        let description = OAQuickSearchTableController.addressDescription(for: city)
        guard let location = city.location else {
            return PointSecondaryContent(formattedDistance: nil, direction: 0, address: typeName, date: nil, trailingText: description)
        }

        return locationReference.secondaryContent(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, address: typeName, trailingText: description)
    }
}

extension AddressViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        rows.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch rows[indexPath.section][indexPath.row] {
        case .action(let action):
            cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath)
            cell.contentConfiguration = contentConfiguration(for: action)
        case .city(let city):
            cell = tableView.dequeueReusableCell(withIdentifier: PoiContentTableViewCell.reuseIdentifier, for: indexPath)
            cell.contentConfiguration = cityConfiguration(for: city)
        }

        PointContentConfiguration.applyHighlightableBackground(to: cell)
        cell.accessibilityTraits = .button
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard case .city? = rows[section].first, let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Self.headerIdentifier) else { return nil }
        var content = UIListContentConfiguration.groupedHeader()
        content.text = localizedString("nearest_cities")
        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        content.textProperties.color = .textColorSecondary
        content.textProperties.transform = .none
        header.contentConfiguration = content
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch rows[indexPath.section][indexPath.row] {
        case .action(.selectStreet(let cityName)):
            delegate?.addressDidRequestStreetSearch(lastCity: lastCity, cityName: cityName)
        case .action(.selectCity):
            delegate?.addressDidRequestCitySearch()
        case .action(.postcode):
            delegate?.addressDidRequestPostcodeSearch()
        case .action(.coordinates):
            delegate?.addressDidRequestCoordinatesSearch()
        case .city(let city):
            delegate?.addressDidSelectCity(city)
        }
    }
}

extension AddressViewController: QuickSearchPageContent {
    var pageScrollView: UIScrollView {
        tableView
    }
}
