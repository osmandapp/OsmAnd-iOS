//
//  StatisticsSelectionBottomSheetViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 03.03.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objc protocol OAStatisticsSelectionDelegate: AnyObject {
    func onGraphModeChanged(_ selectedXAxisMode: GPXDataSetAxisType, types: [NSNumber])
}

private enum RowKey: String {
    case type
    case axisType
    case selected
    case isCustomLeftSeparatorInset
}

private enum VehicleMetricsSubgroup: Int, CaseIterable {
    case temperature
    case engine
    case fuel
    case other
}

private struct VehicleMetricsMeta {
    let subgroup: VehicleMetricsSubgroup
    let itemOrder: Int
}

@objcMembers
final class StatisticsSelectionBottomSheetViewController: OABaseNavbarSubviewViewController {
    private var types: [NSNumber]
    private var selectedXAxisMode: GPXDataSetAxisType
    private var analysis: GpxTrackAnalysis
    private var segmentedControl: UISegmentedControl?
    private var isYAxisMode = true
    
    weak var delegate: OAStatisticsSelectionDelegate?
    
    init(types: [NSNumber], selectedXAxisMode: GPXDataSetAxisType, analysis: GpxTrackAnalysis) {
        self.types = types
        self.selectedXAxisMode = selectedXAxisMode
        self.analysis = analysis
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyTableMode()
        syncCheckmarksFromData()
    }
    
    override func getTitle() -> String {
        localizedString("graph_axis")
    }
    
