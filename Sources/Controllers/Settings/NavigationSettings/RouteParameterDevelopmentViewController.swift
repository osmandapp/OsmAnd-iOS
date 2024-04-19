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
    
    init(applicationMode: OAApplicationMode, parameterType: ParameterType) {
        self.parameterType = parameterType
        super.init(appMode: applicationMode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String? {
        switch parameterType {
        case .routingAlgorithm:
            return  localizedString("routing_algorithm")
        case .autoZoom:
            return  localizedString("auto_zoom")
        }
    }
    
    override func getSubtitle() -> String? {
        String()
    }
    
    override func getLeftNavbarButtonTitle() -> String? {
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
            let isUseOldRouting = OAAppSettings.sharedManager().useOldRouting.get()
            let highwayRow = section.createNewRow()
            highwayRow.cellType = OASimpleTableViewCell.getIdentifier()
            highwayRow.key = "highway_hierarchies"
            highwayRow.title = localizedString("routing_algorithm_highway_hierarchies")
            highwayRow.iconName = "ic_checkmark_default"
            highwayRow.setObj(!isUseOldRouting, forKey: "selected")
            let aRow = section.createNewRow()
            aRow.cellType = OASimpleTableViewCell.getIdentifier()
            aRow.key = "routing_algorithm_a"
            aRow.title = localizedString("routing_algorithm_a")
            aRow.iconName = "ic_checkmark_default"
            aRow.setObj(isUseOldRouting, forKey: "selected")
        case .autoZoom:
            let isUseV1AutoZoom = OAAppSettings.sharedManager().useV1AutoZoom.get()
            let smoothRow = section.createNewRow()
            smoothRow.cellType = OASimpleTableViewCell.getIdentifier()
            smoothRow.key = "smooth"
            smoothRow.title = localizedString("auto_zoom_smooth")
            smoothRow.iconName = "ic_checkmark_default"
            smoothRow.setObj(!isUseV1AutoZoom, forKey: "selected")
            let discreteRow = section.createNewRow()
            discreteRow.cellType = OASimpleTableViewCell.getIdentifier()
            discreteRow.key = "discrete"
            discreteRow.title = localizedString("auto_zoom_discrete")
            discreteRow.iconName = "ic_checkmark_default"
            discreteRow.setObj(isUseV1AutoZoom, forKey: "selected")
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
    
    override func onRowSelected(_ indexPath: IndexPath?) {
        guard let indexPath else { return }
        let item = tableData.item(for: indexPath)
        guard let key = item.key else { return }
        switch parameterType {
        case .routingAlgorithm:
            selectRoutingAlgorithmSetting(forKey: key)
        case .autoZoom:
            selectAutoZoomSetting(forKey: key)
        }
        
        delegate?.onSettingsChanged()
        dismiss(animated: true)
    }
    
    private func selectRoutingAlgorithmSetting(forKey key: String) {
        OAAppSettings.sharedManager().useOldRouting.set(key == "routing_algorithm_a")
    }
    
    private func selectAutoZoomSetting(forKey key: String) {
        OAAppSettings.sharedManager().useV1AutoZoom.set(key == "discrete")
    }
}
