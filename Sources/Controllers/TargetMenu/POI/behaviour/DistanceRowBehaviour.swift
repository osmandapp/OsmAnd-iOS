//
//  DistanceRowBehaviour.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 04/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class DistanceRowBehaviour: DefaultPoiAdditionalRowBehaviour {
    
    override func applyCommonRules(params: PoiRowParams) {
        super.applyCommonRules(params: params)
        
        let metricSystem = OAAppSettings.sharedManager().metricSystem.get()
        
        let valueAsFloatInMeters = (Float(params.value) ?? 0) * 1000
        var formattedValue = ""
        
        if metricSystem == .KILOMETERS_AND_METERS {
            formattedValue = params.value + " " + localizedString("km")
        } else {
            formattedValue = OAOsmAndFormatter.getFormattedDistance(valueAsFloatInMeters)
        }
        params.builder.text = formattedValue
        
        let prefix = params.builder.textPrefix
        params.builder.textPrefix = formatPrefix(prefix: prefix, units: localizedString("shared_string_distance"))
    }
}
