//
//  CategoriesViewController.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objc protocol CategoriesViewControllerDelegate: AnyObject {
    func categoriesDidSelectResult(_ result: OASearchResult)
    func categoriesDidRequestAddFilter()
    func categoriesDidRequestRearrangeFilters(_ filters: [OAPOIUIFilter])
    func categoriesDidRequestDeleteFilters(_ filters: [OAPOIUIFilter])
}

final class CategoriesViewController: UIViewController {
    private enum Row {
        case category(OASearchResult)
        case addFilter
        case rearrangeFilters([OAPOIUIFilter])
        case deleteFilters([OAPOIUIFilter])
    }

    private static let cellIdentifier = "CategoryCell"
    private static let topContentInset: CGFloat = 16
    private static let iconSize = CGSize(width: 24, height: 24)
    private static let titleNumberOfLines = 2

    @objc weak var delegate: CategoriesViewControllerDelegate?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var rows: [Row] = []
    private var loadingRequest = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCategories()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        loadingRequest += 1
    }

    @objc func reloadData() {
        guard viewIfLoaded?.window != nil else { return }
        loadCategories()
    }

    private func setupTableView() {
        view.backgroundColor = .viewBg
        tableView.backgroundColor = .viewBg
        tableView.dataSource = self
        tableView.delegate = self
        tableView.alwaysBounceVertical = true
        tableView.contentInset.top = Self.topContentInset
        tableView.sectionHeaderTopPadding = 0
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadCategories() {
        loadingRequest += 1
        let request = loadingRequest
        OAQuickSearchHelper.instance().getCore().shallowSearchAsync(OASearchAmenityTypesAPI.self, text: "", matcher: nil) { [weak self] results in
            DispatchQueue.main.async {
                guard let self, request == self.loadingRequest else { return }
                self.rows = Self.buildRows(from: results)
                self.tableView.reloadData()
            }
        }
    }

    private static func buildRows(from results: OASearchResultCollection?) -> [Row] {
        guard let results else { return [] }
        var rows: [Row] = (results.getCurrentSearchResults() ?? []).map { .category($0) }
        rows.append(.addFilter)
        let filtersHelper = OAPOIFiltersHelper.sharedInstance()
        let sortedFilters = filtersHelper?.getSortedPoiFilters(false) ?? []
        if !sortedFilters.isEmpty {
            rows.append(.rearrangeFilters(sortedFilters))
        }
        let customFilters = filtersHelper?.getUserDefinedPoiFilters(false) ?? []
        if !customFilters.isEmpty {
            rows.append(.deleteFilters(customFilters))
        }
        return rows
    }

    private static func icon(for result: OASearchResult) -> UIImage? {
        if let poiType = result.object as? OAPOIBaseType {
            return poiType.icon() ?? .icCustomSearch
        }
        if let filter = result.object as? OAPOIUIFilter {
            return filter.searchIcon
        }
        return .icCustomSearch
    }

    private static func actionTitle(for row: Row) -> String? {
        switch row {
        case .category:
            return nil
        case .addFilter:
            return localizedString("add_custom_category")
        case .rearrangeFilters:
            return localizedString("rearrange_categories")
        case .deleteFilters:
            return localizedString("delete_custom_categories")
        }
    }

    private func contentConfiguration(for row: Row) -> UIListContentConfiguration {
        var content = UIListContentConfiguration.cell()
        content.textProperties.numberOfLines = Self.titleNumberOfLines
        if case .category(let result) = row {
            content.text = result.localeName
            content.textProperties.color = .textColorPrimary
            content.image = Self.icon(for: result)
            content.imageProperties.tintColor = .iconColorSelected
            content.imageProperties.maximumSize = Self.iconSize
            content.imageProperties.reservedLayoutSize = Self.iconSize
        } else {
            content.text = Self.actionTitle(for: row)
            content.textProperties.color = .textColorActive
        }
        return content
    }
}

extension CategoriesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath)
        let row = rows[indexPath.row]
        cell.contentConfiguration = contentConfiguration(for: row)
        var background = UIBackgroundConfiguration.listGroupedCell()
        background.backgroundColor = .groupBg
        cell.backgroundConfiguration = background
        if case .category = row {
            cell.accessibilityTraits = .none
        } else {
            cell.accessibilityTraits = .button
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch rows[indexPath.row] {
        case .category(let result):
            delegate?.categoriesDidSelectResult(result)
        case .addFilter:
            delegate?.categoriesDidRequestAddFilter()
        case .rearrangeFilters(let filters):
            delegate?.categoriesDidRequestRearrangeFilters(filters)
        case .deleteFilters(let filters):
            delegate?.categoriesDidRequestDeleteFilters(filters)
        }
    }
}
