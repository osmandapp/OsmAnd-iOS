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
        let hasDescription = buildDescription(amenities: wikiAmenities, allowOnlineWiki: false, rows: rows)
        
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
    
    private func buildDescription(amenities: [OAPOI], allowOnlineWiki: Bool, rows: NSMutableArray) -> Bool {
        if let detailsObject, buildDescription(amenity: detailsObject.syntheticAmenity, allowOnlineWiki: false, rows: rows) {
            return true
        }
        
        for ameniry in amenities {
            if buildDescription(amenity: ameniry, allowOnlineWiki: false, rows: rows) {
                return true
            }
        }
        
        return false
    }
    
    private func buildDescription(amenity: OAPOI, allowOnlineWiki: Bool, rows: NSMutableArray) -> Bool {
        let extensions = amenity.getAmenityExtensions(false)
        let bundle = AdditionalInfoBundle(additionalInfo: extensions)
        let filteredInfo = bundle.getFilteredLocalizedInfo()
        
        if buildShortWikiDescription(filteredInfo, allowOnlineWiki: allowOnlineWiki, rows: rows) {
            return true
        }
        
        if let pair = AmenityUIHelper.getDescriptionWithPreferredLang(amenity: amenity, key: DESCRIPTION_TAG, map: filteredInfo) {
            let text = pair.first as? String ?? ""
            if let routeId = amenity.getRouteId(), !routeId.isEmpty {
                let row = OAAmenityInfoRow(key: SHORT_DESCRIPTION_TAG, icon: nil, textPrefix: routeId, text: text, textColor: nil, isText: false, needLinks: false, order: -10000, typeName: kShortDescriptionTravelRowType, isPhoneNumber: false, isUrl: false)
                rows.add(row)
            } else {
                let row = OAAmenityInfoRow(key: SHORT_DESCRIPTION_TAG, icon: nil, textPrefix: nil, text: text, textColor: nil, isText: false, needLinks: false, order: -10000, typeName: kShortDescriptionRowType, isPhoneNumber: false, isUrl: false)
                rows.add(row)
            }
            return true
        }
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
        let collapsavleView = OACollapsableTravelGuidesView(defaultParameters: true)
        collapsavleView?.setData(articlesMap: articles)
        return collapsavleView
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
            guard let type = amenity.type else {
                continue
            }
            if type.category.isWiki() {
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
