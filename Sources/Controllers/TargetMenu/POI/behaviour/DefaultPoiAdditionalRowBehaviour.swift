//
//  DefaultPoiAdditionalRowBehaviour.swift
//  OsmAnd
//
//  Created by Max Kojin on 01/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class DefaultPoiAdditionalRowBehaviour: IPoiAdditionalRowBehavior {
    
    func applyCustomRules(params: PoiRowParams) {
        
        //TODO: check it changes original variable! ([in-out])
        
        if let iconName = params.rule.customIconName {
            params.builder.iconName = iconName
        }
        if let prefix = params.rule.customTextPrefix {
            params.builder.textPrefix = localizedString(prefix)
        }
        params.builder.isWiki = params.rule.isWikipedia
        params.builder.needLinks = params.rule.isNeedLinks
        params.builder.isPhoneNumber = params.rule.isPhoneNumber
    }
    
    func applyCommonRules(params: PoiRowParams) {
        
        //TODO: check it changes original variable! ([in-out])
        
        var isUrl = params.rule.isUrl || WikiAlgorithms.isUrl(params.value)
        if let hiddenUrl = AmenityUIHelper.getSocialMediaUrl(key: params.key, value: params.value) {
            params.builder.hiddenUrl = hiddenUrl
            isUrl = true
        }
        params.builder.isUrl = isUrl
        
        if let poiType = params.poiType {
            params.builder.order = Int(poiType.order)
            params.builder.name = poiType.name
            params.builder.isText = poiType.isText
        }
        
        // try to fetch appropriate icon, text and textPrefix based on poi additional type
        // (if this parameters was not predefined)
        
        
        
        
        //TODO: implement
    }
    
    func getIconName() {
        //TODO: implement
    }
    
    func formatPrefix(prefix: String?, units: String) -> String {
        if let prefix, !prefix.isEmpty {
            return "\(prefix) \(units)"
        } else {
            return units
        }
    }
}
