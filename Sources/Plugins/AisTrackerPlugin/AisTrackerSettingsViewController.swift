//
//  AisTrackerSettingsViewController.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objcMembers
final class AisTrackerSettingsViewController: OABaseNavbarViewController {
    private enum Section: Int, CaseIterable {
        case address
        case timeouts
        case cpa

        var titleKey: String {
            switch self {
            case .address: "ais_address_settings"
            case .timeouts: "ais_object_lost_timeouts"
            case .cpa: "ais_cpa_settings"
            }
        }

        var rows: [Row] {
            switch self {
            case .address: [.protocolType, .host, .tcpPort, .udpPort, .useNmeaLocation]
            case .timeouts: [.shipLostTimeout, .objectLostTimeout]
            case .cpa: [.cpaWarningTime, .cpaWarningDistance]
            }
        }
    }

    private enum Row {
        case protocolType
        case host
        case tcpPort
        case udpPort
        case useNmeaLocation
        case shipLostTimeout
        case objectLostTimeout
        case cpaWarningTime
        case cpaWarningDistance
    }

    private let plugin: AisTrackerPlugin
    private let appMode: OAApplicationMode
    private let objectLostTimeoutValues = [3, 5, 7, 10, 12, 15, 20]
    private let shipLostTimeoutValues = [2, 3, 4, 5, 7, 10, 15, 100]
    private let cpaWarningTimeValues = [0, 1, 5, 10, 20, 30, 60]
    private let cpaWarningDistanceValues = [0.02, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0]

    private var isSelectedProfileActive: Bool {
        appMode == OAAppSettings.sharedManager().applicationMode.get()
    }

    convenience init(plugin: AisTrackerPlugin) {
        self.init(plugin: plugin, appMode: OAAppSettings.sharedManager().applicationMode.get())
    }

