//
//  PoiRowParams.swift
//  OsmAnd
//
//  Created by Max Kojin on 01/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class PoiRowParams: NSObject {
    
    //TODO: clean code
//    val app: OsmandApplication,
//    val context: Context,
    
    var builder: AmenityInfoRowParams.Builder 
//    var menuBuilder: MenuBuilder
    var poiType: OAPOIType?
    var rule: PoiAdditionalUiRule
    var key: String
    var value: String
    var subtype: String?
    
    init(builder: AmenityInfoRowParams.Builder, poiType: OAPOIType? = nil, rule: PoiAdditionalUiRule, key: String, value: String, subtype: String?) {
        self.builder = builder
        self.poiType = poiType
        self.rule = rule
        self.key = key
        self.value = value
        self.subtype = subtype
    }
}
