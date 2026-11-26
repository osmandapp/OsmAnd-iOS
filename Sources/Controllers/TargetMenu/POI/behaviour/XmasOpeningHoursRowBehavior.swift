//
//  XmasOpeningHoursRowBehavior.swift
//  OsmAnd
//
//  Created by Kseniia Velychko on 18/11/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import OsmAndShared

final class XmasOpeningHoursRowBehavior: DefaultPoiAdditionalRowBehaviour {

    override func applyCustomRules(params: PoiRowParams) {
        super.applyCustomRules(params: params)
        params.builder.text = getText(value: params.value, season: params.additionalInfo?.getFilteredInfo()[XMAS_DAY_DATE_TAG])
    }

    private func getText(value: String, season: String?) -> String {
        let openingHours = isEveryRuleParsed(value) ? OAOpeningHoursParser(string: value) : nil
        let hours = (openingHours?.toLocalString() ?? value).replacingOccurrences(of: "; ", with: "\n")
        guard let season, !season.isEmpty else { return hours }

        return hours + "\n" + season
    }

    private func isEveryRuleParsed(_ value: String) -> Bool {
        value.components(separatedBy: SEPARATOR)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .allSatisfy { OAOpeningHoursParser(string: $0) != nil }
    }
}
