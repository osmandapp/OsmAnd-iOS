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
        let visible = OAWidgetsVisibilityHelper.init().shouldShowTopCurrentLocationCoordinatesWidget()
        updateVisibility(visible: visible)

        if visible {
            if let lastKnownLocation = OsmAndApp.swiftInstance().locationServices.lastKnownLocation {
                showFormattedCoordinates(lat: lastKnownLocation.coordinate.latitude,
                                         lon: lastKnownLocation.coordinate.longitude)
            } else {
                showSearchingGpsMessage()
            }
        }
        return true
    }

    private func showSearchingGpsMessage() {
        firstIcon.isHidden = true
        divider.isHidden = true
        secondContainer.isHidden = true

//        let gpsInfo = locationProvider.getGPSInfo()
//        let message = "\(getString(R.string.searching_gps))… \(gpsInfo.usedSatellites)/\(gpsInfo.foundSatellites)"
        firstCoordinate.text = "message"
    }

}
