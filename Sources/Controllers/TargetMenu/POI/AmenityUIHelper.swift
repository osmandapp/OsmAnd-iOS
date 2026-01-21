//
//  AmenityUIHelper.swift
//  OsmAnd
//
//  Created by Max Kojin on 02/10/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class AmenityUIHelper: NSObject {
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
    
    private var cuisineRow: OARowInfo?
    private var poiAdditionalCategories = [String: [OAPOIType]]()
    private var collectedPoiTypes = [String: [OAPOIType]]()
    private var osmEditingEnabled = OAPluginsHelper.isEnabled(OAOsmEditingPlugin.self) // PluginsHelper.isActive(OsmEditingPlugin.class);
    private var lastBuiltRowIsDescription = false
    
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
    
    func buildInternal() -> [OARowInfo] {
        initVariables()
        var infoRows = [OARowInfo]()
        var descriptions = [OARowInfo]()
        var resultRows = [OARowInfo]()
        
        let filteredInfo = additionalInfo.getFilteredLocalizedInfo()
        for entry in filteredInfo {
            let key = entry.key
            let value = entry.value
            if let that = helper.getAnyPoiAdditionalType(byKey: key) as? OAPOIType {
                if that.isHidden {
                    continue
                }
            }
            if key.contains(WIKIPEDIA_TAG) || key.contains(CONTENT_TAG) || key.contains(SHORT_DESCRIPTION) || key.contains(WIKI_LANG) {
                continue
            }
            if subtype == ROUTE_ARTICLE && key.contains(DESCRIPTION_TAG) {
                continue // will be added in buildNamesRow
            }
            
            var infoRow: OARowInfo?
            if let strValue = value as? String {
                infoRow = createPoiAdditionalInfoRow(key: key, value: strValue)
            } else {
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
                            pt = helper.getAnyPoiAdditionalType(byKey: record) as! OAPOIType
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
                    let pType = categoryTypes[0]   //TODO: fix crash here!
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
                    let row = OARowInfo(key: poiAdditionalCategoryName ?? "", icon: icon, textPrefix: pType.poiAdditionalCategoryLocalized, text: sb, textColor: nil, isText: true, needLinks: true, collapsable: collapsableView, order: Int(pType.order), typeName: pType.name, isPhoneNumber: false, isUrl: false)
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
                    let row = OARowInfo(key: poiCategory.name, icon: icon, textPrefix: poiCategory.nameLocalized, text: sb, textColor: nil, isText: true, needLinks: true, collapsable: collapsableView, order: 40, typeName: poiCategory.name, isPhoneNumber: false, isUrl: false)
                    infoRows.append(row)
                }
            }
        }
        
        sortInfoRows(&infoRows)
        for info in infoRows {
//            buildAmenityRow(view, info);
            // TODO: implement
            
            // ??temp code
            resultRows.append(info)
        }
        
        sortDescriptionRows(&descriptions)
        for info in descriptions {
//            buildAmenityRow(view, info);
            // TODO: implement
        }
        
//        if (PluginsHelper.getActivePlugin(OsmEditingPlugin.class) != null) {
//            buildWikiDataRow(view);
//        }
        
        return resultRows
    }
    
    func buildWikiDataRow() {
        // TODO: implement
    }
    
    // private void sortInfoRows(@NonNull List<AmenityInfoRow> infoRows) {
    private func sortInfoRows(_ infoRows: inout [OARowInfo]) {
        // TODO: implement
    }
    
    // private void sortDescriptionRows(@NonNull List<AmenityInfoRow> descriptions) {
    private func sortDescriptionRows(_ descriptions: inout [OARowInfo]) {
        // TODO: implement
    }
    
    // private AmenityInfoRow createPoiAdditionalInfoRow(@NonNull Context context,
    private func createPoiAdditionalInfoRow(key: String, value: String) -> OARowInfo? {
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
        if let pType, pType.isText {
            if let categoryName = pType.poiAdditionalCategory, !categoryName.isEmpty {
                poiAdditionalCategories
//                poiAdditionalCategories.computeIfAbsent(categoryName, k -> new ArrayList<>()).add(pType);
                return nil
            }
            
        }
        
        return nil
        // TODO: implement
    }
    
    // private AmenityInfoRow createLocalizedAmenityInfoRow(@NonNull Context context, @NonNull String key, @NonNull Object vl) {
    private func createLocalizedAmenityInfoRow(key: String, value: Any) -> OARowInfo? {
        
        return nil
        // TODO: implement
    }
    
    private func isKeyToSkip(key: String) -> Bool {
        return key.hasPrefix(COLLAPSABLE_PREFIX) || key.hasPrefix(ALT_NAME_WITH_LANG_PREFIX) || key.hasPrefix(LANG_YES) ||
            key == WIKI_PHOTO || key == WIKIDATA_TAG || key == WIKIMEDIA_COMMONS_TAG || key == "image" || key == "mapillary" || key == "subway_region" ||
            (key == "note" && !osmEditingEnabled) ||
            OAMapObject.isNameLangTag(key) ||
            key.contains(ROUTE_TAG)
    }
    
    private func fetchPoiAdditionalType(key: String, value: String) -> OAPOIType? {
        poiType = helper.getPoiType(byKey: key)
        var pt: OAPOIBaseType? = poiCategory?.getPoiType(byKeyName: key)
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
    
    // public void buildAmenityRow(View view, AmenityInfoRow info) {
    
//    func buildAmenityRow(_ info: OARowInfo) {
////        if let icon = info.icon {
////            
////        }
//    }
    
    // private CollapsableView getPoiTypeCollapsableView(Context context, boolean collapsed,
    private func getPoiTypeCollapsableView(collapsed: Bool, categoryTypes: [OAPOIType], poiAdditional: Bool, textRow: OARowInfo?, type: OAPOICategory?) -> OACollapsableView? {
        
        // TODO: implement
        return nil
    }
    
    // public static Set<String> collectAvailableLocalesFromTags(@NonNull Collection<String> tags) {
    
    // private Locale getPreferredLocale(Collection<String> locales) {
    
    // public static Pair<String, Locale> getDescriptionWithPreferredLang(@NonNull OsmandApplication app,
    
    private func getRowIcon(_ name: String) -> UIImage? {
        OATargetInfoViewController.getIcon("mx_" + name, size: CGSize(width: 20, height: 20))
    }
}
