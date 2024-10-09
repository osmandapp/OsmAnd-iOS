//
//  WptPtExtension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 02.10.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import OsmAndShared

@objc(OASWptPt)
extension WptPt {

    var position: CLLocationCoordinate2D {
        get {
            CLLocationCoordinate2DMake(lat, lon)
        }
        set {
            self.lat = newValue.latitude
            self.lon = newValue.longitude
        }
    }
}
