//
//  WeatherDataSourceViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 26.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
final class WeatherSourceObjWrapper: NSObject {

    static func getTitleFor(type: WeatherSource) -> String {
        type.title
    }

    static func getDescriptionFor(type: WeatherSource) -> String {
        type.description
    }

    static func getSettingValueFor(type: WeatherSource) -> String {
        type.settingValue
    }
    
    static func getDefaultSource() -> WeatherSource {
        WeatherSource.getDefaultSource()
    }
    
    static func getTitleForSource(type: WeatherSource) -> String {
        WeatherSource.getDefaultSource().title
    }
    
    static func getWeatherSourceBySettingsValue(string: String) -> WeatherSource {
        WeatherSource.getWeatherSourceBySettingsValue(settingsValue: string)
    }
}


@objc enum WeatherSource: Int, CaseIterable {
    case gfs
    case ecmwf
    
    var title: String {
        switch self {
        case .gfs: localizedString("weather_source_GFS_title")
        case .ecmwf: localizedString("weather_source_ecmwf_title")
        }
    }
    
    var description: String {
        switch self {
        case .gfs: localizedString("weather_source_GFS_description")
        case .ecmwf: localizedString("weather_source_ecmwf_description")
        }
    }
    
    var settingValue: String {
        switch self {
        case .gfs: "gfs"
        case .ecmwf: "ecmwf"
        }
    }
    
    static func getDefaultSource() -> WeatherSource {
        .gfs
    }
    
    static func getWeatherSourceBySettingsValue(settingsValue: String) -> WeatherSource {
        switch settingsValue {
        case "gfs": .gfs
        case "ecmwf": .ecmwf
        default: getDefaultSource()
        }
    }
}

@objcMembers
final class WeatherDataSourceViewController: OABaseNavbarViewController {
    
    override func getTitle() -> String {
        localizedString("data_source")
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_cancel")
    }
    
    override func isNavbarSeparatorVisible() -> Bool {
        false
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func getTableHeaderDescription() -> String {
        localizedString("weather_data_sources_prompt")
    }

    // MARK: Table data

    override func generateData() {
        tableData.clearAllData()
        let section = tableData.createNewSection()
        let weatherSourceID = OsmAndApp.swiftInstance().data.weatherSource
        
        for source in WeatherSource.allCases {
            let row = section.createNewRow()
            let isSelected = weatherSourceID == source.settingValue
            row.setObj(source, forKey: "weatherSource")
            row.setObj(isSelected, forKey: "isSelected")
        }
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if let weatherSource = item.obj(forKey: "weatherSource") as? WeatherSource {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
            cell.tintColor = .iconColorActive
            let isSelected = item.obj(forKey: "isSelected") as? Bool ?? false
            cell.descriptionLabel.text = weatherSource.description
            cell.descriptionVisibility(true)
            cell.titleLabel.text = weatherSource.title
            cell.leftIconView.image = isSelected ? UIImage.templateImageNamed("ic_checkmark_default") : nil
            cell.leftIconView.tintColor = .iconColorActive
            cell.accessibilityLabel = cell.titleLabel.text
            cell.accessibilityValue = localizedString(isSelected ? "shared_string_selected" : "shared_string_not_selected")
            return cell
        }
        return nil
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if let weatherSource = item.obj(forKey: "weatherSource") as? WeatherSource {
            OsmAndApp.swiftInstance().data.weatherSource = weatherSource.settingValue
            reloadDataWith(animated: true, completion: nil)
        }
    }
}
