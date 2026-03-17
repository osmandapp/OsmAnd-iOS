//
//  LiquidCapacityRowBehaviour.swift
//  OsmAnd
//
//  Created by Max Kojin on 04/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class LiquidCapacityRowBehaviour: DefaultPoiAdditionalRowBehaviour {
   
    override func applyCustomRules(params: PoiRowParams) {
        super.applyCustomRules(params: params)
        
        if params.subtype == "water_tower" || params.subtype == "storage_tank" {
            params.builder.text = params.value + " " + localizedString("cubic_m")
        }
    }
}
