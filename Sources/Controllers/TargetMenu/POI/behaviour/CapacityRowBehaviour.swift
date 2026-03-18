//
//  CapacityRowBehaviour.swift
//  OsmAnd
//
//  Created by Max Kojin on 04/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class CapacityRowBehaviour: DefaultPoiAdditionalRowBehaviour {
    
    override func applyCommonRules(params: PoiRowParams) {
        super.applyCommonRules(params: params)
        
        guard Int(params.value) != nil else { return }
        
        let prefix = params.builder.textPrefix
        params.builder.textPrefix = formatPrefix(prefix: prefix,
                                                 units: localizedString("shared_string_capacity")
        )
    }
}
