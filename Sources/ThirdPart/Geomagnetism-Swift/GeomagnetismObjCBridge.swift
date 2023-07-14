//
//  GeomagnetismObjCBridge.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 11.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//


/*
    Replacing of Android's "GeomagneticField" class.
 
    Documentation says: This uses the World Magnetic Model produced by the United States National Geospatial-Intelligence Agency.
    https://developer.android.com/reference/android/hardware/GeomagneticField
    
    Their site has a list of different libs in "Third-Party Software" section.
    https://www.ncei.noaa.gov/products/world-magnetic-model
    
    We're using a lib for Swift language.
    https://github.com/kanchudeep/Geomagnetism-Swift
 
    TODO:
    Update this lib file after 2025 year.
    Espesially this array with all geomagnetic data:
        private static let WMM_COF:[String] = [ ... ]
 
    Documentation says about model: This class currently uses WMM-2020 which is valid until 2025, but should produce acceptable results for several years after that.
 */


import Foundation

@objc(OAGeomagneticField)
@objcMembers
class GeomagnetismObjCBridge : NSObject {
    
    private var geomagnetism : Geomagnetism
    
    init(longitude:Double, latitude:Double, altitude:Double, date:Date) {
        self.geomagnetism = Geomagnetism.init(longitude: longitude, latitude: latitude, date: date)
    }
    
    func declination() -> Double {
        return geomagnetism.declination
    }
}
