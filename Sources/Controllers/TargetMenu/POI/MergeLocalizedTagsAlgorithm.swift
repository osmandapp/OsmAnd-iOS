//
//  MergeLocalizedTagsAlgorithm.swift
//  OsmAnd
//
//  Created by Max Kojin on 03/10/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class MergeLocalizedTagsAlgorithm: NSObject {
    
    private let NAME_TAG_PREFIXES = ["name", "int_name", "nat_name", "reg_name", "loc_name",
    "old_name", "alt_name", "short_name", "official_name", "lock_name"]
    
    private override init() {}
    
    static let shared = MergeLocalizedTagsAlgorithm()
    
    func execute(originalDict: [String: Any]) -> [String: Any] {
        executeImpl(originalDict)
    }
    
    private func executeImpl(_ originalDict: [String: Any]) -> [String: Any] {
        var resultDict: [String: Any] = [:]
        let langDict = applyLanguageOverride(originalDict)
        var localizationsDict: [String: [String: Any]] = [:]

        for key in langDict.keys {
            let converted = convertKey(key)
            processAdditionalTypeWithKey(key: key, convertedKey: converted, originalDict: langDict, localizationsDict: &localizationsDict, resultDict: &resultDict)
        }

        let keysToUpdate = findKeysToUpdate(localizationsDict)
        for baseKey in keysToUpdate {
            var localizations = localizationsDict[baseKey]
            
            if let value = langDict[baseKey] {
                localizations?[baseKey] = value
            } else {
                continue
            }
        }

        var finalDict = finalizeLocalizationDict(localizationsDict)
        addRemainingEntriesFrom(resultDict, into: &finalDict)
        return finalDict
    }
    
    private func applyLanguageOverride(_ originalDict: [String: Any]) -> [String: Any] {
        var processedDict = originalDict
        
        let langYesPrefix = LANG_YES + ":"
        let langKeys = processedDict.keys.filter { $0.hasPrefix(langYesPrefix) && processedDict[$0] as! String == "yes" }
        
        if langKeys.count == 1, let langKey = langKeys.first {
            let langCode = String(langKey.dropFirst(langYesPrefix.count))
            
            renameTagInMap(&processedDict, oldKey: POI_NAME, newKey: POI_NAME + ":" + langCode)
            renameTagInMap(&processedDict, oldKey: DESCRIPTION_TAG, newKey: DESCRIPTION_TAG + ":" + langCode)
        }
        return processedDict
    }
    
    private func renameTagInMap(_ dict: inout [String: Any], oldKey: String, newKey: String) {
        if let value = dict.removeValue(forKey: oldKey) {
            dict[newKey] = value
        }
    }
    
    private func processNameTagWithKey(key: String, convertedKey: String, originalDict: [String: Any], localizationsDict: inout [String: [String: Any]]) {
        if key.contains(":") {
            let components = convertedKey.components(separatedBy: ":")
            if components.count == 2 {
                let baseKey = components[0]
                let localeKey = "\(baseKey):\(components[1])"
                
                if let value = originalDict[convertedKey] {
                    var nameDict = dictionaryForKey(key: "name", dict: &localizationsDict)
                    nameDict[localeKey] = value
                }
            }
        } else {
            if let value = originalDict[key] {
                var nameDict = dictionaryForKey(key: "name", dict: &localizationsDict)
                nameDict[convertedKey] = value
            }
        }
    }
    
    private func processAdditionalTypeWithKey(key: String, convertedKey: String, originalDict: [String: Any], localizationsDict: inout [String: [String: Any]], resultDict: inout [String: Any]) {
        let poiType = OAPOIHelper.sharedInstance().getAnyPoiAdditionalType(byKey: convertedKey)
        
        if poiType?.lang != nil, key.contains(":") {
            let components = key.components(separatedBy: ":")
            if components.count == 2 {
                let baseKey = components[0]
                let localeKey = "\(baseKey):\(components[1])"
                
                if let value = originalDict[key] {
                    var baseDict = dictionaryForKey(key: baseKey, dict: &localizationsDict)
                    baseDict[localeKey] = value
                }
            }
        } else {
            if let value = originalDict[key] {
                resultDict[key] = value
            }
        }
    }
    
    private func dictionaryForKey(key: String, dict: inout [String: [String: Any]]) -> [String: Any] {
        if dict[key] == nil {
            dict[key] = [:]
        }
        return dict[key] ?? [:]
    }
    
    private func findKeysToUpdate(_ localizationsDict: [String: [String: Any]]) -> [String] {
        var keysToUpdate = [String]()
        for baseKey in localizationsDict.keys {
            if let localizations = localizationsDict[baseKey], localizations[baseKey] == nil {
                keysToUpdate.append(baseKey)
            }
        }
        return keysToUpdate
    }
    
    private func finalizeLocalizationDict(_ localizationsDict: [String: [String: Any]]) -> [String: Any] {
        var finalDict: [String: Any] = [:]
        
        for baseKey in localizationsDict.keys {
            var entryDict = [String: Any]()
            if let localizations = localizationsDict[baseKey] {
                entryDict["localizations"] = localizations
            }
            finalDict[baseKey] = entryDict
        }
        return finalDict
    }
    
    private func addRemainingEntriesFrom(_ resultDict: [String: Any], into finalDict: inout [String: Any]) {
        for (key, value) in resultDict {
            if finalDict[key] == nil {
                finalDict[key] = value
            }
        }
    }
    
    private func isNameTag(_ tag: String) -> Bool {
        for prefix in NAME_TAG_PREFIXES {
            if tag.hasPrefix(prefix) {
                return true
            }
        }
        return false
    }
    
    private func convertKey(_ key: String) -> String {
        key.replacingOccurrences(of: XML_COLON, with: ":")
    }
}
