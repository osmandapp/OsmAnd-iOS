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
    
    private var additionalInfo: AdditionalInfoBundle
    
    private var preferredLang: String
    private var wikiAmenity: OAPOI?
    private var poiTypes: OAPOIType?
    private var poiCategory: OAPOICategory?
    private var poiType: OAPOIType?
    private var subtype: String?
    
    //private var cuisineRow: AmenityInfoRow?
    private var poiAdditionalCategories = [String: [OAPOIType]]()
    private var collectedPoiTypes = [String: [OAPOIType]]()
    private var osmEditingEnabled = true // PluginsHelper.isActive(OsmEditingPlugin.class);
    private var lastBuiltRowIsDescription = false
    
    init(preferredLang: String, infoBundle: AdditionalInfoBundle) {
        self.preferredLang = preferredLang
        self.additionalInfo = infoBundle
        super.init()
    }
    
    func setPreferredLang(_ lang: String) {
        preferredLang = lang
    }
    
    func buildInternal() {
        // TODO: implement
    }
    
    func buildWikiDataRow() {
        // TODO: implement
    }
    
    func initVariables() {
        // TODO: implement
    }
    
    // private void sortInfoRows(@NonNull List<AmenityInfoRow> infoRows) {
    
    // private AmenityInfoRow createLocalizedAmenityInfoRow(@NonNull Context context, @NonNull String key, @NonNull Object vl) {
    
    // private AmenityInfoRow createPoiAdditionalInfoRow(@NonNull Context context,
    
    // private boolean isKeyToSkip(@NonNull String key) {
    
    // private PoiType fetchPoiAdditionalType(@NonNull String key, @Nullable String vl) {
    
    // public void buildNamesRow(ViewGroup viewGroup, Map<String, String> namesMap, boolean altName) {
    
    // protected CollapsableView getNamesCollapsableView(@NonNull Map<String, String> mapNames,
    
    // private void sortDescriptionRows(@NonNull List<AmenityInfoRow> descriptions) {
    
    // public static String getSocialMediaUrl(String key, String value) {
    
    // private void buildRow(View view, int iconId, String text, String textPrefix, String hiddenUrl,
    
    // protected void buildRow(View view, Drawable icon, String text, String textPrefix,
    
    // public void buildAmenityRow(View view, AmenityInfoRow info) {
    
    // private CollapsableView getPoiTypeCollapsableView(Context context, boolean collapsed,
    
    // public static Set<String> collectAvailableLocalesFromTags(@NonNull Collection<String> tags) {
    
    // private Locale getPreferredLocale(Collection<String> locales) {
    
    // public static Pair<String, Locale> getDescriptionWithPreferredLang(@NonNull OsmandApplication app,
}
