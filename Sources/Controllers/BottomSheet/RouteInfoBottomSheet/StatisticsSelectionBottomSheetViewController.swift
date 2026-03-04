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
        
        tableView.setEditing(true, animated: false)
        tableView.allowsMultipleSelectionDuringEditing = true
        applyInitialSelectionIfNeeded()
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
        segmentedControl = UISegmentedControl(items: [localizedString("y_axis"), localizedString("x_axis")])
        segmentedControl?.selectedSegmentIndex = 0
        segmentedControl?.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        return segmentedControl
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func shouldShowSubviewSeparator() -> Bool {
        false
    }
    
    override func getTableHeaderDescription() -> String {
        localizedString("y_axis_description")
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
        let isSelected = tableView.indexPathsForSelectedRows?.contains(indexPath) == true
        cell.leftIconView.tintColor = isSelected ? .iconColorActive : .iconColorDisabled
        cell.titleLabel.textColor = isSelected ? .textColorPrimary : .textColorTertiary
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let selectedCount = tableView.indexPathsForSelectedRows?.count ?? 0
        if selectedCount >= 2 {
            return nil
        }
        
        return indexPath
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        updateAppearance(for: indexPath)
    }
    
    override func onRowDeselected(_ indexPath: IndexPath) {
        updateAppearance(for: indexPath)
    }
    
    @objc private func onClosePressed() {
        dismiss(animated: true)
    }
    
    @objc private func onDonePressed() {
        let selected = tableView.indexPathsForSelectedRows ?? []
        let picked: [NSNumber] = selected.compactMap { indexPath in
            let item = tableData.item(for: indexPath)
            return item.obj(forKey: "type") as? NSNumber
        }
        
        let limited = Array(picked.prefix(2))
        self.types = limited
        delegate?.onTypesSelected(limited)
        dismiss(animated: true)
    }
    
    @objc private func segmentChanged(_ control: UISegmentedControl) {
    }
    
    private func applyInitialSelectionIfNeeded() {
        let selectedRaw = Set(types.map { $0.intValue })
        for section in 0..<tableData.sectionCount() {
            for row in 0..<tableData.rowCount(section) {
                let indexPath = IndexPath(row: Int(row), section: Int(section))
                let item = tableData.item(for: indexPath)
                guard let raw = (item.obj(forKey: "type") as? NSNumber)?.intValue else { continue }
                if selectedRaw.contains(raw) {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }
        }
    }
    
    private func updateAppearance(for indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? OASimpleTableViewCell else { return }
        let isSelected = tableView.indexPathsForSelectedRows?.contains(indexPath) == true
        cell.leftIconView.tintColor = isSelected ? .iconColorActive : .iconColorDisabled
        cell.titleLabel.textColor = isSelected ? .textColorPrimary : .textColorTertiary
    }
}
