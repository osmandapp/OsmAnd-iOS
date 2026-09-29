//
//  CoordinatesMapCenterWidget.swift
//  OsmAnd Maps
//
//  Created by Skalii on 24.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@objc(OACoordinatesMapCenterWidget)
@objcMembers
final class CoordinatesMapCenterWidget: CoordinatesBaseWidget {

    init(customId: String?, appMode: OAApplicationMode, widgetParams: [String: Any]? = nil) {
        super.init(type: .coordinatesMapCenter,
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
        let loc: CLLocation = OARootViewController.instance().mapPanel.mapViewController.getMapLocation()

        updateVisibility(visible: visible)
        if visible {
            showFormattedCoordinates(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
        }
        return true
    }

    override func getCoordinateIcon() -> UIImage {
        UIImage.widgetCoordinatesMapCenter
    }
}
