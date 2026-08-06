//
//  RouteSettingsViewController.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class RouteSettingsViewController: UIViewController {

    private enum Row {
        case parameter(OALocalRoutingParameter)
        case hazmatUsa([AnyHashable: Any])
        case navigationSettings
    }

    private struct SectionModel {
        let rows: [Row]
    }

    var onAvoidRoadsTapped: (() -> Void)?
    var onNavigationSettingsTapped: (() -> Void)?
    var settingsChangedHandler: (() -> Void)?

    private let appMode: OAApplicationMode
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var sections: [SectionModel] = []

    private var profileColor: UIColor {
        appMode.getProfileColor() ?? .iconColorActive
    }

    init(appMode: OAApplicationMode) {
        self.appMode = appMode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    func reloadData() {
        sections = buildSections()
        guard isViewLoaded else { return }
        tableView.reloadData()
    }

    private func setupTableView() {
        view.backgroundColor = .viewBg
        tableView.backgroundColor = .viewBg
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 52
        tableView.sectionHeaderTopPadding = 0
        tableView.register(RouteSettingToggleCell.self, forCellReuseIdentifier: RouteSettingToggleCell.reuseIdentifier)
        tableView.register(RouteSettingNavigationCell.self, forCellReuseIdentifier: RouteSettingNavigationCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func buildSections() -> [SectionModel] {
        let provider = OARouteSettingsBaseViewController()
        guard let routingData = provider.getRoutingParameters(appMode),
              let routeParameters = routingData[1] as? [Any] else {
            return [SectionModel(rows: [.navigationSettings])]
        }
        let rows: [Row] = routeParameters.compactMap { item in
            if let parameter = item as? OALocalRoutingParameter {
                parameter.delegate = self
                return .parameter(parameter)
            }
            if let hazmatData = item as? [AnyHashable: Any] {
                return .hazmatUsa(hazmatData)
            }
            return nil
        }
        return [SectionModel(rows: rows), SectionModel(rows: [.navigationSettings])]
    }

    private func configureParameterCell(_ parameter: OALocalRoutingParameter, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let title = parameter.getText() ?? ""
        let icon = parameter.getIcon()
        if parameter.getCellType() == OASwitchTableViewCell.reuseIdentifier {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RouteSettingToggleCell.reuseIdentifier, for: indexPath) as? RouteSettingToggleCell else {
                return UITableViewCell()
            }
            let isOn = parameter.isChecked()
            let tintColor = isOn ? profileColor : .iconColorDisabled
            cell.configure(title: title, icon: icon, tintColor: tintColor, isOn: isOn) { [weak self, weak parameter] isOn in
                parameter?.applyNewParameterValue(isOn)
                self?.settingsChangedHandler?()
            }
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RouteSettingNavigationCell.reuseIdentifier, for: indexPath) as? RouteSettingNavigationCell else {
            return UITableViewCell()
        }
        cell.configure(title: title,
                       value: parameterValue(parameter),
                       icon: icon,
                       tintColor: profileColor)
        return cell
    }

    private func parameterValue(_ parameter: OALocalRoutingParameter) -> String? {
        guard let hazmatParameter = parameter as? OAHazmatRoutingParameter else {
            return parameter.getValue()
        }
        guard hazmatParameter.isSelected() else {
            return localizedString("shared_string_no")
        }
        return String(format: localizedString("ltr_or_rtl_combine_via_comma"),
                      localizedString("shared_string_yes"),
                      hazmatParameter.getValue() ?? "")
    }

    private func configureHazmatCell(_ data: [AnyHashable: Any], tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RouteSettingNavigationCell.reuseIdentifier, for: indexPath) as? RouteSettingNavigationCell else {
            return UITableViewCell()
        }
        cell.configure(title: data[titleRouteSettingsKey] as? String ?? "",
                       value: data[valueRouteSettingsKey] as? String,
                       icon: data[iconRouteSettingsKey] as? UIImage,
                       tintColor: data[iconTintRouteSettingsKey] as? UIColor ?? profileColor)
        return cell
    }

    private func openParameter(_ parameter: OALocalRoutingParameter, indexPath: IndexPath) {
        parameter.rowSelectAction(tableView, indexPath: indexPath)
    }

    private func openHazmat(_ data: [AnyHashable: Any]) {
        guard let parameterIds = data[paramsIdsRouteSettingsKey] as? [String],
              let parameterNames = data[paramsNamesRouteSettingsKey] as? [String] else { return }
        let viewController = RouteParameterHazmatUsa(applicationMode: appMode,
                                                     parameterIds: parameterIds,
                                                     parameterNames: parameterNames)
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
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
        case let .parameter(parameter):
            return configureParameterCell(parameter, tableView: tableView, indexPath: indexPath)
        case let .hazmatUsa(data):
            return configureHazmatCell(data, tableView: tableView, indexPath: indexPath)
        case .navigationSettings:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RouteSettingNavigationCell.reuseIdentifier, for: indexPath) as? RouteSettingNavigationCell else {
                return UITableViewCell()
            }
            cell.configure(title: localizedString("routing_settings_2"),
                           icon: appMode.getIcon(),
                           tintColor: profileColor)
            return cell
        }
    }
}

