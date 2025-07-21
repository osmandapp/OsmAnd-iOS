//
//  ObfConstants.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 04/11/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class ObfConstants: NSObject {
    
    static let SHIFT_MULTIPOLYGON_IDS: Int64 = 43
    static let SHIFT_NON_SPLIT_EXISTING_IDS: Int64 = 41
    static let SHIFT_PROPAGATED_NODE_IDS: Int64 = 50
    static let SHIFT_PROPAGATED_NODES_BITS: Int64 = 11
    static let MAX_ID_PROPAGATED_NODES: Int64 = (1 << SHIFT_PROPAGATED_NODES_BITS) - 1     // 2047
    static let RELATION_BIT: Int64 = 1 << (SHIFT_MULTIPOLYGON_IDS - 1)                     // 1L << 42
    static let PROPAGATE_NODE_BIT: Int64 = 1 << (SHIFT_PROPAGATED_NODE_IDS - 1)            // 1L << 41
    static let SPLIT_BIT: Int64 = 1 << (SHIFT_NON_SPLIT_EXISTING_IDS - 1)                  // 1L << 40
    static let DUPLICATE_SPLIT: Int64 = 5                                                  // According IndexPoiCreator DUPLICATE_SPLIT
    
    static private let SHIFT_ID = 6
    static private let AMENITY_ID_RIGHT_SHIFT = 1
    static private let WAY_MODULO_REMAINDER = 1
    
    static private let NODE = kEntityTypeNode
    static private let WAY = kEntityTypeWay
    static private let RELATION = kEntityTypeRelation
    
    static func getOsmUrlForId(_ object: OAMapObject) -> String {
        guard let type = getOsmEntityType(object) else { return "" }
        let osmId = getOsmObjectId(object)
        return "https://www.openstreetmap.org/\(type)/\(osmId)"
    }
    
    static func createMapObjectIdFromOsmId(_ osmId: Int64, type: String?) -> Int64 {
        guard let type else { return osmId }
        
        switch type {
        case NODE:
            return osmId << AMENITY_ID_RIGHT_SHIFT
        case WAY:
            return (osmId << AMENITY_ID_RIGHT_SHIFT) + 1
        case RELATION:
            return RELATION_BIT + ((osmId << SHIFT_ID) << DUPLICATE_SPLIT)
        default:
            return osmId
        }
    }
    
    static func getOsmObjectId(_ object: OAMapObject) -> Int64 {
        var originalId: Int64 = -1
        var obfId = object.obfId
        if obfId != -1 {
            if object is OARenderedObject {
                obfId >>= 1
            }
            if isIdFromPropagatedNode(obfId) {
                let shifted = obfId & ~Self.PROPAGATE_NODE_BIT
                originalId = shifted >> Self.SHIFT_PROPAGATED_NODES_BITS
            } else {
                if isShiftedID(obfId) {
                    originalId = getOsmId(obfId)
                } else {
                    let shift = object is OAPOI ? Self.AMENITY_ID_RIGHT_SHIFT : Self.SHIFT_ID
                    originalId = obfId >> shift
                }
            }
        }
        return originalId
    }
    
    static func getOsmEntityType(_ object: OAMapObject) -> String? {
        if isOsmUrlAvailable(object) {
            let obfId = object.obfId
            let originalId = obfId >> 1
            if object is OARenderedObject && isIdFromPropagatedNode(originalId) {
                return WAY
            }
            if isIdFromPropagatedNode(obfId) {
                return WAY
            }
            let relationShift = 1 << 41
            if originalId > relationShift {
                return RELATION
            } else {
                return obfId.isMultiple(of: 2) ? NODE : WAY
            }
        }
        return nil
    }
    
    static func isOsmUrlAvailable(_ object: OAMapObject) -> Bool {
        return object.obfId > 0
    }
    
    static func getOsmId(_ obfId: Int64) -> Int64 {
        // According methods assignIdForMultipolygon and genId in IndexPoiCreator
        let clearBits = RELATION_BIT | SPLIT_BIT
        let midifiedId = isShiftedID(obfId) ? (obfId & ~clearBits) >> DUPLICATE_SPLIT : obfId
        return midifiedId >> Self.SHIFT_ID
    }
    
    static func isShiftedID(_ obfId: Int64) -> Bool {
        isIdFromRelation(obfId) || isIdFromSplit(obfId)
    }
    
    static func isIdFromRelation(_ obfId: Int64) -> Bool {
        obfId > 0 && (obfId & Self.RELATION_BIT) == Self.RELATION_BIT
    }
    
    static func isIdFromPropagatedNode(_ obfId: Int64) -> Bool {
        obfId > 0 && (obfId & Self.PROPAGATE_NODE_BIT) == Self.PROPAGATE_NODE_BIT
    }
    
    static func isIdFromSplit(_ obfId: Int64) -> Bool {
        obfId > 0 && (obfId & Self.SPLIT_BIT) == Self.SPLIT_BIT
    }
    
    static func isTagIndexedForSearchAsName(_ tag: String?) -> Bool {
        guard let tag = tag else { return false }
        return tag.contains("name") || tag.contains("brand")
    }
        
    static func isTagIndexedForSearchAsId(_ tag: String?) -> Bool {
        guard let tag = tag else { return false }
        return tag == "wikidata" || tag == "route_id"
    }
}
