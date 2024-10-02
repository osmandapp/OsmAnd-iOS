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
    case colorFilterType
    case widthFilterType
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
    private static let lengthRowKey = "lengthRowKey"
    private static let durationRowKey = "durationRowKey"
    private static let timeInMotionRowKey = "timeInMotionRowKey"
    private static let fromDateRowKey = "fromDateRowKey"
    private static let toDateRowKey = "toDateRowKey"
    private static let averageSpeedRowKey = "averageSpeedRowKey"
    private static let maxSpeedRowKey = "maxSpeedRowKey"
    private static let averageAltitudeRowKey = "averageAltitudeRowKey"
    private static let maxAltitudeRowKey = "maxAltitudeRowKey"
    private static let uphillRowKey = "uphillRowKey"
    private static let downhillRowKey = "downhillRowKey"
    private static let sensorSpeedMaxRowKey = "sensorSpeedMaxRowKey"
    private static let sensorSpeedAverageRowKey = "sensorSpeedAverageRowKey"
    private static let heartRateMaxRowKey = "heartRateMaxRowKey"
    private static let heartRateAverageRowKey = "heartRateAverageRowKey"
    private static let bicycleCadenceMaxRowKey = "bicycleCadenceMaxRowKey"
    private static let bicycleCadenceAverageRowKey = "bicycleCadenceAverageRowKey"
    private static let bicyclePowerMaxRowKey = "bicyclePowerMaxRowKey"
    private static let bicyclePowerAverageRowKey = "bicyclePowerAverageRowKey"
    private static let temperatureMaxRowKey = "temperatureMaxRowKey"
    private static let temperatureAverageRowKey = "temperatureAverageRowKey"

    private let filterType: FilterParameterType
    private let sliderMinValue: Float = 0
    
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
        addCell(OARangeSliderFilterTableViewCell.reuseIdentifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onOutsideCellsTapped))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)

        if filterType == .colorFilterType || filterType == .nearestCitiesFilterType || filterType == .folderFilterType {
            searchController = UISearchController(searchResultsController: nil)
            searchController?.searchBar.delegate = self
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.searchBar.placeholder = localizedString("shared_string_search")
            searchController?.searchBar.returnKeyType = .go
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
        case .colorFilterType:
            return localizedString("shared_string_color")
        case .widthFilterType:
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
    
    override func isNavbarSeparatorVisible() -> Bool {
        filterType == .colorFilterType || filterType == .widthFilterType || filterType == .nearestCitiesFilterType || filterType == .folderFilterType
    }
    
    override func generateData() {
        tableData.clearAllData()
        switch filterType {
        case .lengthFilterType:
            configureFilterSection(withKey: Self.lengthRowKey, forType: .lengthFilterType)
        case .durationFilterType:
            configureFilterSection(withKey: Self.durationRowKey, forType: .durationFilterType)
        case .timeInMotionFilterType:
            configureFilterSection(withKey: Self.timeInMotionRowKey, forType: .timeInMotionFilterType)
        case .dateCreationFilterType:
            configureDatePickerSection(fromKey: Self.fromDateRowKey, toKey: Self.toDateRowKey)
        case .averageSpeedFilterType:
            configureFilterSection(withKey: Self.averageSpeedRowKey, forType: .averageSpeedFilterType)
        case .maxSpeedFilterType:
            configureFilterSection(withKey: Self.maxSpeedRowKey, forType: .maxSpeedFilterType)
        case .averageAltitudeFilterType:
            configureFilterSection(withKey: Self.averageAltitudeRowKey, forType: .averageAltitudeFilterType)
        case .maxAltitudeFilterType:
            configureFilterSection(withKey: Self.maxAltitudeRowKey, forType: .maxAltitudeFilterType)
        case .uphillFilterType:
            configureFilterSection(withKey: Self.uphillRowKey, forType: .uphillFilterType)
        case .downhillFilterType:
            configureFilterSection(withKey: Self.downhillRowKey, forType: .downhillFilterType)
        case .colorFilterType:
            configureColorFilterData()
        case .widthFilterType:
            configureWidthFilterData()
        case .nearestCitiesFilterType:
            configureNearestCitiesFilterData()
        case .folderFilterType:
            configureFolderFilterData()
        case .sensorSpeedMaxFilterType:
            configureFilterSection(withKey: Self.sensorSpeedMaxRowKey, forType: .sensorSpeedMaxFilterType)
        case .sensorSpeedAverageFilterType:
            configureFilterSection(withKey: Self.sensorSpeedAverageRowKey, forType: .sensorSpeedAverageFilterType)
        case .heartRateMaxFilterType:
            configureFilterSection(withKey: Self.heartRateMaxRowKey, forType: .heartRateMaxFilterType)
        case .heartRateAverageFilterType:
            configureFilterSection(withKey: Self.heartRateAverageRowKey, forType: .heartRateAverageFilterType)
        case .bicycleCadenceMaxFilterType:
            configureFilterSection(withKey: Self.bicycleCadenceMaxRowKey, forType: .bicycleCadenceMaxFilterType)
        case .bicycleCadenceAverageFilterType:
            configureFilterSection(withKey: Self.bicycleCadenceAverageRowKey, forType: .bicycleCadenceAverageFilterType)
        case .bicyclePowerMaxFilterType:
            configureFilterSection(withKey: Self.bicyclePowerMaxRowKey, forType: .bicyclePowerMaxFilterType)
        case .bicyclePowerAverageFilterType:
            configureFilterSection(withKey: Self.bicyclePowerAverageRowKey, forType: .bicyclePowerAverageFilterType)
        case .temperatureMaxFilterType:
            configureFilterSection(withKey: Self.temperatureMaxRowKey, forType: .temperatureMaxFilterType)
        case .temperatureAverageFilterType:
            configureFilterSection(withKey: Self.temperatureAverageRowKey, forType: .temperatureAverageFilterType)
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
        } else if item.cellType == OARangeSliderFilterTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OARangeSliderFilterTableViewCell.reuseIdentifier) as! OARangeSliderFilterTableViewCell
            cell.selectionStyle = .none
            cell.minTextField.returnKeyType = .go
            cell.maxTextField.returnKeyType = .go
            cell.minTextField.enablesReturnKeyAutomatically = true
            cell.maxTextField.enablesReturnKeyAutomatically = true
            cell.rangeSlider.minValue = sliderMinValue
            cell.rangeSlider.maxValue = 100
            cell.rangeSlider.selectedMinimum = sliderMinValue
            cell.rangeSlider.selectedMaximum = 100
            if let descr = item.descr {
                cell.unit = descr
            }
            return cell
        }
        
        return nil
    }
    
    @objc private func onOutsideCellsTapped() {
        view.endEditing(true)
    }
    
    private func configureFilterSection(withKey key: String, forType type: FilterParameterType) {
        let section = tableData.createNewSection()
        let row = section.createNewRow()
        row.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
        row.key = key
        var description = unitForFilterType(type)
        switch type {
        case .bicycleCadenceMaxFilterType, .bicycleCadenceAverageFilterType, .bicyclePowerMaxFilterType, .bicyclePowerAverageFilterType:
            description = description.lowercased()
        default:
            break
        }
        
        row.descr = description
    }
    
    private func configureDatePickerSection(fromKey: String, toKey: String) {
        let dateSection = tableData.createNewSection()
        let fromDateRow = dateSection.createNewRow()
        fromDateRow.cellType = OADatePickerTableViewCell.reuseIdentifier
        fromDateRow.key = fromKey
        fromDateRow.title = localizedString("shared_string_from").capitalized
        let toDateRow = dateSection.createNewRow()
        toDateRow.cellType = OADatePickerTableViewCell.reuseIdentifier
        toDateRow.key = toKey
        toDateRow.title = localizedString("shared_string_to")
    }
    
    private func configureColorFilterData() {
    }
    
    private func configureWidthFilterData() {
    }
    
    private func configureNearestCitiesFilterData() {
    }
    
    private func configureFolderFilterData() {
    }
    
    private func unitForFilterType(_ type: FilterParameterType) -> String {
        let locale = Locale.current
        switch type {
        case .lengthFilterType:
            return unitFromMetric("km", imperial: "mile", for: locale)
        case .durationFilterType, .timeInMotionFilterType:
            return localizedString("int_min")
        case .averageSpeedFilterType, .maxSpeedFilterType, .sensorSpeedMaxFilterType, .sensorSpeedAverageFilterType:
            return unitFromMetric("km_h", imperial: "mile_per_hour", for: locale)
        case .averageAltitudeFilterType, .maxAltitudeFilterType, .uphillFilterType, .downhillFilterType:
            return unitFromMetric("m", imperial: "foot", for: locale)
        case .heartRateMaxFilterType, .heartRateAverageFilterType:
            return localizedString("beats_per_minute_short")
        case .bicycleCadenceMaxFilterType, .bicycleCadenceAverageFilterType:
            return localizedString("revolutions_per_minute_unit")
        case .bicyclePowerMaxFilterType, .bicyclePowerAverageFilterType:
            return localizedString("power_watts_unit")
        case .temperatureMaxFilterType, .temperatureAverageFilterType:
            let formatter = MeasurementFormatter()
            formatter.unitStyle = .short
            formatter.locale = Locale.autoupdatingCurrent
            return formatter.displayString(from: UnitTemperature.current())
        default:
            return ""
        }
    }
    
    private func unitFromMetric(_ metricUnit: String, imperial: String, for locale: Locale) -> String {
        if #available(iOS 16, *) {
            switch locale.measurementSystem {
            case .metric:
                return localizedString(metricUnit)
            case .uk, .us:
                return localizedString(imperial)
            default:
                return ""
            }
        } else {
            return locale.usesMetricSystem ? localizedString(metricUnit) : localizedString(imperial)
        }
    }
}

extension TracksFilterDetailsViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
