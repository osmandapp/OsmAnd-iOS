//
//  AisObjectViewController.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import CoreLocation
import OsmAndShared

final class AisObjectViewController: OATargetInfoViewController {

    private static let rowStartOrder = 100
    private static let rowHeight: Int32 = 50

    private let object: AisObject

    private var menuRows: NSMutableArray?
    private var aisValueRowKeys = Set<String>()

    @objc(initWithAisObject:)
    init(aisObject: AisObject) {
        object = aisObject
        super.init(nibName: "OATargetInfoViewController", bundle: nil)
        if let position = aisObject.position {
            location = CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)
        }
        showTitleIfTruncated = false
        customOnlinePhotosPosition = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: OAValueTableViewCell.reuseIdentifier, bundle: nil),
                           forCellReuseIdentifier: OAValueTableViewCell.reuseIdentifier)
    }

    override func getTargetObj() -> Any {
        object
    }

    override func getIcon() -> UIImage? {
        .icActionSailBoatDark.withRenderingMode(.alwaysOriginal)
    }

    override func getTypeStr() -> String? {
        objectTypeName(object.objectClass)
    }

    override func getCommonTypeStr() -> String {
        getTypeStr() ?? ""
    }

    override func getNameStr() -> String? {
        String(format: localizedString("ais_object_with_mmsi"), Int(object.mmsi))
    }

    override func needAddress() -> Bool {
        false
    }

    override func showDetailsButton() -> Bool {
        false
    }

    override func showNearestWiki() -> Bool {
        false
    }

    override func showNearestPoi() -> Bool {
        false
    }

    override func buildDescription(_ rows: NSMutableArray) {
    }

    override func buildTopInternal(_ rows: NSMutableArray) {
    }

    override func buildMenu(_ rows: NSMutableArray) {
        menuRows = rows
        aisValueRowKeys.removeAll()
        super.buildMenu(rows)
    }

    override func buildPluginRows(_ rows: NSMutableArray) {
    }

    override func buildInternal(_ rows: NSMutableArray) {
        var order = Self.rowStartOrder
        let plugin = OAPluginsHelper.getPlugin(AisTrackerPlugin.self) as? AisTrackerPlugin
        plugin?.updateCpa(for: object)

        addRow(to: rows, key: "mmsi", prefix: localizedString("ais_mmsi"), text: String(object.mmsi), order: &order)
        if object.position != nil {
            addRow(to: rows, key: "position", prefix: localizedString("ais_position"), text: formatPosition(), order: &order)
        }
        if let plugin {
            let distance = plugin.distanceInNauticalMiles(to: object)
            if distance >= 0 {
                addRow(to: rows, key: "distance", prefix: localizedString("shared_string_distance"), text: String(format: "%.1f nm", distance), order: &order)
            }
            let bearing = plugin.bearing(to: object)
            if bearing >= 0 {
                addRow(to: rows, key: "bearing", prefix: localizedString("shared_string_bearing"), text: String(format: "%.0f", bearing), order: &order)
            }
        }
        if object.cpa.valid {
            addRow(to: rows, key: "cpa", prefix: localizedString("ais_cpa"), text: String(format: "%.1f nm", object.cpa.cpa), order: &order)
            addRow(to: rows, key: "tcpa", prefix: localizedString("ais_tcpa"), text: formatTcpa(object.cpa.tcpa), order: &order)
        }

        if isType(object.objectClass, .aisAton) || isType(object.objectClass, .aisAtonVirtual) {
            if object.aidType != AisObjectConstants.shared.UNSPECIFIED_AID_TYPE {
                addRow(to: rows, key: "aid_type", prefix: localizedString("ais_aid_type"), text: object.getAidTypeString(), order: &order)
            }
            addDimensionRow(to: rows, order: &order)
        } else if isType(object.objectClass, .aisAirplane) {
            addRow(to: rows, key: "object_type", prefix: localizedString("ais_object_type"), text: objectTypeName(object.objectClass), order: &order)
            addCourseRows(to: rows, order: &order, includeHeading: false, includeNavStatus: false)
            if object.altitude != AisObjectConstants.shared.INVALID_ALTITUDE {
                addRow(to: rows, key: "altitude", prefix: localizedString("altitude"), text: "\(object.altitude) m", order: &order)
            }
        } else {
            addRow(to: rows, key: "callsign", prefix: localizedString("ais_call_sign"), text: object.callSign, order: &order)
            if object.imo > 0, hasMessageType(5) {
                addRow(to: rows, key: "imo", prefix: localizedString("ais_imo"), text: String(object.imo), order: &order)
            }
            addRow(to: rows, key: "ship_name", prefix: localizedString("ais_ship_name"), text: object.shipName, order: &order)
            if hasMessageType(5) || hasMessageType(19) || hasMessageType(24) {
                addRow(to: rows, key: "ship_type", prefix: localizedString("ais_ship_type"), text: object.getShipTypeString(), order: &order)
            }
            addCourseRows(to: rows, order: &order, includeHeading: true, includeNavStatus: true)
            addDimensionRow(to: rows, order: &order)
            if object.draught != AisObjectConstants.shared.INVALID_DRAUGHT {
                addRow(to: rows, key: "draught", prefix: localizedString("ais_draught"), text: String(format: "%.1f m", object.draught), order: &order)
            }
            addRow(to: rows, key: "destination", prefix: localizedString("ais_destination"), text: object.destination, order: &order)
            if object.etaMon != AisObjectConstants.shared.INVALID_ETA,
               object.etaDay != AisObjectConstants.shared.INVALID_ETA {
                let eta = String(format: "%02d.%02d. %02d:%02d", object.etaDay, object.etaMon, object.etaHour, object.etaMin)
                addRow(to: rows, key: "eta", prefix: localizedString("ais_eta"), text: eta, order: &order)
            }
        }

        addRow(to: rows, key: "last_update", prefix: localizedString("ais_last_update"), text: formatLastUpdate(), order: &order)
        addRow(to: rows, key: "message_types", prefix: localizedString("ais_message_types"), text: AisObjectHelper.messageTypesString(object), order: &order)
    }

    override func needBuildCoordinatesRow() -> Bool {
        true
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let menuRows, indexPath.row < menuRows.count,
              let row = menuRows[indexPath.row] as? OAAmenityInfoRow else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
        let key = row.key
        guard aisValueRowKeys.contains(key),
              let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier) as? OAValueTableViewCell else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }

        cell.leftIconVisibility(false)
        cell.descriptionVisibility(false)
        cell.valueVisibility(true)
        cell.setupValueLabelFlexible()
        cell.selectionStyle = .none
        cell.titleLabel.text = row.textPrefix
        cell.titleLabel.textColor = .textColorPrimary
        cell.titleLabel.font = .preferredFont(forTextStyle: .body)
        cell.titleLabel.numberOfLines = 0
        cell.valueLabel.text = row.text
        cell.valueLabel.textColor = .textColorActive
        cell.valueLabel.font = .scaledSystemFont(ofSize: 16, weight: .medium)
        cell.valueLabel.numberOfLines = 0
        cell.accessibilityLabel = row.textPrefix
        cell.accessibilityValue = row.text
        return cell
    }

    private func addRow(to rows: NSMutableArray, key: String, prefix: String, text: String?, order: inout Int) {
        guard let text, !text.isEmpty else { return }
        let row = OAAmenityInfoRow(key: key,
                                   icon: nil,
                                   textPrefix: prefix,
                                   text: text,
                                   textColor: .textColorPrimary,
                                   isText: true,
                                   needLinks: false,
                                   order: order,
                                   typeName: key,
                                   isPhoneNumber: false,
                                   isUrl: false)
        row.height = Self.rowHeight
        rows.add(row)
        aisValueRowKeys.insert(key)
        order += 1
    }

    private func addCourseRows(to rows: NSMutableArray, order: inout Int, includeHeading: Bool, includeNavStatus: Bool) {
        let constants = AisObjectConstants.shared
        if includeNavStatus, object.navStatus != constants.INVALID_NAV_STATUS {
            addRow(to: rows, key: "nav_status", prefix: localizedString("ais_navigation_status"), text: object.getNavStatusString().uppercased(), order: &order)
        }
        if object.cog != constants.INVALID_COG {
            addRow(to: rows, key: "cog", prefix: localizedString("ais_cog"), text: String(format: "%.0f", object.cog), order: &order)
        }
        if object.sog != constants.INVALID_SOG {
            addRow(to: rows, key: "sog", prefix: localizedString("ais_sog"), text: String(format: "%.1f %@", object.sog, localizedString("shared_string_kts")), order: &order)
        }
        if includeHeading, object.heading != constants.INVALID_HEADING {
            addRow(to: rows, key: "heading", prefix: localizedString("ais_heading"), text: String(object.heading), order: &order)
        }
        if includeHeading, object.rot != constants.INVALID_ROT {
            addRow(to: rows, key: "rot", prefix: localizedString("ais_rate_of_turn"), text: String(format: "%.1f", object.rot), order: &order)
        }
    }

    private func addDimensionRow(to rows: NSMutableArray, order: inout Int) {
        let invalidDimension = AisObjectConstants.shared.INVALID_DIMENSION
        let hasLength = object.dimensionToBow != invalidDimension || object.dimensionToStern != invalidDimension
        let hasWidth = object.dimensionToPort != invalidDimension || object.dimensionToStarboard != invalidDimension
        guard hasLength, hasWidth else { return }
        let length = object.dimensionToBow + object.dimensionToStern
        let width = object.dimensionToPort + object.dimensionToStarboard
        addRow(to: rows, key: "dimension", prefix: localizedString("ais_dimension"), text: "\(length)m x \(width)m", order: &order)
    }

    private func formatPosition() -> String {
        guard let position = object.position else { return "" }
        let latitude = OALocationConvert.convertLatitude(position.latitude, outputType: Int(FORMAT_MINUTES), addCardinalDirection: true) ?? ""
        let longitude = OALocationConvert.convertLongitude(position.longitude, outputType: Int(FORMAT_MINUTES), addCardinalDirection: true) ?? ""
        return "\(latitude), \(longitude)"
    }

    private func formatLastUpdate() -> String {
        let seconds = max(0, Int(round(-AisObjectHelper.lastUpdateDate(object).timeIntervalSinceNow)))
        if seconds > 60 {
            return "\(seconds / 60) \(localizedString("shared_string_minute_lowercase")) \(seconds % 60) \(localizedString("shared_string_sec"))"
        }
        return "\(seconds) \(localizedString("shared_string_sec"))"
    }

    private func objectTypeName(_ type: AisObjType) -> String {
        let names: [(AisObjType, String)] = [
            (.aisVessel, "ais_type_vessel"),
            (.aisVesselSport, "ais_type_sport_vessel"),
            (.aisVesselFast, "ais_type_high_speed_vessel"),
            (.aisVesselPassenger, "ais_type_passenger_vessel"),
            (.aisVesselFreight, "ais_type_cargo_tanker"),
            (.aisVesselCommercial, "ais_type_commercial_vessel"),
            (.aisVesselAuthorities, "ais_type_authorities_vessel"),
            (.aisVesselSar, "ais_type_sar_vessel"),
            (.aisLandstation, "ais_type_base_station"),
            (.aisAirplane, "ais_type_sar_aircraft"),
            (.aisSart, "ais_type_sart"),
            (.aisAton, "ais_type_aid_to_navigation"),
            (.aisAtonVirtual, "ais_type_virtual_aid_to_navigation"),
            (.aisVesselOther, "ais_type_other_vessel")
        ]
        return localizedString(names.first { isType(type, $0.0) }?.1 ?? "ais_type_object")
    }

    private func formatTcpa(_ tcpa: Double) -> String {
        let absoluteTcpa = abs(tcpa)
        let hours = Int(absoluteTcpa)
        let minutes = Int(round((absoluteTcpa - Double(hours)) * 60))
        let value = hours > 0
            ? "\(hours) \(localizedString("int_hour")) \(minutes) \(localizedString("shared_string_minute_lowercase"))"
            : "\(minutes) \(localizedString("shared_string_minute_lowercase"))"
        return tcpa >= 0 ? value : "-\(value)"
    }

    private func hasMessageType(_ type: Int32) -> Bool {
        object.msgTypes.compactMap { ($0 as? KotlinInt)?.intValue }.contains(Int(type))
    }

    private func isType(_ type: AisObjType, _ expected: AisObjType) -> Bool {
        type === expected || type.isEqual(expected)
    }
}
