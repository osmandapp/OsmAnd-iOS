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
    
    var onChangeButtonIconAction: ((Bool) -> Void)?
    
//    lazy var weatherBandTemperature: OAWeatherBand = OAWeatherBand.withWeatherBand(.WEATHER_BAND_TEMPERATURE)
//    lazy var weatherBandPressure: OAWeatherBand = OAWeatherBand.withWeatherBand(.WEATHER_BAND_PRESSURE)
//    lazy var weatherBandWind: OAWeatherBand = OAWeatherBand.withWeatherBand(.WEATHER_BAND_WIND_SPEED)
//    lazy var weatherBandCloud: OAWeatherBand = OAWeatherBand.withWeatherBand(.WEATHER_BAND_CLOUD)
//    lazy var weatherBandPrecipitation: OAWeatherBand = OAWeatherBand.withWeatherBand(.WEATHER_BAND_PRECIPITATION)
    
    override func getTitle() -> String! {
        localizedString("shared_string_layers")
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_close")
    }
    
    override func registerCells() {
        addCell(OASwitchTableViewCell.reuseIdentifier)
    }
    
//    for (OAWeatherBand *band in _weatherHelper.bands)
//    {
//        [measurementCells addObject:@{
//                @"key": [@"band_" stringByAppendingString:[band getMeasurementName]],
//                @"band": band,
//                @"type": [OAValueTableViewCell getCellIdentifier]
//        }];
//    }
    
    override func generateData() {
        let section = tableData.createNewSection()
        OAWeatherHelper.sharedInstance().bands.forEach({
            let row = section.createNewRow()
            row.cellType = OASwitchTableViewCell.reuseIdentifier
            row.title = $0.getMeasurementName()
            row.iconName = $0.getIcon()
          //  @"image" : _weatherBand ? _weatherBand.getIcon : @"ic_custom_contour_lines"
            let isVisible = $0.isBandVisible()
            row.setObj(isVisible, forKey: Self.selectedKey)
            row.setObj($0, forKey: "band")
            row.accessibilityLabel = row.title
            row.accessibilityValue = localizedString(isVisible ? "shared_string_on" : "shared_string_off")
        })
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
    
    @objc func onSwitchClick(_ sender: Any) -> Bool {
        guard let sw = sender as? UISwitch else {
            return false
        }
        
        let indexPath = IndexPath(row: sw.tag & 0x3FF, section: sw.tag >> 10)
        let data = tableData!.item(for: indexPath)
        
        if data.key == Self.weatherLayerKey {
            if let band = data.obj(forKey: "band") as? OAWeatherBand {
                band.setSelect(sw.isOn)
                reloadDataWith(animated: true, completion: nil)
                
                //let bands: [Bool] = OAWeatherHelper.sharedInstance().bands.map{ $0.isBandVisible() }
                let allLayersAreDisabled = OAWeatherHelper.sharedInstance().allLayersAreDisabled//bands.allSatisfy({!$0})
                
                onChangeButtonIconAction?(allLayersAreDisabled)
            }
        }
        
        return false
    }
}
