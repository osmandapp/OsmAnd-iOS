//
//  TracksFilterDetailsViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 26.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

protocol TrackFilterConfigurable {
    func configure(with filter: BaseTrackFilter, in controller: TracksFilterDetailsViewController)
}

struct DisplayFolderItem {
    let key: String
    let path: String
    let displayName: String
    var subfolders: [DisplayFolderItem] = []
    let icon: UIImage
    let iconTintColor: UIColor
}

class RangeTrackFilterConfigurator: TrackFilterConfigurable {
    func configure(with filter: BaseTrackFilter, in controller: TracksFilterDetailsViewController) {
        controller.rangeFilterType = filter as? RangeTrackFilter<AnyObject>
        guard let rangeFilter = controller.rangeFilterType else { return }
        controller.rangeFilterType = rangeFilter
        controller.currentMinValue = Float(TracksSearchFilter.getDisplayMinValue(filter: rangeFilter))
        controller.currentMaxValue = Float(TracksSearchFilter.getDisplayMaxValue(filter: rangeFilter))
        controller.currentValueFrom = Float(TracksSearchFilter.getDisplayValueFrom(filter: rangeFilter))
        controller.currentValueTo = Float(TracksSearchFilter.getDisplayValueTo(filter: rangeFilter))
        controller.updateRangeValues()
    }
}

class DateTrackFilterConfigurator: TrackFilterConfigurable {
    func configure(with filter: BaseTrackFilter, in controller: TracksFilterDetailsViewController) {
        controller.dateCreationFilterType = filter as? DateTrackFilter
        guard let dateFilter = controller.dateCreationFilterType else { return }
        controller.dateCreationFromValue = dateFilter.valueFrom
        controller.dateCreationToValue = dateFilter.valueTo
    }
}

class ListTrackFilterConfigurator: TrackFilterConfigurable {
    func configure(with filter: BaseTrackFilter, in controller: TracksFilterDetailsViewController) {
        controller.listFilterType = filter as? ListTrackFilter
        guard let listFilter = controller.listFilterType else { return }
        controller.allListItems = listFilter.allItems.compactMap { $0 as? String }
        if let emptyIndex = controller.allListItems.firstIndex(of: "") {
            if emptyIndex != 0 {
                let emptyItem = controller.allListItems.remove(at: emptyIndex)
                controller.allListItems.insert(emptyItem, at: 0)
            }
        }
        
        controller.selectedItems = listFilter.selectedItems.compactMap { $0 as? String }
    }
}

