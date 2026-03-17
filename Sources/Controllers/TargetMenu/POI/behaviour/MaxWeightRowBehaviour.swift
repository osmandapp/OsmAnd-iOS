//
//  MaxWeightRowBehaviour.swift
//  OsmAnd
//
//  Created by Max Kojin on 04/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class MaxWeightRowBehaviour: DefaultPoiAdditionalRowBehaviour {
   
    override func applyCustomRules(params: PoiRowParams) {
        super.applyCustomRules(params: params)
        
        guard Int(params.value) != nil else { return }
         
        params.builder.text = "\(params.value) \(localizedString("metric_ton"))"
    }
}
