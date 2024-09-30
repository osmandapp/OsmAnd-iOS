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
        
        if filterType == .colorillFilterType || filterType == .nearestCitiesFilterType || filterType == .folderFilterType {
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
    
    override func isNavbarSeparatorVisible() -> Bool {
        filterType == .colorillFilterType || filterType == .widthillFilterType || filterType == .nearestCitiesFilterType || filterType == .folderFilterType
    }
    
    override func generateData() {
        tableData.clearAllData()
        if filterType == .lengthFilterType {
            let lengthSection = tableData.createNewSection()
            let lengthRow = lengthSection.createNewRow()
            lengthRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            lengthRow.key = Self.lengthRowKey
            lengthRow.descr = unitForFilterType(.lengthFilterType)
        } else if filterType == .durationFilterType {
            let durationSection = tableData.createNewSection()
            let durationRow = durationSection.createNewRow()
            durationRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            durationRow.key = Self.durationRowKey
            durationRow.descr = unitForFilterType(.durationFilterType)
        } else if filterType == .timeInMotionFilterType {
            let timeInMotionSection = tableData.createNewSection()
            let timeInMotionRow = timeInMotionSection.createNewRow()
            timeInMotionRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            timeInMotionRow.key = Self.timeInMotionRowKey
            timeInMotionRow.descr = unitForFilterType(.timeInMotionFilterType)
        } else if filterType == .dateCreationFilterType {
            let dateSection = tableData.createNewSection()
            let fromDateRow = dateSection.createNewRow()
            fromDateRow.cellType = OADatePickerTableViewCell.reuseIdentifier
            fromDateRow.key = Self.fromDateRowKey
            fromDateRow.title = localizedString("shared_string_from").capitalized
            let toDateRow = dateSection.createNewRow()
            toDateRow.cellType = OADatePickerTableViewCell.reuseIdentifier
            toDateRow.key = Self.toDateRowKey
            toDateRow.title = localizedString("shared_string_to")
        } else if filterType == .averageSpeedFilterType {
            let averageSpeedSection = tableData.createNewSection()
            let averageSpeedRow = averageSpeedSection.createNewRow()
            averageSpeedRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            averageSpeedRow.key = Self.averageSpeedRowKey
            averageSpeedRow.descr = unitForFilterType(.averageSpeedFilterType)
        } else if filterType == .maxSpeedFilterType {
            let maxSpeedSection = tableData.createNewSection()
            let maxSpeedRow = maxSpeedSection.createNewRow()
            maxSpeedRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            maxSpeedRow.key = Self.maxSpeedRowKey
            maxSpeedRow.descr = unitForFilterType(.maxSpeedFilterType)
        } else if filterType == .averageAltitudeFilterType {
            let averageAltitudeSection = tableData.createNewSection()
            let averageAltitudeRow = averageAltitudeSection.createNewRow()
            averageAltitudeRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            averageAltitudeRow.key = Self.averageAltitudeRowKey
            averageAltitudeRow.descr = unitForFilterType(.averageAltitudeFilterType)
        } else if filterType == .maxAltitudeFilterType {
            let maxAltitudeSection = tableData.createNewSection()
            let maxAltitudeRow = maxAltitudeSection.createNewRow()
            maxAltitudeRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            maxAltitudeRow.key = Self.maxAltitudeRowKey
            maxAltitudeRow.descr = unitForFilterType(.maxAltitudeFilterType)
        } else if filterType == .uphillFilterType {
            let uphillSection = tableData.createNewSection()
            let uphillRow = uphillSection.createNewRow()
            uphillRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            uphillRow.key = Self.uphillRowKey
            uphillRow.descr = unitForFilterType(.uphillFilterType)
        } else if filterType == .downhillFilterType {
            let downhillSection = tableData.createNewSection()
            let downhillRow = downhillSection.createNewRow()
            downhillRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            downhillRow.key = Self.downhillRowKey
            downhillRow.descr = unitForFilterType(.downhillFilterType)
        } else if filterType == .colorillFilterType {
        } else if filterType == .widthillFilterType {
        } else if filterType == .nearestCitiesFilterType {
        } else if filterType == .folderFilterType {
        } else if filterType == .sensorSpeedMaxFilterType {
            let sensorSpeedMaxSection = tableData.createNewSection()
            let sensorSpeedMaxRow = sensorSpeedMaxSection.createNewRow()
            sensorSpeedMaxRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            sensorSpeedMaxRow.key = Self.sensorSpeedMaxRowKey
            sensorSpeedMaxRow.descr = unitForFilterType(.sensorSpeedMaxFilterType)
        } else if filterType == .sensorSpeedAverageFilterType {
            let sensorSpeedAverageSection = tableData.createNewSection()
            let sensorSpeedAverageRow = sensorSpeedAverageSection.createNewRow()
            sensorSpeedAverageRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            sensorSpeedAverageRow.key = Self.sensorSpeedAverageRowKey
            sensorSpeedAverageRow.descr = unitForFilterType(.sensorSpeedAverageFilterType)
        } else if filterType == .heartRateMaxFilterType {
            let heartRateMaxSection = tableData.createNewSection()
            let heartRateMaxRow = heartRateMaxSection.createNewRow()
            heartRateMaxRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            heartRateMaxRow.key = Self.heartRateMaxRowKey
            heartRateMaxRow.descr = unitForFilterType(.heartRateMaxFilterType)
        } else if filterType == .heartRateAverageFilterType {
            let heartRateAverageSection = tableData.createNewSection()
            let heartRateAverageRow = heartRateAverageSection.createNewRow()
            heartRateAverageRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            heartRateAverageRow.key = Self.heartRateAverageRowKey
            heartRateAverageRow.descr = unitForFilterType(.heartRateAverageFilterType)
        } else if filterType == .bicycleCadenceMaxFilterType {
            let bicycleCadenceMaxSection = tableData.createNewSection()
            let bicycleCadenceMaxRow = bicycleCadenceMaxSection.createNewRow()
            bicycleCadenceMaxRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            bicycleCadenceMaxRow.key = Self.bicycleCadenceMaxRowKey
            bicycleCadenceMaxRow.descr = unitForFilterType(.bicycleCadenceMaxFilterType)
        } else if filterType == .bicycleCadenceAverageFilterType {
            let bicycleCadenceAverageSection = tableData.createNewSection()
            let bicycleCadenceAverageRow = bicycleCadenceAverageSection.createNewRow()
            bicycleCadenceAverageRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            bicycleCadenceAverageRow.key = Self.bicycleCadenceMaxRowKey
            bicycleCadenceAverageRow.descr = unitForFilterType(.bicycleCadenceAverageFilterType)
        } else if filterType == .bicyclePowerMaxFilterType {
            let bicyclePowerMaxSection = tableData.createNewSection()
            let bicyclePowerMaxRow = bicyclePowerMaxSection.createNewRow()
            bicyclePowerMaxRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            bicyclePowerMaxRow.key = Self.bicyclePowerMaxRowKey
            bicyclePowerMaxRow.descr = unitForFilterType(.bicyclePowerMaxFilterType).lowercased()
        } else if filterType == .bicyclePowerAverageFilterType {
            let bicyclePowerAverageSection = tableData.createNewSection()
            let bicyclePowerAverageRow = bicyclePowerAverageSection.createNewRow()
            bicyclePowerAverageRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            bicyclePowerAverageRow.key = Self.bicyclePowerAverageRowKey
            bicyclePowerAverageRow.descr = unitForFilterType(.bicyclePowerAverageFilterType).lowercased()
        } else if filterType == .temperatureMaxFilterType {
            let temperatureMaxSection = tableData.createNewSection()
            let temperatureMaxRow = temperatureMaxSection.createNewRow()
            temperatureMaxRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            temperatureMaxRow.key = Self.temperatureMaxRowKey
            temperatureMaxRow.descr = unitForFilterType(.temperatureMaxFilterType)
        } else if filterType == .temperatureAverageFilterType {
            let temperatureAverageSection = tableData.createNewSection()
            let temperatureAverageRow = temperatureAverageSection.createNewRow()
            temperatureAverageRow.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
            temperatureAverageRow.key = Self.temperatureMaxRowKey
            temperatureAverageRow.descr = unitForFilterType(.temperatureAverageFilterType)
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
    
    private func unitForFilterType(_ type: FilterParameterType) -> String {
        let locale = Locale.current
        switch type {
        case .lengthFilterType:
            if #available(iOS 16, *) {
                switch locale.measurementSystem {
                case .metric:
                    return localizedString("km")
                case .uk:
                    return localizedString("mile")
                case .us:
                    return localizedString("mile")
                default:
                    return ""
                }
            } else {
                return locale.usesMetricSystem ? localizedString("km") : localizedString("mile")
            }
        case .durationFilterType, .timeInMotionFilterType:
            return localizedString("int_min")
        case .averageSpeedFilterType, .maxSpeedFilterType, .sensorSpeedMaxFilterType, .sensorSpeedAverageFilterType:
            if #available(iOS 16, *) {
                switch locale.measurementSystem {
                case .metric:
                    return localizedString("km_h")
                case .uk:
                    return localizedString("mile_per_hour")
                case .us:
                    return localizedString("mile_per_hour")
                default:
                    return ""
                }
            } else {
                return locale.usesMetricSystem ? localizedString("km_h") : localizedString("mile_per_hour")
            }
        case .averageAltitudeFilterType, .maxAltitudeFilterType, .uphillFilterType, .downhillFilterType:
            if #available(iOS 16, *) {
                switch locale.measurementSystem {
                case .metric:
                    return localizedString("m")
                case .uk:
                    return localizedString("foot")
                case .us:
                    return localizedString("foot")
                default:
                    return ""
                }
            } else {
                return locale.usesMetricSystem ? localizedString("m") : localizedString("foot")
            }
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
