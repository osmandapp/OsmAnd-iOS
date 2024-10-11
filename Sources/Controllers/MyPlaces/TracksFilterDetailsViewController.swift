//
//  TracksFilterDetailsViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 26.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

final class TracksFilterDetailsViewController: OABaseNavbarViewController {
    private static let fromDateRowKey = "fromDateRowKey"
    private static let toDateRowKey = "toDateRowKey"
    
    private var baseFilters: TracksSearchFilter
    private var baseFiltersResult: FilterResults
    private var rangeFilterType: RangeTrackFilter<AnyObject>?
    private var dateCreationFilterType: DateTrackFilter?
    private var searchController: UISearchController?
    private var currentMinValue: Float = 0.0
    private var currentMaxValue: Float = 0.0
    private var currentValueFrom: Float = 0.0
    private var currentValueTo: Float = 0.0
    private var rangeSliderMinValue: Float = 0.0
    private var rangeSliderMaxValue: Float = 0.0
    private var rangeSliderFromValue: Float = 0.0
    private var rangeSliderToValue: Float = 0.0
    private var valueFromInputText = ""
    private var valueToInputText = ""
    private var minFilterValueText = ""
    private var maxFilterValueText = ""
    private var dateCreationFromValue: Int64?
    private var dateCreationToValue: Int64?
    private var isSliderDragging = false
    private var isBinding = false
    
