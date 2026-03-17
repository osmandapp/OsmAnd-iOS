//
//  MapSettingsBuildings3DScreen.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 16.03.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

private enum RowKey: String {
    case showHide3dObjectsRowKey
    case formatRowKey
    case zoomRowKey
    case labelsPositionRowKey
    case colorRowKey
    case getColorRowKey
}

@objcMembers
final class MapSettingsBuildings3DScreen: NSObject, OAMapSettingsScreen {
    var settingsScreen: EMapSettingsScreen = .buildings3DVisibility
    var vwController: OADashboardViewController?
    var tblView: UITableView?
    var title: String?
    var isOnlineMapSource = false
    var tableData: [Any]?
    
    private var data: OATableDataModel
    private var is3DObjectsEnabled = false
    
    init(table tableView: UITableView, viewController: OADashboardViewController) {
        data = OATableDataModel()
        super.init()
        self.tblView = tableView
        self.vwController = viewController
        self.title = localizedString("enable_3d_objects")
    }
    
    init(table tableView: UITableView, viewController: OADashboardViewController, param: Any) {
        fatalError("init(table:viewController:param:)")
    }
    
    func setupView() {
        is3DObjectsEnabled = is3DObjectsCurrentlyEnabled()
        registerCells()
        initData()
        registerNotifications()
    }
    
