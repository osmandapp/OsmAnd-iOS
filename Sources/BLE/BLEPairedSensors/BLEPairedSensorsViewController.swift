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
        devices = gatConnectedAndPaireDisconnectedDevicesFor()
        generateData()
        tableView.reloadData()
    }
    
    // MARK: - Override's
    
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
        0
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCell(withIdentifier: СhoicePairedDeviceTableViewCell.reuseIdentifier) as! СhoicePairedDeviceTableViewCell
        if let devices, devices.count > indexPath.row {
            cell.configure(item: devices[indexPath.row])
        }
        return cell
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        if let devices, devices.count > indexPath.row {
            let controller = BLEDescriptionViewController()
            controller.device = devices[indexPath.row]
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    // MARK: - Private func's
    
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
    
    // MARK: - @IBAction's
    
    @IBAction private func onPairNewSensorButtonPressed(_ sender: Any) {
        pairNewSensor()
    }
}
