//
//  AmenityUIHelper.swift
//  OsmAnd
//
//  Created by Max Kojin on 02/10/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class AmenityUIHelper: NSObject {
    
    static let defaultAmenityIconName = "ic_custom_info_outlined"
    
    private static let CUISINE_INFO_ID = COLLAPSABLE_PREFIX + "cuisine"
    private static let DISH_INFO_ID = COLLAPSABLE_PREFIX + "dish"
    private static let US_MAPS_RECREATION_AREA = "us_maps_recreation_area"
    
    private let helper: OAPOIHelper
    
    private var additionalInfo: AdditionalInfoBundle
    
    private var preferredLang: String
    private var wikiAmenity: OAPOI?
    private var poiCategory: OAPOICategory?
    private var poiType: OAPOIType?
    private var subtype: String?
    
    private var cuisineRow: OAAmenityInfoRow?
    private var poiAdditionalCategories = [String: [OAPOIType]]()
    private var collectedPoiTypes = [String: [OAPOIType]]()
    private var osmEditingEnabled = OAPluginsHelper.isEnabled(OAOsmEditingPlugin.self) // PluginsHelper.isActive(OsmEditingPlugin.class);
    private var lastBuiltRowIsDescription = false
    
    private var showDefaultTags = false // TODO: in parent class MenuBuilder
    
    init(preferredLang: String, infoBundle: AdditionalInfoBundle) {
        self.preferredLang = preferredLang
        self.additionalInfo = infoBundle
        self.helper = OAPOIHelper.sharedInstance()
        super.init()
    }
    
    func initVariables() {
        poiCategory = nil
        if let typeTag = additionalInfo.get(POITYPE), !typeTag.isEmpty {
            poiCategory = helper.getPoiCategory(byName: typeTag)
        }
        if poiCategory == nil {
            poiCategory = helper.otherPoiCategory
        }
        
        subtype = additionalInfo.get(SUBTYPE)
        cuisineRow = nil
        poiAdditionalCategories = [:]
        collectedPoiTypes = [:]
        osmEditingEnabled = OAPluginsHelper.isEnabled(OAOsmEditingPlugin.self)
    }
    
    func setPreferredLang(_ lang: String) {
        preferredLang = lang
    }
    
    func buildInternal() -> [OAAmenityInfoRow] {
        initVariables()
        var infoRows = [OAAmenityInfoRow]()
        var descriptions = [OAAmenityInfoRow]()
        var resultRows = [OAAmenityInfoRow]()
  
        // TODO: restore original code after debug
//        let filteredInfo = additionalInfo.getFilteredLocalizedInfo()
//        for entry in filteredInfo {
//            let key = entry.key
//            let value = entry.value
        
        // TODO: delete test code after debug
        let filteredInfo = additionalInfo.getFilteredLocalizedInfo() as NSDictionary
        let keys = (filteredInfo.allKeys as? [String] ?? []).sorted()
        for key in keys {
            let value = filteredInfo[key]
            
            
            if let that = helper.getAnyPoiAdditionalType(byKey: key) as? OAPOIType {
                if that.isHidden {
                    continue
                }
            }
            if key.contains(WIKIPEDIA_TAG) || key.contains(CONTENT_TAG) || key.contains(SHORT_DESCRIPTION) || key.contains(WIKI_LANG) {
                continue
            }
            if subtype == ROUTE_ARTICLE && key.contains(DESCRIPTION_TAG) {
                continue
            }
            if key == POI_NAME {
                continue // will be added in buildNamesRow
            }
            
            var infoRow: OAAmenityInfoRow?
            if let strValue = value as? String {
                infoRow = createPoiAdditionalInfoRow(key: key, value: strValue, collapsableView: nil)
            } else if let value {
                infoRow = createLocalizedAmenityInfoRow(key: key, value: value)
            }
            
            if let infoRow {
                if lastBuiltRowIsDescription {
                    descriptions.append(infoRow)
                } else if key == CUISINE_TAG {
                    cuisineRow = infoRow
                } else if poiType == nil {
                    infoRows.append(infoRow)
                }
            }
        }
        
        if let cuisineRow, !additionalInfo.containsAny([AmenityUIHelper.CUISINE_INFO_ID, AmenityUIHelper.DISH_INFO_ID]) {
            infoRows.append(cuisineRow)
        }
        
        for entry in additionalInfo.getFilteredInfo() ?? [:] {
            let key = entry.key
            let value = entry.value
            if key.hasPrefix(COLLAPSABLE_PREFIX) {
                var categoryTypes = [OAPOIType]()
                
                if !value.isEmpty {
                    var sb = ""
                    let records = value.components(separatedBy: SEPARATOR)
                    for record in records {
                        var pt = helper.getPoiAdditionalType(poiCategory, name: record)
                        if pt == nil {
                            pt = helper.getAnyPoiAdditionalType(byKey: record) as? OAPOIType
                        }
                        if let pt {
                            categoryTypes.append(pt)
                            if sb.length > 0 {
                                sb.append(" • ")
                            }
                            sb.append(pt.nameLocalized)
                        }
                    }
                    
                    var icon: UIImage?
                    let pType = categoryTypes[0]   // TODO: fix crash here!
                    let poiAdditionalCategoryName = pType.poiAdditionalCategory
                    let poiAdditionalIconName = helper.getPoiAdditionalCategoryIcon(poiAdditionalCategoryName)
                    
                    if let poiAdditionalIconName {
                        icon = getRowIcon(poiAdditionalIconName)
                    }
                    if icon == nil, let poiAdditionalCategoryName {
                        icon = getRowIcon(poiAdditionalCategoryName)
                    }
                    if icon == nil, let typeIconKeyName = pType.iconName() {
                        icon = getRowIcon(typeIconKeyName)
                    }
                    if icon == nil {
                        icon = UIImage(named: "ic_description")
                    }
                    
                    let cuisineOrDish = key == CUISINE_TAG || key == DISH_TAG
                    let collapsableView = getPoiTypeCollapsableView(collapsed: true, categoryTypes: categoryTypes, poiAdditional: true, textRow: cuisineOrDish ? cuisineRow : nil, type: poiCategory)
                    
                    let row = OAAmenityInfoRow(key: poiAdditionalCategoryName ?? "", icon: icon, textPrefix: pType.poiAdditionalCategoryLocalized, text: sb, hiddenUrl: nil, collapsableView: collapsableView, textColor: nil, isWiki: false, isText: true, needLinks: true, isPhoneNumber: false, isUrl: false, order: Int(pType.order), name: pType.name, matchWidthDivider: false, textLinesLimit: 1)
                    infoRows.append(row)
                }
            }
        }
        
        if !collectedPoiTypes.isEmpty {
            for entry in collectedPoiTypes {
                let poiTypeList = entry.value
                let collapsableView = getPoiTypeCollapsableView(collapsed: true, categoryTypes: poiTypeList, poiAdditional: false, textRow: nil, type: poiCategory)
                var poiCategory = self.poiCategory
                var sb = ""
                
                for pt in poiTypeList {
                    if sb.length > 0 {
                        sb.append(" • ")
                    }
                    sb.append(pt.nameLocalized)
                    poiCategory = pt.category
                }
                
                var icon: UIImage?
                if let poiCategory {
                    icon = getRowIcon(poiCategory.iconName())
                    let row = OAAmenityInfoRow(key: poiCategory.name, icon: icon, textPrefix: poiCategory.nameLocalized, text: sb, hiddenUrl: nil, collapsableView: collapsableView, textColor: nil, isWiki: false, isText: true, needLinks: true, isPhoneNumber: false, isUrl: false, order: 40, name: poiCategory.name, matchWidthDivider: false, textLinesLimit: 1)
                    infoRows.append(row)
                }
            }
        }
        
        sortInfoRows(&infoRows)
        for info in infoRows {
            // TODO: not needed?
            // buildAmenityRow(view, info);
            resultRows.append(info)
        }
        
        sortDescriptionRows(&descriptions)
        for info in descriptions {
            resultRows.append(info)
        }
        
        if let osmPlugin = OAPluginsHelper.getPlugin(OAOsmEditingPlugin.self) as? OAOsmEditingPlugin, osmPlugin.isEnabled() {
            if let info = buildWikiDataRow() {
                resultRows.append(info)
            }
        }

        return resultRows
    }
    
    func buildWikiDataRow() -> OAAmenityInfoRow? {
        if let value = additionalInfo.get(WIKIDATA_TAG) {
            if let pType = OAPOIHelper.sharedInstance().getAnyPoiAdditionalType(byKey: WIKIDATA_TAG) as? OAPOIType {
                let rowInfo = OAAmenityInfoRow(key: WIKIDATA_TAG, icon: UIImage.templateImageNamed("ic_custom_wikipedia"), textPrefix: pType.nameLocalized, text: value, hiddenUrl: nil, collapsableView: nil, textColor: nil, isWiki: false, isText: true, needLinks: true, isPhoneNumber: false, isUrl: false, order: Int(pType.order), name: pType.name, matchWidthDivider: false, textLinesLimit: 1)
                return rowInfo
            }
        }
        return nil
    }
    
    private func sortInfoRows(_ infoRows: inout [OAAmenityInfoRow]) {
        infoRows.sort { $0.order < $1.order }
    }
    
    // private void sortDescriptionRows(@NonNull List<AmenityInfoRow> descriptions) {
    private func sortDescriptionRows(_ descriptions: inout [OAAmenityInfoRow]) {
        // TODO: implement
    }
    
    static func getSocialMediaUrl(key: String, value: String) -> String? {
        // Remove leading and closing slashes
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            return nil
        }

        var sb = value
        if sb.first == "/" {
            sb.removeFirst()
        }
        if sb.last == "/" {
            sb.removeLast()
        }

        // It cannot be username
        if isWebUrlLike(sb) {
            return "https://\(value)"
        }

        var urls: [String: String] = [:]
        urls["facebook"] = "https://facebook.com/%@"
        urls["vk"] = "https://vk.com/%@"
        urls["instagram"] = "https://instagram.com/%@"
        urls["twitter"] = "https://x.com/%@"
        urls["ok"] = "https://ok.ru/%@"
        urls["telegram"] = "https://t.me/%@"
        urls["flickr"] = "https://flickr.com/%@"
        urls["wikidata"] = WikiAlgorithms.wikidataBaseUrl + "%@"

        if let url = urls[key] {
            return String(format: url, value)
        }
        return nil
    }
    
    private static func isWebUrlLike(_ value: String) -> Bool {
        // java: PatternsCompat.AUTOLINK_WEB_URL()
        if let url = URL(string: value), url.scheme != nil {
            return true
        }
        if let url = URL(string: "https://\(value)"),
           let host = url.host, !host.isEmpty {
            return true
        }
        return false
    }
    
    private func createPoiAdditionalInfoRow(key: String, value: String, collapsableView: OACollapsableView?) -> OAAmenityInfoRow? {
        guard !isKeyToSkip(key: key) else { return nil }
        
        var pType = fetchPoiAdditionalType(key: key, value: value)
        if pType == nil {
            let altKey = key.replacingOccurrences(of: ":", with: "_")
            pType = fetchPoiAdditionalType(key: altKey, value: value)
        }
        
        if let pType, pType.filterOnly {
            return nil
        }
        
        // filter poi additional categories on this step, they will be processed separately
        if let pType, !pType.isText {
            if let categoryName = pType.poiAdditionalCategory, !categoryName.isEmpty {
                
                // computeIfAbsent()
                var list = poiAdditionalCategories[categoryName]
                if list == nil {
                    list = []
                    poiAdditionalCategories[categoryName] = list
                }
                list?.append(pType)
    
                return nil
            }
        }
        
        let rowParamsBuilder = AmenityInfoRowParams.Builder(key: key)
        rowParamsBuilder.collapsableView = collapsableView
        
        if let pType {
            let poiAdditionalUiRule = PoiAdditionalUiRules.shared.findRule(key: key)
            poiAdditionalUiRule.apply(builder: rowParamsBuilder, poiType: pType, key: key, value: value, subtype: subtype)
        } else if let poiType {
            let category = poiType.category.name
            if category == OTHER_MAP_CATEGORY {
                return nil // the "Others" value is already displayed as a title
            }
            if let category {
                // computeIfAbsent()
                var list = collectedPoiTypes[category]
                if list == nil {
                    list = []
                    collectedPoiTypes[category] = list
                }
                list?.append(poiType)
            }
        } else if showDefaultTags {
            // pType = new PoiType(poiTypes, poiCategory, null, key, poiCategory.getIconKeyName());
            pType = OAPOIType(name: key, category: poiCategory)
            pType?.isText = true
            let poiAdditionalUiRule = PoiAdditionalUiRules.shared.findRule(key: key)
            let translation = OAPOIHelper.sharedInstance().getTranslation(value) ?? ""
            poiAdditionalUiRule.apply(builder: rowParamsBuilder, poiType: pType ?? OAPOIType(), key: key, value: translation, subtype: subtype)
        } else {
            return nil // skip non-translatable NON-poiType tags
        }
        
        lastBuiltRowIsDescription = rowParamsBuilder.isDescription()
        rowParamsBuilder.matchWidthDivider = !rowParamsBuilder.isDescription() && rowParamsBuilder.isWiki
        
        // TODO: implement? return AmenityInfoRowParams.Builder dto directly?
        //return rowParamsBuilder.build()
        
        let param = rowParamsBuilder.build()
        let iconName = param.iconName ?? "ic_custom_info_outlined"
        let icon = OAUtilities.getMxIcon(iconName) ?? UIImage.templateImageNamed(iconName)
        
        let result = OAAmenityInfoRow(key: param.key, icon: icon, textPrefix: param.textPrefix, text: param.text, hiddenUrl: param.hiddenUrl, collapsableView: param.collapsableView, textColor: param.textColor, isWiki: param.isWiki, isText: param.isText, needLinks: param.needLinks, isPhoneNumber: param.isPhoneNumber, isUrl: param.isUrl, order: param.order, name: param.name, matchWidthDivider: param.matchWidthDivider, textLinesLimit: Int32(param.textLinesLimit))
        result.collapsed = true
        
        return result
    }
    
    private func createLocalizedAmenityInfoRow(key: String, value: Any) -> OAAmenityInfoRow? {
        
        //TODO: delete after test
        if let dict = value as? Dictionary<String, Any> {
            let debugDict = key + ": " + String(describing: dict)
            var info = OAAmenityInfoRow(key: debugDict, icon: UIImage.templateImageNamed("ic_custom_file_info"), textPrefix: nil, text: debugDict, hiddenUrl: nil, collapsableView: nil, textColor: nil, isWiki: false, isText: true, needLinks: false, isPhoneNumber: false, isUrl: false, order: 999999999, name: debugDict, matchWidthDivider: false, textLinesLimit: 1)
            return info
        }
        return nil
        
        // TODO: implement correct function !!!
    }
    
    private func isKeyToSkip(key: String) -> Bool {
        return key.hasPrefix(COLLAPSABLE_PREFIX) || key.hasPrefix(ALT_NAME_WITH_LANG_PREFIX) || key.hasPrefix(LANG_YES) ||
            key == WIKI_PHOTO || key == WIKIDATA_TAG || key == WIKIMEDIA_COMMONS_TAG || key == "image" || key == "mapillary" || key == "subway_region" ||
            (key == "note" && !osmEditingEnabled) ||
            OAMapObject.isNameLangTag(key) ||
            key.contains(ROUTE_TAG)
    }
    
    private func fetchPoiAdditionalType(key: String, value: String) -> OAPOIType? {
        poiType = helper.getAnyPoiType(byKey: key)
        var pt: OAPOIBaseType? = helper.getAnyPoiAdditionalType(byKey: key)
        if pt == nil && !value.isEmpty && value.length < 50 {
            pt = helper.getAnyPoiAdditionalType(byKey: key + "_" + value)
        }
        if poiType == nil && pt == nil {
            poiType = helper.getPoiType(byKey: key)
        }
        return pt != nil ? (pt as? OAPOIType) : nil
    }
    
    // public void buildNamesRow(ViewGroup viewGroup, Map<String, String> namesMap, boolean altName) {
    
    // protected CollapsableView getNamesCollapsableView(@NonNull Map<String, String> mapNames,
    
    // public static String getSocialMediaUrl(String key, String value) {
    
    // private void buildRow(View view, int iconId, String text, String textPrefix, String hiddenUrl,
    
    // protected void buildRow(View view, Drawable icon, String text, String textPrefix,
    
