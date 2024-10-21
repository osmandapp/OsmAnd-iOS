//
//  TracksFiltersViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 25.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

final class TracksFiltersViewController: OABaseButtonsViewController {
    private static let nameFilterRowKey = "nameFilter"
    private static let lengthFilterRowKey = "lengthFilter"
    private static let durationFilterRowKey = "durationFilter"
    private static let timeInMotionFilterRowKey = "timeInMotionFilter"
    private static let dateCreationFilterRowKey = "dateCreationFilter"
    private static let averageSpeedFilterRowKey = "averageSpeedFilter"
    private static let maxSpeedFilterRowKey = "maxSpeedFilter"
    private static let averageAltitudeFilterRowKey = "averageAltitudeFilter"
    private static let maxAltitudeFilterRowKey = "maxAltitudeFilter"
    private static let uphillFilterRowKey = "uphillFilter"
    private static let downhillFilterRowKey = "downhillFilter"
    private static let colorFilterRowKey = "colorFilter"
    private static let widthFilterRowKey = "widthFilter"
    private static let nearestCitiesFilterRowKey = "nearestCitiesFilter"
    private static let folderFilterRowKey = "folderFilter"
    private static let sensorSpeedMaxFilterRowKey = "sensorSpeedMaxFilter"
    private static let sensorSpeedAverageFilterRowKey = "sensorSpeedAverageFilter"
    private static let heartRateMaxFilterRowKey = "heartRateMaxFilter"
    private static let heartRateAverageFilterRowKey = "heartRateAverageFilter"
    private static let bicycleCadenceMaxFilterRowKey = "bicycleCadenceMaxFilter"
    private static let bicycleCadenceAverageFilterRowKey = "bicycleCadenceAverageFilter"
    private static let bicyclePowerMaxFilterRowKey = "bicyclePowerMaxFilter"
    private static let bicyclePowerAverageFilterRowKey = "bicyclePowerAverageFilter"
    private static let temperatureMaxFilterRowKey = "temperatureMaxFilter"
    private static let temperatureAverageFilterRowKey = "temperatureAverageFilter"
    private static let visibleOnMapFilterRowKey = "visibleOnMapFilter"
    private static let withWaypointsFilterRowKey = "withWaypointsFilter"
    private static let selectedKey = "selected"
    
    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    private var baseFilters: TracksSearchFilter
    private var baseFiltersResult: FilterResults
    private var nameFilterType: TextTrackFilter?
    private var otherFilterType: OtherTrackFilter?
    
    private lazy var filterMappings: [String: (type: TrackFilterType, isModal: Bool)] = [
        Self.lengthFilterRowKey: (.length, false),
        Self.durationFilterRowKey: (.duration, false),
        Self.timeInMotionFilterRowKey: (.timeInMotion, false),
        Self.dateCreationFilterRowKey: (.dateCreation, false),
        Self.averageSpeedFilterRowKey: (.averageSpeed, false),
        Self.maxSpeedFilterRowKey: (.maxSpeed, false),
        Self.averageAltitudeFilterRowKey: (.averageAltitude, false),
        Self.maxAltitudeFilterRowKey: (.maxAltitude, false),
        Self.uphillFilterRowKey: (.uphill, false),
        Self.downhillFilterRowKey: (.downhill, false),
        Self.colorFilterRowKey: (.color, true),
        Self.widthFilterRowKey: (.width, true),
        Self.nearestCitiesFilterRowKey: (.city, true),
        Self.folderFilterRowKey: (.folder, true),
        Self.sensorSpeedMaxFilterRowKey: (.maxSensorSpeed, false),
        Self.sensorSpeedAverageFilterRowKey: (.averageSensorSpeed, false),
        Self.heartRateMaxFilterRowKey: (.maxSensorHeartRate, false),
        Self.heartRateAverageFilterRowKey: (.averageSensorHeartRate, false),
        Self.bicycleCadenceMaxFilterRowKey: (.maxSensorCadence, false),
        Self.bicycleCadenceAverageFilterRowKey: (.averageSensorCadence, false),
        Self.bicyclePowerMaxFilterRowKey: (.maxSensorBicyclePower, false),
        Self.bicyclePowerAverageFilterRowKey: (.averageSensorBicyclePower, false),
        Self.temperatureMaxFilterRowKey: (.maxSensorTemperature, false),
        Self.temperatureAverageFilterRowKey: (.averageSensorTemperature, false)
    ]
    
