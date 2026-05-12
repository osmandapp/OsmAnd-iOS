//
//  SearchByRouteIdTask.swift
//  OsmAnd
//
//  Created by Max Kojin on 06/05/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class SearchByRouteIdTask : OAAsyncTask {
    
//    protected SearchByRouteIdTask(@Nullable Amenity amenity, SearchType type, OsmandApplication app, SearchByRouteIdListener listener) {
//        this.listener = listener;
//        if (amenity != null) {
//            routeId = amenity.getAdditionalInfo(Amenity.ROUTE_ID);
//            routeMembersIds = amenity.getAdditionalInfo(Amenity.ROUTE_MEMBERS_IDS);
//        } else {
//            routeId = null;
//            routeMembersIds = null;
//        }
//        searchType = type;
//        this.app = app;
//        this.amenity = amenity;
//    }
//
//    public SearchByRouteIdTask(String routeId, String routeMembersIds, SearchType type, OsmandApplication app, SearchByRouteIdListener listener) {
//        this.routeId = routeId;
//        this.routeMembersIds = routeMembersIds;
//        this.listener = listener;
//        this.searchType = type;
//        this.app = app;
//        this.amenity = null;
//    }
    
//    init(routeIds: [String: CLLocation], callback: @escaping (([String: [String: TravelArticle]]) -> Void)) {
//        self.routeIds = routeIds
//        self.callback = callback
//        super.init()
//    }
    
    private var amenity: OAPOI?
    private var searchType: String
    
    private var routeId: String?
    private var routeMembersIds: String?
    
    init(amenity: OAPOI?, searchType: String) {
        if let amenity {
            routeId = amenity.getAdditionalInfo(ROUTE_ID)
            routeMembersIds = amenity.getAdditionalInfo(ROUTE_MEMBERS_IDS)
        }
        
        self.searchType = searchType
        self.amenity = amenity
        //this.listener = listener;
        
        super.init()
    }
    
    override func doInBackground() -> Any? {
        //TODO: implement
        var amenities = [OAPOI]()
        let amenitySearcher = OAAmenitySearcher()
        
        if searchType == "MEMBERS" {
            //TODO: implement
            
        } else if searchType == "RELATED" {
            //TODO: implement
            
        } else if searchType == "PART_OF" {
            if let routeId, !routeId.isEmpty {
                let list = amenitySearcher.searchRoutePart(of: routeId)
                var routeIdHash = Set<String>()
                
                for am in list {
                    if let routeId = am.getAdditionalInfo(ROUTE_ID) {
                        if !routeIdHash.contains(routeId) {
                            amenities.append(am)
                            routeIdHash.insert(routeId)
                        }
                    }
                }
                
            }
        }
        return amenities
    }
    
    override func onPostExecute(result: Any?) {
        //TODO: implement
        super.onPostExecute(result: result)
    }
}
