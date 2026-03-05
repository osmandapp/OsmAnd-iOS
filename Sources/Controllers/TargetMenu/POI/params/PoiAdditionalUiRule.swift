//
//  PoiAdditionalUiRule.swift
//  OsmAnd
//
//  Created by Max Kojin on 03/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class PoiAdditionalUiRule: NSObject {
    
    var key: String
    var customIconName: String?
    var customTextPrefix: String?
    var isUrl: Bool = false
    var isWikipedia: Bool = false
    var isNeedLinks: Bool = true
    var isPhoneNumber: Bool = false
    var checkBaseKey: Bool = true
    var checkKeyOnContains: Bool = false
    var behavior: IPoiAdditionalRowBehavior? = DefaultPoiAdditionalRowBehaviour()
    
    init(key: String) {
        self.key = key
    }
    
    func apply(builder: AmenityInfoRowParams.Builder, poiType: OAPOIType, key: String, value: String, subtype: String?) {
        let params = PoiRowParams(builder: builder, poiType: poiType, rule: self, key: key, value: value, subtype: subtype)
        apply(params: params)
    }
    
    func apply(params: PoiRowParams) {
        behavior?.applyCustomRules(params: params)
        behavior?.applyCommonRules(params: params)
    }
}