    func deinitView() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func initData() {
        data.clearAllData()
        is3DObjectsEnabled = is3DObjectsCurrentlyEnabled()
        let switchSection = data.createNewSection()
        let showHide3dObjectsRow = switchSection.createNewRow()
        showHide3dObjectsRow.cellType = OASwitchTableViewCell.reuseIdentifier
        showHide3dObjectsRow.key = RowKey.showHide3dObjectsRowKey.rawValue
        showHide3dObjectsRow.title = localizedString(is3DObjectsEnabled ? "shared_string_enabled" : "rendering_value_disabled_name")
        showHide3dObjectsRow.icon = UIImage.templateImageNamed(is3DObjectsEnabled ? "ic_custom_show" : "ic_custom_hide")
        showHide3dObjectsRow.iconTintColor = is3DObjectsEnabled ? .iconColorSelected : .iconColorDisabled
        showHide3dObjectsRow.setObj(is3DObjectsEnabled, forKey: "isEnabled")
//        if isCoordinatesGridEnabled {
//            let formatZoomSection = data.createNewSection()
//            let formatRow = formatZoomSection.createNewRow()
//            formatRow.cellType = OAButtonTableViewCell.reuseIdentifier
//            formatRow.key = RowKey.formatRowKey.rawValue
//            formatRow.title = localizedString("shared_string_format")
//            formatRow.icon = .icCustomLongitude
//            formatRow.iconTintColor = .iconColorDefault
//            let zoomRow = formatZoomSection.createNewRow()
//            zoomRow.cellType = OAValueTableViewCell.reuseIdentifier
//            zoomRow.key = RowKey.zoomRowKey.rawValue
//            zoomRow.title = localizedString("shared_string_zoom_levels")
//            zoomRow.descr = "\(coordinatesGridSettings.getZoomLevelsWithRestrictions(forAppMode: settings.applicationMode.get()).min) – \(coordinatesGridSettings.getZoomLevelsWithRestrictions(forAppMode: settings.applicationMode.get()).max)"
//            zoomRow.icon = .icCustomOverlayMap
//            zoomRow.iconTintColor = .iconColorDefault
//            
//            let positionColorSection = data.createNewSection()
//            let labelsPositionRow = positionColorSection.createNewRow()
//            labelsPositionRow.cellType = OAButtonTableViewCell.reuseIdentifier
//            labelsPositionRow.key = RowKey.labelsPositionRowKey.rawValue
//            labelsPositionRow.title = localizedString("labels_position")
//            let pos = GridLabelsPosition(rawValue: coordinatesGridSettings.getGridLabelsPosition(forAppMode: settings.applicationMode.get())) ?? .edges
//            labelsPositionRow.icon = pos.icon
//            labelsPositionRow.iconTintColor = .iconColorDefault
//            let colorRow = positionColorSection.createNewRow()
//            colorRow.cellType = isMapsPlusProAvailable() ? OARightIconTableViewCell.reuseIdentifier : OATwoButtonsTableViewCell.reuseIdentifier
//            colorRow.key = isMapsPlusProAvailable() ? RowKey.colorRowKey.rawValue : RowKey.getColorRowKey.rawValue
//            colorRow.title = localizedString("grid_color")
//            colorRow.descr = localizedString("customize_grid_color")
//            colorRow.icon = isMapsPlusProAvailable() ? UIImage.templateImageNamed("ic_custom_appearance") : .icCustomGridColored
//            colorRow.iconTintColor = .iconColorDefault
//            colorRow.secondaryIconTintColor = UIColor(argb: Int(Int32(settings.nightMode ? coordinatesGridSettings.getNightGridColor() : coordinatesGridSettings.getDayGridColor())))
//            colorRow.setObj(localizedString("shared_string_get"), forKey: Constants.buttonTitleKey)
//            colorRow.setObj("ic_custom_arrow_forward", forKey: Constants.buttonIconKey)
//        }
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
            cell.leftIconView.image = item.icon
            cell.leftIconView.tintColor = item.iconTintColor
            cell.switchView.setOn(item.bool(forKey: "isEnabled"), animated: true)
            cell.switchView.tag = indexPath.section << 10 | indexPath.row
            cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
            cell.switchView.addTarget(self, action: #selector(on3DObjectsSwitchChanged(_:)), for: .valueChanged)
            return cell
        }
//        else if item.cellType == OAButtonTableViewCell.reuseIdentifier {
//            let cell = tableView.dequeueReusableCell(withIdentifier: OAButtonTableViewCell.reuseIdentifier) as! OAButtonTableViewCell
//            cell.selectionStyle = .none
//            cell.descriptionVisibility(false)
//            cell.titleLabel.text = item.title
//            cell.leftIconView.image = item.icon
//            cell.leftIconView.tintColor = item.iconTintColor
//            var config = UIButton.Configuration.plain()
//            config.baseForegroundColor = .textColorActive
//            config.contentInsets = NSDirectionalEdgeInsets(top: 3.1, leading: 16, bottom: 3.1, trailing: 0)
//            cell.button.configuration = config
//            if let key = item.key {
//                cell.button.menu = createStateSelectionMenu(for: key)
//            }
//            cell.button.showsMenuAsPrimaryAction = true
//            cell.button.changesSelectionAsPrimaryAction = true
//            cell.button.contentHorizontalAlignment = .right
//            cell.button.setContentHuggingPriority(.required, for: .horizontal)
//            cell.button.setContentCompressionResistancePriority(.required, for: .horizontal)
//            return cell
//        } else if item.cellType == OAValueTableViewCell.reuseIdentifier {
//            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier) as! OAValueTableViewCell
//            cell.accessoryType = .disclosureIndicator
//            cell.descriptionVisibility(false)
//            cell.titleLabel.text = item.title
//            cell.valueLabel.text = item.descr
//            cell.leftIconView.image = item.icon
//            cell.leftIconView.tintColor = item.iconTintColor
//            return cell
//        } else if item.cellType == OARightIconTableViewCell.reuseIdentifier {
//            let cell = tableView.dequeueReusableCell(withIdentifier: OARightIconTableViewCell.reuseIdentifier) as! OARightIconTableViewCell
//            cell.accessoryType = .disclosureIndicator
//            cell.descriptionVisibility(false)
//            cell.titleLabel.text = item.title
//            cell.leftIconView.image = item.icon
//            cell.leftIconView.tintColor = item.iconTintColor
//            cell.rightIconView.backgroundColor = item.secondaryIconTintColor
//            cell.rightIconView.layer.cornerRadius = cell.leftIconView.frame.height / 2
//            return cell
//        } else if item.cellType == OATwoButtonsTableViewCell.reuseIdentifier {
//            let cell = tableView.dequeueReusableCell(withIdentifier: OATwoButtonsTableViewCell.reuseIdentifier) as! OATwoButtonsTableViewCell
//            cell.selectionStyle = .none
//            cell.setLeftButtonVisible(false)
//            cell.titleLabel.text = item.title
//            cell.descriptionLabel.text = item.descr
//            cell.leftIconView.image = item.icon
//            let title = item.string(forKey: Constants.buttonTitleKey) ?? localizedString("shared_string_get")
//            cell.rightButton.configuration = .purchasePlanButtonConfiguration(title: title)
//            cell.rightButton.accessibilityLabel = title
//            cell.rightButton.layer.cornerRadius = 6
//            cell.rightButton.layer.masksToBounds = true
//            cell.rightButton.semanticContentAttribute = .forceLeftToRight
//            cell.rightButton.setContentHuggingPriority(.required, for: .horizontal)
//            cell.rightButton.setContentCompressionResistancePriority(.required, for: .horizontal)
//            cell.rightButton.removeTarget(nil, action: nil, for: .allEvents)
//            cell.rightButton.tag = indexPath.section << 10 | indexPath.row
//            cell.rightButton.addTarget(self, action: #selector(onCellButtonClicked(sender:)), for: .touchUpInside)
//            return cell
//        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let item = data.item(for: indexPath)
//        switch item.key {
//        case RowKey.zoomRowKey.rawValue:
//            showTerrainParametersScreen(type: .EOATerrainSettingsTypeCoordinatesGridZoomLevels)
//        case RowKey.colorRowKey.rawValue:
//            showTerrainParametersScreen(type: .EOATerrainSettingsTypeCoordinatesGridColor)
//        default:
//            break
//        }
    }
    
