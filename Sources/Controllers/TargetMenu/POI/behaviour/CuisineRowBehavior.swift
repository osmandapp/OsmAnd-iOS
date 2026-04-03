//
//  CuisineRowBehavior.swift
//  OsmAnd
//
//  Created by Max Kojin on 04/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class CuisineRowBehavior: DefaultPoiAdditionalRowBehaviour {
    
    override func applyCustomRules(params: PoiRowParams) {
        super.applyCustomRules(params: params)
        
        let helper = OAPOIHelper.sharedInstance()
        
        let cuisines = params.value
            .split(separator: ";")
            .compactMap { helper.translation("cuisine_\($0)", withDefault: true) }
        
        params.builder.text = cuisines
            .enumerated()
            .map { $0 == 0 ? $1 : $1.lowercased() }
            .joined(separator: ", ")
    }
}
