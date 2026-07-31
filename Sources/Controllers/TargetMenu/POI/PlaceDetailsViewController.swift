//
//  PlaceDetailsViewController.swift
//  OsmAnd
//
//  Created by Max Kojin on 02/09/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

// analog in android: PlaceDetailsMenuBuilder.java

@objcMembers
final class PlaceDetailsViewController: OAPOIViewController {
    
    private var detailsObject: BaseDetailsObject?
    private var renderedObject: OARenderedObject?
    private var sourceObject: AnyObject?
    private var provider: RenderedObjectAmenityProvider!
    private var cityFetchStarted = false
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(poi: OAPOI, detailsObject: BaseDetailsObject, renderedObject: OARenderedObject?) {
        super.init(poi: detailsObject.syntheticAmenity)
        self.detailsObject = detailsObject
        self.renderedObject = renderedObject
        self.sourceObject = renderedObject ?? detailsObject.syntheticAmenity
        self.provider = RenderedObjectAmenityProvider(detailsObject: detailsObject, renderedObject: renderedObject)
        setObject(detailsObject)
    }

    init(renderedObject: OARenderedObject) {
        let poi = BaseDetailsObject.convertRenderedObjectToAmenity(renderedObject)
        super.init(poi: poi)
        self.renderedObject = renderedObject
        self.sourceObject = renderedObject
        self.provider = RenderedObjectAmenityProvider(renderedObject: renderedObject)
    }

