//
//  BLEPairedSensorsViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

final class BLEPairedSensorsViewController: OABaseNavbarViewController {
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
    @IBOutlet private weak var emptyView: UIView!
    
    var widgetType: WidgetType?
    var widget: SensorTextWidget?
    var onSelectDeviceAction: ((String) -> Void)?
    
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
        configureDataSource()
        reloadData()
    }
    
    // MARK: - Override's
    
    override func registerObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceDisconected),
                                               name: .DeviceDisconnected,
                                               object: nil)
    }
    
    override func getTitle() -> String! {
        localizedString("ant_plus_pair_new_sensor")
    }
    
    override func generateData() {
        tableData.clearAllData()
        if let devices {
            emptyView.isHidden = true
            let section = tableData.createNewSection()
            devices.forEach { _ in section.createNewRow() }
        } else {
            configureEmptyViewSearchingTitle()
            emptyView.isHidden = false
        }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: СhoicePairedDeviceTableViewCell.reuseIdentifier) as! СhoicePairedDeviceTableViewCell
        // separators go edge to edge
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        cell.preservesSuperviewLayoutMargins = false
        if let devices, devices.count > indexPath.row {
            cell.configure(item: devices[indexPath.row])
        }
        return cell
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        guard let devices, devices.count > indexPath.row else { return }
        guard !devices[indexPath.row].isSelected else { return }
        
        let currentSelectedDevice = devices[indexPath.row]
        widget?.configureDevice(id: currentSelectedDevice.id)
        
        for (index, item) in devices.enumerated() {
            item.isSelected = index == indexPath.row
        }
        onSelectDeviceAction?(currentSelectedDevice.id)
        tableView.reloadData()
    }
    
    // MARK: - Private func's
    
    private func configureDataSource() {
        devices = gatConnectedAndPaireDisconnectedDevicesFor()?.sorted(by: { $0.deviceName < $1.deviceName })
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
        tableView.rowHeight = 72
        tableView.backgroundColor = .clear
        view.backgroundColor = UIColor.viewBgColor
        
        tableView.register(SectionHeaderFooterButton.nib,
                           forHeaderFooterViewReuseIdentifier: SectionHeaderFooterButton.getCellIdentifier())
    }
    
    private func configureEmptyViewSearchingTitle() {
        searchingTitle.text = "\"" + (widgetType?.title ?? "") + "\" " + localizedString("external_sensors_not_found").lowercased()
    }
    
    private func gatConnectedAndPaireDisconnectedDevicesFor() -> [Device]? {
        if let widgetType,
           let devices = DeviceHelper.shared.gatConnectedAndPaireDisconnectedDevicesFor(type: widgetType), !devices.isEmpty  {
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
    
    @objc private func deviceDisconected() {
        guard view.window != nil else { return }
        reloadData()
    }
    
    // MARK: - @IBAction's
    
    @IBAction private func onPairNewSensorButtonPressed(_ sender: Any) {
        pairNewSensor()
    }
}
