//
//  UsMapsRecreationAreaRowBehaviour.swift
//  OsmAnd
//
//  Created by Max Kojin on 04/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class UsMapsRecreationAreaRowBehaviour: DefaultPoiAdditionalRowBehaviour {
   
    override func applyCustomRules(params: PoiRowParams) {
        super.applyCustomRules(params: params)
        
        if let translatedUsMapsKey = OAPOIHelper.sharedInstance().getTranslation(params.key), !translatedUsMapsKey.isEmpty {
            params.builder.textPrefix = translatedUsMapsKey
        } else {
            params.builder.textPrefix = OAUtilities.capitalizeFirstLetter(params.key)
        }
    }
}