    init(amenityPoi poi: OAPOI) {
        super.init(poi: poi)
        self.sourceObject = poi
        self.provider = RenderedObjectAmenityProvider()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "OAPOIViewController", bundle: nibBundleOrNil)
    }

    override func viewDidLoad() {
        applyPolygonAddressIfNeeded()
        if detailsObject != nil {
            updateMenuWithDetailedObject()
        }
        super.viewDidLoad()
        if detailsObject == nil {
            resolveDetailedObjectInBackground()
        } else {
            highlightPolygonInBackground()
        }
    }

    override func setObject(_ object: Any) {
        if let detailsObj = object as? BaseDetailsObject {
            poi = detailsObj.syntheticAmenity
        } else {
            super.setObject(object)
        }
    }
    
    override func getNameStr() -> String? {
        let name = provider.nameOnlyString()
        
        if !name.isEmpty {
            return name
        }
        
        return getTypeStr()
    }

    override func getTypeStr() -> String? {
        let typeString = provider.typeString { super.getTypeStr() }
        return typeString ?? super.getTypeStr()
    }

    override func getIcon() -> UIImage? {
        guard detailsObject == nil, let renderedObject else { return super.getIcon() }
        return RenderedObjectHelper.getIcon(renderedObject: renderedObject)
    }

    override func getOsmUrl() -> String {
        guard detailsObject == nil, let renderedObject else { return super.getOsmUrl() }
        return ObfConstants.getOsmUrlForId(renderedObject)
    }

    override func buildPhotosRow(_ rows: NSMutableArray) {
        super.buildPhotosRow(rows)
        buildGuidesRow()
    }
    
    override func buildDescription(_ rows: NSMutableArray) {
        if detailsObject == nil {
            super.buildDescription(rows)
            return
        }
        let wikiAmenities = getWikiAmenities()
        var hasDescription = buildDescription(amenities: wikiAmenities, allowOnlineWiki: false, rows: rows)
        
        if !hasDescription {
            let filteredInfo = infoBundle.getFilteredLocalizedInfo()
            buildShortWikiDescription(filteredInfo, allowOnlineWiki: true, rows: rows)
            
            hasDescription = buildDescription(amenities: getTravelAmenities(), allowOnlineWiki: false, rows: rows)
        }
        if hasDescription {
            infoBundle.setCustomHiddenExtensions([DESCRIPTION_TAG])
        }
        
        if customOnlinePhotosPosition {
            buildPhotosRow(rows)
        }
    }

    private func buildDescription(amenities: [OAPOI], allowOnlineWiki: Bool, rows: NSMutableArray) -> Bool {
        if let detailsObject, buildDescription(amenity: detailsObject.syntheticAmenity, allowOnlineWiki: false, rows: rows) {
            return true
        }
        
        for amenity in amenities where buildDescription(amenity: amenity, allowOnlineWiki: false, rows: rows) {
            return true
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

    private func buildGuidesRow() {
        guard let routeIds = getTravelIds(), !routeIds.isEmpty else { return }
        
        searchTravelArticles(routeIds: routeIds) { articles in
            if !articles.isEmpty {
                let icon = UIImage.templateImageNamed("ic_custom_backpack")
                let title = localizedString("travel_guides")
                let collapsableView = self.getGuidesCollapsableView(articles: articles)
                
                let row = OAAmenityInfoRow(key: "travel", icon: icon, textPrefix: "", text: title, hiddenUrl: nil, collapsableView: collapsableView, textColor: nil, isWiki: false, isText: true, needLinks: true, isPhoneNumber: false, isUrl: false, order: -100, name: "travel", matchWidthDivider: self.matchWidthDivider, textLinesLimit: 1)
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
        let collapsableView = OACollapsableTravelGuidesView(defaultParameters: true)
        collapsableView?.setData(articlesMap: articles)
        return collapsableView
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
        
        for amenity in detailsObjectAmenities where amenity.isRoutePoint() {
            amenities.append(amenity)
        }
        return amenities
    }
    
    private func updateMenuWithDetailedObject() {
        guard let detailsObject else { return }
        let amenity = detailsObject.syntheticAmenity
        setup(amenity)
        updateTargetPoint(with: amenity)
    }

    private func highlightPolygonInBackground() {
        let poi: OAPOI? = (sourceObject as? OAPOI) ?? detailsObject?.syntheticAmenity
        guard let poi else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let geoObject = OAAmenitySearcher.sharedInstance().resolveGeometryOnly(poi) else { return }
            DispatchQueue.main.async {
                guard let mapPanel = OARootViewController.instance()?.mapPanel,
                      mapPanel.getCurrentTargetPoint() != nil
                else { return }
                mapPanel.highlightContextPinPolygon(geoObject)
            }
        }
    }

    private func resolveDetailedObjectInBackground() {
        guard let sourceObject else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let poi = sourceObject as? OAPOI,
               let geoObject = OAAmenitySearcher.sharedInstance().resolveGeometryOnly(poi) {
                DispatchQueue.main.async {
                    guard let self,
                          self.detailsObject == nil,
                          let mapPanel = OARootViewController.instance()?.mapPanel,
                          let targetPoint = mapPanel.getCurrentTargetPoint(),
                          (targetPoint.targetObj as AnyObject) === sourceObject
                    else { return }
                    mapPanel.highlightContextPinPolygon(geoObject)
                }
            }
            let details = OAAmenitySearcher.sharedInstance().searchDetailedObject(sourceObject)
            DispatchQueue.main.async {
                guard let self,
                      let details,
                      let tableView = self.tableView,
                      let mapPanel = OARootViewController.instance()?.mapPanel,
                      let targetPoint = mapPanel.getCurrentTargetPoint(),
                      (targetPoint.targetObj as AnyObject) === sourceObject
                else { return }
                self.detailsObject = details
                self.provider.detailsObject = details
                let amenity = details.syntheticAmenity
                self.setup(amenity)
                self.updateTargetPoint(with: amenity)
                self.rebuildRows()
                tableView.reloadData()
                self.delegate?.refreshTargetPointHeader?()
                mapPanel.highlightContextPinPolygon(details)
            }
        }
    }

    private func updateTargetPoint(with amenity: OAPOI) {
        guard let mapPanel = OARootViewController.instance()?.mapPanel,
              let targetPoint = mapPanel.getCurrentTargetPoint() else { return }

        targetPoint.title = amenity.nameLocalized ?? amenity.name
        targetPoint.icon = amenity.type?.icon()

        applyPolygonAddressIfNeeded()
        mapPanel.update(targetPoint)
    }

    private func applyPolygonAddressIfNeeded() {
        guard let mapPanel = OARootViewController.instance()?.mapPanel,
              let targetPoint = mapPanel.getCurrentTargetPoint() else { return }

        let amenity: OAPOI? = detailsObject?.syntheticAmenity ?? (sourceObject as? OAPOI) ?? poi
        let polygonPoints = max(Int(renderedObject?.x.count ?? 0), Int(amenity?.x.count ?? 0))
        guard polygonPoints > 2 else { return }

        targetPoint.shouldFetchAddress = false
        if let address = polygonAddressString(amenity), !address.isEmpty {
            targetPoint.titleAddress = address
            targetPoint.addressFound = true
        }
        fetchCityInBackground(for: targetPoint)
    }

    private func fetchCityInBackground(for targetPoint: OATargetPoint) {
        guard !cityFetchStarted else { return }
        cityFetchStarted = true

        let lat = targetPoint.location.latitude
        let lon = targetPoint.location.longitude
        let objectId = targetPoint.obfId

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let fullAddress = OAReverseGeocoder.instance().lookupAddress(atLat: lat, lon: lon, objectId: objectId)
            let trimmed = fullAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            DispatchQueue.main.async {
                guard let self, !trimmed.isEmpty,
                      let mapPanel = OARootViewController.instance()?.mapPanel,
                      let currentTarget = mapPanel.getCurrentTargetPoint(),
                      currentTarget === targetPoint else { return }
                currentTarget.titleAddress = trimmed
                currentTarget.addressFound = true
                self.delegate?.refreshTargetPointHeader?()
            }
        }
    }

    private func polygonAddressString(_ amenity: OAPOI?) -> String? {
        guard let amenity else { return nil }
        let street = amenity.getAdditionalInfo("addr:street") ?? amenity.getAdditionalInfo("addr_street")
        let house = amenity.getAdditionalInfo("addr:housenumber") ?? amenity.getAdditionalInfo("addr_housenumber")
        let cityCandidates: [String?] = [
            amenity.cityName,
            amenity.getAdditionalInfo("addr:city"),
            amenity.getAdditionalInfo("addr_city"),
            amenity.getAdditionalInfo("addr:place"),
            amenity.getAdditionalInfo("addr_place"),
            amenity.getAdditionalInfo("is_in:city"),
            amenity.getAdditionalInfo("is_in")
        ]
        let city = cityCandidates.compactMap { $0 }.first { !$0.isEmpty }
        var line = ""
        if let street, !street.isEmpty {
            if let house, !house.isEmpty {
                line = "\(street) \(house)"
            } else {
                line = street
            }
        }
        var parts: [String] = []
        if !line.isEmpty { parts.append(line) }
        if let city, !city.isEmpty { parts.append(city) }
        let result = parts.joined(separator: ", ")
        return result.isEmpty ? nil : result
    }
}
