//
//  BLEPairedSensorsViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

final class BLEPairedSensorsViewController: OABaseNavbarViewController {
    
    enum PairedSensorsType {
        case widget, tripRecording
    }
    
    @IBOutlet private weak var searchingTitle: UILabel!
    @IBOutlet private weak var searchingDescription: UILabel! {
        didSet {
            searchingDescription.text = localizedString("there_are_no_connected_sensors_of_this_type")
        }
    }
    @IBOutlet private weak var pairNewSensorButton: UIButton! {
        didSet {
            pairNewSensorButton.setTitle(localizedString("ant_plus_pair_new_sensor"), for: .normal)
        }
    }
    var appMode: OAApplicationMode?
    var widgetType: WidgetType?
    var widget: SensorTextWidget?
    var pairedSensorsType: PairedSensorsType = .widget
    var onSelectDeviceAction: ((Device) -> Void)?
    var onSelectCommonOptionsAction: (() -> Void)?
    
    private var devices: [Device]?
    
    // MARK: - Init
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initTableData()
    }
    
    // MARK: - Life circle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        switch pairedSensorsType {
        case .widget:
            configureWidgetDataSource()
        case .tripRecording:
            configureTripRecordingDataSource()
        }
        generateData()
    }
    
    // MARK: - Override's
    
    override func registerObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceDisconnected),
                                               name: .DeviceDisconnected,
                                               object: nil)
    }
    
    override func getTitle() -> String {
        localizedString("paired_sensors")
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_cancel")
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func generateData() {
        tableData.clearAllData()
        let section = tableData.createNewSection()
        devices?.forEach { _ in section.createNewRow() }
        tableView.reloadData()
    }
    
    override func getCustomView(forFooter section: Int) -> UIView {
        let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterButton.getCellIdentifier()) as! SectionHeaderFooterButton
        footer.configireButton(title: localizedString("ant_plus_pair_new_sensor"))
        footer.onBottonAction = { [weak self] in
            self?.pairNewSensor()
        }
        return footer
    }
    
    override func getCustomHeight(forFooter section: Int) -> CGFloat {
        48
    }

    override func registerCells() {
        addCell(OptionDeviceTableViewCell.reuseIdentifier)
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        if let devices, devices.count > indexPath.row {
            let item = devices[indexPath.row]
            if item is OptionDevice {
                if let cell = tableView.dequeueReusableCell(withIdentifier: OptionDeviceTableViewCell.reuseIdentifier) as? OptionDeviceTableViewCell {
                    cell.topSeparatorView.isHidden = indexPath.row != 0
                    cell.separatorBottomInsetLeft = indexPath.row < devices.count - 1 ? 66 : 0
                    
                    if let widgetType, let optionDevice = devices[indexPath.row] as? OptionDevice {
                        var title = ""
                        switch optionDevice.option {
                        case .none:
                            title = localizedString("shared_string_none")
                        case .anyConnected:
                            title = localizedString("external_device_any_connected")
                        }
                        cell.configure(optionDevice: optionDevice,
                                       widgetType: widgetType,
                                       title: title)
                    }
                    return cell
                }
            } else {
                if let cell = tableView.dequeueReusableCell(withIdentifier: СhoicePairedDeviceTableViewCell.reuseIdentifier) as? СhoicePairedDeviceTableViewCell {
                    cell.separatorBottomInsetLeft = indexPath.row < devices.count - 1 ? 66 : 0
                    cell.configure(item: devices[indexPath.row])
                    return cell
                }
            }
        }
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        guard let devices, devices.count > indexPath.row else { return }
        guard !devices[indexPath.row].isSelected else { return }
        guard let widgetType, let appMode else { return }
        
        for (index, item) in devices.enumerated() {
            item.isSelected = index == indexPath.row
        }

        let currentSelectedDevice = devices[indexPath.row]
        
        if let optionDevice = currentSelectedDevice as? OptionDevice {
            if pairedSensorsType == .widget {
                widget?.setAnyDevice(use: true)
                widget?.configureDevice(id: "")
            } else if pairedSensorsType == .tripRecording {
                guard let plugin = OAPlugin.getEnabledPlugin(OAExternalSensorsPlugin.self) as? OAExternalSensorsPlugin else { return }
                switch optionDevice.option {
                case .none:
                    plugin.saveDeviceId("", widgetType: widgetType, appMode: appMode)
                case .anyConnected:
                    plugin.saveDeviceId(plugin.getAnyConnectedDeviceId(), widgetType: widgetType, appMode: appMode)
                }
            }
            onSelectCommonOptionsAction?()
        } else {
            switch pairedSensorsType {
            case .widget:
                widget?.setAnyDevice(use: false)
                widget?.configureDevice(id: currentSelectedDevice.id)
            case .tripRecording:
                guard let plugin = OAPlugin.getEnabledPlugin(OAExternalSensorsPlugin.self) as? OAExternalSensorsPlugin else { return }
                plugin.saveDeviceId(currentSelectedDevice.id, widgetType: widgetType, appMode: appMode)
            }
            onSelectDeviceAction?(currentSelectedDevice)
        }
        tableView.reloadData()
        dismiss()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch pairedSensorsType {
        case .widget:
            return indexPath.row == 0 ? UITableView.automaticDimension : 73
        case .tripRecording:
            return indexPath.row <= 1 ? UITableView.automaticDimension : 73
        }
    }
    
    // MARK: - Private func's
    
    private func configureTripRecordingDataSource() {
        guard let widgetType,
              let appMode,
              let plugin = OAPlugin.getEnabledPlugin(OAExternalSensorsPlugin.self) as? OAExternalSensorsPlugin else { return }
        
        devices = []
        let savedDeviceId = plugin.getDeviceId(for: widgetType, appMode: appMode)
        let isSelectedNoneConnectedDeviceOption = savedDeviceId.isEmpty
        let isSelectedAnyConnectedDeviceOption = savedDeviceId == plugin.getAnyConnectedDeviceId()
        
        let noneDevice = OptionDevice(deviceType: nil)
        noneDevice.option = .none
        if isSelectedNoneConnectedDeviceOption {
            noneDevice.isSelected = true
        } else {
            noneDevice.isSelected = false
        }
        devices?.append(noneDevice)
        
        let anyConnectedDevice = OptionDevice(deviceType: nil)
        anyConnectedDevice.option = .anyConnected
        if isSelectedAnyConnectedDeviceOption {
            anyConnectedDevice.isSelected = true
        } else {
            anyConnectedDevice.isSelected = false
        }
        devices?.append(anyConnectedDevice)
        
        let isSelectedDeviceId = !isSelectedNoneConnectedDeviceOption && !isSelectedAnyConnectedDeviceOption
        
        let devicesArray = getPairedDevicesForCurrentWidgetType()?.sorted(by: { $0.deviceName < $1.deviceName }) ?? []
        // reset to default state for checkbox
        devicesArray.forEach { $0.isSelected = false }
        if isSelectedDeviceId {
            if let device = devicesArray.first(where: { $0.id == savedDeviceId }) {
                device.isSelected = true
            }
        }
        
        if !devicesArray.isEmpty {
            devices! += devicesArray
        }
    }
    
    private func configureWidgetDataSource() {
        guard let widget else { return }
        let isSelectedAnyConnectedDeviceOption = widget.shouldUseAnyConnectedDevice
        let anyConnectedDevice = OptionDevice(deviceType: nil)
        anyConnectedDevice.option = .anyConnected
        anyConnectedDevice.isSelected = isSelectedAnyConnectedDeviceOption
        
        devices = getPairedDevicesForCurrentWidgetType()?.sorted(by: { $0.deviceName < $1.deviceName }) ?? []
        // reset to default state for checkbox
        devices?.forEach { $0.isSelected = false }
        if devices?.isEmpty ?? true {
            devices?.insert(anyConnectedDevice, at: 0)
            anyConnectedDevice.isSelected = true
        } else {
            if !isSelectedAnyConnectedDeviceOption {
                if let device = devices?.first(where: { $0.id == widget.externalDeviceId }) {
                    device.isSelected = true
                } else {
                    if let device = devices?.last {
                        widget.configureDevice(id: device.id)
                        device.isSelected = true
                    }
                }
            }
            devices?.insert(anyConnectedDevice, at: 0)
        }
    }
    
    private func configureTableView() {
        tableView.isHidden = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.sectionHeaderTopPadding = 34
        tableView.separatorStyle = .none
        
        tableView.backgroundColor = .clear
        view.backgroundColor = UIColor.viewBg
        tableView.register(SectionHeaderFooterButton.nib,
                           forHeaderFooterViewReuseIdentifier: SectionHeaderFooterButton.getCellIdentifier())
    }
        
    private func getPairedDevicesForCurrentWidgetType() -> [Device]? {
        if let widgetType,
           let devices = DeviceHelper.shared.getPairedDevicesFor(type: widgetType), !devices.isEmpty {
            return devices
        }
        return nil
    }
    
    private func pairNewSensor() {
        let storyboard = UIStoryboard(name: "BLESearchViewController", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "BLESearchViewController") as? BLESearchViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc private func deviceDisconnected() {
        guard view.window != nil else { return }
        tableView.reloadData()
    }
    
    // MARK: - @IBAction's
    
    @IBAction private func onPairNewSensorButtonPressed(_ sender: Any) {
        pairNewSensor()
    }
}