extension RouteSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        switch row {
        case let .parameter(parameter):
            openParameter(parameter, indexPath: indexPath)
        case let .hazmatUsa(data):
            openHazmat(data)
        case .navigationSettings:
            onNavigationSettingsTapped?()
        }
    }
}

extension RouteSettingsViewController: OARoutePreferencesParametersDelegate {
    func updateParameters() {
        reloadData()
    }

    func openNavigationSettings() {
        onNavigationSettingsTapped?()
    }

    func openRouteLineAppearance() {
    }

    func showParameterGroupScreen(_ group: OALocalRoutingParameterGroup) {
        let viewController = OARouteParameterValuesViewController(routingParameterGroup: group, appMode: appMode)
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }

    func showParameterValuesScreen(_ parameter: OALocalRoutingParameter) {
        let viewController = OARouteParameterValuesViewController(routingParameter: parameter, appMode: appMode)
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }

    func selectVoiceGuidance(_ tableView: UITableView, indexPath: IndexPath) {
    }

    func showAvoidRoadsScreen() {
        onAvoidRoadsTapped?()
    }

    func showTripSettingsScreen() {
    }

    func showAvoidTransportScreen() {
    }

    func openSimulateNavigationScreen() {
    }

    func openShowAlongScreen() {
        let viewController = PlanRouteShowAlongSettingsViewController(appMode: appMode)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension RouteSettingsViewController: OASettingsDataDelegate {
    func onSettingsChanged() {
        reloadData()
        settingsChangedHandler?()
    }
}

private final class PlanRouteShowAlongSettingsViewController: UIViewController {

    private enum Item: Int, CaseIterable {
        case poi
        case favorites
        case trafficWarnings

        var title: String {
            switch self {
            case .poi:
                return localizedString("poi")
            case .favorites:
                return localizedString("my_favorites")
            case .trafficWarnings:
                return localizedString("show_traffic_warnings")
            }
        }
    }

    private let settingsBridge: OAPlanRouteShowAlongSettingsBridge
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init(appMode: OAApplicationMode) {
        settingsBridge = OAPlanRouteShowAlongSettingsBridge(applicationMode: appMode)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = localizedString("show_along_the_route")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.icNavbarChevron.imageFlippedForRightToLeftLayoutDirection(),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(onBackTapped))
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    override func isNavbarVisible() -> Bool {
        true
    }

    private func setupTableView() {
        view.backgroundColor = .viewBg
        tableView.backgroundColor = .viewBg
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 52
        tableView.sectionHeaderTopPadding = 0
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func onBackTapped() {
        navigationController?.popViewController(animated: true)
    }
}

extension PlanRouteShowAlongSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Item.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = Item(rawValue: indexPath.row),
              let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier) else {
            return UITableViewCell()
        }
        let isOn = settingsBridge.isEnabled(forType: item.rawValue)
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.textProperties.font = .scaledSystemFont(ofSize: 17)
        content.textProperties.color = .textColorPrimary
        cell.contentConfiguration = content
        cell.backgroundColor = .groupBg
        cell.selectionStyle = .none
        cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.onTintColor = .accentsGreen
        toggle.accessibilityLabel = item.title
        toggle.addAction(UIAction { [weak self, weak toggle] _ in
            guard let toggle else { return }
            self?.settingsBridge.setEnabled(toggle.isOn, forType: item.rawValue)
        }, for: .valueChanged)
        cell.accessoryView = toggle
        return cell
    }
}
