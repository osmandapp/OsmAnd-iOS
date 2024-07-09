//
//  WeatherLayerSettingsViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 25.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class WeatherLayerSettingsViewController: OABaseNavbarViewController {
    
    private static let weatherLayerKey = "weatherLayer"
    private static let selectedKey = "isSelected"
    
    var onChangeSwitchLayerAction: (() -> Void)?
    var onCloseAction: (() -> Void)?
    
    private lazy var weatherArray: [OAWeatherBand] = {
        [OAWeatherBand.withWeatherBand(.WEATHER_BAND_TEMPERATURE),
        OAWeatherBand.withWeatherBand(.WEATHER_BAND_PRESSURE),
        OAWeatherBand.withWeatherBand(.WEATHER_BAND_WIND_SPEED),
        OAWeatherBand.withWeatherBand(.WEATHER_BAND_CLOUD),
        OAWeatherBand.withWeatherBand(.WEATHER_BAND_PRECIPITATION)]
    }()
    
    private lazy var windAnimation = OAWeatherBand.withWeatherBand(.WEATHER_BAND_WIND_ANIMATION)
    
    override func getTitle() -> String {
        localizedString("shared_string_layers")
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_close")
    }
    
    override func isNavbarSeparatorVisible() -> Bool {
        false
    }
    
    override func registerCells() {
        addCell(OASwitchTableViewCell.reuseIdentifier)
    }
    
    override func onLeftNavbarButtonPressed() {
        super.onLeftNavbarButtonPressed()
        onCloseAction?()
    }
    
    override func generateData() {
        tableData.clearAllData()
        generateWeatherSectionData()
#warning("Waiting for tasks on adding wind animation")
        // generateWindAnimationSectionData()
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell! {
        guard let tableData else { return nil }
        let item = tableData.item(for: indexPath)
        
        if item.cellType == OASwitchTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.reuseIdentifier) as! OASwitchTableViewCell
            cell.descriptionVisibility(false)
            cell.leftIconVisibility(true)
            let selected = item.bool(forKey: Self.selectedKey)
            cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
            cell.leftIconView.tintColor = selected ? .iconColorActive : .iconColorDefault
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
    
    private func generateWeatherSectionData() {
        let section = tableData.createNewSection()
        
        weatherArray.forEach { weatherItem in
            let row = section.createNewRow()
            configureRow(row, with: weatherItem)
        }
    }

    private func generateWindAnimationSectionData() {
        let section = tableData.createNewSection()
        let row = section.createNewRow()
        
        configureRow(row, with: windAnimation)
    }
    
    private func configureRow(_ row: OATableRowData, with item: OAWeatherBand) {
        row.cellType = OASwitchTableViewCell.reuseIdentifier
        row.key = Self.weatherLayerKey
        row.title = item.getMeasurementName()
        row.iconName = item.getIcon()
        
        let isVisible = item.isBandVisible()
        row.setObj(isVisible, forKey: Self.selectedKey)
        row.setObj(item, forKey: "band")
        
        row.accessibilityLabel = row.title
        row.accessibilityValue = localizedString(isVisible ? "shared_string_on" : "shared_string_off")
    }
    
    @objc private func onSwitchClick(_ sender: Any) -> Bool {
        guard let sw = sender as? UISwitch else {
            return false
        }
        
        let indexPath = IndexPath(row: sw.tag & 0x3FF, section: sw.tag >> 10)
        let data = tableData.item(for: indexPath)
        
        if data.key == Self.weatherLayerKey {
            if let band = data.obj(forKey: "band") as? OAWeatherBand {
                band.setSelect(sw.isOn)
                reloadDataWith(animated: true, completion: nil)
                onChangeSwitchLayerAction?()
            }
        }
        
        return false
    }
}
