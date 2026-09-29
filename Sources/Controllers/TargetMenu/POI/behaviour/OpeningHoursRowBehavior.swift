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
        let formattedValue = value.replacingOccurrences(of: "; ", with: "\n").replacingOccurrences(of: ",", with: ", ")

        if let checkDate = OpeningHoursCheckDateFormatter.format(params.openingHoursCheckDate) {
            let caption = String(format: localizedString("ltr_or_rtl_combine_via_colon"), localizedString("opening_hours_check_date"), checkDate)
            params.builder.collapsableView = OpeningHoursCollapsableView(checkDate: caption, collapsed: true)
        } else {
            params.builder.collapsableView = OACollapsableLabelView(text: formattedValue, collapsed: true)
        }
        
        if let openingHours = OAOpeningHoursParser(string: value) {
            value = openingHours.toLocalString()
            params.builder.textColor = openingHours.getColor()
        }
        params.builder.text = value.replacingOccurrences(of: "; ", with: "\n")
    }
}
