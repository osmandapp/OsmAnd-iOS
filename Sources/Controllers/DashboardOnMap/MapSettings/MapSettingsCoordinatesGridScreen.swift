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
    private static let formatRowKey = "formatRowKey"
    private static let zoomRowKey = "zoomRowKey"
    private static let labelsPositionRowKey = "labelsPositionRowKey"
    private static let colorRowKey = "colorRowKey"
    private static let buttonTitleKey = "buttonTitleKey"
    private static let buttonIconKey = "buttonIconKey"
    
    var settingsScreen: EMapSettingsScreen = .coordinatesGrid
    var vwController: OADashboardViewController?
    var tblView: UITableView?
    var title: String?
    var isOnlineMapSource = false
    var tableData: [Any]?
    
    private var isCoordinatesGridEnabled: Bool
    private var data: OATableDataModel
    private var settings: OAAppSettings
    
    init(table tableView: UITableView, viewController: OADashboardViewController) {
        data = OATableDataModel()
        settings = OAAppSettings.sharedManager()
        isCoordinatesGridEnabled = settings.mapSettingShowCoordinatesGrid.get()
        super.init()
        self.tblView = tableView
        self.vwController = viewController
        self.title = localizedString("layer_coordinates_grid")
    }
    
    init(table tableView: UITableView, viewController: OADashboardViewController, param: Any) {
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
        showHideCoordinatesGridRow.icon = UIImage.templateImageNamed(isCoordinatesGridEnabled ? "ic_custom_show" : "ic_custom_hide")
        showHideCoordinatesGridRow.iconTintColor = isCoordinatesGridEnabled ? .iconColorSelected : .iconColorDisabled
        showHideCoordinatesGridRow.setObj(isCoordinatesGridEnabled, forKey: "isEnabled")
        if isCoordinatesGridEnabled {
            let formatZoomSection = data.createNewSection()
            let formatRow = formatZoomSection.createNewRow()
            formatRow.cellType = OAButtonTableViewCell.reuseIdentifier
            formatRow.key = Self.formatRowKey
            formatRow.title = localizedString("shared_string_format")
            formatRow.icon = .icCustomLongitude
            formatRow.iconTintColor = .iconColorDefault
            let zoomRow = formatZoomSection.createNewRow()
            zoomRow.cellType = OAValueTableViewCell.reuseIdentifier
            zoomRow.key = Self.zoomRowKey
            zoomRow.title = localizedString("shared_string_zoom_levels")
            zoomRow.descr = "\(settings.coordinateGridMinZoom.get()) – \(settings.coordinateGridMaxZoom.get())"
            zoomRow.icon = .icCustomOverlayMap
            zoomRow.iconTintColor = .iconColorDefault
            
            let positionColorSection = data.createNewSection()
            let labelsPositionRow = positionColorSection.createNewRow()
            labelsPositionRow.cellType = OAButtonTableViewCell.reuseIdentifier
            labelsPositionRow.key = Self.labelsPositionRowKey
            labelsPositionRow.title = localizedString("labels_position")
            let pos = GridLabelsPosition(rawValue: settings.coordinatesGridLabelsPosition.get()) ?? .edges
            labelsPositionRow.icon = pos.icon
            labelsPositionRow.iconTintColor = .iconColorDefault
            let colorRow = positionColorSection.createNewRow()
            colorRow.cellType = isMapsPlusProAvailable() ? OARightIconTableViewCell.reuseIdentifier : OATwoButtonsTableViewCell.reuseIdentifier
            colorRow.key = Self.colorRowKey
            colorRow.title = localizedString("grid_color")
            colorRow.descr = localizedString("customize_grid_color")
            colorRow.icon = isMapsPlusProAvailable() ? UIImage.templateImageNamed("ic_custom_appearance") : .icCustomGridColored
            colorRow.iconTintColor = .iconColorDefault
            colorRow.secondaryIconTintColor = UIColor(argb: Int(Int32(settings.nightMode ? settings.coordinatesGridColorNight.get() : settings.coordinatesGridColorDay.get())))
            colorRow.setObj(localizedString("shared_string_get"), forKey: Self.buttonTitleKey)
            colorRow.setObj("ic_custom_arrow_forward", forKey: Self.buttonIconKey)
        }
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
            cell.switchView.addTarget(self, action: #selector(mapSettingSwitchChanged(_:)), for: .valueChanged)
            return cell
        } else if item.cellType == OAButtonTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAButtonTableViewCell.reuseIdentifier) as! OAButtonTableViewCell
            cell.selectionStyle = .none
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.leftIconView.image = item.icon
            cell.leftIconView.tintColor = item.iconTintColor
            var config = UIButton.Configuration.plain()
            config.baseForegroundColor = .textColorActive
            config.contentInsets = NSDirectionalEdgeInsets(top: 3.1, leading: 16, bottom: 3.1, trailing: 0)
            cell.button.configuration = config
            if let key = item.key {
                cell.button.menu = createStateSelectionMenu(for: key)
            }
            cell.button.showsMenuAsPrimaryAction = true
            cell.button.changesSelectionAsPrimaryAction = true
            cell.button.contentHorizontalAlignment = .right
            cell.button.setContentHuggingPriority(.required, for: .horizontal)
            cell.button.setContentCompressionResistancePriority(.required, for: .horizontal)
            return cell
        } else if item.cellType == OAValueTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier) as! OAValueTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.valueLabel.text = item.descr
            cell.leftIconView.image = item.icon
            cell.leftIconView.tintColor = item.iconTintColor
            return cell
        } else if item.cellType == OARightIconTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OARightIconTableViewCell.reuseIdentifier) as! OARightIconTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.leftIconView.image = item.icon
            cell.leftIconView.tintColor = item.iconTintColor
            cell.rightIconView.backgroundColor = item.secondaryIconTintColor
            cell.rightIconView.layer.cornerRadius = cell.leftIconView.frame.height / 2
            return cell
        } else if item.cellType == OATwoButtonsTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OATwoButtonsTableViewCell.reuseIdentifier) as! OATwoButtonsTableViewCell
            cell.selectionStyle = .none
            cell.setLeftButtonVisible(false)
            cell.titleLabel.text = item.title
            cell.descriptionLabel.text = item.descr
            cell.leftIconView.image = item.icon
            cell.rightButton.layer.cornerRadius = 10
            cell.rightButton.backgroundColor = UIColor.contextMenuButtonBg
            var config = UIButton.Configuration.filled()
            config.baseBackgroundColor = UIColor.contextMenuButtonBg
            config.baseForegroundColor = .textColorActive
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(top: 3.1, leading: 4, bottom: 3.1, trailing: 4)
            config.imagePadding = 4
            config.imagePlacement = .trailing
            cell.rightButton.configuration = config
            cell.rightButton.setContentHuggingPriority(.required, for: .horizontal)
            cell.rightButton.setContentCompressionResistancePriority(.required, for: .horizontal)
            if let buttonTitle = item.string(forKey: Self.buttonTitleKey) {
                cell.rightButton.setTitle(buttonTitle, for: .normal)
                cell.rightButton.accessibilityLabel = buttonTitle
            }
            if let buttonIconName = item.string(forKey: Self.buttonIconKey) {
                cell.rightButton.setImage(UIImage.templateImageNamed(buttonIconName).imageFlippedForRightToLeftLayoutDirection(), for: .normal)
                cell.rightButton.tintColor = UIColor.iconColorActive
            }
            cell.rightButton.removeTarget(nil, action: nil, for: .allEvents)
            cell.rightButton.tag = indexPath.section << 10 | indexPath.row
            cell.rightButton.addTarget(self, action: #selector(onCellButtonClicked(sender:)), for: .touchUpInside)
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = data.item(for: indexPath)
        switch item.key {
        case Self.zoomRowKey:
            showTerrainParametersScreen(type: .EOATerrainSettingsTypeCoordinatesGridZoomLevels)
        case Self.colorRowKey:
            showTerrainParametersScreen(type: .EOATerrainSettingsTypeCoordinatesGridColor)
        default:
            break
        }
    }
    
    private func registerCells() {
        tblView?.register(UINib(nibName: OASwitchTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OASwitchTableViewCell.reuseIdentifier)
        tblView?.register(UINib(nibName: OAButtonTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OAButtonTableViewCell.reuseIdentifier)
        tblView?.register(UINib(nibName: OAValueTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OAValueTableViewCell.reuseIdentifier)
        tblView?.register(UINib(nibName: OARightIconTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OARightIconTableViewCell.reuseIdentifier)
        tblView?.register(UINib(nibName: OATwoButtonsTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OATwoButtonsTableViewCell.reuseIdentifier)
    }
    
    private func updateData() {
        initData()
        tblView?.reloadData()
    }
    
    private func createStateSelectionMenu(for key: String) -> UIMenu {
        if key == Self.formatRowKey {
            let actions = GridFormat.allCases.map { format in
                UIAction(title: format.title, state: format.id == settings.coordinateGridFormat.get() ? .on : .off) { [weak self] _ in
                    guard let self = self else { return }
                    self.settings.coordinateGridFormat.set(format.id)
                    self.updateData()
                }
            }
            return UIMenu(options: .singleSelection, children: actions)
        } else if key == Self.labelsPositionRowKey {
            let actions = GridLabelsPosition.allCases.map { pos in
                UIAction(title: pos.title, state: pos.rawValue == settings.coordinatesGridLabelsPosition.get() ? .on : .off) { [weak self] _ in
                    guard let self = self else { return }
                    self.settings.coordinatesGridLabelsPosition.set(pos.rawValue)
                    self.updateData()
                }
            }
            return UIMenu(options: .singleSelection, children: actions)
        }
        
        return UIMenu()
    }
    
    private func showTerrainParametersScreen(type: EOATerrainSettingsType) {
        let terrainParametersScreen = OAMapSettingsTerrainParametersViewController(settingsType: type)
        terrainParametersScreen.delegate = self
        vwController?.hide(true, animated: true)
        OARootViewController.instance()?.mapPanel.showScrollableHudViewController(terrainParametersScreen)
    }
    
    private func isMapsPlusProAvailable() -> Bool {
        OAIAPHelper.isMapsPlusAvailable() || OAIAPHelper.isOsmAndProAvailable()
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
    
    @objc private func onCellButtonClicked(sender: UIButton) {
        if let navigationController = vwController?.navigationController {
            OAChoosePlanHelper.showChoosePlanScreen(with: OAFeature.advanced_WIDGETS(), navController: navigationController)
        }
    }
}

extension MapSettingsCoordinatesGridScreen: OATerrainParametersDelegate {
    func onBackTerrainParameters() {
        OARootViewController.instance()?.mapPanel.showCoordinatesGridScreen()
    }
}
