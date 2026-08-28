//
//  CoordinatesFormatAddViewController.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 11.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class CoordinatesFormatAddViewController: OABaseSettingsViewController {
    private static let infoRowKey = "info"
    private static let formatIdKey = "formatId"

    var onFormatAdded: ((String) -> Void)?

    private let searchController = UISearchController(searchResultsController: nil)
    private var excludedIds: Set<String>
    private var searchQuery = ""
    private var searchResults: [CoordinateFormat] = []
    private var isSearchActive = false
    private var isSearching: Bool {
        isSearchActive
    }

    init(appMode: OAApplicationMode, excludedIds: [String]) {
        self.excludedIds = Set(excludedIds.compactMap { CoordinateFormatIds.normalize($0) })
        super.init(appMode: appMode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEditing(true, animated: false)
        tableView.sectionHeaderTopPadding = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupSearchController()
    }

    // MARK: - NavBar

    override func getTitle() -> String? {
        localizedString("coordinate_format_add_title")
    }
    
    override func getSubtitle() -> String? {
        nil
    }
    
    override func systemLeftBarButtonItem() -> UIBarButtonItem? {
        UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(onLeftNavbarButtonPressed))
    }
    
    // MARK: - Table
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OARightIconTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()

        if !isSearching {
            let infoSection = tableData.createNewSection()
            let info = infoSection.createNewRow()
            info.key = Self.infoRowKey
            info.cellType = OARightIconTableViewCell.reuseIdentifier
            info.title = localizedString("coordinate_format_add_empty_title")
            info.descr = localizedString("coordinate_format_add_empty_body")
            info.icon = .icCustomCoordinatesLocation
        }

        let formats = visibleFormats()
        guard !formats.isEmpty else { return }

        let section = tableData.createNewSection()
        if !isSearching {
            section.headerText = localizedString("group_general")
        }
        for format in formats {
            let row = section.createNewRow()
            row.cellType = OASimpleTableViewCell.reuseIdentifier
            row.title = format.title
            row.descr = CoordinateFormatHelper.summary(format, primary: false)
            row.setObj(format.id, forKey: Self.formatIdKey)
        }
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)

        if item.key == Self.infoRowKey,
           let cell = tableView.dequeueReusableCell(
                withIdentifier: OARightIconTableViewCell.reuseIdentifier,
                for: indexPath
           ) as? OARightIconTableViewCell {
            cell.selectionStyle = .none
            cell.leftIconVisibility(false)
            cell.leftEditButtonVisibility(false)
            cell.rightIconVisibility(true)
            cell.descriptionVisibility(true)
            cell.titleLabel.font = .preferredFont(forTextStyle: .body)
            cell.titleLabel.textColor = .textColorPrimary
            cell.titleLabel.text = item.title
            cell.descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
            cell.descriptionLabel.textColor = .textColorSecondary
            cell.descriptionLabel.numberOfLines = 0
            cell.descriptionLabel.text = item.descr
            cell.rightIconView.image = item.icon
            cell.rightIconView.tintColor = .iconColorDefault
            cell.anchorContent(.topStyle)
            cell.textIndentsStyle(.increasedTopCenterIndentStyle)
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = item.title
            cell.accessibilityValue = item.descr
            cell.accessibilityTraits = .staticText
            
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(
                withIdentifier: OASimpleTableViewCell.reuseIdentifier,
                for: indexPath
              ) as? OASimpleTableViewCell else { return nil }

        cell.selectionStyle = .none
        cell.accessoryType = .none
        cell.leftIconVisibility(false)
        cell.descriptionVisibility(!(item.descr ?? "").isEmpty)
        cell.titleLabel.text = item.title
        cell.titleLabel.textColor = .textColorPrimary
        cell.descriptionLabel.text = item.descr
        cell.descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        cell.setRightSeparatorInset(16)

        cell.isAccessibilityElement = true
        cell.accessibilityLabel = item.title
        cell.accessibilityValue = item.descr
        cell.accessibilityTraits = .button
        cell.accessibilityHint = localizedString("shared_string_add")
        return cell
    }
    
    override func tableView(_ tableView: UITableView,
                            canEditRowAt indexPath: IndexPath) -> Bool {
        tableData.item(for: indexPath).key != Self.infoRowKey
    }
    
    override func tableView(_ tableView: UITableView,
                            editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        tableData.item(for: indexPath).key == Self.infoRowKey ? .none : .insert
    }
    
    override func tableView(_ tableView: UITableView,
                            shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        tableData.item(for: indexPath).key != Self.infoRowKey
    }
    
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        guard editingStyle == .insert else { return }
        addFormatIfPossible(at: indexPath)
    }

    private func availableFormats() -> [CoordinateFormat] {
        BuiltInCoordinateFormat.allCases
            .map { $0.toCoordinateFormat() }
            .filter { !excludedIds.contains($0.id) }
    }

    private func visibleFormats() -> [CoordinateFormat] {
        if isSearching {
            return searchResults.filter { !excludedIds.contains($0.id) }
        }
        return availableFormats()
    }

    private func addFormat(_ id: String) {
        guard let normalized = CoordinateFormatIds.normalize(id),
              !excludedIds.contains(normalized) else { return }
        excludedIds.insert(normalized)
        onFormatAdded?(normalized)
        generateData()
        tableView.reloadData()
    }
    
    private func addFormatIfPossible(at indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        guard item.key != Self.infoRowKey,
              let id = item.obj(forKey: Self.formatIdKey) as? String else { return }
        addFormat(id)
    }
    
    // MARK: - Search
    
    private func setupSearchController() {
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = localizedString("coordinate_format_add_search_hint")
        navigationItem.searchController = searchController
        if #available(iOS 16.0, *) {
            navigationItem.preferredSearchBarPlacement = .stacked
        }
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    private func runCatalogSearch(_ query: String) {
        CoordinateFormatHelper.search(query) { [weak self] results in
            guard let self, self.isSearchActive, self.searchQuery == query else { return }
            self.searchResults = results
            self.generateData()
            self.tableView.reloadData()
        }
    }
    
    deinit {
        CoordinateFormatHelper.cancelSearch()
    }
}

// MARK: - UISearchResultsUpdating

extension CoordinatesFormatAddViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchQuery = searchController.searchBar.text ?? ""
        if isSearching {
            let query = searchQuery
            CoordinateFormatHelper.search(query) { [weak self] results in
                guard let self, self.searchQuery == query else { return }
                self.searchResults = results
                self.generateData()
                self.tableView.reloadData()
            }
        } else {
            CoordinateFormatHelper.cancelSearch()
            searchResults = []
            generateData()
            tableView.reloadData()
        }
    }
}

// MARK: - UISearchControllerDelegate

extension CoordinatesFormatAddViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        isSearchActive = true
        searchQuery = searchController.searchBar.text ?? ""
        runCatalogSearch(searchQuery)
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        isSearchActive = false
        searchQuery = ""
        CoordinateFormatHelper.cancelSearch()
        searchResults = []
        generateData()
        tableView.reloadData()
    }
}
