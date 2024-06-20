//
//  RouteParameterHazmatUsa.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 20/06/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objc(OARouteParameterHazmatUsa)
@objcMembers
final class RouteParameterHazmatUsa: OABaseSettingsViewController {

    private let paramsKey = "param"
    private let selectedKey = "selected"
    
    private var parameterIds: [String]
    private var parameterNames: [String]
    
    init(applicationMode: OAApplicationMode, parameterIds: [String], parameterNames: [String]) {
        self.parameterIds = parameterIds
        self.parameterNames = parameterNames
        super.init(appMode: applicationMode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func registerCells() {
        addCell(OASwitchTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String? {
        return localizedString("dangerous_goods")
    }
    
    override func getSubtitle() -> String? {
        appMode.toHumanString()
    }
    
    override func getLeftNavbarButtonTitle() -> String? {
        localizedString("shared_string_cancel")
    }
    
    override func getTableHeaderDescription() -> String {
        localizedString("dangerous_goods_description")
    }
    
    override func isNavbarSeparatorVisible() -> Bool {
        false
    }
    
    override func generateData() {
        tableData.clearAllData()
        let section = tableData.createNewSection()
        
        for i in 0 ..< parameterIds.count {
            let row = section.createNewRow()
            row.cellType = OASwitchTableViewCell.getIdentifier()
            row.key = parameterIds[i]
            row.title = parameterNames[i]
            if let param = OAAppSettings.sharedManager().getCustomRoutingBooleanProperty(row.key, defaultValue: false) {
                row.setObj(param, forKey: paramsKey)
                row.setObj(param.get(appMode), forKey: selectedKey)
            }
        }
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.reuseIdentifier, for: indexPath) as! OASwitchTableViewCell
        cell.titleLabel.text = item.title
        cell.descriptionVisibility(false)
        cell.leftIconVisibility(false)
        let selected = item.bool(forKey: selectedKey)
        cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
        cell.switchView.isOn = selected
        cell.switchView.tag = indexPath.section << 10 | indexPath.row
        cell.switchView.addTarget(self, action: #selector(onSwitchClick(_:)), for: .valueChanged)
        return cell
    }
    
    @objc private func onSwitchClick(_ sender: Any) {
        guard let sw = sender as? UISwitch else { return }
        let indexPath = IndexPath(row: sw.tag & 0x3FF, section: sw.tag >> 10)
        let data = tableData.item(for: indexPath)
        if let param = data.obj(forKey: paramsKey) as? OACommonBoolean {
            param.set(sw.isOn, mode: appMode)
            delegate?.onSettingsChanged()
        }
    }
}
