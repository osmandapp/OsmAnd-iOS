//
//  SpeedometerWidgetSettingsViewController.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 15/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

final class SpeedometerWidgetSettingsViewController: OABaseNavbarViewController, WidgetStateDelegate {
    
    private static let selectedKey = "isSelected"
    private static let valuesKey = "values"
    private static let widgetSizeKey = "widgetSize"
    private static let turnOnRowKey = "turnOnRow"
    private static let speedLimitWarningRowKey = "speedLimitWarningRow"
    private static let previewSpeedometerRowKey = "previewSpeedometerRow"
    
    weak var delegate: WidgetStateDelegate?
    
    override func getTitle() -> String {
        localizedString("shared_string_speedometer")
    }
    
    override func getNavbarStyle() -> EOABaseNavbarStyle {
        .largeTitle
    }
    
    override func registerCells() {
        addCell(SegmentImagesWithRightLableTableViewCell.reuseIdentifier)
        addCell(OAValueTableViewCell.reuseIdentifier)
        addCell(OASwitchTableViewCell.reuseIdentifier)
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        let settings = OAAppSettings.sharedManager()!
        let showSpeedometer = settings.showSpeedometer.get()
        let mode = settings.applicationMode
        
        tableData.clearAllData()
        let switchCellSection = tableData.createNewSection()
        switchCellSection.footerText = showSpeedometer ?  "" : localizedString("speedometer_description")
        
        let turnOnRow = switchCellSection.createNewRow()
        turnOnRow.cellType = OASwitchTableViewCell.reuseIdentifier
        turnOnRow.key = Self.turnOnRowKey
        turnOnRow.title = localizedString("shared_string_speedometer")
        turnOnRow.accessibilityLabel = turnOnRow.title
        turnOnRow.accessibilityValue = localizedString( showSpeedometer ? "shared_string_on" : "shared_string_off")
        turnOnRow.setObj(showSpeedometer, forKey: Self.selectedKey)
        
        if showSpeedometer {
            let sellectSizeSection = tableData.createNewSection()
            sellectSizeSection.footerText = localizedString("speedometer_description")
            
            //TODO: implement preview cell
            let previewSpeedometerRow = sellectSizeSection.createNewRow()
            previewSpeedometerRow.cellType = Self.previewSpeedometerRowKey
            
            let sellectSizeRow = sellectSizeSection.createNewRow()
            sellectSizeRow.cellType = SegmentImagesWithRightLableTableViewCell.reuseIdentifier
            sellectSizeRow.title = localizedString("shared_string_size")
            sellectSizeRow.setObj(["ic_custom20_height_s", "ic_custom20_height_m", "ic_custom20_height_l"], forKey: Self.valuesKey)
            if let size = settings.speedometerSize {
                sellectSizeRow.setObj(size, forKey: Self.widgetSizeKey)
            }
            let settingsSection = tableData.createNewSection()
            settingsSection.headerText = localizedString("shared_string_settings")
            
            let speedLimitWarningRow = settingsSection.createNewRow()
            speedLimitWarningRow.cellType = OAValueTableViewCell.reuseIdentifier
            speedLimitWarningRow.key = Self.speedLimitWarningRowKey
            speedLimitWarningRow.title = localizedString("speed_limit_warning")
            speedLimitWarningRow.descr = settings.showSpeedLimitWarning?.toHumanString()
            speedLimitWarningRow.accessibilityLabel = speedLimitWarningRow.title
            speedLimitWarningRow.accessibilityValue = speedLimitWarningRow.descr
        }
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        guard let tableData else { return nil }
        let item = tableData.item(for: indexPath)
        
        if item.cellType == OAValueTableViewCell.reuseIdentifier {
            var cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier) as! OAValueTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.descriptionVisibility(false)
            cell.leftIconVisibility(false)
            cell.valueLabel.text = item.descr
            cell.titleLabel.text = item.title
            cell.accessibilityLabel = item.accessibilityLabel
            cell.accessibilityValue = item.accessibilityValue
            return cell
        } else if item.cellType == OASwitchTableViewCell.reuseIdentifier {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.reuseIdentifier) as! OASwitchTableViewCell
            cell.descriptionVisibility(false)
            cell.leftIconVisibility(false)
            let selected = item.bool(forKey: Self.selectedKey)
            cell.leftIconView.tintColor = selected ? UIColor(rgb: item.iconTint) : .iconColorDefault
            cell.titleLabel.text = item.title
            cell.accessibilityLabel = item.accessibilityLabel
            cell.accessibilityValue = item.accessibilityValue
            cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
            cell.switchView.isOn = selected
            cell.switchView.tag = indexPath.section << 10 | indexPath.row
            cell.switchView.addTarget(self, action: #selector(onSwitchClick(_:)), for: .valueChanged)
            return cell
        } else if item.cellType == SegmentImagesWithRightLableTableViewCell.reuseIdentifier {
            var cell = tableView.dequeueReusableCell(withIdentifier: SegmentImagesWithRightLableTableViewCell.reuseIdentifier) as! SegmentImagesWithRightLableTableViewCell
            cell.selectionStyle = .none
            if let icons = item.obj(forKey: Self.valuesKey) as? [String], let sizePref = item.obj(forKey: Self.widgetSizeKey) as? OACommonWidgetSizeStyle {
                let widgetSizeStyle = sizePref.get()
                cell.configureSegmenedtControl(icons: icons, selectedSegmentIndex: widgetSizeStyle.rawValue)
            }
            if let title = item.string(forKey: "title") {
                cell.configureTitle(title: title)
            }
            cell.didSelectSegmentIndex = { [weak self] index in
                guard let self, let sizePref = item.obj(forKey: Self.widgetSizeKey) as? OACommonWidgetSizeStyle else { return }
                sizePref.set(EOAWidgetSizeStyle(rawValue: index) ?? .medium, mode: OAAppSettings.sharedManager().applicationMode.get())
            }
            
            return cell
        } else if item.cellType == Self.previewSpeedometerRowKey {
            //TODO: implement preview cell
            var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier) as! OASimpleTableViewCell
            cell.backgroundColor = .mapStyleWater
            cell.titleLabel.text = nil
            cell.descriptionLabel.text = nil
            return cell
        }
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        guard let tableData else { return }
        let data = tableData.item(for: indexPath)
        if data.key == Self.speedLimitWarningRowKey {
            let vc = SpeedLimitWarningViewController()
            vc.delegate = self
            showMediumSheetViewController(vc, isLargeAvailable: false)
        }
    }
    
    @objc func onSwitchClick(_ sender: Any) -> Bool {
        guard let tableData, let sw = sender as? UISwitch else { return false }
        
        let indexPath = IndexPath(row: sw.tag & 0x3FF, section: sw.tag >> 10)
        let data = tableData.item(for: indexPath)
        
        let settings = OAAppSettings.sharedManager()!
        if data.key == Self.turnOnRowKey {
            settings.showSpeedometer.set(sw.isOn)
            OARootViewController.instance().mapPanel.hudViewController.mapInfoController.updateLayout()
            reloadDataWith(animated: true, completion: nil)
            delegate?.onWidgetStateChanged()
        }
        return false
    }
    
    // MARK: WidgetStateDelegate
    func onWidgetStateChanged() {
        generateData()
        tableView.reloadData()
    }
}
