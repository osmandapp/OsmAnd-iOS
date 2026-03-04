//
//  StatisticsSelectionBottomSheetViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 03.03.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objc protocol OAStatisticsSelectionDelegate: AnyObject {
    func onTypesSelected(_ types: [NSNumber])
}

@objcMembers
final class StatisticsSelectionBottomSheetViewController: OABaseNavbarSubviewViewController {
    private var types: [NSNumber]
    private var analysis: GpxTrackAnalysis
    private var segmentedControl: UISegmentedControl?
    private var isYAxisMode = true
    
    weak var delegate: OAStatisticsSelectionDelegate?
    
    init(types: [NSNumber], analysis: GpxTrackAnalysis) {
        self.types = types
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
        true
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
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        struct SectionSpec {
            let header: String?
            let allowed: Set<GPXDataSetType>
        }
        
        let sections: [SectionSpec] = [.init(header: nil, allowed: [.altitude, .slope, .speed]), .init(header: localizedString("external_sensor_widgets"), allowed: [.sensorSpeed, .sensorHeartRate, .sensorBikePower, .sensorBikeCadence, .sensorTemperatureA, .sensorTemperatureW])]
        
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
            
            for spec in sections {
                let visible = availableSingles.filter { spec.allowed.contains($0) && hasData($0) }
                guard !visible.isEmpty else { continue }
                let section = tableData.createNewSection()
                section.headerText = spec.header ?? ""
                for type in visible {
                    let row = section.createNewRow()
                    row.cellType = OASimpleTableViewCell.reuseIdentifier
                    row.title = OAGPXDataSetType.getTitle(type.rawValue)
                    row.iconName = OAGPXDataSetType.getIconName(type.rawValue)
                    row.setObj(NSNumber(value: type.rawValue), forKey: "type")
                    row.setObj(NSNumber(value: types.contains { $0.intValue == type.rawValue }), forKey: "selected")
                }
            }
        }
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        guard item.cellType == OASimpleTableViewCell.reuseIdentifier else { return nil }
        let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
        cell.descriptionVisibility(false)
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = UIColor.groupBg
        cell.titleLabel.text = item.title
        cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
        let isSelected = item.bool(forKey: "selected")
        cell.leftIconView.tintColor = isSelected ? .iconColorActive : .iconColorDisabled
        cell.titleLabel.textColor = isSelected ? .textColorPrimary : .textColorTertiary
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard isYAxisMode else { return nil }
        let selectedCount = tableView.indexPathsForSelectedRows?.count ?? 0
        return selectedCount >= 2 ? nil : indexPath
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        toggleSelection(at: indexPath, isSelected: true)
    }
    
    override func onRowDeselected(_ indexPath: IndexPath) {
        toggleSelection(at: indexPath, isSelected: false)
    }
    
    @objc private func onClosePressed() {
        dismiss(animated: true)
    }
    
    @objc private func onDonePressed() {
        let result = Array(types.prefix(2))
        guard !result.isEmpty else { return }
        delegate?.onTypesSelected(result)
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
    
    private func toggleSelection(at indexPath: IndexPath, isSelected: Bool) {
        guard isYAxisMode else { return }
        let item = tableData.item(for: indexPath)
        guard let type = item.obj(forKey: "type") as? NSNumber else { return }
        let raw = type.intValue
        if isSelected {
            if !types.contains(where: { $0.intValue == raw }) {
                types.append(type)
            }
        } else {
            types.removeAll { $0.intValue == raw }
        }
        
        item.setObj(NSNumber(value: isSelected), forKey: "selected")
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
                let shouldSelect = item.bool(forKey: "selected")
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
}
