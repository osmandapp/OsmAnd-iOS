//
//  JsonOnlineRoutingEngine.swift
//  OsmAnd Maps
//
//  Created by Skalii on 19.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAJsonOnlineRoutingEngine)
@objcMembers
class JsonOnlineRoutingEngine: OnlineRoutingEngine {

//    override func parseResponse(content: String,
//                                leftSideNavigation: Bool,
//                                initialCalculation: Bool,
//                                calculationProgress: OARouteCalculationProgress?) throws -> OnlineRoutingResponse? {
//        let root = try parseRootResponseObject(content: content)
//        return root != nil ? try parseServerResponse(root: root!, leftSideNavigation: leftSideNavigation) : nil
//    }

//    func parseRootResponseObject(content: String) throws -> JSONObject? {
//        let fullJSON = try JSONObject(content)
//        let key = getRootArrayKey()
//        var array: JSONArray?
//        if fullJSON.has(key) {
//            array = fullJSON.getJSONArray(key)
//        }
//        return array != nil && array!.length() > 0 ? array!.getJSONObject(0) : nil
//    }

//    func isResultOk(errorMessage: StringBuilder, content: String) throws -> Bool {
//        let obj = try JSONObject(content)
//        let messageKey = getErrorMessageKey()
//        if obj.has(messageKey) {
//            let message = obj.getString(messageKey)
//            errorMessage.append(message)
//        }
//        return obj.has(getRootArrayKey())
//    }

//    func parseServerResponse(root: JSONObject, leftSideNavigation: Bool) throws -> OnlineRoutingResponse? {
//        fatalError("Subclasses must implement 'parseServerResponse' method.")
//    }

    func getRootArrayKey() -> String {
        fatalError("Subclasses must implement 'getRootArrayKey' method.")
    }

    func getErrorMessageKey() -> String {
        fatalError("Subclasses must implement 'getErrorMessageKey' method.")
    }

//    static func convertRouteToLocationsList(route: [LatLon]) -> [Location] {
//        var result: [Location] = []
//        if !route.isEmpty {
//            for pt in route {
//                let wpt = WptPt()
//                wpt.lat = pt.getLatitude()
//                wpt.lon = pt.getLongitude()
//                result.append(RouteProvider.createLocation(wpt))
//            }
//        }
//        return result
//    }
}
