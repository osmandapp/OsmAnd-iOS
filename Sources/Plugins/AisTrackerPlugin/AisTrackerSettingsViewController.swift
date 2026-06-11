import UIKit

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
            case .address: [.protocolType, .host, .tcpPort, .udpPort]
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
        case shipLostTimeout
        case objectLostTimeout
        case cpaWarningTime
        case cpaWarningDistance
    }

    private let plugin: OAAisTrackerPlugin
    private let objectLostTimeoutValues = [3, 5, 7, 10, 12, 15, 20]
    private let shipLostTimeoutValues = [2, 3, 4, 5, 7, 10, 15, 100]
    private let cpaWarningTimeValues = [0, 1, 5, 10, 20, 30, 60]
    private let cpaWarningDistanceValues = [0.02, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0]

    init(plugin: OAAisTrackerPlugin) {
        self.plugin = plugin
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadStatus), name: .aisNmeaConnectionStateChanged, object: plugin)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadStatus), name: .aisNmeaLocationReceived, object: plugin)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func getTitle() -> String {
        localizedString("plugin_ais_tracker_name")
    }

    override func tableStyle() -> UITableView.Style {
        .insetGrouped
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
            cell.detailTextLabel?.text = plugin.hostPref.get()
        case .tcpPort:
            cell.textLabel?.text = localizedString("ais_port_nmea_server")
            cell.detailTextLabel?.text = "\(plugin.tcpPortPref.get())"
        case .udpPort:
            cell.textLabel?.text = localizedString("ais_port_nmea_local")
            cell.detailTextLabel?.text = "\(plugin.udpPortPref.get())"
        case .objectLostTimeout:
            cell.textLabel?.text = localizedString("ais_object_lost_timeout")
            cell.detailTextLabel?.text = minutesText(Int(plugin.objectLostTimeoutPref.get()))
        case .shipLostTimeout:
            cell.textLabel?.text = localizedString("ais_ship_lost_timeout")
            cell.detailTextLabel?.text = shipLostTimeoutText(Int(plugin.shipLostTimeoutPref.get()))
        case .cpaWarningTime:
            cell.textLabel?.text = localizedString("ais_cpa_warning_time")
            cell.detailTextLabel?.text = cpaWarningTimeText(Int(plugin.cpaWarningTimePref.get()))
        case .cpaWarningDistance:
            cell.textLabel?.text = localizedString("ais_cpa_warning_distance")
            cell.detailTextLabel?.text = nauticalMilesText(plugin.cpaWarningDistancePref.get())
        }
        return cell
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let row = rowData(indexPath), isRowEnabled(row) else { return }
        switch row {
        case .protocolType:
            chooseProtocol()
        case .host:
            editString(title: localizedString("ais_address_nmea_server"), message: descriptionText(for: row), value: plugin.hostPref.get()) { [weak self] value in
                let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
                guard self?.isValidIPv4(value) == true else {
                    self?.showValidationError(localizedString("ais_error_ipv4_only"))
                    return false
                }
                self?.plugin.hostPref.set(value)
                self?.plugin.restartConnection()
                return true
            }
        case .tcpPort:
            editPort(title: localizedString("ais_port_nmea_server"), message: descriptionText(for: row), value: Int(plugin.tcpPortPref.get())) { [weak self] value in
                self?.plugin.tcpPortPref.set(Int32(value))
                self?.plugin.restartConnection()
            }
        case .udpPort:
            editPort(title: localizedString("ais_port_nmea_local"), message: descriptionText(for: row), value: Int(plugin.udpPortPref.get())) { [weak self] value in
                self?.plugin.udpPortPref.set(Int32(value))
                self?.plugin.restartConnection()
            }
        case .objectLostTimeout:
            chooseIntValue(title: localizedString("ais_object_lost_timeout"),
                           message: descriptionText(for: row),
                           values: objectLostTimeoutValues,
                           current: Int(plugin.objectLostTimeoutPref.get()),
                           titleProvider: minutesText) { [weak self] value in
                self?.plugin.objectLostTimeoutPref.set(Int32(value))
                self?.tableView.reloadData()
            }
        case .shipLostTimeout:
            chooseIntValue(title: localizedString("ais_ship_lost_timeout"),
                           message: descriptionText(for: row),
                           values: shipLostTimeoutValues,
                           current: Int(plugin.shipLostTimeoutPref.get()),
                           titleProvider: shipLostTimeoutText) { [weak self] value in
                self?.plugin.shipLostTimeoutPref.set(Int32(value))
                self?.tableView.reloadData()
            }
        case .cpaWarningTime:
            chooseIntValue(title: localizedString("ais_cpa_warning_time"),
                           message: descriptionText(for: row),
                           values: cpaWarningTimeValues,
                           current: Int(plugin.cpaWarningTimePref.get()),
                           titleProvider: cpaWarningTimeText) { [weak self] value in
                self?.plugin.cpaWarningTimePref.set(Int32(value))
                self?.tableView.reloadData()
            }
        case .cpaWarningDistance:
            chooseDoubleValue(title: localizedString("ais_cpa_warning_distance"),
                              message: descriptionText(for: row),
                              values: cpaWarningDistanceValues,
                              current: plugin.cpaWarningDistancePref.get(),
                              titleProvider: nauticalMilesText) { [weak self] value in
                self?.plugin.cpaWarningDistancePref.set(value)
                self?.tableView.reloadData()
            }
        }
    }

    private func chooseProtocol() {
        let alert = UIAlertController(title: localizedString("ais_nmea_protocol"), message: descriptionText(for: .protocolType), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "UDP", style: .default) { [weak self] _ in
            self?.plugin.protocolPref.set(Int32(AisNmeaProtocol.udp.rawValue))
            self?.plugin.restartConnection()
            self?.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "TCP", style: .default) { [weak self] _ in
            self?.plugin.protocolPref.set(Int32(AisNmeaProtocol.tcp.rawValue))
            self?.plugin.restartConnection()
            self?.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
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

    private func chooseIntValue(title: String, message: String?, values: [Int], current: Int, titleProvider: @escaping (Int) -> String, onSelect: @escaping (Int) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for value in values {
            alert.addAction(UIAlertAction(title: titleProvider(value), style: .default) { _ in
                onSelect(value)
            })
        }
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }

    private func chooseDoubleValue(title: String, message: String?, values: [Double], current: Double, titleProvider: @escaping (Double) -> String, onSelect: @escaping (Double) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for value in values {
            alert.addAction(UIAlertAction(title: titleProvider(value), style: .default) { _ in
                onSelect(value)
            })
        }
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
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
        (AisNmeaProtocol(rawValue: Int(plugin.protocolPref.get())) ?? .udp) == .tcp
    }

    private func isRowEnabled(_ row: Row) -> Bool {
        switch row {
        case .host, .tcpPort:
            return isTcpSelected()
        case .udpPort:
            return !isTcpSelected()
        case .cpaWarningDistance:
            return plugin.cpaWarningTimePref.get() > 0
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
}
