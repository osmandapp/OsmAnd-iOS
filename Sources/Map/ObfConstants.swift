//
//  ObfConstants.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 04/11/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAObfConstants)
@objcMembers
class ObfConstants: NSObject {
    
    static let SHIFT_MULTIPOLYGON_IDS = 43
    static let SHIFT_NON_SPLIT_EXISTING_IDS = 41
    static let SHIFT_PROPAGATED_NODE_IDS = 50
    static let SHIFT_PROPAGATED_NODES_BITS = 11
    static let MAX_ID_PROPAGATED_NODES = (1 << SHIFT_PROPAGATED_NODES_BITS) - 1     // 2047
    static let RELATION_BIT = 1 << (SHIFT_MULTIPOLYGON_IDS - 1)                     // 1L << 42
    static let PROPAGATE_NODE_BIT = 1 << (SHIFT_PROPAGATED_NODE_IDS - 1)            // 1L << 41
    static let SPLIT_BIT = 1 << (SHIFT_NON_SPLIT_EXISTING_IDS - 1)                  // 1L << 40
    static let DUPLICATE_SPLIT = 5                                                  // According IndexPoiCreator DUPLICATE_SPLIT
    
    static private let SHIFT_ID = 6
    static private let AMENITY_ID_RIGHT_SHIFT = 1
    static private let WAY_MODULO_REMAINDER = 1
    
    static private let NODE = "node"
    static private let WAY = "way"
    static private let RELATION = "relation"
    
    static func getOsmUrlForId(_ object: OAPOI) -> String {
        guard let type = getOsmEntityType(object) else { return "" }
        let osmId = getOsmObjectId(object)
        return "https://www.openstreetmap.org/\(type)/\(osmId)"
    }
    
    static func getOsmObjectId(_ object: OAPOI) -> Int {
        var originalId = -1
        var obfId = Int(object.obfId)
        if obfId != -1 {
            if object.isRenderedObject {
                obfId >>= 1
            }
            if isIdFromPropagatedNode(obfId) {
                let shifted = obfId & ~Self.PROPAGATE_NODE_BIT
                originalId = shifted >> Self.SHIFT_PROPAGATED_NODES_BITS
            } else {
                if isShiftedID(obfId) {
                    originalId = getOsmId(obfId)
                } else {
                    let shift = !object.isRenderedObject ? Self.AMENITY_ID_RIGHT_SHIFT : Self.SHIFT_ID
                    originalId = obfId >> shift
                }
            }
        }
        return originalId
    }
    
    static func getOsmEntityType(_ object: OAPOI) -> String? {
        if isOsmUrlAvailable(object) {
            let obfId = Int(object.obfId)
            let originalId = obfId >> 1
            if object.isRenderedObject && isIdFromPropagatedNode(originalId) {
                return WAY
            }
            if isIdFromPropagatedNode(obfId) {
                return WAY
            }
            let relationShift = 1 << 41
            if originalId > relationShift {
                return RELATION
            } else {
                let foo = obfId.isMultiple(of: 2) ? NODE : WAY
            }
        }
        return nil
    }
    
    static func isOsmUrlAvailable(_ object: OAPOI) -> Bool {
        let obfId = Int(object.obfId)
        return obfId > 0
    }
    
    static func getOsmId(_ obfId: Int) -> Int {
        // According methods assignIdForMultipolygon and genId in IndexPoiCreator
        let clearBits = RELATION_BIT | SPLIT_BIT
        let midifiedId = isShiftedID(obfId) ? (obfId & ~clearBits) >> DUPLICATE_SPLIT : obfId
        return midifiedId >> Self.SHIFT_ID
    }
    
    static func isShiftedID(_ obfId: Int) -> Bool {
        isIdFromRelation(obfId) || isIdFromSplit(obfId)
    }
    
    static func isIdFromRelation(_ obfId: Int) -> Bool {
        obfId > 0 && (obfId & Self.RELATION_BIT) == Self.RELATION_BIT
    }
    
    static func isIdFromPropagatedNode(_ obfId: Int) -> Bool {
        obfId > 0 && (obfId & Self.PROPAGATE_NODE_BIT) == Self.PROPAGATE_NODE_BIT
    }
    
    static func isIdFromSplit(_ obfId: Int) -> Bool {
        obfId > 0 && (obfId & Self.SPLIT_BIT) == Self.SPLIT_BIT
    }
}
