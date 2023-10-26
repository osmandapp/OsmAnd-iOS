//
//  BLEExternalSensorsViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 13.10.2023.
//

import UIKit

final class BLEExternalSensorsViewController: OABaseNavbarViewController {
    
    private enum ExternalSensorsCellData: String {
        case title, learnMore
    }
    
    @IBOutlet private weak var emptyView: UIView! {
        didSet {
            emptyView.isHidden = false
        }
    }
    
    private let headerView: UIView = UIView(frame: .zero)
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initTableData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.sectionHeaderTopPadding = 0
        configureHeader()
    }
    
    override func setupTableHeaderView() {
        configureHeader()
    }
    
    private func configureHeader() {
        headerView.subviews.forEach { $0.removeFromSuperview() }
        let imageView = UIImageView(image: UIImage(named: "img_help_sensors_day"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 1.0
        headerView.addSubview(imageView)
        headerView.frame.size.height = 201
        headerView.frame.size.width = view.frame.width
        imageView.frame = headerView.frame
        tableView.tableHeaderView = headerView
    }
    
    override func getTitle() -> String! {
        "External sensors"
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        let add = UIBarButtonItem(barButtonSystemItem: .add,
                                  target: self,
                                  action: #selector(onRightNavbarButtonPressed))
        add.tintColor = UIColor.buttonBgColorPrimary
        return [add]
    }
    
    override func onRightNavbarButtonPressed() {
        pairNewSensor()
    }
    
    @objc private func pairNewSensor() {
        let storyboard = UIStoryboard(name: "BLESearchViewController", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "BLESearchViewController") as? BLESearchViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    override func generateData() {
        tableData.clearAllData()
        let section = tableData.createNewSection()
        let titleBLE = section.createNewRow()
        titleBLE.cellType = OASimpleTableViewCell.getIdentifier()
        titleBLE.key = ExternalSensorsCellData.title.rawValue
        titleBLE.title = "You can pair Bluetooth Low Energy (BLE) sensors with OsmAnd."

        let learnMoreBLE = section.createNewRow()
        learnMoreBLE.cellType = OASimpleTableViewCell.getIdentifier()
        learnMoreBLE.key = ExternalSensorsCellData.learnMore.rawValue
        learnMoreBLE.title = "Learn more about sensors."
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        if item.cellType == OASimpleTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASimpleTableViewCell
                cell?.descriptionVisibility(false)
                cell?.leftIconVisibility(false)
            }
            if let cell {
                cell.titleLabel.text = item.title
                if let key = item.key, let item = ExternalSensorsCellData(rawValue: key) {
                    switch item {
                    case .title:
                        cell.titleLabel.textColor = UIColor.textColorPrimary
                        cell.selectionStyle = .none
                    case .learnMore:
                        cell.titleLabel.textColor = UIColor.buttonBgColorPrimary
                        cell.selectionStyle = .default
                    }
                }
            }
            outCell = cell
        }
        return outCell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNonzeroMagnitude
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNonzeroMagnitude
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if let key = item.key, let item = ExternalSensorsCellData(rawValue: key) {
            if case .learnMore = item {
#warning("add push")
            }
            
        }
    }
    
    // MARK: - IBAction
    @IBAction func onPairNewSensorButtonPressed(_ sender: Any) {
        pairNewSensor()
    }
}
