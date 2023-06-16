//
//  EngineType.swift
//  OsmAnd Maps
//
//  Created by Skalii on 12.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAEngineType)
@objcMembers
class EngineType: NSObject {
//    static let GRAPHHOPPER_TYPE = GraphhopperEngine(nil)
//    static let OSRM_TYPE = OsrmEngine(nil)
//    static let ORS_TYPE = OrsEngine(nil)
    static let GpxType = GpxEngine(params: nil)

    private static var enginesTypes: [OnlineRoutingEngine]?

    static func values() -> [OnlineRoutingEngine] {
        if enginesTypes == nil {
            enginesTypes = [
//                GRAPHHOPPER_TYPE,
//                OSRM_TYPE,
//                ORS_TYPE,
                GpxType
            ]
        }
        return enginesTypes!
    }

    static func getTypeByName(typeName: String) -> OnlineRoutingEngine {
        for type in values() {
            if type.getTypeName() == typeName {
                return type
            }
        }
        return values()[0]
    }
}