    override func getSystemLeftBarButtonItem() -> UIBarButtonItem? {
        UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(onClosePressed))
    }
    
    override func getSystemRightBarButtonItems() -> [UIBarButtonItem]? {
        [UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDonePressed))]
    }
    
    override func createSubview() -> UIView? {
        if segmentedControl == nil {
            segmentedControl = UISegmentedControl(items: [localizedString("y_axis"), localizedString("x_axis")])
            segmentedControl?.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        }
        
        segmentedControl?.selectedSegmentIndex = isYAxisMode ? 0 : 1
        return segmentedControl
    }
    
    override func hideFirstHeader() -> Bool {
        isYAxisMode ? true : false
    }
    
    override func shouldShowSubviewSeparator() -> Bool {
        false
    }
    
    override func getTableHeaderDescription() -> String? {
        isYAxisMode ? localizedString("y_axis_description") : nil
    }
    
    override func getTableStyle() -> UITableView.Style {
        .insetGrouped
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OATwoIconsButtonTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()
        func hasData(_ type: GPXDataSetType) -> Bool {
            guard let tag = OAGPXDataSetType.getDataKey(type.rawValue), !tag.isEmpty else { return false }
            let hasTag = analysis.hasData(tag: tag)
            if type == .speed || type == .sensorSpeed {
                return hasTag && analysis.hasSpeedData()
            }
            
            return hasTag
        }
        
        if isYAxisMode {
            let baseSets: [[NSNumber]] = [[NSNumber(value: GPXDataSetType.altitude.rawValue)], [NSNumber(value: GPXDataSetType.slope.rawValue)], [NSNumber(value: GPXDataSetType.speed.rawValue)]]
            let available = NSMutableArray(array: baseSets)
            OAPluginsHelper.getAvailableGPXDataSetTypes(analysis, availableTypes: available)
            var seen = Set<GPXDataSetType>()
            let availableSingles: [GPXDataSetType] = available.compactMap { item in
                guard let set = item as? [NSNumber], set.count == 1, let raw = set.first?.intValue, let type = GPXDataSetType(rawValue: raw), seen.insert(type).inserted else { return nil }
                return type
            }
            
            let order: [GpxDataSetTypeGroup] = [.general, .externalSensors, .vehicleMetrics]
            let grouped = Dictionary(grouping: availableSingles) { $0.getTypeGroup() }
            for group in order {
                guard let items = grouped[group] else { continue }
                var visible = items.filter(hasData)
                guard !visible.isEmpty else { continue }
                var lastTypesInVehicleSubgroups = Set<GPXDataSetType>()
                if group == .vehicleMetrics {
                    visible.sort { lhs, rhs in
                        let lhsMeta = vehicleMetricsMeta(for: lhs)
                        let rhsMeta = vehicleMetricsMeta(for: rhs)
                        let lhsSubgroup = lhsMeta?.subgroup.rawValue ?? Int.max
                        let rhsSubgroup = rhsMeta?.subgroup.rawValue ?? Int.max
                        if lhsSubgroup != rhsSubgroup {
                            return lhsSubgroup < rhsSubgroup
                        }
                        
                        let lhsOrder = lhsMeta?.itemOrder ?? Int.max
                        let rhsOrder = rhsMeta?.itemOrder ?? Int.max
                        if lhsOrder != rhsOrder {
                            return lhsOrder < rhsOrder
                        }
                        
                        return lhs.rawValue < rhs.rawValue
                    }
                    
                    let groupedBySubgroup = Dictionary(grouping: visible) { vehicleMetricsMeta(for: $0)?.subgroup.rawValue }
                    for subgroup in VehicleMetricsSubgroup.allCases {
                        guard let subgroupItems = groupedBySubgroup[subgroup.rawValue], let last = subgroupItems.last else { continue }
                        lastTypesInVehicleSubgroups.insert(last)
                    }
                }
                
                let section = tableData.createNewSection()
                section.headerText = group.getName() ?? ""
                for type in visible {
                    let row = section.createNewRow()
                    row.cellType = OASimpleTableViewCell.reuseIdentifier
                    row.title = OAGPXDataSetType.getTitle(type.rawValue)
                    row.iconName = OAGPXDataSetType.getIconName(type.rawValue)
                    row.setObj(NSNumber(value: type.rawValue), forKey: RowKey.type.rawValue)
                    row.setObj(NSNumber(value: types.contains { $0.intValue == type.rawValue }), forKey: RowKey.selected.rawValue)
                    row.setObj(NSNumber(value: lastTypesInVehicleSubgroups.contains(type)), forKey: RowKey.isCustomLeftSeparatorInset.rawValue)
                }
            }
        } else {
            let section = tableData.createNewSection()
            let availableAxisTypes: [GPXDataSetAxisType] = analysis.isTimeSpecified() ? [.distance, .time, .timeOfDay] : [.distance]
            for axisType in availableAxisTypes {
                let row = section.createNewRow()
                row.cellType = OATwoIconsButtonTableViewCell.reuseIdentifier
                row.title = axisType.getName()
                row.iconName = axisType.getImageName()
                row.setObj(NSNumber(value: axisType.rawValue), forKey: RowKey.axisType.rawValue)
                row.setObj(NSNumber(value: selectedXAxisMode == axisType), forKey: RowKey.selected.rawValue)
            }
        }
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
            cell.descriptionVisibility(false)
            cell.selectedBackgroundView = UIView()
            cell.selectedBackgroundView?.backgroundColor = UIColor.groupBg
            cell.titleLabel.text = item.title
            cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
            let isSelected = item.bool(forKey: RowKey.selected.rawValue)
            cell.leftIconView.tintColor = isSelected ? .iconColorActive : .iconColorDisabled
            cell.titleLabel.textColor = isSelected ? .textColorPrimary : .textColorTertiary
            let isCustomLeftSeparatorInset = item.bool(forKey: RowKey.isCustomLeftSeparatorInset.rawValue)
            cell.setCustomLeftSeparatorInset(isCustomLeftSeparatorInset)
            if isCustomLeftSeparatorInset {
                cell.separatorInset = .zero
            } else {
                cell.updateSeparatorInset()
            }
            return cell
        } else if item.cellType == OATwoIconsButtonTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OATwoIconsButtonTableViewCell.reuseIdentifier, for: indexPath) as! OATwoIconsButtonTableViewCell
            cell.descriptionVisibility(false)
            cell.buttonVisibility(false)
            cell.titleLabel.text = item.title
            let isSelected = item.bool(forKey: RowKey.selected.rawValue)
            cell.leftIconView.image = isSelected ? UIImage.templateImageNamed("ic_checkmark_default") : nil
            cell.leftIconView.tintColor = .iconColorActive
            cell.secondLeftIconView.image = UIImage.templateImageNamed(item.iconName)
            cell.secondLeftIconView.tintColor = isSelected ? .iconColorActive : .iconColorDisabled
            cell.setSecondLeftIconSize(30)
            return cell
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard isYAxisMode else { return indexPath }
        let selectedCount = tableView.indexPathsForSelectedRows?.count ?? 0
        return selectedCount >= 2 ? nil : indexPath
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        if isYAxisMode {
            toggleSelection(at: indexPath, isSelected: true)
        } else {
            updateSelectedXAxisMode(at: indexPath)
        }
    }
    
    override func onRowDeselected(_ indexPath: IndexPath) {
        guard isYAxisMode else { return }
        toggleSelection(at: indexPath, isSelected: false)
    }
    
    @objc private func onClosePressed() {
        dismiss(animated: true)
    }
    
    @objc private func onDonePressed() {
        let result = Array(types.prefix(2))
        guard !result.isEmpty else { return }
        delegate?.onGraphModeChanged(selectedXAxisMode, types: result)
        dismiss(animated: true)
    }
    
    @objc private func segmentChanged(_ control: UISegmentedControl) {
        isYAxisMode = control.selectedSegmentIndex == 0
        applyTableMode()
        updateUIAnimated { [weak self] _ in
            guard let self else { return }
            self.clearAllSelections()
            self.syncCheckmarksFromData()
        }
    }
    
    private func applyTableMode() {
        if tableView.isEditing != isYAxisMode {
            tableView.setEditing(isYAxisMode, animated: false)
        }
        
        tableView.allowsMultipleSelectionDuringEditing = isYAxisMode
        if !isYAxisMode {
            tableView.indexPathsForSelectedRows?.forEach {
                tableView.deselectRow(at: $0, animated: false)
            }
        }
    }
    
    private func updateSelectedXAxisMode(at indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        guard let axisTypeNumber = item.obj(forKey: RowKey.axisType.rawValue) as? NSNumber, let axisType = GPXDataSetAxisType(rawValue: axisTypeNumber.intValue), selectedXAxisMode != axisType else { return }
        selectedXAxisMode = axisType
        generateData()
        tableView.reloadData()
    }
    
    private func toggleSelection(at indexPath: IndexPath, isSelected: Bool) {
        guard isYAxisMode else { return }
        let item = tableData.item(for: indexPath)
        guard let type = item.obj(forKey: RowKey.type.rawValue) as? NSNumber else { return }
        let raw = type.intValue
        if isSelected {
            if !types.contains(where: { $0.intValue == raw }) {
                types.append(type)
            }
        } else {
            types.removeAll { $0.intValue == raw }
        }
        
        item.setObj(NSNumber(value: isSelected), forKey: RowKey.selected.rawValue)
        tableView.reloadRows(at: [indexPath], with: .none)
        syncCheckmarksFromData()
    }
    
    private func clearAllSelections() {
        (tableView.indexPathsForSelectedRows ?? []).forEach {
            tableView.deselectRow(at: $0, animated: false)
        }
    }
    
    private func syncCheckmarksFromData() {
        guard isYAxisMode else { return }
        for section in 0..<tableData.sectionCount() {
            for row in 0..<tableData.rowCount(section) {
                let indexPath = IndexPath(row: Int(row), section: Int(section))
                let item = tableData.item(for: indexPath)
                let shouldSelect = item.bool(forKey: RowKey.selected.rawValue)
                if shouldSelect {
                    if tableView.indexPathsForSelectedRows?.contains(indexPath) != true {
                        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                    }
                } else {
                    if tableView.indexPathsForSelectedRows?.contains(indexPath) == true {
                        tableView.deselectRow(at: indexPath, animated: false)
                    }
                }
            }
        }
    }
    
    private func vehicleMetricsMeta(for type: GPXDataSetType) -> VehicleMetricsMeta? {
        switch type {
        case .intakeTemperature:
            return VehicleMetricsMeta(subgroup: .temperature, itemOrder: 0)
        case .ambientTemperature:
            return VehicleMetricsMeta(subgroup: .temperature, itemOrder: 1)
        case .coolantTemperature:
            return VehicleMetricsMeta(subgroup: .temperature, itemOrder: 2)
        case .engineOilTemperature:
            return VehicleMetricsMeta(subgroup: .temperature, itemOrder: 3)
        case .engineSpeed:
            return VehicleMetricsMeta(subgroup: .engine, itemOrder: 0)
        case .engineRuntime:
            return VehicleMetricsMeta(subgroup: .engine, itemOrder: 1)
        case .engineLoad:
            return VehicleMetricsMeta(subgroup: .engine, itemOrder: 2)
        case .fuelPressure:
            return VehicleMetricsMeta(subgroup: .fuel, itemOrder: 0)
        case .fuelConsumption:
            return VehicleMetricsMeta(subgroup: .fuel, itemOrder: 1)
        case .remainingFuel:
            return VehicleMetricsMeta(subgroup: .fuel, itemOrder: 2)
        case .batteryLevel:
            return VehicleMetricsMeta(subgroup: .other, itemOrder: 0)
        case .vehicleSpeed:
            return VehicleMetricsMeta(subgroup: .other, itemOrder: 1)
        case .throttlePosition:
            return VehicleMetricsMeta(subgroup: .other, itemOrder: 2)
        default:
            return nil
        }
    }
}
