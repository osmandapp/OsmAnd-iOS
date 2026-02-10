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
    
    private static let NAMES_ROW_KEY = "names_row_key"
    private static let ALT_NAMES_ROW_KEY = "alt_names_row_key"
    
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
    private var osmEditingEnabled = OAPluginsHelper.isEnabled(OAOsmEditingPlugin.self)
    private var lastBuiltRowIsDescription = false
    
    var latLon: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    
    // values from parent class MenuBuilder - base ContextMenuVC class
    var showDefaultTags = false
    var matchWidthDivider = false // show separator to full screen with
    
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
  
        let filteredInfo = additionalInfo.getFilteredLocalizedInfo()
        for entry in filteredInfo {
            let key = entry.key
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
                    
                    guard let pType = categoryTypes.first else { continue }
                    
                    var icon: UIImage?
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
                    
                    // TODO: here is a bug with poi type parsing
                    // self.poiCategory should be == "tourism, but it is == "user_defined_other"
                    // correct code:
//                    let collapsableView = getPoiTypeCollapsableView(collapsed: true, categoryTypes: categoryTypes, poiAdditional: true, textRow: cuisineOrDish ? cuisineRow : nil, type: poiCategory)
                    
                    let collapsableView = getPoiTypeCollapsableView(collapsed: true, categoryTypes: categoryTypes, poiAdditional: true, textRow: cuisineOrDish ? cuisineRow : nil, type: pType.category)
                    
                    let row = OAAmenityInfoRow(key: poiAdditionalCategoryName ?? "", icon: icon, textPrefix: pType.poiAdditionalCategoryLocalized, text: sb, hiddenUrl: nil, collapsableView: collapsableView, textColor: nil, isWiki: false, isText: true, needLinks: true, isPhoneNumber: false, isUrl: false, order: Int(pType.order), name: pType.name, matchWidthDivider: false, textLinesLimit: 1)
                    row.collapsed = collapsableView?.collapsed ?? true
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
                    row.collapsed = true
                    infoRows.append(row)
                }
            }
        }
        
        sortInfoRows(&infoRows)
        for info in infoRows {
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
            let url = Self.getSocialMediaUrl(key: WIKIDATA_TAG, value: value)
            if let pType = OAPOIHelper.sharedInstance().getAnyPoiAdditionalType(byKey: WIKIDATA_TAG) as? OAPOIType {
                let rowInfo = OAAmenityInfoRow(key: WIKIDATA_TAG, icon: UIImage.templateImageNamed("ic_custom_wikipedia"), textPrefix: pType.nameLocalized, text: value, hiddenUrl: url, collapsableView: nil, textColor: nil, isWiki: false, isText: true, needLinks: true, isPhoneNumber: false, isUrl: true, order: Int(pType.order), name: pType.name, matchWidthDivider: matchWidthDivider, textLinesLimit: 1)
                return rowInfo
            }
        }
        return nil
    }
    
    private func sortInfoRows(_ infoRows: inout [OAAmenityInfoRow]) {
        infoRows.sort { (row1: OAAmenityInfoRow, row2: OAAmenityInfoRow) -> Bool in
            if row1.order != row2.order {
                return row1.order < row2.order
            }
            return row1.typeName.localizedCompare(row2.typeName) == .orderedAscending
        }
    }
    
    private func sortDescriptionRows(_ descriptions: inout [OAAmenityInfoRow]) {
        let langSuffix = ":" + getPreferredMapAppLang()
        var descInPrefLang: OAAmenityInfoRow?
        for desc in descriptions {
            if desc.key.length > langSuffix.length && desc.key.hasSuffix(langSuffix) {
                descInPrefLang = desc
                break
            }
        }
        
        if let descInPrefLang {
            if let index = descriptions.firstIndex(of: descInPrefLang) {
                descriptions.remove(at: index)
                descriptions.insert(descInPrefLang, at: 0)
            }
        }
    }
    
    func getPreferredMapAppLang() -> String {
        let lang = OAAppSettings.sharedManager().settingPrefMapLanguage.get()
        return lang.isEmpty ? "en" : lang
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
                poiAdditionalCategories = computeIfAbsent(dictionary: poiAdditionalCategories, key: categoryName, value: pType)
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
                collectedPoiTypes = computeIfAbsent(dictionary: collectedPoiTypes, key: category, value: poiType)
            }
        } else if showDefaultTags {
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
        
        let param = rowParamsBuilder.build()
        let iconName = param.iconName ?? "ic_custom_info_outlined"
        let icon = OAUtilities.getMxIcon(iconName) ?? UIImage.templateImageNamed(iconName)
        
        let result = OAAmenityInfoRow(key: param.key, icon: icon, textPrefix: param.textPrefix, text: param.text, hiddenUrl: param.hiddenUrl, collapsableView: param.collapsableView, textColor: param.textColor, isWiki: param.isWiki, isText: param.isText, needLinks: param.needLinks, isPhoneNumber: param.isPhoneNumber, isUrl: param.isUrl, order: param.order, name: param.name, matchWidthDivider: param.matchWidthDivider, textLinesLimit: Int32(param.textLinesLimit))
        result.collapsed = true
        
        return result
    }
    
    private func computeIfAbsent(dictionary: [String: [OAPOIType]], key: String, value: OAPOIType) -> [String: [OAPOIType]] {
        var newDictionary = dictionary
        if var list = dictionary[key] {
            list.append(value)
            newDictionary[key] = list
        } else {
            newDictionary[key] = [value]
        }
        return newDictionary
    }
    
    private func createLocalizedAmenityInfoRow(key: String, value: Any) -> OAAmenityInfoRow? {
        guard let map = value as? [String: Any] else { return nil }
        guard let localizedAdditionalInfo = map["localizations"] as? [String: String] else { return nil }
        guard !localizedAdditionalInfo.isEmpty else { return nil }
        
        let keys = Array(localizedAdditionalInfo.keys)
        let availableLocales = Array(Self.collectAvailableLocalesFromTags(keys))
        
        var headerKey = key
        if let prefferedLocale = getPreferredLocale(availableLocales) {
            headerKey = key + ":" + prefferedLocale
        }
        var headerValue = localizedAdditionalInfo[headerKey]
        if headerValue == nil {
            headerKey = keys[0]
            headerValue = localizedAdditionalInfo[headerKey]
        }
        
        var collapsableView: OACollapsableView?
        if !localizedAdditionalInfo.isEmpty {
            var infoRows: [OAAmenityInfoRow] = []
            for localizedEntry in localizedAdditionalInfo {
                let localizedKey = localizedEntry.key
                let localizedValue = localizedEntry.value
                
                if !localizedKey.isEmpty && !localizedValue.isEmpty && headerKey != localizedKey {
                    if let infoRow = createPoiAdditionalInfoRow(key: localizedKey, value: localizedValue, collapsableView: nil) {
                        infoRows.append(infoRow)
                    }
                }
            }
            
            if infoRows.count > 1 {
                sortInfoRows(&infoRows)
            }
            
            var collapsableContent = ""
            for infoRow in infoRows {
                if !collapsableContent.isEmpty {
                    collapsableContent += "\n\n"
                }
                collapsableContent += infoRow.textPrefix + ": " + infoRow.text
            }
            collapsableView = OACollapsableLabelView(text: collapsableContent, collapsed: true)
        }
        return createPoiAdditionalInfoRow(key: headerKey, value: headerValue ?? "", collapsableView: collapsableView)
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
    
    func buildNamesRow(namesMap: [String: String], altName: Bool) -> OAAmenityInfoRow? {
        if !namesMap.isEmpty {
            let keys = Array(namesMap.keys)
            var nameLocale = getPreferredLocale(keys)
            if nameLocale == nil {
                nameLocale = keys[0]
            }
            guard let nameLocale else { return nil }
            guard let name = namesMap[nameLocale] else { return nil }
            
            let key = altName ? Self.ALT_NAMES_ROW_KEY : Self.NAMES_ROW_KEY
            let hint = localizedString(altName ? "shared_string_alt_name" : "shared_string_name")
            let text = String(format: localizedString("ltr_or_rtl_combine_via_colon"), hint, nameLocale)
            let icon = UIImage.templateImageNamed("ic_custom_map_languge")
            
            let collapsableView = key.count > 1 ? getNamesCollapsableView() : nil
            
            let row = OAAmenityInfoRow(key: key, icon: icon, textPrefix: text, text: name, textColor: nil, isText: true, needLinks: true, collapsable: collapsableView, order: 18000, typeName: "names", isPhoneNumber: false, isUrl: false)
            return row
        }
        return nil
    }
    
    private func getNamesCollapsableView() -> OACollapsableView? {
       
        // TODO: implement
        nil
    }
    
    private func getPoiTypeCollapsableView(collapsed: Bool, categoryTypes: [OAPOIType], poiAdditional: Bool, textRow: OAAmenityInfoRow?, type: OAPOICategory?) -> OACollapsableView? {
        let collapsableView = OACollapsableNearestPoiTypeView(defaultParameters: true)
        collapsableView?.setData(categoryTypes, amenityPoiCategory: type, lat: latLon.latitude, lon: latLon.longitude, isPoiAdditional: poiAdditional, textRow: textRow)
        return collapsableView
    }
    
    static func collectAvailableLocalesFromTags(_ tags: [String]) -> Set<String> {
        var result: Set<String> = []
        for tag in tags {
            let parts = tag.split(separator: ":")
            let locale = parts.count > 1 ? String(parts[1]) : "en"
            if !locale.isEmpty {
                result.insert(locale)
            }
        }
        return result
    }
    
    private func getPreferredLocale(_ localeIds: [String]) -> String? {
        LocaleHelper.getPreferredNameLocale(localeIds)
    }
    
    private func getRowIcon(_ name: String) -> UIImage? {
        let iconName = name.hasPrefix("mx_") ? name : "mx_" + name
        return OATargetInfoViewController.getIcon(iconName, size: CGSize(width: 20, height: 20))
    }
}