class FolderTrackFilterConfigurator: TrackFilterConfigurable {
    func configure(with filter: BaseTrackFilter, in controller: TracksFilterDetailsViewController) {
        controller.listFilterType = filter as? FolderTrackFilter
        guard let listFilter = controller.listFilterType else { return }
        var orderedFolders: [DisplayFolderItem] = []
        
        func addSubfolder(to folder: inout DisplayFolderItem, with pathComponents: [String], currentPath: String, originalKey: String, displayName: String) {
            let subfolderPath = currentPath
            if !folder.subfolders.contains(where: { $0.path == subfolderPath && $0.displayName == displayName }) {
                let subfolder = createFolderItem(key: originalKey, path: subfolderPath, displayName: displayName, isRoot: false)
                folder.subfolders.append(subfolder)
            }
        }
        
        func processSubfolders(for folder: inout DisplayFolderItem, with remainingComponents: [String], currentPath: String, originalKey: String) {
            guard let subfolderName = remainingComponents.first else { return }
            let subfolderDisplayName = listFilter.collectionFilterParams.getItemText(itemName: subfolderName)
            addSubfolder(to: &folder, with: remainingComponents, currentPath: currentPath, originalKey: originalKey, displayName: subfolderDisplayName)
            let nextComponents = Array(remainingComponents.dropFirst())
            if !nextComponents.isEmpty {
                let subfolderPath = currentPath + "/" + subfolderName
                if let index = folder.subfolders.firstIndex(where: { $0.path == currentPath && $0.displayName == subfolderDisplayName }) {
                    processSubfolders(for: &folder.subfolders[index], with: nextComponents, currentPath: subfolderPath, originalKey: originalKey)
                }
            }
        }
        
        func createFolderItem(key: String, path: String, displayName: String, isRoot: Bool) -> DisplayFolderItem {
            let icon = isRoot ? UIImage.icCustomFolderOpen : UIImage.icCustomFolder
            let tintColor = isRoot ? UIColor.iconColorSelected : UIColor.iconColorDefault
            return DisplayFolderItem(key: key, path: path, displayName: displayName, icon: icon, iconTintColor: tintColor)
        }
        
        for folder in listFilter.allItems.compactMap({ $0 as? String }) {
            let components = folder.split(separator: "/").map(String.init)
            let topLevel = components.first ?? ""
            let subfolderPath = components.dropFirst().joined(separator: "/")
            if let topLevelIndex = orderedFolders.firstIndex(where: { $0.path == topLevel }) {
                if !subfolderPath.isEmpty {
                    processSubfolders(for: &orderedFolders[topLevelIndex], with: Array(components.dropFirst()), currentPath: topLevel, originalKey: folder)
                }
            } else {
                let topLevelFolder = createFolderItem(key: folder, path: topLevel, displayName: listFilter.collectionFilterParams.getItemText(itemName: topLevel), isRoot: true)
                orderedFolders.append(topLevelFolder)
                if !subfolderPath.isEmpty {
                    var newTopLevelFolder = topLevelFolder
                    processSubfolders(for: &newTopLevelFolder, with: Array(components.dropFirst()), currentPath: topLevel, originalKey: folder)
                    if let index = orderedFolders.firstIndex(where: { $0.path == topLevel }) {
                        orderedFolders[index] = newTopLevelFolder
                    }
                }
            }
        }
        
        controller.allFoldersListItems = orderedFolders
        controller.selectedItems = listFilter.selectedItems.compactMap { $0 as? String }
        if let emptyIndex = controller.allFoldersListItems.firstIndex(where: { $0.path.isEmpty }), emptyIndex != 0 {
            let emptyItem = controller.allFoldersListItems.remove(at: emptyIndex)
            controller.allFoldersListItems.insert(emptyItem, at: 0)
        }
    }
}

final class TracksFilterDetailsViewController: OABaseNavbarViewController {
    private static let fromDateRowKey = "fromDateRowKey"
    private static let toDateRowKey = "toDateRowKey"
    private static let allFoldersRowKey = "allFoldersRowKey"
    private static let folderPath = "folderPath"
    
    private var baseFilters: TracksSearchFilter
    private var baseFiltersResult: FilterResults
    private var filteredListItems: [String] = []
    private var filteredFoldersListItems: [DisplayFolderItem] = []
    private var searchController: UISearchController?
    private var rangeSliderMinValue: Float = 0.0
    private var rangeSliderMaxValue: Float = 0.0
    private var rangeSliderFromValue: Float = 0.0
    private var rangeSliderToValue: Float = 0.0
    private var valueFromInputText = ""
    private var valueToInputText = ""
    private var minFilterValueText = ""
    private var maxFilterValueText = ""
    private var isSliderDragging = false
    private var isBinding = false
    private var isSearchActive = false
    
    var rangeFilterType: RangeTrackFilter<AnyObject>?
    var dateCreationFilterType: DateTrackFilter?
    var listFilterType: ListTrackFilter?
    var allListItems: [String] = []
    var allFoldersListItems: [DisplayFolderItem] = []
    var selectedItems: [String] = []
    var currentMinValue: Float = 0.0
    var currentMaxValue: Float = 0.0
    var currentValueFrom: Float = 0.0
    var currentValueTo: Float = 0.0
    var dateCreationFromValue: Int64?
    var dateCreationToValue: Int64?
    
