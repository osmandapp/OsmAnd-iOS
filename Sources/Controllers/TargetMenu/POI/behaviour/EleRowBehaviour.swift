//
//  EleRowBehaviour.swift
//  OsmAnd
//
//  Created by Max Kojin on 04/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class EleRowBehaviour: DefaultPoiAdditionalRowBehaviour {
    
    override func applyCustomRules(params: PoiRowParams) {
        super.applyCustomRules(params: params)
        
        var value = params.value
        let altitudeMetrics = OAAppSettings.sharedManager().altitudeMetric.get()
        
        if let distance = Double(params.value) {
            value = OAOsmAndFormatter.getFormattedAlt(distance)
            
            var collapsibleVal = ""
            if altitudeMetrics == .FEET {
                collapsibleVal = OAOsmAndFormatter.getFormattedAlt(distance, mc: .METERS)
            } else {
                collapsibleVal = OAOsmAndFormatter.getFormattedAlt(distance, mc: .FEET)
            }
            
            let collapsableView = OACollapsableLabelView(text: collapsibleVal, collapsed: true)
            params.builder.collapsableView = collapsableView
        }
        
        params.builder.text = value
    }
}
