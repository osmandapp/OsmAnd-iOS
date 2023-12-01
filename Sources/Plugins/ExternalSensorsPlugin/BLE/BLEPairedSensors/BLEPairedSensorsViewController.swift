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
        tableView.reloadData()
    }
    
    private func configureTripRecordingDataSource() {
        guard let widget else { return }
        // TODO: Add logic in branch TripRecording
    }
    
    private func configureWidgetDataSource() {
        guard let widget else { return }
        let isSelectedAnyConnectedDeviceOption = widget.useAnyDevicePref?.get() == true
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
    
    // MARK: - Override's
    
    override func registerObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceDisconnected),
                                               name: .DeviceDisconnected,
                                               object: nil)
    }
    
    override func getTitle() -> String! {
        localizedString("ant_plus_pair_new_sensor")
    }
    
    override func generateData() {
        tableData.clearAllData()
        let section = tableData.createNewSection()
        devices?.forEach { _ in section.createNewRow() }
        tableView.reloadData()
    }
    
    override func getCustomView(forFooter section: Int) -> UIView! {
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
    
    override func getCustomHeight(forHeader section: Int) -> CGFloat {
        10
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        if let devices, devices.count > indexPath.row {
            let item = devices[indexPath.row]
            if item is OptionDevice {
                if let cell = tableView.dequeueReusableCell(withIdentifier: AnyConnectedDevicesTableViewCell.reuseIdentifier) as? AnyConnectedDevicesTableViewCell {
                    cell.separatorInset = .zero
                    cell.layoutMargins = .zero
                    cell.preservesSuperviewLayoutMargins = false
                    if let widgetType, let anyConnectedDevice = devices[indexPath.row] as? OptionDevice {
                        cell.configure(anyConnectedDevice: anyConnectedDevice,
                                       widgetType: widgetType,
                                       title: localizedString("external_device_any_connected"))
                    }
                    return cell
                }
            } else {
                if let cell = tableView.dequeueReusableCell(withIdentifier: СhoicePairedDeviceTableViewCell.reuseIdentifier) as? СhoicePairedDeviceTableViewCell {
                    // separators go edge to edge
                    cell.separatorInset = .zero
                    cell.layoutMargins = .zero
                    cell.preservesSuperviewLayoutMargins = false
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
        
        let currentSelectedDevice = devices[indexPath.row]
        
        for (index, item) in devices.enumerated() {
            item.isSelected = index == indexPath.row
        }
        
        if currentSelectedDevice is OptionDevice {
            widget?.useAnyDevicePref(use: true)
            widget?.configureDevice(id: "")
            onSelectCommonOptionsAction?()
        } else {
            widget?.useAnyDevicePref(use: false)
            widget?.configureDevice(id: currentSelectedDevice.id)
            onSelectDeviceAction?(currentSelectedDevice)
        }
       
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.row == 0 ? 48 : 73
    }
    
    // MARK: - Private func's
    
    private func configureDataSource() {
        devices = getPairedDevicesForCurrentWidgetType()?.sorted(by: { $0.deviceName < $1.deviceName })
        // reset to default state for checkbox
        devices?.forEach { $0.isSelected = false }
        if let devices {
            if let device = devices.first(where: { $0.id == widget?.externalDeviceId }) {
                device.isSelected = true
            } else {
                if let device = devices.first {
                    widget?.configureDevice(id: device.id)
                    device.isSelected = true
                }
            }
        }
    }
    
    private func configureTableView() {
        tableView.isHidden = false
        tableView.dataSource = self
        tableView.delegate = self

        tableView.backgroundColor = .clear
        view.backgroundColor = UIColor.viewBgColor
        tableView.register(SectionHeaderFooterButton.nib,
                           forHeaderFooterViewReuseIdentifier: SectionHeaderFooterButton.getCellIdentifier())
        tableView.register(UINib(nibName: AnyConnectedDevicesTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: AnyConnectedDevicesTableViewCell.reuseIdentifier)
    }
        
    private func getPairedDevicesForCurrentWidgetType() -> [Device]? {
        if let widgetType,
           let devices = DeviceHelper.shared.getPairedDevicesFor(type: widgetType), !devices.isEmpty  {
            return devices
        } else {
        }
        return nil
    }
    
    private func pairNewSensor() {
        let storyboard = UIStoryboard(name: "BLESearchViewController", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "BLESearchViewController") as? BLESearchViewController {
            navigationController?.pushViewController(vc, animated: true)
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
    
    // MARK: - @IBAction's
    
    @IBAction private func onPairNewSensorButtonPressed(_ sender: Any) {
        pairNewSensor()
    }
}
