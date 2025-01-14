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
final class ExternalSettingsWriteToTrackSettingsViewController: OABaseNavbarViewController {

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
    
    override func registerObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceDisconnected),
                                               name: .DeviceDisconnected,
                                               object: nil)
    }
    
    // MARK: - Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
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
        if let plugin = OAPluginsHelper.getEnabledPlugin(OAExternalSensorsPlugin.self) as? OAExternalSensorsPlugin {
            let dataTypeSection: OATableSectionData = tableData.createNewSection()
            dataTypeSection.headerText = localizedString("shared_string_data_type")
            for widgetType in plugin.getExternalSensorTrackDataType() {
                var deviceFound = false
                let deviceIdPref: OACommonString? = plugin.getWriteToTrackDeviceIdPref(widgetType)
                let deviceId: String? = deviceIdPref?.get(appMode)
                
                let dataType: OATableRowData = dataTypeSection.createNewRow()
                dataType.key = widgetType.id
                var deviceName = localizedString("shared_string_none")
                if let deviceId, !deviceId.isEmpty {
                    if deviceId == plugin.getAnyConnectedDeviceId() {
                        if let connectedDevices = DeviceHelper.shared.getConnectedDevicesForWidget(type: widgetType),
                           let firstDevice = connectedDevices.first {
                            deviceFound = true
                            deviceName = localizedString("external_device_any_connected") + ": " + firstDevice.deviceName
                        } else {
                            deviceName = localizedString("external_device_any_connected")
                        }
                    } else {
                        if let device = DeviceHelper.shared.getPairedDevicesFor(type: widgetType, deviceId: deviceId) {
                            deviceFound = true
                            deviceName = device.deviceName
                        }
                    }
                }
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
        if let cell {
            if let widgetType = item.obj(forKey: "widgetType") as? WidgetType {
                cell.titleLabel.text = widgetType.title
                cell.descriptionLabel.text = item.descr
                cell.leftIconView.image = UIImage.templateImageNamed(widgetType.disabledIconName)
                cell.leftIconView.tintColor = item.iconTintColor
            }
        }
        return cell
    }

    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if let widgetType = item.obj(forKey: "widgetType") as? WidgetType {
            let storyboard = UIStoryboard(name: "BLEPairedSensors", bundle: nil)
            if let controller = storyboard.instantiateViewController(withIdentifier: "BLEPairedSensors") as? BLEPairedSensorsViewController {
                controller.pairedSensorsType = .tripRecording
                controller.appMode = appMode
                controller.widgetType = widgetType
                controller.onSelectDeviceAction = { [weak self] _ in
                    self?.reloadData()
                }
                controller.onSelectCommonOptionsAction = { [weak self] in
                    self?.reloadData()
                }
                showModalViewController(controller)
            }
        }
    }
    
    private func reloadData() {
        generateData()
        tableView.reloadData()
    }
    
    @objc private func deviceDisconnected() {
        guard view.window != nil else { return }
        reloadData()
    }
}
