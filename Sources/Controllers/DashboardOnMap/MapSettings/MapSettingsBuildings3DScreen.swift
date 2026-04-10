//
//  MapSettingsBuildings3DScreen.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 16.03.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

private enum RowKey: String {
    case showHide3dObjects
    case enabled
    case color
    case visibility
    case detail
    case viewDistance
    case valuesOff
    case selectedValues
}

@objcMembers
final class MapSettingsBuildings3DScreen: NSObject, OAMapSettingsScreen {
    var settingsScreen: EMapSettingsScreen = .buildings3DVisibility
    var vwController: OADashboardViewController?
    var tblView: UITableView?
    var title: String?
    var isOnlineMapSource = false
    var tableData: [Any]?
    
    private let srtmPlugin = OAPluginsHelper.getPlugin(OASRTMPlugin.self) as? OASRTMPlugin
    private let segmentIconSize = CGSize(width: 20.0, height: 20.0)
    
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
        registerCells()
        initData()
    }
    
    func initData() {
        data.clearAllData()
        is3DObjectsEnabled = is3DObjectsCurrentlyEnabled()
        
        let switchSection = data.createNewSection()
        let showHide3dObjectsRow = switchSection.createNewRow()
        showHide3dObjectsRow.cellType = OASwitchTableViewCell.reuseIdentifier
        showHide3dObjectsRow.key = RowKey.showHide3dObjects.rawValue
        showHide3dObjectsRow.title = localizedString(is3DObjectsEnabled ? "shared_string_enabled" : "rendering_value_disabled_name")
        showHide3dObjectsRow.icon = is3DObjectsEnabled ? .icCustomShow : .icCustomHide
        showHide3dObjectsRow.iconTintColor = is3DObjectsEnabled ? .iconColorSelected : .iconColorDisabled
        showHide3dObjectsRow.setObj(is3DObjectsEnabled, forKey: RowKey.enabled.rawValue)
        
        guard is3DObjectsEnabled, let srtmPlugin else { return }
        let appearanceSection = data.createNewSection()
        appearanceSection.headerText = localizedString("shared_string_appearance")
        let colorRow = appearanceSection.createNewRow()
        colorRow.cellType = OAValueTableViewCell.reuseIdentifier
        colorRow.key = RowKey.color.rawValue
        colorRow.title = localizedString("shared_string_color")
        colorRow.icon = .icCustomAppearanceOutlined
        colorRow.iconTintColor = .iconColorDefault
        colorRow.descr = localizedString(Buildings3DColorType.getById(Int(srtmPlugin.buildings3dColorStylePref.get())).labelId)
        let visibilityRow = appearanceSection.createNewRow()
        visibilityRow.cellType = OAValueTableViewCell.reuseIdentifier
        visibilityRow.key = RowKey.visibility.rawValue
        visibilityRow.title = localizedString("visibility")
        visibilityRow.icon = UIImage.templateImageNamed("ic_custom_visibility")
        visibilityRow.iconTintColor = .iconColorDefault
        visibilityRow.descr = NumberFormatter.percentFormatter.string(from: srtmPlugin.buildings3dAlphaPref.get() as NSNumber)
        
        let performanceSection = data.createNewSection()
        performanceSection.headerText = localizedString("performance")
        let detailRow = performanceSection.createNewRow()
        detailRow.cellType = SegmentImagesWithRightLabelTableViewCell.reuseIdentifier
        detailRow.key = RowKey.detail.rawValue
        detailRow.title = localizedString("level_of_details")
        detailRow.setObj([resizedSegmentIcon(UIImage.icCustom3DBuildingsDetailLowOff), resizedSegmentIcon(UIImage.icCustom3DBuildingsDetailHighOff)], forKey: RowKey.valuesOff.rawValue)
        detailRow.setObj([resizedSegmentIcon(UIImage.icCustom3DBuildingsDetailLowOn, tintColor: nil), resizedSegmentIcon(UIImage.icCustom3DBuildingsDetailHighOn, tintColor: nil)], forKey: RowKey.selectedValues.rawValue)
        let viewDistanceRow = performanceSection.createNewRow()
        viewDistanceRow.cellType = SegmentImagesWithRightLabelTableViewCell.reuseIdentifier
        viewDistanceRow.key = RowKey.viewDistance.rawValue
        viewDistanceRow.title = localizedString("view_distance")
        viewDistanceRow.setObj([resizedSegmentIcon(UIImage.icCustomViewDistanceNearOff), resizedSegmentIcon(UIImage.icCustomViewDistanceFarOff)], forKey: RowKey.valuesOff.rawValue)
        viewDistanceRow.setObj([resizedSegmentIcon(UIImage.icCustomViewDistanceNearOn, tintColor: nil), resizedSegmentIcon(UIImage.icCustomViewDistanceFarOn, tintColor: nil)], forKey: RowKey.selectedValues.rawValue)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        Int(data.sectionCount())
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        data.sectionData(for: UInt(section)).headerText
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Int(data.rowCount(UInt(section)))
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = data.item(for: indexPath)
        if item.cellType == OASwitchTableViewCell.reuseIdentifier, let cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.reuseIdentifier, for: indexPath) as? OASwitchTableViewCell {
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.leftIconView.image = item.icon
            cell.leftIconView.tintColor = item.iconTintColor
            cell.switchView.setOn(item.bool(forKey: RowKey.enabled.rawValue), animated: true)
            cell.switchView.tag = indexPath.section << 10 | indexPath.row
            cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
            cell.switchView.addTarget(self, action: #selector(on3DObjectsSwitchChanged(_:)), for: .valueChanged)
            return cell
        }
        if item.cellType == OAValueTableViewCell.reuseIdentifier, let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier, for: indexPath) as? OAValueTableViewCell {
            cell.accessoryType = .disclosureIndicator
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.valueLabel.text = item.descr
            cell.leftIconView.image = item.icon
            cell.leftIconView.tintColor = item.iconTintColor
            return cell
        }
        if item.cellType == SegmentImagesWithRightLabelTableViewCell.reuseIdentifier, let cell = tableView.dequeueReusableCell(withIdentifier: SegmentImagesWithRightLabelTableViewCell.reuseIdentifier, for: indexPath) as? SegmentImagesWithRightLabelTableViewCell {
            cell.selectionStyle = .none
            cell.configureTitle(title: item.title)
            if let srtmPlugin, let icons = item.obj(forKey: RowKey.valuesOff.rawValue) as? [UIImage], let selectedIcons = item.obj(forKey: RowKey.selectedValues.rawValue) as? [UIImage] {
                let isViewDistanceRow = item.key == RowKey.viewDistance.rawValue
                let selectedSegmentIndex: Int
                if isViewDistanceRow {
                    let isFarDistanceSelected = srtmPlugin.buildings3dViewDistancePref.get() == 2
                    selectedSegmentIndex = isFarDistanceSelected ? 1 : 0
                } else {
                    selectedSegmentIndex = srtmPlugin.buildings3dDetailLevelPref.get() ? 1 : 0
                }
                cell.configureSegmentedControl(icons: icons, selectedSegmentIndex: selectedSegmentIndex, selectedIcons: selectedIcons)
            }
            cell.didSelectSegmentIndex = { [weak self] index in
                let isViewDistanceRow = item.key == RowKey.viewDistance.rawValue
                if isViewDistanceRow {
                    self?.applyBuildings3DViewDistance(index == 1 ? 2 : 1)
                } else {
                    self?.applyBuildings3DDetailLevel(index == 1)
                }
            }
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = data.item(for: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
        switch item.key {
        case RowKey.color.rawValue:
            showBuildings3DParametersScreen(type: .color)
        case RowKey.visibility.rawValue:
            showBuildings3DParametersScreen(type: .visibility)
        default:
            break
        }
    }
    
    private func registerCells() {
        tblView?.register(UINib(nibName: OASwitchTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OASwitchTableViewCell.reuseIdentifier)
        tblView?.register(UINib(nibName: SegmentImagesWithRightLabelTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: SegmentImagesWithRightLabelTableViewCell.reuseIdentifier)
        tblView?.register(UINib(nibName: OAValueTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OAValueTableViewCell.reuseIdentifier)
    }
    
    private func updateData() {
        initData()
        tblView?.reloadData()
    }
    
    private func resizedSegmentIcon(_ image: UIImage, tintColor: UIColor? = .iconColorActive) -> UIImage {
        let resizedImage = OAUtilities.resize(image, newSize: segmentIconSize) ?? image
        guard let tintColor else { return resizedImage }
        return resizedImage.withTintColor(tintColor, renderingMode: .alwaysOriginal)
    }
    
    private func is3DObjectsCurrentlyEnabled() -> Bool {
        guard let srtmPlugin else { return false }
        return srtmPlugin.is3dMapObjectsEnabled()
    }
    
    private func applyBuildings3DDetailLevel(_ isHigh: Bool) {
        guard let srtmPlugin else { return }
        srtmPlugin.buildings3dDetailLevelPref.set(isHigh)
        OsmAndApp.swiftInstance().mapSettingsChangeObservable.notifyEvent()
    }
    
    private func applyBuildings3DViewDistance(_ level: Int) {
        guard let srtmPlugin else { return }
        srtmPlugin.buildings3dViewDistancePref.set(Int32(level))
        srtmPlugin.apply3DBuildingsDetalization()
    }
    
    private func showBuildings3DParametersScreen(type: Buildings3DSettingsType) {
        let parametersScreen = MapSettingsBuildings3DParametersViewController(settingsType: type)
        parametersScreen.delegate = self
        vwController?.hide(true, animated: true)
        OARootViewController.instance()?.mapPanel.showScrollableHudViewController(parametersScreen)
    }
    
    @objc private func on3DObjectsSwitchChanged(_ sender: UISwitch) {
        guard let srtmPlugin else { return }
        srtmPlugin.set3dMapObjectsEnabled(sender.isOn)
        updateData()
    }
}

extension MapSettingsBuildings3DScreen: Buildings3DParametersDelegate {
    func onBackBuildings3DParameters() {
        OARootViewController.instance()?.mapPanel.showBuildings3DScreen()
    }
}
