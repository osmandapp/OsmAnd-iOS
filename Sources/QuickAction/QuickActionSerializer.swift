//
//  QuickActionSerializer.swift
//  OsmAnd Maps
//
//  Created by Skalii on 27.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAQuickActionSerializer)
@objcMembers
class QuickActionSerializer: NSObject {

    private var quickActionTypesStr: [String: QuickActionType] = [:]
    private var quickActionTypesInt: [Int: QuickActionType] = [:]

    func setQuickActionTypesStr(_ quickActionTypesStr: [String: QuickActionType]) {
        self.quickActionTypesStr = quickActionTypesStr
    }

    func setQuickActionTypesInt(_ quickActionTypesInt: [Int: QuickActionType]) {
        self.quickActionTypesInt = quickActionTypesInt
    }

    func deserialize(_ json: Data) throws -> [OAQuickAction] {
        let obj = try JSONSerialization.jsonObject(with: json, options: []) as? [[AnyHashable: Any]] ?? [[:]]
        var quickActions = [OAQuickAction]()
        for json in obj {
            if let quickAction = try getObjFromJson(json) {
                quickActions.append(quickAction)
            }
        }
        return quickActions
    }

    func serialize(_ quickActions: [OAQuickAction]) throws -> Data {
        var objs = [[String: Any]]()
        for quickAction in quickActions {
            objs.append(try getJsonFromObj(quickAction))
        }
        return try JSONSerialization.data(withJSONObject: objs)
    }

    private func getJsonFromObj(_ quickAction: OAQuickAction) throws -> [String: Any] {
        var obj: [String: Any] = [:]
        obj["actionType"] = quickAction.actionType?.stringId
        obj["id"] = NSNumber(value: quickAction.id)
        obj["name"] = quickAction.getRawName()
        
        let params = Self.adjustParamsForExport(quickAction.getParams(), action: quickAction)
        if let jsonData = try? JSONSerialization.data(withJSONObject: params) {
            obj["params"] = String(data: jsonData, encoding: .utf8)
        }
        return obj
    }

    private func getObjFromJson(_ json: [AnyHashable: Any]) throws -> OAQuickAction? {
        var found: QuickActionType?
        if let actionType = json["actionType"] as? String {
            found = quickActionTypesStr[actionType]
        } else if let type = json["type"] as? Int {
            found = quickActionTypesInt[type]
        }
        if let found = found {
            let qa = found.createNew()
            if let name = json["name"] as? String {
                qa.setName(name)
            }
            if let id = json["id"] as? NSNumber {
                qa.setId(id.intValue)
            }
            if let params = json["params"] as? String {
                OAQuickActionsSettingsItem.parseParams(params, quickAction: qa)
            }
            return qa
        }
        return nil
    }

    static func adjustParamsForExport(_ params: [AnyHashable: Any], action: OAQuickAction) -> [AnyHashable: Any] {
         if action is OASwitchableAction<AnyObject>, let switchableAction = action as? OASwitchableAction<AnyObject> {
             var paramsCopy = params
             let className = String(describing: type(of: action))
             let key: String = switchableAction.getListKey()
             if className == String(describing: OAMapStyleAction.self) {
                 if let values = params[key] as? [String], !values.isEmpty {
                     paramsCopy[key] = values.joined(separator: ",")
                 }
                 return paramsCopy
             }
             if let values = params[key] as? [Any], !values.isEmpty {
                 if let data = paramsToExportArray(values) {
                     if let stringData = String(data: data, encoding: .utf8) {
                         paramsCopy[key] = stringData
                     }
                 }
             }

            return paramsCopy
        }
        return params
    }

    static func parseParamsFromString(_ params: String) -> [Any] {
        if let jsonData = params.data(using: .utf8) {
            if let jsonArr = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) {
                if let jsonDictArr = jsonArr as? [[String: Any]] {
                    var res = [[String]]()
                    for pair in jsonDictArr {
                        if let first = pair["first"] as? String, let second = pair["second"] as? String {
                            res.append([first, second])
                        }
                    }
                    return res
                } else if let array = jsonArr as? [String] {
                    return array
                } else if let str = jsonArr as? String {
                    return str.components(separatedBy: ",")
                } else if let arrArr = jsonArr as? [[String]] {
                    return arrArr
                }
            }
        }
        return params.components(separatedBy: ",")
    }

    private static func paramsToExportArray(_ params: [Any]?) -> Data? {
        do {
            if let array = params as? [[String]], !array.isEmpty {
                var res = [[String: String]]()
                for pair in array where pair.count == 2 {
                    res.append(["first": pair[0], "second": pair[1]])
                }
                return try JSONSerialization.data(withJSONObject: res)
            } else if let array = params as? [NSNumber], !array.isEmpty {
                let res = array.map { $0.stringValue }
                return try JSONSerialization.data(withJSONObject: res)
            } else if let array = params as? [String], !array.isEmpty {
                return try JSONSerialization.data(withJSONObject: array)
            }
        } catch {
            return nil
        }
        return nil
    }
}
