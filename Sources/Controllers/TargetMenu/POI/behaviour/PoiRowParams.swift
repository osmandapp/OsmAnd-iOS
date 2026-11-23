//
//  PoiRowParams.swift
//  OsmAnd
//
//  Created by Max Kojin on 01/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import OsmAndShared

final class PoiRowParams: NSObject {
    
    var builder: AmenityInfoRowParams.Builder 
    var poiType: OAPOIType?
    var rule: PoiAdditionalUiRule
    var key: String
    var value: String
    var subtype: String?
    var openingHoursCheckDate: String?
    var additionalInfo: AdditionalInfoBundle?
    
    init(builder: AmenityInfoRowParams.Builder, poiType: OAPOIType? = nil, rule: PoiAdditionalUiRule, key: String, value: String, subtype: String?, openingHoursCheckDate: String? = nil, additionalInfo: AdditionalInfoBundle? = nil) {
        self.builder = builder
        self.poiType = poiType
        self.rule = rule
        self.key = key
        self.value = value
        self.subtype = subtype
        self.openingHoursCheckDate = openingHoursCheckDate
        self.additionalInfo = additionalInfo
    }
}
