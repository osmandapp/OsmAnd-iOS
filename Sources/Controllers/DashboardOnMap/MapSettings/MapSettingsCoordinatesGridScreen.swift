//
//  MapSettingsCoordinatesGridScreen.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 16.04.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class MapSettingsCoordinatesGridScreen: NSObject, OAMapSettingsScreen {
    private static let showHideCoordinatesGridRowKey = "showHideCoordinatesGridRowKey"
    
    var settingsScreen: EMapSettingsScreen = .coordinatesGrid
    var vwController: OADashboardViewController?
    var tblView: UITableView?
    var title: String?
    var isOnlineMapSource = false
    var tableData: [Any]?
    
    private var isCoordinatesGridEnabled: Bool
    private var data: OATableDataModel
    private var settings: OAAppSettings
    
    required init(table tableView: UITableView, viewController: OADashboardViewController?) {
        data = OATableDataModel()
        settings = OAAppSettings.sharedManager()
        isCoordinatesGridEnabled = settings.mapSettingShowCoordinatesGrid.get()
        super.init()
        self.tblView = tableView
        self.vwController = viewController
        self.title = localizedString("layer_coordinates_grid")
    }
    
    required init(table tableView: UITableView, viewController: OADashboardViewController!, param: Any) {
        fatalError("init(table:viewController:param:)")
    }
    
    func setupView() {
        registerCells()
        initData()
    }
    
    func initData() {
        data.clearAllData()
        let switchSection = data.createNewSection()
        let showHideCoordinatesGridRow = switchSection.createNewRow()
        showHideCoordinatesGridRow.cellType = OASwitchTableViewCell.reuseIdentifier
        showHideCoordinatesGridRow.key = Self.showHideCoordinatesGridRowKey
        showHideCoordinatesGridRow.title = localizedString(isCoordinatesGridEnabled ? "shared_string_enabled" : "rendering_value_disabled_name")
        showHideCoordinatesGridRow.iconName = isCoordinatesGridEnabled ? "ic_custom_show" : "ic_custom_hide"
        showHideCoordinatesGridRow.iconTintColor = isCoordinatesGridEnabled ? .iconColorSelected : .iconColorDisabled
        showHideCoordinatesGridRow.setObj(isCoordinatesGridEnabled, forKey: "isEnabled")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        Int(data.sectionCount())
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Int(data.rowCount(UInt(section)))
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = data.item(for: indexPath)
        if item.cellType == OASwitchTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.reuseIdentifier) as! OASwitchTableViewCell
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.leftIconView.image =  UIImage.templateImageNamed(item.iconName)
            cell.leftIconView.tintColor = item.iconTintColor
            cell.switchView.setOn(item.bool(forKey: "isEnabled"), animated: true)
            cell.switchView.tag = indexPath.section << 10 | indexPath.row
            cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
            cell.switchView.addTarget(self, action: #selector(mapSettingSwitchChanged(_:)), for: .valueChanged)
            return cell
        }
        
        return UITableViewCell()
    }
    
    private func registerCells() {
        tblView?.register(UINib(nibName: OASwitchTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OASwitchTableViewCell.reuseIdentifier)
    }
    
    private func updateData() {
        initData()
        tblView?.reloadData()
    }
    
    @objc private func mapSettingSwitchChanged(_ sender: Any) -> Bool {
        guard let sw = sender as? UISwitch else { return false }
        let indexPath = IndexPath(row: sw.tag & 0x3FF, section: sw.tag >> 10)
        let data = data.item(for: indexPath)
        if data.key == Self.showHideCoordinatesGridRowKey {
            isCoordinatesGridEnabled = sw.isOn
            settings.mapSettingShowCoordinatesGrid.set(isCoordinatesGridEnabled)
            updateData()
        }
        
        return false
    }
}
