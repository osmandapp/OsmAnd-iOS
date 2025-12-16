//
//  DistanceByTapViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 01.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class DistanceByTapViewController: OABaseNavbarViewController {
    private static let imgRowKey = "imgRowKey"
    private static let selectedKey = "isSelected"
    private static let distanceByTapKey = "distanceByTapKey"
    private static let textSizeKey = "textSizeKey"
    
    weak var delegate: OASettingsDataDelegate?
    
    private var settings: OAAppSettings!
    private var appMode: OAApplicationMode!
    
    override func commonInit() {
        settings = OAAppSettings.sharedManager()
        appMode = settings.applicationMode.get()
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
        addCell(OAButtonTableViewCell.reuseIdentifier)
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
        
        if showDistanceRuler {
            let appearanceSection = tableData.createNewSection()
            appearanceSection.headerText = localizedString("shared_string_appearance").uppercased()
            
            let textSizeRow = appearanceSection.createNewRow()
            textSizeRow.cellType = OAButtonTableViewCell.reuseIdentifier
            textSizeRow.key = Self.textSizeKey
            textSizeRow.title = localizedString("text_size")
        }
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
        } else if item.cellType == OAButtonTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAButtonTableViewCell.reuseIdentifier) as! OAButtonTableViewCell
            cell.selectionStyle = .none
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            var config = UIButton.Configuration.plain()
            config.baseForegroundColor = .textColorActive
            config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 0)
            cell.button.configuration = config
            cell.button.menu = createTextSizeMenu()
            cell.button.showsMenuAsPrimaryAction = true
            cell.button.changesSelectionAsPrimaryAction = true
            cell.button.setContentHuggingPriority(.required, for: .horizontal)
            cell.button.setContentCompressionResistancePriority(.required, for: .horizontal)
            return cell
        }
        return nil
    }
    
    private func createTextSizeMenu() -> UIMenu {
        var actions: [UIAction] = []
        for textSize in [EOADistanceByTapTextSizeConstant.NORMAL, EOADistanceByTapTextSizeConstant.LARGE] {
            let action = UIAction(title: OADistanceByTapTextSizeConstant.toHumanString(textSize), state: settings.distanceByTapTextSize.get() == textSize ? .on : .off) { [weak self] _ in
                guard let self else { return }
                settings.distanceByTapTextSize.set(textSize, mode: appMode)
            }
            actions.append(action)
        }
        return UIMenu(title: "", options: .displayInline, children: actions)
    }
    
    @objc private func onSwitchClick(_ sender: Any) -> Bool {
        guard let tableData, let sw = sender as? UISwitch else { return false }
        
        let indexPath = IndexPath(row: sw.tag & 0x3FF, section: sw.tag >> 10)
        let data = tableData.item(for: indexPath)
        
        if data.key == Self.distanceByTapKey {
            settings.showDistanceRuler.set(sw.isOn)
            reloadDataWith(animated: true, completion: nil)
            OARootViewController.instance().mapPanel.mapViewController.updateTapRulerLayer()
            delegate?.onSettingsChanged()
        }
        return false
    }
}
