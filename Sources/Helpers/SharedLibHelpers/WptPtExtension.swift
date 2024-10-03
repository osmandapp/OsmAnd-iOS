//
//  WptPtExtension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 02.10.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import OsmAndShared

private var wptTypeKey: UInt8 = 0

@objc(OASWptPt)
extension WptPt {
    
    var type: String? {
        get {
            objc_getAssociatedObject(self, &wptTypeKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &wptTypeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
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