    init(baseFilters: TracksSearchFilter, baseFiltersResult: FilterResults) {
        self.baseFilters = baseFilters
        self.baseFiltersResult = baseFiltersResult
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func commonInit() {
        nameFilterType = baseFilters.getFilterByType(.name) as? TextTrackFilter
        otherFilterType = baseFilters.getFilterByType(.other) as? OtherTrackFilter
    }
    
    override func registerCells() {
        addCell(OAInputTableViewCell.reuseIdentifier)
        addCell(OAValueTableViewCell.reuseIdentifier)
        addCell(OASwitchTableViewCell.reuseIdentifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onOutsideCellsTapped))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        baseFilters.addFiltersChangedListener(self)
    }
    
    override func getTitle() -> String? {
        localizedString("filter_current_poiButton")
    }
    
    override func getLeftNavbarButtonTitle() -> String? {
        localizedString("shared_string_cancel")
    }
    
    override func getBottomAxisMode() -> NSLayoutConstraint.Axis {
        .horizontal
    }
    
    override func getTopButtonTitle() -> String? {
        localizedString("shared_string_reset_all")
    }
    
    override func getBottomButtonTitle() -> String? {
        localizedString("shared_string_show") + " (\(baseFilters.getFilteredTrackItems().count))"
    }
    
    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        baseFilters.getAppliedFiltersCount() > 0 ? .graySimple : .inactive
    }
    
    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        baseFilters.getFilteredTrackItems().count > 0 ? .graySimple : .inactive
    }
    
    override func generateData() {
        tableData.clearAllData()
        let nameFilterSection = tableData.createNewSection()
        let nameRow = nameFilterSection.createNewRow()
        nameRow.cellType = OAInputTableViewCell.reuseIdentifier
        nameRow.key = Self.nameFilterRowKey
        nameRow.title = nameFilterType?.value
        nameRow.descr = localizedString("filter_poi_hint")
        
        addRangeFilterSections(sectionHeader: "", filters: [
            (key: Self.lengthFilterRowKey, type: .length, title: "routing_attr_length_name"),
            (key: Self.durationFilterRowKey, type: .duration, title: "map_widget_trip_recording_duration"),
            (key: Self.timeInMotionFilterRowKey, type: .timeInMotion, title: "moving_time"),
            (key: Self.dateCreationFilterRowKey, type: .dateCreation, title: "date_of_creation")
        ])
        
        addRangeFilterSections(sectionHeader: "shared_string_speed", filters: [
            (key: Self.averageSpeedFilterRowKey, type: .averageSpeed, title: "map_widget_average_speed"),
            (key: Self.maxSpeedFilterRowKey, type: .maxSpeed, title: "gpx_max_speed")
        ])
        
        addRangeFilterSections(sectionHeader: "altitud_and_elevation", filters: [
            (key: Self.averageAltitudeFilterRowKey, type: .averageAltitude, title: "average_altitude"),
            (key: Self.maxAltitudeFilterRowKey, type: .maxAltitude, title: "max_altitude"),
            (key: Self.uphillFilterRowKey, type: .uphill, title: "map_widget_trip_recording_uphill"),
            (key: Self.downhillFilterRowKey, type: .downhill, title: "map_widget_trip_recording_downhill")
        ])
        
        let appearanceFilterSection = tableData.createNewSection()
        appearanceFilterSection.headerText = localizedString("shared_string_appearance")
        let colorRow = appearanceFilterSection.createNewRow()
        colorRow.cellType = OAValueTableViewCell.reuseIdentifier
        colorRow.key = Self.colorFilterRowKey
        colorRow.title = localizedString("shared_string_color")
        updateListFilterRowDescription(forFilterType: .color, inRow: colorRow)
        let widthRow = appearanceFilterSection.createNewRow()
        widthRow.cellType = OAValueTableViewCell.reuseIdentifier
        widthRow.key = Self.widthFilterRowKey
        widthRow.title = localizedString("routing_attr_width_name")
        updateListFilterRowDescription(forFilterType: .width, inRow: widthRow)
        
        let infoFilterSection = tableData.createNewSection()
        infoFilterSection.headerText = localizedString("info_button")
        let nearestCitiesRow = infoFilterSection.createNewRow()
        nearestCitiesRow.cellType = OAValueTableViewCell.reuseIdentifier
        nearestCitiesRow.key = Self.nearestCitiesFilterRowKey
        nearestCitiesRow.title = localizedString("nearest_cities")
        updateListFilterRowDescription(forFilterType: .city, inRow: nearestCitiesRow)
        let folderRow = infoFilterSection.createNewRow()
        folderRow.cellType = OAValueTableViewCell.reuseIdentifier
        folderRow.key = Self.folderFilterRowKey
        folderRow.title = localizedString("plan_route_folder")
        updateListFilterRowDescription(forFilterType: .folder, inRow: folderRow)
        
        addRangeFilterSections(sectionHeader: "shared_string_sensors", filters: [
            (key: Self.sensorSpeedMaxFilterRowKey, type: .maxSensorSpeed, title: "max_sensor_speed"),
            (key: Self.sensorSpeedAverageFilterRowKey, type: .averageSensorSpeed, title: "avg_sensor_speed")
        ])
        
        addRangeFilterSections(sectionHeader: "", filters: [
            (key: Self.heartRateMaxFilterRowKey, type: .maxSensorHeartRate, title: "max_sensor_heartrate"),
            (key: Self.heartRateAverageFilterRowKey, type: .averageSensorHeartRate, title: "avg_sensor_heartrate")
        ])
        
        addRangeFilterSections(sectionHeader: "", filters: [
            (key: Self.bicycleCadenceMaxFilterRowKey, type: .maxSensorCadence, title: "max_sensor_cadence"),
            (key: Self.bicycleCadenceAverageFilterRowKey, type: .averageSensorCadence, title: "avg_sensor_cadence")
        ])
        
        addRangeFilterSections(sectionHeader: "", filters: [
            (key: Self.bicyclePowerMaxFilterRowKey, type: .maxSensorBicyclePower, title: "max_sensor_bycicle_power"),
            (key: Self.bicyclePowerAverageFilterRowKey, type: .averageSensorBicyclePower, title: "avg_sensor_bycicle_power")
        ])
        
        addRangeFilterSections(sectionHeader: "", filters: [
            (key: Self.temperatureMaxFilterRowKey, type: .maxSensorTemperature, title: "max_sensor_temperature"),
            (key: Self.temperatureAverageFilterRowKey, type: .averageSensorTemperature, title: "avg_sensor_temperature")
        ])
        
        let otherFilterSection = tableData.createNewSection()
        otherFilterSection.headerText = localizedString("other_location")
        let visibleOnMapRow = otherFilterSection.createNewRow()
        visibleOnMapRow.cellType = OASwitchTableViewCell.reuseIdentifier
        visibleOnMapRow.key = Self.visibleOnMapFilterRowKey
        visibleOnMapRow.title = localizedString("shared_string_visible_on_map")
        visibleOnMapRow.setObj(otherFilterType?.isParamSelected(param: .visibleOnMap) ?? false, forKey: Self.selectedKey)
        let withWaypointsRow = otherFilterSection.createNewRow()
        withWaypointsRow.cellType = OASwitchTableViewCell.reuseIdentifier
        withWaypointsRow.key = Self.withWaypointsFilterRowKey
        withWaypointsRow.title = localizedString("with_waypoints")
        withWaypointsRow.setObj(otherFilterType?.isParamSelected(param: .withWaypoints) ?? false, forKey: Self.selectedKey)
    }

    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == OAInputTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAInputTableViewCell.reuseIdentifier) as! OAInputTableViewCell
            cell.leftIconVisibility(false)
            cell.titleVisibility(false)
            cell.clearButtonVisibility(false)
            cell.inputField.delegate = self
            cell.inputField.returnKeyType = .go
            cell.inputField.enablesReturnKeyAutomatically = true
            cell.inputField.textAlignment = .left
            if let title = item.title, !title.isEmpty {
                cell.inputField.text = title
            } else {
                cell.inputField.placeholder = item.descr
            }
            return cell
        } else if item.cellType == OAValueTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier) as! OAValueTableViewCell
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.accessoryType = .disclosureIndicator
            cell.titleLabel.text = item.title
            cell.valueLabel.text = item.descr
            return cell
        } else if item.cellType == OASwitchTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.reuseIdentifier) as! OASwitchTableViewCell
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.switchView.isOn = item.bool(forKey: Self.selectedKey)
            cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
            cell.switchView.tag = indexPath.section << 10 | indexPath.row
            cell.switchView.addTarget(self, action: #selector(onSwitchClick(_:)), for: .valueChanged)
            return cell
        }
        
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        let item = tableData.item(for: indexPath)
        if let key = item.key, let mapping = filterMappings[key] {
            let filterDetailsVC = TracksFilterDetailsViewController(filterType: mapping.type, baseFilters: baseFilters, baseFiltersResult: baseFiltersResult)
            if mapping.isModal {
                showModalViewController(filterDetailsVC)
            } else {
                showMediumSheetViewController(filterDetailsVC, isLargeAvailable: false)
            }
        }
    }
    
    override func onLeftNavbarButtonPressed() {
        if baseFilters.getAppliedFiltersCount() > 0 {
            showResetFiltersAlert()
        } else {
            super.onLeftNavbarButtonPressed()
        }
    }
    
    override func onTopButtonPressed() {
        baseFilters.resetCurrentFilters()
        baseFiltersResult = baseFilters.performFiltering("")
        generateData()
        tableView.reloadData()
        updateBottomButtons()
    }
    
    override func onBottomButtonPressed() {
        super.onLeftNavbarButtonPressed()
    }
    
    @objc private func onSwitchClick(_ sender: Any) -> Bool {
        guard let tableData, let sw = sender as? UISwitch else { return false }
        let indexPath = IndexPath(row: sw.tag & 0x3FF, section: sw.tag >> 10)
        let data = tableData.item(for: indexPath)
        otherFilterType = baseFilters.getFilterByType(.other) as? OtherTrackFilter
        if data.key == Self.visibleOnMapFilterRowKey {
            otherFilterType?.setItemSelected(param: .visibleOnMap, selected: sw.isOn)
        } else if data.key == Self.withWaypointsFilterRowKey {
            otherFilterType?.setItemSelected(param: .withWaypoints, selected: sw.isOn)
        }
        
        baseFiltersResult = baseFilters.performFiltering("")
        updateBottomButtons()
        return false
    }
    
    @objc private func onOutsideCellsTapped() {
        view.endEditing(true)
    }
    
    private func addRangeFilterSections(sectionHeader: String, filters: [(key: String, type: TrackFilterType, title: String)]) {
        let section = tableData.createNewSection()
        section.headerText = localizedString(sectionHeader)
        filters.forEach { filterInfo in
            let row = section.createNewRow()
            configureRangeFilterRow(row: row, filterType: filterInfo.type, title: filterInfo.title, key: filterInfo.key)
        }
    }
    
    private func configureRangeFilterRow(row: OATableRowData, filterType: TrackFilterType, title: String, key: String) {
        row.cellType = OAValueTableViewCell.reuseIdentifier
        row.key = key
        row.title = localizedString(title)
        switch filterType {
        case .dateCreation:
            if let dateFilter = baseFilters.getFilterByType(filterType) as? DateTrackFilter {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                let fromDate = Date(timeIntervalSince1970: TimeInterval(dateFilter.valueFrom) / 1000)
                let toDate = Date(timeIntervalSince1970: TimeInterval(dateFilter.valueTo) / 1000)
                row.descr = "\(dateFormatter.string(from: fromDate)) - \(dateFormatter.string(from: toDate))"
            }
        default:
            if let filter = baseFilters.getFilterByType(filterType) as? RangeTrackFilter<AnyObject> {
                let mappedConstant = TracksSearchFilter.mapEOAMetricsConstantToMetricsConstants(OAAppSettings.sharedManager().metricSystem.get())
                let minValue = Float(TracksSearchFilter.getDisplayValueFrom(filter: filter))
                let maxValue = Float(TracksSearchFilter.getDisplayValueTo(filter: filter))
                row.descr = "\(decimalFormatter.string(from: NSNumber(value: minValue)) ?? "") - \(decimalFormatter.string(from: NSNumber(value: maxValue)) ?? "") \(filter.trackFilterType.measureUnitType.getFilterUnitText(mc: mappedConstant))"
            }
        }
    }
    
    private func updateListFilterRowDescription(forFilterType filterType: TrackFilterType, inRow row: OATableRowData) {
        if let filter = baseFilters.getFilterByType(filterType) as? ListTrackFilter {
            let selectedNames = filter.selectedItems.compactMap { item -> String? in
                guard let itemName = item as? String else { return nil }
                return filter.collectionFilterParams.getItemText(itemName: itemName)
            }.joined(separator: ", ")
            row.descr = selectedNames
        }
    }
    
    private func showResetFiltersAlert() {
        let alertController = UIAlertController(title: localizedString("shared_string_discard_changes") + "?", message: localizedString("discard_filter_changes_prompt"), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel, handler: nil)
        let resetAction = UIAlertAction(title: localizedString("shared_string_reset"), style: .destructive) { _ in
            self.baseFilters.resetCurrentFilters()
            self.baseFiltersResult = self.baseFilters.performFiltering("")
            super.onLeftNavbarButtonPressed()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(resetAction)
        present(alertController, animated: true)
    }
}

extension TracksFiltersViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else { return }
        nameFilterType?.value = text
        baseFiltersResult = baseFilters.performFiltering(text)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension TracksFiltersViewController: FilterChangedListener {
    func onFilterChanged() {
        DispatchQueue.main.async {
            self.generateData()
            self.tableView.reloadData()
            self.updateBottomButtons()
        }
    }
}
