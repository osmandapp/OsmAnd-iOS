//
//  DefaultPoiAdditionalRowBehaviour.swift
//  OsmAnd
//
//  Created by Max Kojin on 01/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

class DefaultPoiAdditionalRowBehaviour: IPoiAdditionalRowBehavior {
    
    func applyCustomRules(params: PoiRowParams) {
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
        var isUrl = params.rule.isUrl || WikiAlgorithms.isUrl(params.value)
        if let hiddenUrl = AmenityUIHelper.getSocialMediaUrl(key: params.key, value: params.value) {
            if !params.builder.hasHiddenUrl() && !isUrl && params.builder.isNeedLinks() {
                params.builder.hiddenUrl = hiddenUrl
                isUrl = true
            }
        }
        params.builder.isUrl = isUrl
        
        if let poiType = params.poiType {
            params.builder.order = Int(poiType.order)
            params.builder.name = poiType.name
            params.builder.isText = poiType.isText
        }
        
        // try to fetch appropriate icon, text and textPrefix based on poi additional type
        // (if this parameters was not predefined)
        
        if !params.builder.hasIcon() { // if icon wasn't predefined
            
            //TODO: debug it
//            var iconName = getIconName(key: params.poiType?.iconName())
            var iconName = getIconName(key: params.poiType?.iconKeyName())
            
            if iconName == nil {
                let category = params.poiType?.getOsmTag().replacingOccurrences(of: ":", with: "_")
                if let category, !category.isEmpty {
                    iconName = getIconName(key: category)
                }
                
                if let parentType = params.poiType?.parentType as? OAPOIType {
                    if iconName == nil {
                        iconName = getIconName(key: parentType.iconName())
                        if iconName == nil {
                            var parentIconName = "\(parentType.getOsmTag() ?? "")_\(category ?? "")_\(parentType.getOsmValue() ?? "")"
                            
                            if UIImage(named: parentIconName) == nil {
                                parentIconName = "\(parentType.getOsmTag() ?? "")_\(parentType.getOsmValue() ?? "")"
                                params.builder.iconName = parentIconName
                            }
                            iconName = parentIconName
                        }
                    }
                }
            }
            params.builder.iconName = iconName
            if !params.builder.hasIcon() {
                params.builder.iconName = "ic_custom_info_outlined"
            }
        }
        
        let isTextPredefined = params.builder.hasTextPrefix() || params.builder.hasText()
        if !params.builder.hasTextPrefix() || !params.builder.hasText() {
            if let poiType = params.poiType {
                let translation = poiType.nameLocalized
                if poiType.isText {
                    params.builder.setTextPrefixIfNotPresent(translation)
                    params.builder.setTextIfNotPresent(params.value)
                } else if let translation, translation.contains(":") {
                    let parts = translation.components(separatedBy: ":")
                    params.builder.setTextPrefixIfNotPresent(parts[0].trimWhitespaces())
                    params.builder.setTextIfNotPresent(OAUtilities.capitalizeFirstLetter(parts[0].trimWhitespaces()))
                } else {
                    params.builder.setTextIfNotPresent(translation)
                }
            }
        }
        
        if let textPrefix = params.builder.textPrefix {
            if !isTextPredefined && textPrefix.contains(" (") {
                let prefixParts = textPrefix.components(separatedBy: " (")
                if prefixParts.count == 2 {
                    var text = String(format: localizedString("ltr_or_rtl_combine_via_colon"), prefixParts[0], prefixParts[1])
                    text = OAUtilities.capitalizeFirstLetter(text) ?? ""
                    text = text.replacingOccurrences(of: "[()]", with: "", options: .regularExpression)
                    params.builder.textPrefix = text
                }
            }
        }
    }
    
    func getIconName(key: String?) -> String? {
        
        //TODO: debug it. invalid icon "mx_height"
        
        guard let key else { return nil }
        var iconName = key
        
        if !iconName.hasPrefix("mx_") {
            iconName = "mx_\(key)"
        }
        
        if OAUtilities.getMxIcon(iconName) != nil || UIImage.templateImageNamed(iconName) != nil {
            return iconName
        }
        return nil
    }
    
    func formatPrefix(prefix: String?, units: String) -> String {
        if let prefix, !prefix.isEmpty {
            return "\(prefix) \(units)"
        } else {
            return units
        }
    }
}
