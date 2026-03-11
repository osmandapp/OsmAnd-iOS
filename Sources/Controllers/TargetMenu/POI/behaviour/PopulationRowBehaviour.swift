//
//  PopulationRowBehaviour.swift
//  OsmAnd
//
//  Created by Max Kojin on 04/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class PopulationRowBehaviour: DefaultPoiAdditionalRowBehaviour {

    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US")
        f.numberStyle = .decimal
        f.usesGroupingSeparator = true
        f.groupingSeparator = " "
        f.maximumFractionDigits = 0
        return f
    }()

    override func applyCustomRules(params: PoiRowParams) {
        super.applyCustomRules(params: params)

        guard let value = Int(params.value),
              let formatted = Self.formatter.string(from: NSNumber(value: value)) else {
            params.builder.text = params.value
            return
        }

        params.builder.text = formatted
    }
}
