//
//  CoordinatesCurrentLocationWidget.swift
//  OsmAnd Maps
//
//  Created by Skalii on 24.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@objc(OACoordinatesCurrentLocationWidget)
@objcMembers
final class CoordinatesCurrentLocationWidget: CoordinatesBaseWidget {
    
    init(customId: String?, appMode: OAApplicationMode, widgetParams: [String: Any]? = nil) {
        super.init(type: .coordinatesCurrentLocation,
                   customId: customId,
                   appMode: appMode,
                   widgetParams: widgetParams)
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
        UIImage.widgetCoordinatesLocation
    }
}
