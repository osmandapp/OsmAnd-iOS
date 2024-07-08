//
//  WeatherContoursButton.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 08.07.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
final class WeatherContoursButton: OAHudButton {
    
    var onTapMenuAction: (() -> Void)?
    
    // swiftlint:disable force_unwrapping
    private let app = OsmAndApp.swiftInstance()!
    private let styleSettings = OAMapStyleSettings.sharedInstance()!
    // swiftlint:enable force_unwrapping
    
    func configure() {
        showsMenuAsPrimaryAction = true
        menu = createContourMenu()
    }
    
    private func createContourMenu() -> UIMenu {
        let none = UIAction(title: localizedString("shared_string_none"), image: UIImage(named: "ic_custom_contour_lines_disabled")?.withTintColor(.black)) { [weak self] _ in
            self?.disableContourLayer()
        }
        
        let temperature = UIAction(title: localizedString("map_settings_weather_temp"), image: UIImage(named: "ic_custom_thermometer")?.withTintColor(.black)) { [weak self] _ in
            self?.updateContourLayer(WEATHER_TEMP_CONTOUR_LINES_ATTR)
        }
        
        let pressure = UIAction(title: localizedString("map_settings_weather_pressure"), image: UIImage(named: "ic_custom_air_pressure")?.withTintColor(.black)) { [weak self] _ in
            self?.updateContourLayer(WEATHER_PRESSURE_CONTOURS_LINES_ATTR)
        }
        
        let wind = UIAction(title: localizedString("map_settings_weather_wind"), image: UIImage(named: "ic_custom_wind")?.withTintColor(.black)) { [weak self] _ in
            self?.updateContourLayer(WEATHER_WIND_CONTOURS_LINES_ATTR)
        }
        
        let cloud = UIAction(title: localizedString("map_settings_weather_cloud"), image: UIImage(named: "ic_custom_clouds")?.withTintColor(.black)) { [weak self] _ in
            self?.updateContourLayer(WEATHER_CLOUD_CONTOURS_LINES_ATTR)
        }
        
        let precipitation = UIAction(title: localizedString("map_settings_weather_precip"), image: UIImage(named: "ic_custom_precipitation")?.withTintColor(.black)) { [weak self] _ in
            self?.updateContourLayer(WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR)
        }
        
        let contourName = app.data.contourName ?? ""
        let isEnabled = styleSettings.isAnyWeatherContourLinesEnabled() || !contourName.isEmpty
        
        if isEnabled {
            if styleSettings.isWeatherContourLinesEnabled(WEATHER_TEMP_CONTOUR_LINES_ATTR) || contourName == WEATHER_TEMP_CONTOUR_LINES_ATTR {
                temperature.state = .on
            } else if styleSettings.isWeatherContourLinesEnabled(WEATHER_PRESSURE_CONTOURS_LINES_ATTR) || contourName == WEATHER_PRESSURE_CONTOURS_LINES_ATTR {
                pressure.state = .on
            } else if styleSettings.isWeatherContourLinesEnabled(WEATHER_CLOUD_CONTOURS_LINES_ATTR) || contourName == WEATHER_CLOUD_CONTOURS_LINES_ATTR {
                cloud.state = .on
            } else if styleSettings.isWeatherContourLinesEnabled(WEATHER_WIND_CONTOURS_LINES_ATTR) || contourName == WEATHER_WIND_CONTOURS_LINES_ATTR {
                wind.state = .on
            } else if styleSettings.isWeatherContourLinesEnabled(WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR) || contourName == WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR {
                precipitation.state = .on
            } else {
                none.state = .on
            }
        } else {
            none.state = .on
        }
        
        var menuElements: [UIMenuElement] = [temperature, precipitation, wind, cloud, pressure]
        
        let menu = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: [none] + menuElements)
        
        return menu
    }
    
    private func updateContourLayer(_ contoursType: String) {
        app.data.contourName = contoursType
        app.data.contourNameLastUsed = contoursType
        styleSettings.setWeatherContourLinesEnabled(true, weatherContourLinesAttr: contoursType)
        onTapMenuAction?()
    }
    
    private func disableContourLayer() {
        app.data.contourName = ""
        app.data.contourNameLastUsed = WEATHER_NONE_CONTOURS_LINES_VALUE
        styleSettings.setWeatherContourLinesEnabled(false, weatherContourLinesAttr: WEATHER_NONE_CONTOURS_LINES_VALUE)
        onTapMenuAction?()
    }
}