    private let filterParameter: FilterParameterType
    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    init(filterParameter: FilterParameterType, baseFilters: TracksSearchFilter, baseFiltersResult: FilterResults) {
        self.filterParameter = filterParameter
        self.baseFilters = baseFilters
        self.baseFiltersResult = baseFiltersResult
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func commonInit() {
        let filterTypes: [FilterParameterType: TrackFilterType] = [
            .lengthFilterType: .length,
            .durationFilterType: .duration,
            .timeInMotionFilterType: .timeInMotion,
            .averageSpeedFilterType: .averageSpeed,
            .maxSpeedFilterType: .maxSpeed,
            .averageAltitudeFilterType: .averageAltitude,
            .maxAltitudeFilterType: .maxAltitude,
            .uphillFilterType: .uphill,
            .downhillFilterType: .downhill,
            .sensorSpeedMaxFilterType: .maxSensorSpeed,
            .sensorSpeedAverageFilterType: .averageSensorSpeed,
            .heartRateMaxFilterType: .maxSensorHeartRate,
            .heartRateAverageFilterType: .averageSensorHeartRate,
            .bicycleCadenceMaxFilterType: .maxSensorCadence,
            .bicycleCadenceAverageFilterType: .averageSensorCadence,
            .bicyclePowerMaxFilterType: .maxSensorBicyclePower,
            .bicyclePowerAverageFilterType: .averageSensorBicyclePower,
            .temperatureMaxFilterType: .maxSensorTemperature,
            .temperatureAverageFilterType: .averageSensorTemperature
        ]
        
        if let filterType = filterTypes[filterParameter] {
            rangeFilterType = baseFilters.getFilterByType(filterType) as? RangeTrackFilter<AnyObject>
            guard let rangeFilterType = rangeFilterType else { return }
            currentMinValue = Float(TracksSearchFilter.getDisplayMinValue(filter: rangeFilterType))
            currentMaxValue = Float(TracksSearchFilter.getDisplayMaxValue(filter: rangeFilterType))
            currentValueFrom = Float(TracksSearchFilter.getDisplayValueFrom(filter: rangeFilterType))
            currentValueTo = Float(TracksSearchFilter.getDisplayValueTo(filter: rangeFilterType))
            updateRangeValues()
        } else if filterParameter == .dateCreationFilterType {
            dateCreationFilterType = baseFilters.getFilterByType(.dateCreation) as? DateTrackFilter
            dateCreationFromValue = dateCreationFilterType?.valueFrom
            dateCreationToValue = dateCreationFilterType?.valueTo
        }
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
        
        if filterParameter == .colorFilterType || filterParameter == .nearestCitiesFilterType || filterParameter == .folderFilterType {
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
        switch filterParameter {
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
        filterParameter == .colorFilterType || filterParameter == .widthFilterType || filterParameter == .nearestCitiesFilterType || filterParameter == .folderFilterType
    }
    
    override func generateData() {
        tableData.clearAllData()
        switch filterParameter {
        case .lengthFilterType, .durationFilterType, .timeInMotionFilterType, .averageSpeedFilterType, .maxSpeedFilterType, .averageAltitudeFilterType, .maxAltitudeFilterType, .uphillFilterType, .downhillFilterType, .sensorSpeedMaxFilterType, .sensorSpeedAverageFilterType, .heartRateMaxFilterType, .heartRateAverageFilterType, .bicycleCadenceMaxFilterType, .bicycleCadenceAverageFilterType, .bicyclePowerMaxFilterType, .bicyclePowerAverageFilterType, .temperatureMaxFilterType, .temperatureAverageFilterType:
            let rangeSection = tableData.createNewSection()
            let row = rangeSection.createNewRow()
            row.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
        case .dateCreationFilterType:
            let dateSection = tableData.createNewSection()
            let fromDateRow = dateSection.createNewRow()
            fromDateRow.cellType = OADatePickerTableViewCell.reuseIdentifier
            fromDateRow.key = Self.fromDateRowKey
            fromDateRow.title = localizedString("shared_string_from").capitalized
            fromDateRow.setObj(dateCreationFromValue ?? 0, forKey: "date")
            let toDateRow = dateSection.createNewRow()
            toDateRow.cellType = OADatePickerTableViewCell.reuseIdentifier
            toDateRow.key = Self.toDateRowKey
            toDateRow.title = localizedString("shared_string_to")
            toDateRow.setObj(dateCreationToValue ?? 0, forKey: "date")
        case .colorFilterType:
            break
        case .widthFilterType:
            break
        case .nearestCitiesFilterType:
            break
        case .folderFilterType:
            break
        }
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == OADatePickerTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OADatePickerTableViewCell.reuseIdentifier) as! OADatePickerTableViewCell
            cell.selectionStyle = .none
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.datePicker.preferredDatePickerStyle = .compact
            cell.datePicker.datePickerMode = .date
            if let timestamp = item.obj(forKey: "date") as? Int64 {
                let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
                cell.datePicker.date = date
            } else {
                cell.datePicker.date = Date()
            }
            cell.datePicker.removeTarget(nil, action: nil, for: .allEvents)
            cell.datePicker.tag = indexPath.section << 10 | indexPath.row
            cell.datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
            return cell
        } else if item.cellType == OARangeSliderFilterTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OARangeSliderFilterTableViewCell.reuseIdentifier) as! OARangeSliderFilterTableViewCell
            cell.selectionStyle = .none
            cell.minTextField.delegate = self
            cell.maxTextField.delegate = self
            cell.minTextField.tag = .min
            cell.maxTextField.tag = .max
            cell.minTextField.returnKeyType = .go
            cell.maxTextField.returnKeyType = .go
            cell.minTextField.enablesReturnKeyAutomatically = true
            cell.maxTextField.enablesReturnKeyAutomatically = true
            cell.minTextField.text = valueFromInputText
            cell.maxTextField.text = valueToInputText
            cell.minValueLabel.text = minFilterValueText
            cell.maxValueLabel.text = maxFilterValueText
            cell.rangeSlider.delegate = self
            cell.rangeSlider.tag = indexPath.section << 10 | indexPath.row
            cell.rangeSlider.enableStep = true
            cell.rangeSlider.step = 1.0
            cell.rangeSlider.minValue = rangeSliderMinValue
            cell.rangeSlider.maxValue = rangeSliderMaxValue
            cell.rangeSlider.selectedMinimum = rangeSliderFromValue
            cell.rangeSlider.selectedMaximum = rangeSliderToValue
            return cell
        }
        
