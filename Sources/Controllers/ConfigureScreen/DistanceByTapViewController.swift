//
//  DistanceByTapViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 01.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

final class DistanceByTapViewController: OABaseNavbarViewController {
    private static let imgRowKey = "imgRowKey"
    private static let selectedKey = "isSelected"
    private static let distanceByTapKey = "distanceByTapKey"
    
    weak var delegate: WidgetStateDelegate?
    // swiftlint:disable force_unwrapping
    private lazy var settings = OAAppSettings.sharedManager()!
    // swiftlint:enable force_unwrapping
    
    override func commonInit() {
        settings = OAAppSettings.sharedManager()
    }
    
    override func getTitle() -> String {
        localizedString("map_widget_distance_by_tap")
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func registerCells() {
        addCell(ImageHeaderCell.reuseIdentifier)
        addCell(OASwitchTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        let distanceByTapImgSection = tableData.createNewSection()
        distanceByTapImgSection.footerText = localizedString("distance_by_tap_use_description")
        
        let imgRow = distanceByTapImgSection.createNewRow()
        imgRow.cellType = ImageHeaderCell.reuseIdentifier
        imgRow.key = Self.imgRowKey
        imgRow.iconName = "img_distance_by_tap"
        
        let switchCellSection = tableData.createNewSection()
        let showDistanceRuler = settings.showDistanceRuler.get()
        
        let distanceByTapRow = switchCellSection.createNewRow()
        distanceByTapRow.cellType = OASwitchTableViewCell.reuseIdentifier
        distanceByTapRow.key = Self.distanceByTapKey
        distanceByTapRow.title = localizedString("map_widget_distance_by_tap")
        distanceByTapRow.accessibilityLabel = distanceByTapRow.title
        distanceByTapRow.accessibilityValue = localizedString(showDistanceRuler ? "shared_string_on" : "shared_string_off")
        distanceByTapRow.setObj(showDistanceRuler, forKey: Self.selectedKey)
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == ImageHeaderCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: ImageHeaderCell.reuseIdentifier) as! ImageHeaderCell
            cell.selectionStyle = .none
            cell.backgroundImageView.image = UIImage(named: item.iconName ?? "")
            cell.backgroundImageView.layer.cornerRadius = 6
            cell.configure(verticalSpace: 16, horizontalSpace: 16)
            return cell
        } else if item.cellType == OASwitchTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.reuseIdentifier) as! OASwitchTableViewCell
            cell.descriptionVisibility(false)
            cell.leftIconVisibility(false)
            let selected = item.bool(forKey: Self.selectedKey)
            cell.leftIconView.tintColor = selected ? UIColor(rgb: item.iconTint) : .iconColorDefault
            cell.titleLabel.text = item.title
            cell.accessibilityLabel = item.accessibilityLabel
            cell.accessibilityValue = item.accessibilityValue
            cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
            cell.switchView.isOn = selected
            cell.switchView.tag = indexPath.section << 10 | indexPath.row
            cell.switchView.addTarget(self, action: #selector(onSwitchClick(_:)), for: .valueChanged)
            return cell
        }
        return nil
    }
    
    @objc private func onSwitchClick(_ sender: Any) -> Bool {
        guard let tableData, let sw = sender as? UISwitch else { return false }
        
        let indexPath = IndexPath(row: sw.tag & 0x3FF, section: sw.tag >> 10)
        let data = tableData.item(for: indexPath)
        
        if data.key == Self.distanceByTapKey {
            settings.showDistanceRuler.set(sw.isOn)
            reloadDataWith(animated: true, completion: nil)
            delegate?.onWidgetStateChanged()
        }
        return false
    }
}
