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
    
    private var initialFilterText: String?
    
    override func registerCells() {
        addCell(OAInputTableViewCell.reuseIdentifier)
        addCell(OAValueTableViewCell.reuseIdentifier)
        addCell(OASwitchTableViewCell.reuseIdentifier)
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
        localizedString("discard_filter_changes_prompt")
    }
    
    override func getBottomButtonTitle() -> String? {
        localizedString("shared_string_show") + " (0)"
    }
    
    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        .graySimple
    }
    
    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        .graySimple
    }
    
    override func generateData() {
        tableData.clearAllData()
        let nameFilterSection = tableData.createNewSection()
        let nameRow = nameFilterSection.createNewRow()
        nameRow.cellType = OAInputTableViewCell.reuseIdentifier
        nameRow.key = Self.nameFilterRowKey
        nameRow.title = initialFilterText
        nameRow.descr = localizedString("filter_poi_hint")
        
        addBasicFilterSections()
        addSpeedFilterSections()
        addAltitudeElevationFilterSections()
        addAppearanceElevationFilterSections()
        addInfoFilterSections()
        addSensorsFilterSections()
        
        let otherFilterSection = tableData.createNewSection()
        otherFilterSection.headerText = localizedString("other_location")
        let visibleOnMapRow = otherFilterSection.createNewRow()
        visibleOnMapRow.cellType = OASwitchTableViewCell.reuseIdentifier
        visibleOnMapRow.key = Self.visibleOnMapFilterRowKey
        visibleOnMapRow.title = localizedString("shared_string_visible_on_map")
        visibleOnMapRow.setObj(true, forKey: Self.selectedKey)
        let withWaypointsRow = otherFilterSection.createNewRow()
        withWaypointsRow.cellType = OASwitchTableViewCell.reuseIdentifier
        withWaypointsRow.key = Self.withWaypointsFilterRowKey
        withWaypointsRow.title = localizedString("with_waypoints")
        withWaypointsRow.setObj(true, forKey: Self.selectedKey)
    }

    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == OAInputTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAInputTableViewCell.reuseIdentifier) as! OAInputTableViewCell
            cell.leftIconVisibility(false)
            cell.titleVisibility(false)
            cell.clearButtonVisibility(false)
            cell.inputField.textAlignment = .left
            if let text = initialFilterText, !text.isEmpty {
                cell.inputField.text = text
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
            return cell
        }
        
        return nil
    }
    
    override func onTopButtonPressed() {
    }
    
    override func onBottomButtonPressed() {
    }
    
    private func addBasicFilterSections() {
        let basicFilterSection = tableData.createNewSection()
        let lengthRow = basicFilterSection.createNewRow()
        lengthRow.cellType = OAValueTableViewCell.reuseIdentifier
        lengthRow.key = Self.lengthFilterRowKey
        lengthRow.title = localizedString("routing_attr_length_name")
        lengthRow.descr = "25 - 30 km"
        let durationRow = basicFilterSection.createNewRow()
        durationRow.cellType = OAValueTableViewCell.reuseIdentifier
        durationRow.key = Self.durationFilterRowKey
        durationRow.title = localizedString("map_widget_trip_recording_duration")
        durationRow.descr = "13 - 120 min"
        let timeInMotionRow = basicFilterSection.createNewRow()
        timeInMotionRow.cellType = OAValueTableViewCell.reuseIdentifier
        timeInMotionRow.key = Self.timeInMotionFilterRowKey
        timeInMotionRow.title = localizedString("moving_time")
        timeInMotionRow.descr = "50 - 60 min"
        let dateCreationRow = basicFilterSection.createNewRow()
        dateCreationRow.cellType = OAValueTableViewCell.reuseIdentifier
        dateCreationRow.key = Self.dateCreationFilterRowKey
        dateCreationRow.title = localizedString("date_of_creation")
        dateCreationRow.descr = "23 Aug 2017"
    }
    
    private func addSpeedFilterSections() {
        let speedFilterSection = tableData.createNewSection()
        speedFilterSection.headerText = localizedString("shared_string_speed")
        let averageSpeedRow = speedFilterSection.createNewRow()
        averageSpeedRow.cellType = OAValueTableViewCell.reuseIdentifier
        averageSpeedRow.key = Self.averageSpeedFilterRowKey
        averageSpeedRow.title = localizedString("map_widget_average_speed")
        averageSpeedRow.descr = "15 - 20 km/h"
        let maxSpeedRow = speedFilterSection.createNewRow()
        maxSpeedRow.cellType = OAValueTableViewCell.reuseIdentifier
        maxSpeedRow.key = Self.maxSpeedFilterRowKey
        maxSpeedRow.title = localizedString("gpx_max_speed")
        maxSpeedRow.descr = "100 - 120 km/h"
    }
    
    private func addAltitudeElevationFilterSections() {
        let altitudeElevationFilterSection = tableData.createNewSection()
        altitudeElevationFilterSection.headerText = localizedString("altitud_and_elevation")
        let averageAltitudeRow = altitudeElevationFilterSection.createNewRow()
        averageAltitudeRow.cellType = OAValueTableViewCell.reuseIdentifier
        averageAltitudeRow.key = Self.averageAltitudeFilterRowKey
        averageAltitudeRow.title = localizedString("average_altitude")
        averageAltitudeRow.descr = ""
        let maxAltitudeRow = altitudeElevationFilterSection.createNewRow()
        maxAltitudeRow.cellType = OAValueTableViewCell.reuseIdentifier
        maxAltitudeRow.key = Self.maxAltitudeFilterRowKey
        maxAltitudeRow.title = localizedString("max_altitude")
        maxAltitudeRow.descr = ""
        let uphillRow = altitudeElevationFilterSection.createNewRow()
        uphillRow.cellType = OAValueTableViewCell.reuseIdentifier
        uphillRow.key = Self.uphillFilterRowKey
        uphillRow.title = localizedString("map_widget_trip_recording_uphill")
        uphillRow.descr = ""
        let downhillRow = altitudeElevationFilterSection.createNewRow()
        downhillRow.cellType = OAValueTableViewCell.reuseIdentifier
        downhillRow.key = Self.downhillFilterRowKey
        downhillRow.title = localizedString("map_widget_trip_recording_downhill")
        downhillRow.descr = ""
    }
    
    private func addAppearanceElevationFilterSections() {
        let appearanceFilterSection = tableData.createNewSection()
        appearanceFilterSection.headerText = localizedString("shared_string_appearance")
        let colorRow = appearanceFilterSection.createNewRow()
        colorRow.cellType = OAValueTableViewCell.reuseIdentifier
        colorRow.key = Self.colorFilterRowKey
        colorRow.title = localizedString("shared_string_color")
        let widthRow = appearanceFilterSection.createNewRow()
        widthRow.cellType = OAValueTableViewCell.reuseIdentifier
        widthRow.key = Self.widthFilterRowKey
        widthRow.title = localizedString("routing_attr_width_name")
    }
    
    private func addInfoFilterSections() {
        let infoFilterSection = tableData.createNewSection()
        infoFilterSection.headerText = localizedString("info_button")
        let nearestCitiesRow = infoFilterSection.createNewRow()
        nearestCitiesRow.cellType = OAValueTableViewCell.reuseIdentifier
        nearestCitiesRow.key = Self.nearestCitiesFilterRowKey
        nearestCitiesRow.title = localizedString("nearest_cities")
        let folderRow = infoFilterSection.createNewRow()
        folderRow.cellType = OAValueTableViewCell.reuseIdentifier
        folderRow.key = Self.folderFilterRowKey
        folderRow.title = localizedString("plan_route_folder")
        folderRow.descr = "All folders"
    }
    
    private func addSensorsFilterSections() {
        let sensorsFilterSection = tableData.createNewSection()
        sensorsFilterSection.headerText = localizedString("shared_string_sensors")
        let sensorSpeedMaxRow = sensorsFilterSection.createNewRow()
        sensorSpeedMaxRow.cellType = OAValueTableViewCell.reuseIdentifier
        sensorSpeedMaxRow.key = Self.sensorSpeedMaxFilterRowKey
        sensorSpeedMaxRow.title = localizedString("max_sensor_speed")
        let sensorSpeedAverageRow = sensorsFilterSection.createNewRow()
        sensorSpeedAverageRow.cellType = OAValueTableViewCell.reuseIdentifier
        sensorSpeedAverageRow.key = Self.sensorSpeedAverageFilterRowKey
        sensorSpeedAverageRow.title = localizedString("avg_sensor_speed")
        
        let heartRateFilterSection = tableData.createNewSection()
        let heartRateMaxRow = heartRateFilterSection.createNewRow()
        heartRateMaxRow.cellType = OAValueTableViewCell.reuseIdentifier
        heartRateMaxRow.key = Self.heartRateMaxFilterRowKey
        heartRateMaxRow.title = localizedString("max_sensor_heartrate")
        let heartRateAverageRow = heartRateFilterSection.createNewRow()
        heartRateAverageRow.cellType = OAValueTableViewCell.reuseIdentifier
        heartRateAverageRow.key = Self.heartRateAverageFilterRowKey
        heartRateAverageRow.title = localizedString("avg_sensor_heartrate")
        
        let bicycleCadenceFilterSection = tableData.createNewSection()
        let bicycleCadenceMaxRow = bicycleCadenceFilterSection.createNewRow()
        bicycleCadenceMaxRow.cellType = OAValueTableViewCell.reuseIdentifier
        bicycleCadenceMaxRow.key = Self.bicycleCadenceMaxFilterRowKey
        bicycleCadenceMaxRow.title = localizedString("max_sensor_cadence")
        let bicycleCadenceAverageRow = bicycleCadenceFilterSection.createNewRow()
        bicycleCadenceAverageRow.cellType = OAValueTableViewCell.reuseIdentifier
        bicycleCadenceAverageRow.key = Self.bicycleCadenceAverageFilterRowKey
        bicycleCadenceAverageRow.title = localizedString("avg_sensor_cadence")
        
        let bicyclePowerFilterSection = tableData.createNewSection()
        let bicyclePowerMaxRow = bicyclePowerFilterSection.createNewRow()
        bicyclePowerMaxRow.cellType = OAValueTableViewCell.reuseIdentifier
        bicyclePowerMaxRow.key = Self.bicyclePowerMaxFilterRowKey
        bicyclePowerMaxRow.title = localizedString("max_sensor_bycicle_power")
        let bicyclePowerAverageRow = bicyclePowerFilterSection.createNewRow()
        bicyclePowerAverageRow.cellType = OAValueTableViewCell.reuseIdentifier
        bicyclePowerAverageRow.key = Self.bicyclePowerAverageFilterRowKey
        bicyclePowerAverageRow.title = localizedString("avg_sensor_bycicle_power")
        
        let temperatureFilterSection = tableData.createNewSection()
        let temperatureMaxRow = temperatureFilterSection.createNewRow()
        temperatureMaxRow.cellType = OAValueTableViewCell.reuseIdentifier
        temperatureMaxRow.key = Self.temperatureMaxFilterRowKey
        temperatureMaxRow.title = localizedString("max_sensor_temperature")
        let temperatureAverageRow = temperatureFilterSection.createNewRow()
        temperatureAverageRow.cellType = OAValueTableViewCell.reuseIdentifier
        temperatureAverageRow.key = Self.temperatureAverageFilterRowKey
        temperatureAverageRow.title = localizedString("avg_sensor_temperature")
    }
    
    func setInitialFilterText(_ text: String) {
        initialFilterText = text
    }
}
