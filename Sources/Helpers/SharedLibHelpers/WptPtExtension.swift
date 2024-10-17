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
    
    func getAmenity() -> OAPOI? {
        let extensionsToRead = getExtensionsToRead()
        guard extensionsToRead.count > 0 else {
            return nil
        }
        
        return OAPOI.fromTagValue(extensionsToRead, privatePrefix: "amenity_", osmPrefix: "osm_tag_")
    }
    
    func setAmenity(_ amenity: OAPOI?) {
        guard let amenity else {
            return
        }
        
        guard let extensions = amenity.toTagValue("amenity_", osmPrefix: "osm_tag_"), !extensions.keys.isEmpty else {
            return
        }
        
        extensionsWriters?.addEntries(from: extensions)
    }
}