    private let filterType: TrackFilterType
    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    init(filterType: TrackFilterType, baseFilters: TracksSearchFilter, baseFiltersResult: FilterResults) {
        self.filterType = filterType
        self.baseFilters = baseFilters
        self.baseFiltersResult = baseFiltersResult
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func commonInit() {
        let configurators: [TrackFilterType: TrackFilterConfigurable] = [
            .length: RangeTrackFilterConfigurator(),
            .duration: RangeTrackFilterConfigurator(),
            .timeInMotion: RangeTrackFilterConfigurator(),
            .averageSpeed: RangeTrackFilterConfigurator(),
            .maxSpeed: RangeTrackFilterConfigurator(),
            .averageAltitude: RangeTrackFilterConfigurator(),
            .maxAltitude: RangeTrackFilterConfigurator(),
            .uphill: RangeTrackFilterConfigurator(),
            .downhill: RangeTrackFilterConfigurator(),
            .maxSensorSpeed: RangeTrackFilterConfigurator(),
            .averageSensorSpeed: RangeTrackFilterConfigurator(),
            .maxSensorHeartRate: RangeTrackFilterConfigurator(),
            .averageSensorHeartRate: RangeTrackFilterConfigurator(),
            .maxSensorCadence: RangeTrackFilterConfigurator(),
            .averageSensorCadence: RangeTrackFilterConfigurator(),
            .maxSensorBicyclePower: RangeTrackFilterConfigurator(),
            .averageSensorBicyclePower: RangeTrackFilterConfigurator(),
            .maxSensorTemperature: RangeTrackFilterConfigurator(),
            .averageSensorTemperature: RangeTrackFilterConfigurator(),
            .dateCreation: DateTrackFilterConfigurator(),
            .color: ListTrackFilterConfigurator(),
            .width: ListTrackFilterConfigurator(),
            .city: ListTrackFilterConfigurator(),
            .folder: FolderTrackFilterConfigurator()
        ]
        
        guard let filter = baseFilters.getFilterByType(filterType), let configurator = configurators[filterType] else { return }
        configurator.configure(with: filter, in: self)
    }
    
    override func registerCells() {
        addCell(OADatePickerTableViewCell.reuseIdentifier)
        addCell(OARangeSliderFilterTableViewCell.reuseIdentifier)
        addCell(OAValueTableViewCell.reuseIdentifier)
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onOutsideCellsTapped))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        if filterType == .color || filterType == .width || filterType == .city || filterType == .folder {
            tableView.setEditing(true, animated: false)
            tableView.allowsMultipleSelectionDuringEditing = true
            searchController = UISearchController(searchResultsController: nil)
            searchController?.searchBar.delegate = self
            searchController?.delegate = self
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.searchBar.placeholder = localizedString("shared_string_search")
            searchController?.searchBar.returnKeyType = .go
            navigationItem.searchController = searchController
            definesPresentationContext = true
        }
    }
    
    override func getTitle() -> String? {
        switch filterType {
        case .length:
            return localizedString("routing_attr_length_name")
        case .duration:
            return localizedString("map_widget_trip_recording_duration")
        case .timeInMotion:
            return localizedString("moving_time")
        case .dateCreation:
            return localizedString("date_of_creation")
        case .averageSpeed:
            return localizedString("map_widget_average_speed")
        case .maxSpeed:
            return localizedString("gpx_max_speed")
        case .averageAltitude:
            return localizedString("average_altitude")
        case .maxAltitude:
            return localizedString("max_altitude")
        case .uphill:
            return localizedString("map_widget_trip_recording_uphill")
        case .downhill:
            return localizedString("map_widget_trip_recording_downhill")
        case .color:
            return localizedString("shared_string_color")
        case .width:
            return localizedString("routing_attr_width_name")
        case .city:
            return localizedString("nearest_cities")
        case .folder:
            return localizedString("plan_route_folder")
        case .maxSensorSpeed:
            return localizedString("max_sensor_speed")
        case .averageSensorSpeed:
            return localizedString("avg_sensor_speed")
        case .maxSensorHeartRate:
            return localizedString("max_sensor_heartrate")
        case .averageSensorHeartRate:
            return localizedString("avg_sensor_heartrate")
        case .maxSensorCadence:
            return localizedString("max_sensor_cadence")
        case .averageSensorCadence:
            return localizedString("avg_sensor_cadence")
        case .maxSensorBicyclePower:
            return localizedString("max_sensor_bycicle_power")
        case .averageSensorBicyclePower:
            return localizedString("avg_sensor_bycicle_power")
        case .maxSensorTemperature:
            return localizedString("max_sensor_temperature")
        case .averageSensorTemperature:
            return localizedString("avg_sensor_temperature")
        default:
            return ""
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
        filterType == .color || filterType == .width || filterType == .city || filterType == .folder
    }
    
    override func generateData() {
        tableData.clearAllData()
        switch filterType {
        case .length, .duration, .timeInMotion, .averageSpeed, .maxSpeed, .averageAltitude, .maxAltitude, .uphill, .downhill, .maxSensorSpeed, .averageSensorSpeed, .maxSensorHeartRate, .averageSensorHeartRate, .maxSensorCadence, .averageSensorCadence, .maxSensorBicyclePower, .averageSensorBicyclePower, .maxSensorTemperature, .averageSensorTemperature:
            let rangeSection = tableData.createNewSection()
            let row = rangeSection.createNewRow()
            row.cellType = OARangeSliderFilterTableViewCell.reuseIdentifier
        case .dateCreation:
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
        case .color, .width, .city:
            let section = tableData.createNewSection()
            let itemsToDisplay = isSearchActive ? filteredListItems : allListItems
            for itemName in itemsToDisplay {
                configureRowForSection(section: section, itemName: itemName, isWidth: filterType == .width)
            }
        case .folder:
            let foldersToDisplay = isSearchActive ? filteredFoldersListItems : allFoldersListItems
            if !isSearchActive {
                let allFoldersSection = tableData.createNewSection()
                let allFoldersRow = allFoldersSection.createNewRow()
                allFoldersRow.cellType = OASimpleTableViewCell.reuseIdentifier
                allFoldersRow.key = Self.allFoldersRowKey
                allFoldersRow.title = localizedString("all_folders")
                allFoldersRow.icon = .icCustomFolderOpen
                allFoldersRow.iconTintColor = .iconColorSelected
            }
            
            func displayFolder(_ folderItem: DisplayFolderItem, in section: OATableSectionData, isRootFolder: Bool) {
                let row = section.createNewRow()
                row.cellType = OAValueTableViewCell.reuseIdentifier
                row.key = folderItem.key
                row.title = folderItem.displayName
                row.icon = folderItem.icon
                row.iconTintColor = folderItem.iconTintColor
                if let tracksCount = listFilterType?.getTracksCountForItem(itemName: folderItem.key) {
                    row.descr = String(describing: tracksCount)
                }
                
                if !isRootFolder {
                    row.setObj(folderItem.path, forKey: Self.folderPath)
                }
                
                for subfolder in folderItem.subfolders {
                    displayFolder(subfolder, in: section, isRootFolder: false)
                }
            }
            
            for folderItem in foldersToDisplay {
                let section = tableData.createNewSection()
                displayFolder(folderItem, in: section, isRootFolder: true)
            }
        default:
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
        } else if item.cellType == OAValueTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier) as! OAValueTableViewCell
            cell.descriptionVisibility(item.obj(forKey: Self.folderPath) != nil)
            cell.leftIconVisibility(item.icon != nil || filterType == .color)
            cell.selectedBackgroundView = UIView()
            cell.selectedBackgroundView?.backgroundColor = UIColor.groupBg
            cell.accessoryType = .none
            cell.titleLabel.text = item.title
            cell.descriptionLabel.text = item.obj(forKey: Self.folderPath) as? String
            cell.valueLabel.text = item.descr
            cell.leftIconView.image = item.icon
            cell.leftIconView.tintColor = item.iconTintColor
            if filterType == .color {
                let isKeyNotEmpty = item.key?.isEmpty == false
                cell.leftIconView.backgroundColor = isKeyNotEmpty ? item.iconTintColor : nil
                cell.leftIconView.layer.cornerRadius = isKeyNotEmpty ? cell.leftIconView.frame.height / 2 : 0
            }
            if let key = item.key, selectedItems.contains(key) {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            } else {
                tableView.deselectRow(at: indexPath, animated: false)
            }
            return cell
        } else if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier) as! OASimpleTableViewCell
            cell.descriptionVisibility(false)
            cell.selectedBackgroundView = UIView()
            cell.selectedBackgroundView?.backgroundColor = UIColor.groupBg
            cell.accessoryType = .none
            cell.titleLabel.text = item.title
            cell.leftIconView.image = item.icon
            cell.leftIconView.tintColor = item.iconTintColor
            if item.key == Self.allFoldersRowKey {
                if listFilterType?.isSelectAllItemsSelected == true {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                } else {
                    tableView.deselectRow(at: indexPath, animated: false)
                }
            }
            return cell
        }
        
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        guard let tableData else { return }
        let data = tableData.item(for: indexPath)
        let previousSelectAllStatus = listFilterType?.isSelectAllItemsSelected == true
        if data.key == Self.allFoldersRowKey {
            listFilterType?.isSelectAllItemsSelected = true
            selectAllFolders()
        } else if let itemKey = data.key, !selectedItems.contains(itemKey) {
            selectedItems.append(itemKey)
        }
        
        if !isSearchActive {
            checkIfAllFoldersSelected()
        }
        
        if previousSelectAllStatus != (listFilterType?.isSelectAllItemsSelected == true) {
            tableView.reloadData()
        }
    }
    
    override func onRowDeselected(_ indexPath: IndexPath) {
        guard let tableData else { return }
        let data = tableData.item(for: indexPath)
        let previousSelectAllStatus = listFilterType?.isSelectAllItemsSelected == true
        if data.key == Self.allFoldersRowKey {
            listFilterType?.isSelectAllItemsSelected = false
            deselectAllFolders()
        } else if let itemKey = data.key, let index = selectedItems.firstIndex(of: itemKey) {
            selectedItems.remove(at: index)
        }
        
        if !isSearchActive {
            checkIfAllFoldersSelected()
        }
        
        if previousSelectAllStatus != (listFilterType?.isSelectAllItemsSelected == true) {
            tableView.reloadData()
        }
    }
    
    override func onRightNavbarButtonPressed() {
        switch filterType {
        case .length, .duration, .timeInMotion, .averageSpeed, .maxSpeed, .averageAltitude, .maxAltitude, .uphill, .downhill, .maxSensorSpeed, .averageSensorSpeed, .maxSensorHeartRate, .averageSensorHeartRate, .maxSensorCadence, .averageSensorCadence, .maxSensorBicyclePower, .averageSensorBicyclePower, .maxSensorTemperature, .averageSensorTemperature:
            rangeFilterType?.setValueFrom(from: String(Int(currentValueFrom)), updateListeners_: false)
            rangeFilterType?.setValueTo(to: String(Int(currentValueTo)), updateListeners: false)
        case .dateCreation:
            if let dateFrom = dateCreationFromValue, let dateTo = dateCreationToValue {
                dateCreationFilterType?.valueFrom = dateFrom
                dateCreationFilterType?.valueTo = dateTo
            }
        case .color, .width, .city, .folder:
            listFilterType?.setSelectedItems(selectedItems: selectedItems)
        default:
            break
        }
        
        baseFiltersResult = baseFilters.performFiltering()
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
    
    private func configureRowForSection(section: OATableSectionData, itemName: String, isWidth: Bool) {
        let row = section.createNewRow()
        row.cellType = OAValueTableViewCell.reuseIdentifier
        row.key = itemName
        if itemName.isEmpty {
            row.title = listFilterType?.collectionFilterParams.getItemText(itemName: itemName) ?? ""
        } else {
            row.title = isWidth ? listFilterType?.collectionFilterParams.getItemText(itemName: itemName).capitalized : listFilterType?.collectionFilterParams.getItemText(itemName: itemName)
        }
        
        if let tracksCount = listFilterType?.getTracksCountForItem(itemName: itemName) {
            row.descr = String(describing: tracksCount)
        }
        
        if itemName.isEmpty {
            row.icon = .icCustomAppearanceDisabledOutlined
            row.iconTintColor = .iconColorDisabled
        } else if isWidth {
            switch itemName {
            case "thin":
                row.icon = .icCustomTrackLineThin
            case "medium":
                row.icon = .icCustomTrackLineMedium
            case "bold":
                row.icon = .icCustomTrackLineBold
            default:
                row.icon = .icCustomTrackLineMedium
            }
            row.iconTintColor = .iconColorDisruptive
        } else if let itemInt = Int(itemName) {
            row.iconTintColor = colorFromRGB(itemInt)
        }
    }
    
    private func getMeasureUnitType() -> MeasureUnitType {
        if let rangeFilterType = rangeFilterType {
            return rangeFilterType.trackFilterType.measureUnitType
        }
        
        return .none
    }
    
    private func updateAllFoldersSelection(add: Bool) {
        func updateFolderSelection(from folder: DisplayFolderItem, add: Bool) {
            if add {
                if !selectedItems.contains(folder.key) {
                    selectedItems.append(folder.key)
                }
            } else {
                if let index = selectedItems.firstIndex(of: folder.key) {
                    selectedItems.remove(at: index)
                }
            }
            
            for subfolder in folder.subfolders {
                updateFolderSelection(from: subfolder, add: add)
            }
        }
        
        for folder in allFoldersListItems {
            updateFolderSelection(from: folder, add: add)
        }
    }
    
    private func selectAllFolders() {
        updateAllFoldersSelection(add: true)
    }
    
    private func deselectAllFolders() {
        updateAllFoldersSelection(add: false)
    }
    
    private func checkIfAllFoldersSelected() {
        let folderItemsToDisplay = isSearchActive ? filteredFoldersListItems : allFoldersListItems
        let allFolderKeys = folderItemsToDisplay.flatMap { flattenFolder($0).map { $0.key } }
        listFilterType?.isSelectAllItemsSelected = allFolderKeys.allSatisfy { selectedItems.contains($0) }
    }
    
    private func flattenFolder(_ folderItem: DisplayFolderItem) -> [DisplayFolderItem] {
        var result: [DisplayFolderItem] = [folderItem]
        for subfolder in folderItem.subfolders {
            result.append(contentsOf: flattenFolder(subfolder))
        }
        
        return result
    }
    
    func updateRangeValues() {
        isBinding = true
        if currentMaxValue > currentMinValue {
            rangeSliderMinValue = Float(currentMinValue)
            rangeSliderMaxValue = Float(currentMaxValue)
            rangeSliderFromValue = Float(currentValueFrom)
            rangeSliderToValue = Float(currentValueTo)
            valueFromInputText = String(describing: Int(currentValueFrom))
            valueToInputText = String(describing: Int(currentValueTo))
            let mappedConstant = TracksSearchFilter.mapEOAMetricsConstantToMetricsConstants(OAAppSettings.sharedManager().metricSystem.get())
            minFilterValueText = "\(decimalFormatter.string(from: NSNumber(value: Float(currentMinValue))) ?? "") \(getMeasureUnitType().getFilterUnitText(mc: mappedConstant))"
            maxFilterValueText = "\(decimalFormatter.string(from: NSNumber(value: Float(currentMaxValue))) ?? "") \(getMeasureUnitType().getFilterUnitText(mc: mappedConstant))"
            isBinding = false
        }
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

extension TracksFilterDetailsViewController: UISearchBarDelegate, UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        isSearchActive = true
        filteredListItems = allListItems
        filteredFoldersListItems = allFoldersListItems
        generateData()
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if filterType == .folder {
            func filterFolders(_ folderItems: [DisplayFolderItem], searchText: String) -> [DisplayFolderItem] {
                var result: [DisplayFolderItem] = []
                for folder in folderItems {
                    var folderCopy = folder
                    var hasMatchingSubfolders = false
                    let matchingSubfolders = filterFolders(folder.subfolders, searchText: searchText)
                    if !matchingSubfolders.isEmpty {
                        folderCopy.subfolders = matchingSubfolders
                        hasMatchingSubfolders = true
                    }
                    
                    if folder.displayName.localizedCaseInsensitiveContains(searchText) {
                        folderCopy.subfolders = matchingSubfolders
                        result.append(folderCopy)
                    } else if hasMatchingSubfolders {
                        result.append(contentsOf: matchingSubfolders)
                    }
                }
                
                return result
            }
            
            filteredFoldersListItems = searchText.isEmpty ? allFoldersListItems : filterFolders(allFoldersListItems, searchText: searchText)
        } else {
            filteredListItems = searchText.isEmpty ? allListItems : allListItems.filter { itemName in
                listFilterType?.collectionFilterParams.getItemText(itemName: itemName).localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        generateData()
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearchActive = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        generateData()
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension TracksFilterDetailsViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        DispatchQueue.main.async {
            let newPosition = textField.endOfDocument
            textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
        }
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