    init(plugin: AisTrackerPlugin, appMode: OAApplicationMode) {
        self.plugin = plugin
        self.appMode = appMode
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadStatus), name: .aisNmeaConnectionStateChanged, object: plugin)
    }

    override func getTitle() -> String {
        localizedString("plugin_ais_tracker_name")
    }

    override func sectionsCount() -> Int {
        Section.allCases.count
    }

    override func rowsCount(_ section: Int) -> Int {
        sectionData(section)?.rows.count ?? 0
    }

    override func getTitleForHeader(_ section: Int) -> String {
        guard let section = sectionData(section) else { return "" }
        return localizedString(section.titleKey)
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        guard let row = rowData(indexPath) else { return cell }
        let enabled = isRowEnabled(row)
        cell.isUserInteractionEnabled = enabled
        cell.selectionStyle = enabled ? .default : .none
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        cell.textLabel?.textColor = enabled ? .label : .secondaryLabel
        cell.detailTextLabel?.textColor = .secondaryLabel

        switch row {
        case .protocolType:
            cell.textLabel?.text = localizedString("ais_nmea_protocol")
            cell.detailTextLabel?.text = protocolText()
        case .host:
            cell.textLabel?.text = localizedString("ais_address_nmea_server")
            cell.detailTextLabel?.text = plugin.hostPref.get(appMode)
        case .tcpPort:
            cell.textLabel?.text = localizedString("ais_port_nmea_server")
            cell.detailTextLabel?.text = "\(plugin.tcpPortPref.get(appMode))"
        case .udpPort:
            cell.textLabel?.text = localizedString("ais_port_nmea_local")
            cell.detailTextLabel?.text = "\(plugin.udpPortPref.get(appMode))"
        case .useNmeaLocation:
            cell.textLabel?.text = localizedString("ais_use_nmea_location")
            cell.detailTextLabel?.text = localizedString("ais_use_nmea_location_description")
            let switchView = UISwitch()
            switchView.isOn = plugin.useNmeaLocationPref.get(appMode)
            switchView.addTarget(self, action: #selector(onUseNmeaLocationChanged(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
        case .objectLostTimeout:
            cell.textLabel?.text = localizedString("ais_object_lost_timeout")
            cell.detailTextLabel?.text = minutesText(Int(plugin.objectLostTimeoutPref.get(appMode)))
        case .shipLostTimeout:
            cell.textLabel?.text = localizedString("ais_ship_lost_timeout")
            cell.detailTextLabel?.text = shipLostTimeoutText(Int(plugin.shipLostTimeoutPref.get(appMode)))
        case .cpaWarningTime:
            cell.textLabel?.text = localizedString("ais_cpa_warning_time")
            cell.detailTextLabel?.text = cpaWarningTimeText(Int(plugin.cpaWarningTimePref.get(appMode)))
        case .cpaWarningDistance:
            cell.textLabel?.text = localizedString("ais_cpa_warning_distance")
            cell.detailTextLabel?.text = nauticalMilesText(plugin.cpaWarningDistancePref.get(appMode))
        }
        return cell
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let row = rowData(indexPath), isRowEnabled(row) else { return }
        switch row {
        case .protocolType:
            chooseProtocol(sourceRow: indexPath)
        case .host:
            editString(title: localizedString("ais_address_nmea_server"), message: descriptionText(for: row), value: plugin.hostPref.get(appMode)) { [weak self] value in
                let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
                guard self?.isValidIPv4(value) == true else {
                    self?.showValidationError(localizedString("ais_error_ipv4_only"))
                    return false
                }
                self?.applyStringPreference(self?.plugin.hostPref, value: value, restartsConnection: true)
                return true
            }
        case .tcpPort:
            editPort(title: localizedString("ais_port_nmea_server"), message: descriptionText(for: row), value: Int(plugin.tcpPortPref.get(appMode))) { [weak self] value in
                self?.applyIntPreference(self?.plugin.tcpPortPref, value: Int32(value), restartsConnection: true)
            }
        case .udpPort:
            editPort(title: localizedString("ais_port_nmea_local"), message: descriptionText(for: row), value: Int(plugin.udpPortPref.get(appMode))) { [weak self] value in
                self?.applyIntPreference(self?.plugin.udpPortPref, value: Int32(value), restartsConnection: true)
            }
        case .useNmeaLocation:
            applyBoolPreference(plugin.useNmeaLocationPref, value: !plugin.useNmeaLocationPref.get(appMode))
        case .objectLostTimeout:
            chooseIntValue(title: localizedString("ais_object_lost_timeout"),
                           message: descriptionText(for: row),
                           values: objectLostTimeoutValues,
                           current: Int(plugin.objectLostTimeoutPref.get(appMode)),
                           titleProvider: minutesText,
                           sourceRow: indexPath) { [weak self] value in
                self?.applyIntPreference(self?.plugin.objectLostTimeoutPref, value: Int32(value))
            }
        case .shipLostTimeout:
            chooseIntValue(title: localizedString("ais_ship_lost_timeout"),
                           message: descriptionText(for: row),
                           values: shipLostTimeoutValues,
                           current: Int(plugin.shipLostTimeoutPref.get(appMode)),
                           titleProvider: shipLostTimeoutText,
                           sourceRow: indexPath) { [weak self] value in
                self?.applyIntPreference(self?.plugin.shipLostTimeoutPref, value: Int32(value))
            }
        case .cpaWarningTime:
            chooseIntValue(title: localizedString("ais_cpa_warning_time"),
                           message: descriptionText(for: row),
                           values: cpaWarningTimeValues,
                           current: Int(plugin.cpaWarningTimePref.get(appMode)),
                           titleProvider: cpaWarningTimeText,
                           sourceRow: indexPath) { [weak self] value in
                self?.applyIntPreference(self?.plugin.cpaWarningTimePref, value: Int32(value))
            }
        case .cpaWarningDistance:
            chooseDoubleValue(title: localizedString("ais_cpa_warning_distance"),
                              message: descriptionText(for: row),
                              values: cpaWarningDistanceValues,
                              current: plugin.cpaWarningDistancePref.get(appMode),
                              titleProvider: nauticalMilesText,
                              sourceRow: indexPath) { [weak self] value in
                self?.applyDoublePreference(self?.plugin.cpaWarningDistancePref, value: value)
            }
        }
    }

    private func chooseProtocol(sourceRow: IndexPath) {
        let alert = UIAlertController(title: localizedString("ais_nmea_protocol"), message: descriptionText(for: .protocolType), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "UDP", style: .default) { [weak self] _ in
            self?.applyIntPreference(self?.plugin.protocolPref, value: Int32(AisNmeaProtocol.udp.rawValue), restartsConnection: true)
        })
        alert.addAction(UIAlertAction(title: "TCP", style: .default) { [weak self] _ in
            self?.applyIntPreference(self?.plugin.protocolPref, value: Int32(AisNmeaProtocol.tcp.rawValue), restartsConnection: true)
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        presentActionSheet(alert, sourceRow: sourceRow)
    }

    private func applyIntPreference(_ preference: OACommonInteger?, value: Int32, restartsConnection: Bool = false) {
        guard let preference else { return }
        preference.set(value, mode: appMode)
        finishPreferenceChange(restartsConnection: restartsConnection && isSelectedProfileActive,
                               affectedActiveProfile: isSelectedProfileActive)
    }

    private func applyDoublePreference(_ preference: OACommonDouble?, value: Double) {
        guard let preference else { return }
        preference.set(value, mode: appMode)
        finishPreferenceChange(affectedActiveProfile: isSelectedProfileActive)
    }

    private func applyStringPreference(_ preference: OACommonString?, value: String, restartsConnection: Bool = false) {
        guard let preference else { return }
        preference.set(value, mode: appMode)
        finishPreferenceChange(restartsConnection: restartsConnection && isSelectedProfileActive,
                               affectedActiveProfile: isSelectedProfileActive)
    }

    private func applyBoolPreference(_ preference: OACommonBoolean, value: Bool) {
        preference.set(value, mode: appMode)
        finishPreferenceChange(affectedActiveProfile: isSelectedProfileActive)
    }

    private func finishPreferenceChange(restartsConnection: Bool = false, affectedActiveProfile: Bool = true) {
        if restartsConnection {
            plugin.restartConnection()
        }
        if affectedActiveProfile && !plugin.useNmeaLocationPref.get() {
            plugin.resetNmeaLocationProvider()
        }
        tableView.reloadData()
    }

    private func editString(title: String, message: String?, value: String, onSave: @escaping (String) -> Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = value
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_save"), style: .default) { [weak alert, weak self] _ in
            if onSave(alert?.textFields?.first?.text ?? value) {
                self?.tableView.reloadData()
            }
        })
        present(alert, animated: true)
    }

    private func editPort(title: String, message: String?, value: Int, onSave: @escaping (Int) -> Void) {
        editString(title: title, message: message, value: "\(value)") { text in
            if let port = Int(text), port >= 0, port <= 65535 {
                onSave(port)
                return true
            } else {
                self.showValidationError(localizedString("ais_error_port_only"))
                return false
            }
        }
    }

    private func chooseIntValue(title: String, message: String?, values: [Int], current: Int, titleProvider: @escaping (Int) -> String, sourceRow: IndexPath, onSelect: @escaping (Int) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for value in values {
            alert.addAction(UIAlertAction(title: titleProvider(value), style: .default) { _ in
                onSelect(value)
            })
        }
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        presentActionSheet(alert, sourceRow: sourceRow)
    }

    private func chooseDoubleValue(title: String, message: String?, values: [Double], current: Double, titleProvider: @escaping (Double) -> String, sourceRow: IndexPath, onSelect: @escaping (Double) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for value in values {
            alert.addAction(UIAlertAction(title: titleProvider(value), style: .default) { _ in
                onSelect(value)
            })
        }
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        presentActionSheet(alert, sourceRow: sourceRow)
    }

    private func presentActionSheet(_ alert: UIAlertController, sourceRow: IndexPath) {
        if let popover = alert.popoverPresentationController {
            if let cell = tableView.cellForRow(at: sourceRow) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            } else {
                popover.sourceView = view
                popover.sourceRect = .init(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
            }
            popover.permittedArrowDirections = [.up, .down]
        }
        present(alert, animated: true)
    }

    private func descriptionText(for row: Row) -> String? {
        let key: String
        switch row {
        case .protocolType:
            key = "ais_nmea_protocol_description"
        case .host:
            key = "ais_address_nmea_server_description"
        case .tcpPort:
            key = "ais_port_nmea_server_description"
        case .udpPort:
            key = "ais_port_nmea_local_description"
        case .useNmeaLocation:
            key = "ais_use_nmea_location_description"
        case .shipLostTimeout:
            key = "ais_ship_lost_timeout_description"
        case .objectLostTimeout:
            key = "ais_object_lost_timeout_description"
        case .cpaWarningTime:
            key = "ais_cpa_warning_time_description"
        case .cpaWarningDistance:
            key = "ais_cpa_warning_distance_description"
        }
        return localizedString(key)
    }

    private func sectionData(_ section: Int) -> Section? {
        Section(rawValue: section)
    }

    private func rowData(_ indexPath: IndexPath) -> Row? {
        guard let section = sectionData(indexPath.section), indexPath.row < section.rows.count else { return nil }
        return section.rows[indexPath.row]
    }

    private func isTcpSelected() -> Bool {
        (AisNmeaProtocol(rawValue: Int(plugin.protocolPref.get(appMode))) ?? .udp) == .tcp
    }

    private func isRowEnabled(_ row: Row) -> Bool {
        switch row {
        case .host, .tcpPort:
            return isTcpSelected()
        case .udpPort:
            return !isTcpSelected()
        case .useNmeaLocation:
            return true
        case .cpaWarningDistance:
            return plugin.cpaWarningTimePref.get(appMode) > 0
        default:
            return true
        }
    }

    private func protocolText() -> String {
        isTcpSelected() ? "TCP" : "UDP"
    }

    private func minutesText(_ minutes: Int) -> String {
        "\(minutes) \(localizedString("shared_string_minute_lowercase"))"
    }

    private func shipLostTimeoutText(_ minutes: Int) -> String {
        minutes >= 100 ? localizedString("shared_string_disabled") : minutesText(minutes)
    }

    private func cpaWarningTimeText(_ minutes: Int) -> String {
        minutes == 0 ? localizedString("shared_string_disabled") : minutesText(minutes)
    }

    private func nauticalMilesText(_ miles: Double) -> String {
        if abs(miles - 1.0) < 0.0001 {
            return "1 \(localizedString("ais_nautical_mile"))"
        }
        let value: String
        if ceil(miles) == miles {
            value = String(format: "%.0f", miles)
        } else if miles < 0.1 {
            value = String(format: "%.2f", miles)
        } else {
            value = String(format: "%.1f", miles)
        }
        return "\(value) \(localizedString("ais_nautical_miles"))"
    }

    private func isValidIPv4(_ value: String) -> Bool {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let number = Int(part), number >= 0, number <= 255 else { return false }
            return part.allSatisfy { $0.isNumber }
        }
    }

    private func showValidationError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: localizedString("shared_string_error"), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .default))
            self?.present(alert, animated: true)
        }
    }

    @objc private func reloadStatus() {
        tableView.reloadData()
    }

    @objc private func onUseNmeaLocationChanged(_ sender: UISwitch) {
        applyBoolPreference(plugin.useNmeaLocationPref, value: sender.isOn)
    }
}
