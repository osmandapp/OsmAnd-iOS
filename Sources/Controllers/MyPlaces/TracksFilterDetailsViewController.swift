//
//  TracksFilterDetailsViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 26.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

enum FilterParameterType: Int {
    case lengthFilterType
    case durationFilterType
    case timeInMotionFilterType
    case dateCreationFilterType
    case averageSpeedFilterType
    case maxSpeedFilterType
    case averageAltitudeFilterType
    case maxAltitudeFilterType
    case uphillFilterType
    case downhillFilterType
    case colorillFilterType
    case widthillFilterType
    case nearestCitiesFilterType
    case folderFilterType
    case sensorSpeedMaxFilterType
    case sensorSpeedAverageFilterType
    case heartRateMaxFilterType
    case heartRateAverageFilterType
    case bicycleCadenceMaxFilterType
    case bicycleCadenceAverageFilterType
    case bicyclePowerMaxFilterType
    case bicyclePowerAverageFilterType
    case temperatureMaxFilterType
    case temperatureAverageFilterType
}

final class TracksFilterDetailsViewController: OABaseNavbarViewController {
    private static let fromDateRowKey = "fromDateRowKey"
    private static let toDateRowKey = "toDateRowKey"

    private let filterType: FilterParameterType
    
    private var searchController: UISearchController?
    
    init(filterType: FilterParameterType) {
        self.filterType = filterType
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func registerCells() {
        addCell(OADatePickerTableViewCell.reuseIdentifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if filterType == .colorillFilterType || filterType == .nearestCitiesFilterType || filterType == .folderFilterType {
            searchController = UISearchController(searchResultsController: nil)
            searchController?.searchBar.delegate = self
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.searchBar.placeholder = localizedString("shared_string_search")
            navigationItem.searchController = searchController
            definesPresentationContext = true
        }
    }
    
    override func getTitle() -> String? {
        switch filterType {
        case .lengthFilterType:
            return localizedString("routing_attr_length_name")
        case .durationFilterType:
            return localizedString("map_widget_trip_recording_duration")
        case .timeInMotionFilterType:
            return localizedString("moving_time")
        case .dateCreationFilterType:
            return localizedString("date_of_creation")
        case .averageSpeedFilterType:
            return localizedString("map_widget_average_speed")
        case .maxSpeedFilterType:
            return localizedString("gpx_max_speed")
        case .averageAltitudeFilterType:
            return localizedString("average_altitude")
        case .maxAltitudeFilterType:
            return localizedString("max_altitude")
        case .uphillFilterType:
            return localizedString("map_widget_trip_recording_uphill")
        case .downhillFilterType:
            return localizedString("map_widget_trip_recording_downhill")
        case .colorillFilterType:
            return localizedString("shared_string_color")
        case .widthillFilterType:
            return localizedString("routing_attr_width_name")
        case .nearestCitiesFilterType:
            return localizedString("nearest_cities")
        case .folderFilterType:
            return localizedString("plan_route_folder")
        case .sensorSpeedMaxFilterType:
            return localizedString("max_sensor_speed")
        case .sensorSpeedAverageFilterType:
            return localizedString("avg_sensor_speed")
        case .heartRateMaxFilterType:
            return localizedString("max_sensor_heartrate")
        case .heartRateAverageFilterType:
            return localizedString("avg_sensor_heartrate")
        case .bicycleCadenceMaxFilterType:
            return localizedString("max_sensor_cadence")
        case .bicycleCadenceAverageFilterType:
            return localizedString("avg_sensor_cadence")
        case .bicyclePowerMaxFilterType:
            return localizedString("max_sensor_bycicle_power")
        case .bicyclePowerAverageFilterType:
            return localizedString("avg_sensor_bycicle_power")
        case .temperatureMaxFilterType:
            return localizedString("max_sensor_temperature")
        case .temperatureAverageFilterType:
            return localizedString("avg_sensor_temperature")
        }
    }
    
    override func getLeftNavbarButtonTitle() -> String? {
        localizedString("shared_string_cancel")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        guard let applyBarButton = createRightNavbarButton(localizedString("shared_string_apply"), iconName: nil, action: #selector(onRightNavbarButtonPressed), menu: nil) else {
            return []
        }
        
        return [applyBarButton]
    }
    
    override func generateData() {
        tableData.clearAllData()
        if filterType == .dateCreationFilterType {
            let dateSection = tableData.createNewSection()
            let fromDateRow = dateSection.createNewRow()
            fromDateRow.cellType = OADatePickerTableViewCell.reuseIdentifier
            fromDateRow.key = Self.fromDateRowKey
            fromDateRow.title = localizedString("shared_string_from").capitalized
            let toDateRow = dateSection.createNewRow()
            toDateRow.cellType = OADatePickerTableViewCell.reuseIdentifier
            toDateRow.key = Self.toDateRowKey
            toDateRow.title = localizedString("shared_string_to")
        }
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == OADatePickerTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OADatePickerTableViewCell.reuseIdentifier) as! OADatePickerTableViewCell
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.datePicker.preferredDatePickerStyle = .compact
            cell.datePicker.datePickerMode = .date
            return cell
        }
        
        return nil
    }
}

extension TracksFilterDetailsViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    }
}
