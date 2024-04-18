//
//  RouteParameterDevelopmentViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.04.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objc enum ParameterType: Int {
    case routingAlgorithm, autoZoom
}

@objc(OARouteParameterDevelopmentViewController)
@objcMembers
final class RouteParameterDevelopmentViewController: OABaseSettingsViewController {
    private var parameterType: ParameterType
    
    init(applicationMode: OAApplicationMode!, parameterType: ParameterType) {
        self.parameterType = parameterType
        super.init(appMode: applicationMode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String! {
        switch parameterType {
        case .routingAlgorithm:
            return  localizedString("shared_string_routing_algorithm")
        case .autoZoom:
            return  localizedString("shared_string_auto_zoom")
        }
    }
    
    override func getSubtitle() -> String! {
        String()
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        localizedString("shared_string_cancel")
    }
    
    override func isNavbarSeparatorVisible() -> Bool {
        false
    }
    
    override func generateData() {
        tableData.clearAllData()
        let section = tableData.createNewSection()
        switch parameterType {
        case .routingAlgorithm:
            let highwayRow = section.createNewRow()
            highwayRow.cellType = OASimpleTableViewCell.getIdentifier()
            highwayRow.key = "highway_hierarchies"
            highwayRow.title = localizedString("shared_string_highway_hierarchies")
            highwayRow.iconName = "ic_checkmark_default"
            highwayRow.setObj(localizedString("selected"), forKey: "selected")
            let aRow = section.createNewRow()
            aRow.cellType = OASimpleTableViewCell.getIdentifier()
            aRow.key = "routing_algorithm_a"
            aRow.title = localizedString("shared_string_routing_algorithm_a")
            aRow.iconName = "ic_checkmark_default"
            aRow.setObj(localizedString("selected"), forKey: "selected")
        case .autoZoom:
            let smoothRow = section.createNewRow()
            smoothRow.cellType = OASimpleTableViewCell.getIdentifier()
            smoothRow.key = "smooth"
            smoothRow.title = localizedString("shared_string_smooth")
            smoothRow.iconName = "ic_checkmark_default"
            smoothRow.setObj(localizedString("selected"), forKey: "selected")
            let discreteRow = section.createNewRow()
            discreteRow.cellType = OASimpleTableViewCell.getIdentifier()
            discreteRow.key = "discrete"
            discreteRow.title = localizedString("shared_string_discrete")
            discreteRow.iconName = "ic_checkmark_default"
            discreteRow.setObj(localizedString("selected"), forKey: "selected")
        }
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier(), for: indexPath) as! OASimpleTableViewCell
        cell.descriptionVisibility(false)
        cell.titleLabel.text = item.title
        cell.leftIconView.image = item.obj(forKey: "selected") as? Bool ?? false ? UIImage(named: item.iconName ?? "ic_checkmark_default") : nil
        return cell
    }
}
