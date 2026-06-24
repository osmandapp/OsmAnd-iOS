//
//  SearchByRouteIdTask.swift
//  OsmAnd
//
//  Created by Max Kojin on 06/05/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

typealias SearchByRouteIdTaskResultBlock = (_ result: Any?) -> Void

@objcMembers
final class SearchByRouteIdTask: OAAsyncTask {
    
    @objc(EOASearchByRouteIdTaskSearchType)
    enum SearchType: Int {
        case related
        case partOf
        case members
    }
    
    var completionHandler: (([OAPOI]) -> Void)?
    
    private var amenity: OAPOI?
    private var searchType: SearchType
    
    private var routeId: String?
    private var routeMembersIds: String?
    
    init(amenity: OAPOI?, searchType: SearchType, completionHandler: (([OAPOI]) -> Void)?) {
        self.completionHandler = completionHandler
        if let amenity {
            self.routeId = amenity.getAdditionalInfo(ROUTE_ID)
            self.routeMembersIds = amenity.getAdditionalInfo(ROUTE_MEMBERS_IDS)
        }
        
        self.searchType = searchType
        self.amenity = amenity
        super.init()
    }
    
    override func doInBackground() -> Any? {
        var amenities = [OAPOI]()
        let amenitySearcher = OAAmenitySearcher()
        
        if searchType == .members {
            if let routeMembersIds, !routeMembersIds.isEmpty {
                let members = amenitySearcher.searchRouteMembers(routeMembersIds)
            
                for entry in members {
                    let amenityList = entry.value
                    if !amenityList.isEmpty {
                        amenities.append(amenityList[0])
                    }
                }
            }
        } else if searchType == .related {
            if let routeId, !routeId.isEmpty {
                let related = amenitySearcher.searchRouteMembers(routeId)
                var amenityList = [OAPOI]()
                
                for entry in related {
                    let relatedList = entry.value
                    if !relatedList.isEmpty {
                        amenityList.append(contentsOf: relatedList)
                    }
                }
                
                var seenCoords = Set<String>()
                for am in amenityList {
                    let loc = am.getLocation()
                    let lat = loc.coordinate.latitude
                    let lon = loc.coordinate.longitude
                    let key = String(format: "%.5f,%.5f", lat, lon)
                    if !seenCoords.contains(key) {
                        if let amenity, amenity.obfId != am.obfId {
                            amenities.append(am)
                        } else if amenity == nil {
                            amenities.append(am)
                        }
                    }
                    seenCoords.insert(key)
                }
            }
        } else if searchType == .partOf {
            if let routeId, !routeId.isEmpty {
                let list = amenitySearcher.searchRoutePart(of: routeId)
                var routeIdHash = Set<String>()
                
                for am in list {
                    if let routeId = am.getAdditionalInfo(ROUTE_ID) {
                        if !routeIdHash.contains(routeId) {
                            amenities.append(am)
                        }
                        routeIdHash.insert(routeId)
                    }
                }
            }
        }
        return amenities
    }
    
    override func onPostExecute(result: Any?) {
        if let completionHandler, let amenities = result as? [OAPOI] {
            completionHandler(amenities)
        }
    }
}

