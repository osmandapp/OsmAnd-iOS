//
//  OpeningHoursRowBehavior.swift
//  OsmAnd
//
//  Created by Max Kojin on 04/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class OpeningHoursRowBehavior: DefaultPoiAdditionalRowBehaviour {
    
    override func applyCustomRules(params: PoiRowParams) {
        var value = params.value
        var formattedValue = value.replacingOccurrences(of: "; ", with: "\n")
        formattedValue = value.replacingOccurrences(of: ",", with: ", ")
        
        let collapsableView = OACollapsableLabelView(frame: CGRect(x: 0, y: 0, width: 320, height: 100))
        collapsableView.setText(formattedValue)
        params.builder.collapsableView = collapsableView
        
        if let openingHours = OAOpenedHoursParser(string: value) {
            value = openingHours.toLocalString()
            params.builder.textColor = openingHours.getColor()
        }
        params.builder.text = value.replacingOccurrences(of: "; ", with: "\n")
    }
}
