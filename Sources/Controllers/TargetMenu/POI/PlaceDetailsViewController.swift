//
//  PlaceDetailsViewController.swift
//  OsmAnd
//
//  Created by Max Kojin on 02/09/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class PlaceDetailsViewController: OAPOIViewController {
    
    private var detailsObject: BaseDetailsObject?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "OAPOIViewController", bundle: nibBundleOrNil)
    }
    
    init(poi: OAPOI, detailsObject: BaseDetailsObject) {
        super.init(poi: detailsObject.syntheticAmenity)
        self.detailsObject = detailsObject
        setObject(detailsObject)
    }
    
    override func setObject(_ object: Any) {
        if let detailsObj = object as? BaseDetailsObject {
            poi = detailsObj.syntheticAmenity
        } else {
            super.setObject(object)
        }
    }
    
    override func buildDescription(_ rows: NSMutableArray) {
        let wikiAmenities = getWikiAmenities()
        let hasDescription = buildDescription(amenities: wikiAmenities, allowOnlineWiki: false)
        
        if !hasDescription {
            // TODO: implement
        }
        if hasDescription {
            // TODO: implement
        }
        
        if customOnlinePhotosPosition {
            buildPhotosRow()
        }
//        if (isCustomOnlinePhotosPosition()) {
//            buildPhotosRow((ViewGroup) view, amenity);
//        }
        // TODO: implement
        
    }
    
    private func buildDescription(amenities: [OAPOI], allowOnlineWiki: Bool) -> Bool {
        if let detailsObject {
            if buildDescription(amenity: detailsObject.syntheticAmenity, allowOnlineWiki: false) {
                return true
            }
        }
        
        for ameniry in amenities {
            if buildDescription(amenity: ameniry, allowOnlineWiki: false) {
                return true
            }
        }
        
        return false
    }
    
    private func buildDescription(amenity: OAPOI, allowOnlineWiki: Bool) -> Bool {
        // TODO: implement
        
        return false
    }
    
    override func buildPhotosRow() {
        super.buildPhotosRow()
        buildGuidesRow()
    }
    
    private func buildGuidesRow() {
        guard let routeIds = getTravelIds(), !routeIds.isEmpty else { return }
        
        searchTravelArticles(routeIds: routeIds) { articles in
            if !articles.isEmpty {
                let icon = UIImage.templateImageNamed("ic_custom_backpack")
                let title = localizedString("travel_guides")
                let collapsableView = self.getGuidesCollapsableView(articles: articles)
                
                let row = OAAmenityInfoRow(key: "travel", icon: icon, textPrefix: "", text: title, textColor: nil, isText: true, needLinks: true, collapsable: collapsableView, order: -100, typeName: "travel", isPhoneNumber: false, isUrl: false)
                row.collapsed = true
                
                self.append(row)
            }
        }
    }
    
    private func searchTravelArticles(routeIds: [String: CLLocation], callback: @escaping (([String: [String: TravelArticle]]) -> Void)) {
        let task = SearchTravelArticlesTask(routeIds: routeIds, callback: callback)
        task.execute()
    }
    
    private func getGuidesCollapsableView(articles: [String: [String: TravelArticle]]) -> OACollapsableView? {
        
        var res = ""
        
        let appLang = OAUtilities.currentLang() ?? ""
        let mapLang = OAAppSettings.sharedManager().settingPrefMapLanguage.get()
        
        for articleMap in articles.values {
            if let article = getArticle(articleMap: articleMap, appLang: appLang, mapLang: mapLang) {
                
                res += article.title ?? "" + "\n"
            }
        }
        return OACollapsableLabelView(text: res, collapsed: true)
        
        // TODO: implement
    }
    
    private func getArticle(articleMap: [String: TravelArticle], appLang: String, mapLang: String) -> TravelArticle? {
        var article = articleMap[appLang]
        if article == nil {
            article = articleMap[mapLang]
        }
        if article == nil {
            article = articleMap["en"]
        }
        
        return article != nil ? article : articleMap.first?.value
    }
    
    private func getTravelIds() -> [String: CLLocation]? {
        guard TravelObfHelper.shared.isAnyTravelBookPresent() else { return nil }
        guard let detailsObject else { return nil }
        
        var map = [String: CLLocation]()
        if let routeId = poi.getRouteId(), !routeId.isEmpty {
            map[routeId] = poi.getLocation()
        }
        
        for amenity in detailsObject.getAmenities() {
            if let subtype = amenity.subType {
                if subtype == ROUTE_ARTICLE_POINT || subtype == ROUTE_TRACK_POINT {
                    
                    let routeId = amenity.getRouteId()
                    let wikidata = amenity.getWikidata()
                    
                    if let routeId, !routeId.isEmpty, !map.keys.contains(routeId) {
                        map[routeId] = amenity.getLocation()
                    }
                    if let wikidata, !wikidata.isEmpty, !map.keys.contains(wikidata) {
                        map[wikidata] = amenity.getLocation()
                    }
                }
            }
        }
        return map
    }
    
    private func getWikiAmenities() -> [OAPOI] {
        var amenities = [OAPOI]()
        guard let detailsObjectAmenities = detailsObject?.getAmenities() else { return [] }
        
        for amenity in detailsObjectAmenities {
            if amenity.type.category.isWiki() {
                amenities.append(amenity)
            }
        }
        return amenities
    }
    
    private func getTravelAmenities() -> [OAPOI] {
        var amenities = [OAPOI]()
        guard let detailsObjectAmenities = detailsObject?.getAmenities() else { return [] }
        
        for amenity in detailsObjectAmenities {
            if amenity.isRoutePoint() {
                amenities.append(amenity)
            }
        }
        return amenities
    }
}
