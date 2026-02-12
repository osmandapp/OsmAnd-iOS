//
//  OpeningHoursRowBehavior.swift
//  OsmAnd
//
//  Created by Max Kojin on 04/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class OpeningHoursRowBehavior: DefaultPoiAdditionalRowBehaviour {
    
    override func applyCustomRules(params: PoiRowParams) {
        super.applyCustomRules(params: params)
        
        var value = params.value
        var formattedValue = value.replacingOccurrences(of: "; ", with: "\n")
        formattedValue = value.replacingOccurrences(of: ",", with: ", ")

        let collapsableView = OACollapsableLabelView(text: formattedValue, collapsed: true)
        params.builder.collapsableView = collapsableView
        
        if let openingHours = OAOpenedHoursParser(string: value) {
            value = openingHours.toLocalString()
            params.builder.textColor = openingHours.getColor()
        }
        params.builder.text = value.replacingOccurrences(of: "; ", with: "\n")
    }
}