//    func buildRow(icon: UIImage, text: String, textPrefix: String, hiddenUrl: String, collapsable: Bool, collapsableView: UIView?, textColor: UIColor, isWiki: Bool, isText: Bool, isPhoneNumber: Bool, isUrl: Bool, matchWidthDivider: Bool, textLinesLimit: Int) {
//        //TODO: implement
//    }
    
//    func buildAmenityRow(_ rowInfo: OAAmenityInfoRow) -> OAAmenityInfoRow {
//        var info = OAAmenityInfoRow(key: poiCategory.name, icon: icon, textPrefix: poiCategory.nameLocalized, text: sb, hiddenUrl: nil, collapsableView: collapsableView, textColor: nil, isWiki: false, isText: true, needLinks: true, isPhoneNumber: false, isUrl: false, order:40, name: poiCategory.name, matchWidthDivider: false, textLinesLimit: 1)
//        
//        
//        if info.icon != nil {
////            buildRow(view, info.icon, info.text, info.textPrefix, info.hiddenUrl,
////                    info.collapsable, info.collapsableView, info.textColor, info.isWiki, info.isText,
////                    info.needLinks, info.isPhoneNumber,
////                    info.isUrl, info.matchWidthDivider, info.textLinesLimit);
//            
//            //hiddenUrl: "???"
//            //matchWidthDivider:true
//            //isWiki: info.isWiki
//            //info.textLinesLimit
//            buildRow(icon: info.icon, text: info.text, textPrefix: info.textPrefix, hiddenUrl: "???", collapsable: info.collapsable(), collapsableView: info.collapsableView, textColor: info.textColor, isWiki: false, isText: info.isText, isPhoneNumber: info.isPhoneNumber, isUrl: info.isUrl, matchWidthDivider:true , textLinesLimit: 1)
//            
//        } else {
////            buildRow(view, info.iconId, info.text, info.textPrefix, info.hiddenUrl,
////                    info.collapsable, info.collapsableView, info.textColor, info.isWiki, info.isText,
////                    info.needLinks, info.isPhoneNumber,
////                    info.isUrl, info.matchWidthDivider, info.textLinesLimit);
//        }
//        return info
//    }
    
    // private CollapsableView getPoiTypeCollapsableView(Context context, boolean collapsed,
    private func getPoiTypeCollapsableView(collapsed: Bool, categoryTypes: [OAPOIType], poiAdditional: Bool, textRow: OAAmenityInfoRow?, type: OAPOICategory?) -> OACollapsableView? {
        
        // TODO: implement
        return nil
    }
    
    // public static Set<String> collectAvailableLocalesFromTags(@NonNull Collection<String> tags) {
    
    // private Locale getPreferredLocale(Collection<String> locales) {
    
    // public static Pair<String, Locale> getDescriptionWithPreferredLang(@NonNull OsmandApplication app,
    
    private func getRowIcon(_ name: String) -> UIImage? {
        let iconName = name.hasPrefix("mx_") ? name : "mx_" + name
        return OATargetInfoViewController.getIcon(iconName, size: CGSize(width: 20, height: 20))
    }
}
