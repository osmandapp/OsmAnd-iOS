//
//  CoordinatesMapCenterWidget.swift
//  OsmAnd Maps
//
//  Created by Skalii on 24.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OACoordinatesMapCenterWidget)
@objcMembers
class CoordinatesMapCenterWidget: CoordinatesBaseWidget {

    init() {
        super.init(type: .coordinatesMapCenter)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func updateInfo() -> Bool {
        let visible = OAWidgetsVisibilityHelper.init().shouldShowTopMapCenterCoordinatesWidget()
        let loc: CLLocation = OARootViewController.instance().mapPanel.mapViewController.getMapLocation()

        updateVisibility(visible: visible)
        if visible {
            showFormattedCoordinates(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
        }
        return true
    }

    override func getUtmIcon() -> UIImage {
        let utmIconId = OAAppSettings.sharedManager().nightMode
            ? "widget_coordinates_map_center_utm_night"
            : "widget_coordinates_map_center_utm_day"
        return UIImage.init(named: utmIconId)!
    }

    override func getLatitudeIcon(lat: Double) -> UIImage {
        let latDayIconId = lat >= 0
            ? "widget_coordinates_map_center_latitude_north_day"
            : "widget_coordinates_map_center_latitude_south_day"
        let latNightIconId = lat >= 0
            ? "widget_coordinates_map_center_latitude_north_night"
            : "widget_coordinates_map_center_latitude_south_night"
        let latIconId = OAAppSettings.sharedManager().nightMode ? latNightIconId : latDayIconId
        return UIImage.init(named: latIconId)!
    }

    override func getLongitudeIcon(lon: Double) -> UIImage {
        let lonDayIconId = lon >= 0
            ? "widget_coordinates_map_center_longitude_east_day"
            : "widget_coordinates_map_center_longitude_west_day"
        let lonNightIconId = lon >= 0
            ? "widget_coordinates_map_center_longitude_east_night"
            : "widget_coordinates_map_center_longitude_west_night"
        let lonIconId = OAAppSettings.sharedManager().nightMode ? lonNightIconId : lonDayIconId
        return UIImage.init(named: lonIconId)!
    }

}