        return nil
    }
    
    override func onRightNavbarButtonPressed() {
        switch filterParameter {
        case .lengthFilterType, .durationFilterType, .timeInMotionFilterType, .averageSpeedFilterType, .maxSpeedFilterType, .averageAltitudeFilterType, .maxAltitudeFilterType, .uphillFilterType, .downhillFilterType, .sensorSpeedMaxFilterType, .sensorSpeedAverageFilterType, .heartRateMaxFilterType, .heartRateAverageFilterType, .bicycleCadenceMaxFilterType, .bicycleCadenceAverageFilterType, .bicyclePowerMaxFilterType, .bicyclePowerAverageFilterType, .temperatureMaxFilterType, .temperatureAverageFilterType:
            rangeFilterType?.setValueFrom(from: String(Int(currentValueFrom)), updateListeners_: false)
            rangeFilterType?.setValueTo(to: String(Int(currentValueTo)), updateListeners: false)
        case .dateCreationFilterType:
            if let dateFrom = dateCreationFromValue, let dateTo = dateCreationToValue {
                dateCreationFilterType?.valueFrom = dateFrom
                dateCreationFilterType?.valueTo = dateTo
            }
        default:
            break
        }
        
        baseFiltersResult = baseFilters.performFiltering("")
        baseFilters.onFilterChanged()
        super.onLeftNavbarButtonPressed()
    }
    
    @objc private func onOutsideCellsTapped() {
        view.endEditing(true)
    }
    
    @objc private func datePickerValueChanged(_ sender: UIDatePicker) {
        guard let tableData else { return }
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        let data = tableData.item(for: indexPath)
        let newDate = sender.date
        let timestamp = Int64(newDate.timeIntervalSince1970 * 1000)
        if data.key == Self.fromDateRowKey {
            dateCreationFromValue = timestamp
        } else if data.key == Self.toDateRowKey {
            dateCreationToValue = timestamp
        }
    }
    
    private func updateRangeValues() {
        isBinding = true
        if currentMaxValue > currentMinValue {
            rangeSliderMinValue = Float(currentMinValue)
            rangeSliderMaxValue = Float(currentMaxValue)
            rangeSliderFromValue = Float(currentValueFrom)
            rangeSliderToValue = Float(currentValueTo)
            valueFromInputText = String(describing: Int(currentValueFrom))
            valueToInputText = String(describing: Int(currentValueTo))
            let mappedConstant = TracksSearchFilter.mapEOAMetricsConstantToMetricsConstants(OAAppSettings.sharedManager().metricSystem.get())
            let minValuePrompt = "\(decimalFormatter.string(from: NSNumber(value: Float(currentMinValue))) ?? "") \(getMeasureUnitType().getFilterUnitText(mc: mappedConstant))"
            let maxValuePrompt = "\(decimalFormatter.string(from: NSNumber(value: Float(currentMaxValue))) ?? "") \(getMeasureUnitType().getFilterUnitText(mc: mappedConstant))"
            minFilterValueText = minValuePrompt
            maxFilterValueText = maxValuePrompt
            isBinding = false
        }
    }
    
    private func getMeasureUnitType() -> MeasureUnitType {
        if let rangeFilterType = rangeFilterType {
            return rangeFilterType.trackFilterType.measureUnitType
        }
        
        return .none
    }
}

extension TracksFilterDetailsViewController: TTRangeSliderDelegate {
    func didStartTouches(in sender: TTRangeSlider) {
        isSliderDragging = true
    }
    
    func rangeSlider(_ sender: TTRangeSlider, didChangeSelectedMinimumValue selectedMinimum: Float, andMaximumValue selectedMaximum: Float) {
        let valueFrom = floor(selectedMinimum)
        let valueTo = ceil(selectedMaximum)
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        if valueFrom >= sender.minValue && valueTo <= sender.maxValue {
            valueFromInputText = String(Int(valueFrom))
            valueToInputText = String(Int(valueTo))
            if let cell = tableView.cellForRow(at: indexPath) as? OARangeSliderFilterTableViewCell {
                cell.minTextField.text = valueFromInputText
                cell.maxTextField.text = valueToInputText
            }
        }
    }
    
    func didEndTouches(in sender: TTRangeSlider) {
        isSliderDragging = false
        currentValueFrom = sender.selectedMinimum
        currentValueTo = sender.selectedMaximum
        updateRangeValues()
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
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

extension TracksFilterDetailsViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let newPosition = textField.endOfDocument
        textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text, !text.isEmpty, let newValue = Float(text) else { return }
        switch textField.tag {
        case .min:
            if newValue < currentValueTo, !isSliderDragging, !isBinding {
                currentValueFrom = newValue
                updateRangeValues()
                tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            }
        case .max:
            if newValue > currentValueFrom, !isSliderDragging, !isBinding {
                currentValueTo = newValue
                updateRangeValues()
                tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            }
        default:
            break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
