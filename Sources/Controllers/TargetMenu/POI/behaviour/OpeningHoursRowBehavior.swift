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
        let formattedValue = value.replacingOccurrences(of: ",", with: ", ")

        let collapsableView = OACollapsableLabelView(text: formattedValue, collapsed: true)
        if let collapsableView, let checkDate = CheckDateFormatter.format(params.openingHoursCheckDate) {
            let title = OAPOIHelper.sharedInstance().getPhraseByName(CHECK_DATE_TAG) ?? ""
            let caption = String(format: localizedString("ltr_or_rtl_combine_via_colon"), title, checkDate)
            let text = NSMutableAttributedString(string: formattedValue, attributes: [
                .font: UIFont.preferredFont(forTextStyle: .subheadline),
                .foregroundColor: UIColor.textColorPrimary
            ])
            text.append(NSAttributedString(string: "\n" + caption, attributes: [
                .font: UIFont.preferredFont(forTextStyle: .footnote),
                .foregroundColor: UIColor.textColorSecondary
            ]))
            collapsableView.label.attributedText = text
        }
        params.builder.collapsableView = collapsableView
        
        if let openingHours = OAOpeningHoursParser(string: value) {
            value = openingHours.toLocalString()
            params.builder.textColor = openingHours.getColor()
        }
        params.builder.text = value.replacingOccurrences(of: "; ", with: "\n")
    }
}
