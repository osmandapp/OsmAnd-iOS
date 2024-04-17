//
//  CoordinatesCurrentLocationWidget.swift
//  OsmAnd Maps
//
//  Created by Skalii on 24.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OACoordinatesCurrentLocationWidget)
@objcMembers
class CoordinatesCurrentLocationWidget: CoordinatesBaseWidget {

    init() {
        super.init(type: .coordinatesCurrentLocation)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func updateInfo() -> Bool {
        let visible = OAWidgetsVisibilityHelper.sharedInstance().shouldShowTopCoordinatesWidget()
        updateVisibility(visible: visible)

        if visible {
            if let lastKnownLocation = OsmAndApp.swiftInstance().locationServices?.lastKnownLocation {
                showFormattedCoordinates(lat: lastKnownLocation.coordinate.latitude,
                                         lon: lastKnownLocation.coordinate.longitude)
            }
        }
        return true
    }

    override func getCoordinateIcon() -> UIImage {
        let iconId = "widget_coordinates_location"
        return UIImage.init(named: iconId)!
    }
}
