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

    static let kSwitchProfileStringKeys = "stringKeys"
    static let kSwitchProfileNames = "names"
    static let kSwitchProfileIconNames = "iconsNames"
    static let kSwitchProfileIconColors = "iconsColors"

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
        return try JSONSerialization.data(withJSONObject: objs, options: [])
    }

    private func getJsonFromObj(_ quickAction: OAQuickAction) throws -> [String: Any] {
        var obj: [String: Any] = [:]
        obj["actionType"] = quickAction.actionType?.stringId
        obj["id"] = quickAction.id
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
            if let id = json["id"] as? Int {
                qa.setId(id)
            }
            if let params = json["params"] as? [String: String], let paramsData = try? JSONSerialization.data(withJSONObject: params, options: []) {
                qa.setParams(try JSONDecoder().decode([String: String].self, from: paramsData))
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
             if className == "OAMapStyleAction" {
                 if let values = params[key] as? [String], !values.isEmpty {
                     let res = values.joined(separator: ",")
                     paramsCopy[key] = res
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

            if className == "OASwitchProfileAction" {
                var values = params[key] as? [Any]
                if values == nil || paramsCopy[Self.kSwitchProfileStringKeys] != nil {
                    values = paramsCopy[Self.kSwitchProfileStringKeys] as? [Any]
                    paramsCopy.removeValue(forKey: Self.kSwitchProfileStringKeys)
                    if let data = paramsToExportArray(values) {
                        if let stringData = String(data: data, encoding: .utf8) {
                            paramsCopy[key] = stringData
                        }
                    }
                }
                writeSwitchProfileAction(Self.kSwitchProfileNames, params: params, paramsCopy: &paramsCopy)
                writeSwitchProfileAction(Self.kSwitchProfileIconNames, params: params, paramsCopy: &paramsCopy)
                writeSwitchProfileAction(Self.kSwitchProfileIconColors, params: params, paramsCopy: &paramsCopy)
            }

            return paramsCopy
        }
        return params
    }

    static func parseParamsFromString(_ params: String) -> [[String]] {
        if let jsonData = params.data(using: .utf8) {
            do {
                let jsonArr = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
                if let jsonDictArr = jsonArr as? [[String: Any]] {
                    var res = [[String]]()
                    for pair in jsonDictArr {
                        if let first = pair["first"] as? String, let second = pair["second"] as? String {
                            res.append([first, second])
                        }
                    }
                    return res
                }
                return jsonArr as? [[String]] ?? []
            } catch {
                return []
            }
        }
        return []
    }

    private static func paramsToExportArray(_ params: [Any]?) -> Data? {
        do {
            if let array = params as? [[String]], !array.isEmpty {
                var res = [[String: String]]()
                for pair in array where pair.count == 2 {
                    res.append(["first": pair[0], "second": pair[1]])
                }
                return try JSONSerialization.data(withJSONObject: res, options: [])
            } else if let array = params as? [NSNumber], !array.isEmpty {
                let res = array.map { $0.stringValue }
                return try JSONSerialization.data(withJSONObject: res, options: [])
            } else if let array = params as? [String], !array.isEmpty {
                return try JSONSerialization.data(withJSONObject: array, options: [])
            }
        } catch {
            return nil
        }
        return nil
    }

    static func readSwitchProfileAction(_ key: String, params: NSMutableDictionary) {
        if var values = params[key] as? String {
            if let jsonData = values.data(using: .utf8) {
                do {
                    let json = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
                    if let stringArray = json as? [String] {
                        values = stringArray.joined(separator: ",")
                    }
                } catch {
                    return
                }
            }
            params[key] = values
        } else {
            var values = ""
            if let stringKeys = params[Self.kSwitchProfileStringKeys] as? [String], !stringKeys.isEmpty {
                for (index, stringKey) in stringKeys.enumerated() {
                    if let mode = OAApplicationMode.value(ofStringKey: stringKey, def: OAApplicationMode.default()) {
                        switch key {
                        case Self.kSwitchProfileNames:
                            values += mode.name
                        case Self.kSwitchProfileIconNames:
                            values += mode.getIconName()
                        case Self.kSwitchProfileIconColors:
                            values += "\(mode.getIconColor())"
                        default:
                            break
                        }
                        if index < stringKeys.count - 1 {
                            values += ","
                        }
                    }
                }
            }
            params[key] = values
        }
    }

    private static func writeSwitchProfileAction(_ key: String, params: [AnyHashable: Any], paramsCopy: inout [AnyHashable: Any]) {
        if let values = params[key] as? [Any], !values.isEmpty {
            if let data = paramsToExportArray(values) {
                if let stringData = String(data: data, encoding: .utf8) {
                    paramsCopy[key] = stringData
                }
            }
        }
    }
}
