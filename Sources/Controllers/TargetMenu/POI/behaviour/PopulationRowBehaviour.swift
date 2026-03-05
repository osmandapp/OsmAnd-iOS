//
//  PopulationRowBehaviour.swift
//  OsmAnd
//
//  Created by Max Kojin on 04/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class PopulationRowBehaviour: DefaultPoiAdditionalRowBehaviour {
   
    override func applyCustomRules(params: PoiRowParams) {
        super.applyCustomRules(params: params)
        
        var formatted = params.value
        if let valueAsNumber = Int(params.value) {
            
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.numberStyle = .decimal
            formatter.usesGroupingSeparator = true
            formatter.groupingSeparator = " "
            formatter.maximumFractionDigits = 0

            if let result = formatter.string(from: NSNumber(value: valueAsNumber)) {
                formatted = result
            }
        }
        
        params.builder.text = formatted
    }
}
