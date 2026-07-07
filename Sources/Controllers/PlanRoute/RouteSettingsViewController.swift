//
//  RouteSettingsViewController.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class RouteSettingsViewController: UIViewController {

    private enum Row {
        case useElevationData
        case avoidRoads
        case considerTempLimitations
        case navigationSettings
    }

    private struct SectionModel {
        let rows: [Row]
    }

    var onAvoidRoadsTapped: (() -> Void)?
    var onNavigationSettingsTapped: (() -> Void)?

    private var params: PlanRouteSegmentRoutingParams
    private let onParamsChanged: (PlanRouteSegmentRoutingParams) -> Void

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let sections: [SectionModel] = [
        SectionModel(rows: [.useElevationData]),
        SectionModel(rows: [.avoidRoads, .considerTempLimitations]),
        SectionModel(rows: [.navigationSettings])
    ]

    init(params: PlanRouteSegmentRoutingParams, onParamsChanged: @escaping (PlanRouteSegmentRoutingParams) -> Void) {
        self.params = params
        self.onParamsChanged = onParamsChanged
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    func update(params: PlanRouteSegmentRoutingParams) {
        self.params = params
        guard isViewLoaded else { return }
        tableView.reloadData()
    }

    private func setupTableView() {
        view.backgroundColor = .viewBg
        tableView.backgroundColor = .viewBg
        tableView.dataSource = self
        tableView.delegate = self
        tableView.sectionHeaderTopPadding = 0
        tableView.register(RouteSettingToggleCell.self, forCellReuseIdentifier: RouteSettingToggleCell.reuseId)
        tableView.register(RouteSettingNavigationCell.self, forCellReuseIdentifier: RouteSettingNavigationCell.reuseId)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension RouteSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        switch row {
        case .useElevationData:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RouteSettingToggleCell.reuseId, for: indexPath) as? RouteSettingToggleCell else {
                return UITableViewCell()
            }
            cell.configure(title: localizedString("plan_route_use_elevation_data"),
                           isOn: params.useElevationData) { [weak self] isOn in
                guard let self else { return }
                self.params.useElevationData = isOn
                self.onParamsChanged(self.params)
            }
            return cell
        case .avoidRoads:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RouteSettingNavigationCell.reuseId, for: indexPath) as? RouteSettingNavigationCell else {
                return UITableViewCell()
            }
            cell.configure(title: localizedString("plan_route_avoid_roads"))
            return cell
        case .considerTempLimitations:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RouteSettingToggleCell.reuseId, for: indexPath) as? RouteSettingToggleCell else {
                return UITableViewCell()
            }
            cell.configure(title: localizedString("plan_route_consider_temp_limitations"),
                           isOn: params.considerTemporaryLimitations) { [weak self] isOn in
                guard let self else { return }
                self.params.considerTemporaryLimitations = isOn
                self.onParamsChanged(self.params)
            }
            return cell
        case .navigationSettings:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RouteSettingNavigationCell.reuseId, for: indexPath) as? RouteSettingNavigationCell else {
                return UITableViewCell()
            }
            cell.configure(title: localizedString("plan_route_navigation_settings"))
            return cell
        }
    }
}

extension RouteSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        switch row {
        case .avoidRoads:
            onAvoidRoadsTapped?()
        case .navigationSettings:
            onNavigationSettingsTapped?()
        default:
            break
        }
    }
}
