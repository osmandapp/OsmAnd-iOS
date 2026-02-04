//
//  MetricRowBehaviour.swift
//  OsmAnd
//
//  Created by Max Kojin on 04/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class MetricRowBehaviour: DefaultPoiAdditionalRowBehaviour {
    
    private let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        f.roundingMode = .ceiling
        return f
    }()
    
    override func applyCustomRules(params: PoiRowParams) {
        let metricSystem = OAAppSettings.sharedManager().metricSystem.get()
        
        if let valueAsDouble = Double(params.value), valueAsDouble > 0 {
            var formattedValue = ""
            
            switch metricSystem {
            case .MILES_AND_FEET, .NAUTICAL_MILES_AND_FEET:
                formattedValue = (formatter.string(from: NSNumber(value:valueAsDouble * FEET_IN_ONE_METER)) ?? "") + " " + localizedString("foot")
            case .MILES_AND_YARDS:
                formattedValue = (formatter.string(from: NSNumber(value:valueAsDouble * YARDS_IN_ONE_METER)) ?? "") + " " + localizedString("yard")
            default:
                formattedValue = "\(params.value) " + localizedString("m")
            }
            
            params.builder.text = formattedValue
        } else {
            params.builder.text = params.value
        }
    }
}
