//
//  AdditionalInfoBundle.swift
//  OsmAnd
//
//  Created by Max Kojin on 02/10/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
public class AdditionalInfoBundle: NSObject {
    
    private static let HIDDEN_EXTENSIONS: [String] = [COLOR_NAME_EXTENSION_KEY, ICON_NAME_EXTENSION_KEY, BACKGROUND_TYPE_EXTENSION_KEY, PROFILE_TYPE_EXTENSION_KEY, ADDRESS_EXTENSION_KEY, AMENITY_ORIGIN_EXTENSION_KEY, POITYPE, SUBTYPE]
    
    private let additionalInfo: [String: String]?
    private var filteredAdditionalInfo: [String: String]?
    private var localizedAdditionalInfo: [String: Any]?
    private var customHiddenExtensions: [String] = []
    
    init(additionalInfo: [String: String]) {
        self.additionalInfo = additionalInfo
    }
    
    func getFilteredLocalizedInfo() -> [String: Any] {
        if localizedAdditionalInfo == nil {
            localizedAdditionalInfo = MergeLocalizedTagsAlgorithm.shared.execute(originalDict: getFilteredInfo() ?? [:])
        }
        return localizedAdditionalInfo ?? [:]
    }
    
    func getFilteredInfo() -> [String: String]? {
        if filteredAdditionalInfo == nil {
            var result = [String: String]()
            for origKey in getAdditionalInfoKeys() {
                var key: String?
                if origKey == AMENITY_PREFIX + OPENING_HOURS_TAG {
                    key = origKey.replacingOccurrences(of: AMENITY_PREFIX, with: "")
                } else if origKey.hasPrefix(AMENITY_PREFIX) {
                    continue
                } else {
                    key = origKey.replacingOccurrences(of: OSM_PREFIX_KEY, with: "")
                }
                
                if let key {
                    if !Self.HIDDEN_EXTENSIONS.contains(key) &&
                        (customHiddenExtensions.isEmpty || !customHiddenExtensions.contains(key)) {
                        result[key] = get(key)
                    }
                }
            }
            
            filteredAdditionalInfo = result
        }
        return filteredAdditionalInfo
    }
    
    func containsAny(_ keys: [String]) -> Bool {
        for key in keys {
            if contains(key) {
                return true
            }
        }
        return false
    }
    
    func contains(_ key: String) -> Bool {
        getAdditionalInfoKeys().contains(key)
    }
    
    func getAdditionalInfoKeys() -> [String] {
        if let additionalInfo {
            return Array(additionalInfo.keys)
        }
        return []
    }
    
    func get(_ key: String) -> String? {
        if let additionalInfo {
            let str = additionalInfo[key]
            // TODO: implement if needed
            // str = Amenity.unzipContent(str);
            return str
        }
        return nil
    }
    
    func setCustomHiddenExtensions(_ extensions: [String]) {
        filteredAdditionalInfo = nil
        localizedAdditionalInfo = nil
        customHiddenExtensions = extensions
    }
}
