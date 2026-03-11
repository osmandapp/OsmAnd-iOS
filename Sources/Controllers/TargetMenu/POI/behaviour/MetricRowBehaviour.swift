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
        super.applyCustomRules(params: params)

        guard let value = Double(params.value), value > 0 else {
            params.builder.text = params.value
            return
        }
        
        let metricSystem = OAAppSettings.sharedManager().metricSystem.get()

        let text: String

        switch metricSystem {
        case .MILES_AND_FEET, .NAUTICAL_MILES_AND_FEET:
            let feet = value * FEET_IN_ONE_METER
            text = "\(formatter.string(from: NSNumber(value: feet)) ?? "") \(localizedString("foot"))"

        case .MILES_AND_YARDS:
            let yards = value * YARDS_IN_ONE_METER
            text = "\(formatter.string(from: NSNumber(value: yards)) ?? "") \(localizedString("yard"))"

        default:
            text = "\(params.value) \(localizedString("m"))"
        }

        params.builder.text = text
    }
}