    private func registerCells() {
        tblView?.register(UINib(nibName: OASwitchTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OASwitchTableViewCell.reuseIdentifier)
        tblView?.register(UINib(nibName: OAButtonTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OAButtonTableViewCell.reuseIdentifier)
        tblView?.register(UINib(nibName: OAValueTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OAValueTableViewCell.reuseIdentifier)
        tblView?.register(UINib(nibName: OARightIconTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OARightIconTableViewCell.reuseIdentifier)
        tblView?.register(UINib(nibName: OATwoButtonsTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OATwoButtonsTableViewCell.reuseIdentifier)
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleIAPNotifications), name: Notification.Name(NSNotification.Name.OAIAPProductPurchased.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleIAPNotifications), name: Notification.Name(NSNotification.Name.OAIAPProductsRestored.rawValue), object: nil)
    }
    
    private func updateData() {
        initData()
        tblView?.reloadData()
    }
    
    private func isMapsPlusProAvailable() -> Bool {
        OAIAPHelper.isMapsPlusAvailable() || OAIAPHelper.isOsmAndProAvailable()
    }
    
    private func is3DObjectsCurrentlyEnabled() -> Bool {
        guard let plugin = OAPluginsHelper.getPlugin(OASRTMPlugin.self) as? OASRTMPlugin else {
            return false
        }
        return plugin.is3dMapObjectsEnabled()
    }
    
    @objc private func on3DObjectsSwitchChanged(_ sender: UISwitch) {
        guard let plugin = OAPluginsHelper.getPlugin(OASRTMPlugin.self) as? OASRTMPlugin else {
            return
        }
        plugin.set3dMapObjectsEnabled(sender.isOn)
        updateData()
    }
    
    @objc private func onCellButtonClicked(sender: UIButton) {
        if let navigationController = vwController?.navigationController {
            OAChoosePlanHelper.showChoosePlanScreen(with: OAFeature.advanced_WIDGETS(), navController: navigationController)
        }
    }
    
    @objc private func handleIAPNotifications() {
        DispatchQueue.main.async { [weak self] in
            self?.updateData()
        }
    }
}
