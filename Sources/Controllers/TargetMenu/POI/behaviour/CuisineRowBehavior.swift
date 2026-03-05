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
        
        var sb = ""
        let cuisines = params.value.components(separatedBy: ";")
        
        for name in cuisines {
            if let translation = OAPOIHelper.sharedInstance().getTranslation("cuisine_" + name) {
                if !sb.isEmpty {
                    sb += ", "
                    sb += translation.lowercased()
                } else {
                    sb += translation
                }
            }
        }
        
        params.builder.text = sb
    }
}
