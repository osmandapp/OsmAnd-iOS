//
//  ExternalSettingsWriteToTrackSettingsViewController.swift
//  OsmAnd Maps
//
//  Created by Skalii on 21.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objc(OAExternalSettingsWriteToTrackSettingsViewController)
@objcMembers
class ExternalSettingsWriteToTrackSettingsViewController: OABaseNavbarViewController {

    private let appMode: OAApplicationMode!

    // MARK: - Initialize

    init(applicationMode: OAApplicationMode!) {
        self.appMode = applicationMode
        super.init()
    }

    required init?(coder: NSCoder) {
        self.appMode = nil
        super.init(coder: coder)
    }


    // MARK: - Base UI

    override func getTitle() -> String! {
        localizedString("external_sensors_plugin_name")
    }

    override func getTableHeaderDescription() -> String! {
        localizedString("write_data_from_sensor_to_track")
    }

    // MARK: - Table data

    override func generateData() {
        tableData.clearAllData()
        if let plugin = OAPlugin.getEnabledPlugin(OAExternalSensorsPlugin.self) as? OAExternalSensorsPlugin {
            let dataTypeSection: OATableSectionData = tableData.createNewSection()
            dataTypeSection.headerText = localizedString("shared_string_data_type")
            for widgetType in plugin.getExternalSensorTrackDataType() {
                let deviceIdPref: OACommonString = plugin.getWriteToTrackDeviceIdPref(widgetType)
                let deviceId: String = deviceIdPref.get(appMode)
                var deviceName: String = localizedString("shared_string_none")
                var deviceFound = false
                if deviceId.length > 0 && deviceId != kDenyWriteSensorDataToTrackKey {
                    if let device: Device = DeviceHelper.shared.getConnectedOrPaireDisconnectedDeviceFor(type:widgetType, deviceId: deviceId) {
                        deviceName = device.deviceName
                        deviceFound = true
                    }
                }
                let dataType: OATableRowData = dataTypeSection.createNewRow()
                dataType.key = widgetType.id
                dataType.iconTintColor = deviceFound ? UIColor.iconColorActive : UIColor.iconColorDisabled
                dataType.descr = deviceName
                dataType.setObj(widgetType, forKey: "widgetType")
            }
        }
    }

    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
        if cell == nil {
            let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
            cell = nib?.first as? OASimpleTableViewCell
            cell?.accessoryType = .disclosureIndicator
        }
        if let cell = cell {
            if let widgetType = item.obj(forKey: "widgetType") as? WidgetType {
                cell.titleLabel.text = widgetType.title
                cell.descriptionLabel.text = item.descr
                cell.leftIconView.image = UIImage.templateImageNamed(widgetType.iconName)
                cell.leftIconView.tintColor = item.iconTintColor
            }
        }
        return cell
    }

    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if let widgetType = item.obj(forKey: "widgetType") as? WidgetType {
            var widget: SensorTextWidget?
            let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry!
            let pagedWidgets = widgetRegistry.getPagedWidgets(forPanel: appMode,
                                                              panel: widgetType.getPanel(),
                                                              filterModes: Int(KWidgetModeAvailable | kWidgetModeEnabled))!
            for widgetInfos in pagedWidgets {
                if widget != nil {
                    break
                }
                for widgetInfo in widgetInfos.array as! [MapWidgetInfo] {
                    if widgetInfo.getWidgetType() == widgetType {
                        widget = widgetInfo.widget as? SensorTextWidget
                        break
                    }
                }
            }
            let storyboard = UIStoryboard(name: "BLEPairedSensors", bundle: nil)
            if let controller = storyboard.instantiateViewController(withIdentifier: "BLEPairedSensors") as? BLEPairedSensorsViewController {
                controller.widgetType = widgetType
                controller.widget = widget
                controller.onSelectDeviceAction = { [weak self] device in
                    item.descr = device.deviceName
                    item.iconTintColor = UIColor.iconColorActive
                    self?.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
                self.showModalViewController(controller)
            }
        }
    }

}
