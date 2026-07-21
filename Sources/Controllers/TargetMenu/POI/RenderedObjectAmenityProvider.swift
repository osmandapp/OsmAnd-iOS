//
//  RenderedObjectAmenityProvider.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 22.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objcMembers
final class RenderedObjectAmenityProvider: NSObject {
    
    var detailsObject: BaseDetailsObject? {
        didSet {
            cachedNameStr = nil
            cachedTypeStr = nil
        }
    }
    private var renderedObject: OARenderedObject?
    private var cachedNameStr: String?
    private var cachedTypeStr: String?
    
    init(detailsObject: BaseDetailsObject? = nil, renderedObject: OARenderedObject? = nil) {
        self.detailsObject = detailsObject
        self.renderedObject = renderedObject
    }
    
    func searchObjectNameByRawTags(tags: [String: String]?,
                                   additionalInfoKeys: [String]? = nil) -> String? {
        guard let tags else { return nil }
        let helper = OAPOIHelper.sharedInstance()
        let additionalKeys = Set(additionalInfoKeys ?? [])
        for (key, value) in tags {
            if additionalKeys.contains(key) { continue }
            var translation: String?
            if !value.isEmpty {
                translation = helper.translation("\(key)_\(value)", withDefault: false)
            }
            if translation?.isEmpty ?? true {
                translation = helper.translation(key, withDefault: false)
            }
            if let translation, !translation.isEmpty {
                return translation
            }
        }
        return nil
    }
    
    func searchObjectTypeByAmenityTags(_ amenity: OAPOI) -> String? {
        let poiTranslator = OAPOIHelper.sharedInstance()
        
        var translation = poiTranslator.translation(amenity.subType, withDefault: false)
        
        for key in amenity.getAdditionalInfoKeys() {
            let translationKey = key
                .replacingOccurrences(of: "osmand_", with: "")
                .replacingOccurrences(of: ":", with: "_")
            
            let value = amenity.getAdditionalInfo(key)
            
            if let translation, !translation.isEmpty {
                break
            }
            
            if translation?.isEmpty ?? true {
                translation = poiTranslator.translation("\(translationKey)_\(String(describing: value))", withDefault: false)
            }
            
            if translation?.isEmpty ?? true {
                translation = poiTranslator.translation(value, withDefault: false)
            }
            
            if translation?.isEmpty ?? true {
                translation = poiTranslator.translation(translationKey, withDefault: false)
            }
        }
        
        return translation
    }
    
    func preferredMapAppLang() -> String {
        let lang = OAAppSettings.sharedManager().settingPrefMapLanguage.get()
        return lang.isEmpty ? "en" : lang
    }
    
    func nameOnlyString() -> String {
        if let cachedNameStr, !cachedNameStr.isEmpty {
            return cachedNameStr
        }
        
        let lang = preferredMapAppLang()
        let transliterate = OAAppSettings.sharedManager().settingMapLanguageTranslit.get()
        
        cachedNameStr = renderedObject?.getName(lang, transliterate: transliterate)
        
        if let name = cachedNameStr, !name.isEmpty, !name.isStartingWithRTLChar {
            return name
        } else if let renderedObject, renderedObject.isKind(of: OARenderedObject.self), renderedObject.tags.count > 0 {
            if !lang.isEmpty {
                cachedNameStr = renderedObject.tags["name:\(lang)"] as? String
            }
            
            if cachedNameStr?.isEmpty ?? true {
                cachedNameStr = renderedObject.tags["name"] as? String
            }
        }
        
        return cachedNameStr ?? ""
    }
    
    func actualContentFromIconRes() -> String? {
        guard let content = renderedObject?.iconRes, !content.isEmpty else { return nil }
        if content == "osmand_steps" {
            return "highway_steps"
        }
        return content
    }

    func searchObjectNameByIconRes() -> String? {
        guard let content = actualContentFromIconRes() else { return nil }
        let poiTranslator = OAPOIHelper.sharedInstance()
        let parts = content.split(separator: "_").map(String.init)
        for i in parts.indices {
            let key = parts[i...].joined(separator: "_")
            let translation = poiTranslator.translation(key, withDefault: false)
            if let translation, !translation.isEmpty {
                return translation
            }
        }
        return nil
    }

    func typeString(superTypeProvider: (() -> String?)? = nil) -> String? {
        if let cachedTypeStr, !cachedTypeStr.isEmpty {
            return cachedTypeStr
        }
        
        guard let renderedObject else {
            cachedTypeStr = superTypeProvider?()
            return cachedTypeStr
        }
        
        let amenity: OAPOI? = {
            if let detailsObject {
                return detailsObject.syntheticAmenity
            } else {
                return BaseDetailsObject.convertRenderedObjectToAmenity(renderedObject)
            }
        }()
        
        let byTags = amenity.flatMap { searchObjectTypeByAmenityTags($0) }
        let byIcon = searchObjectNameByIconRes()
        let additionalInfoKeys = amenity?.getAdditionalInfoKeys()
        let byRaw = searchObjectNameByRawTags(
            tags: renderedObject.tags as? [String: String],
            additionalInfoKeys: additionalInfoKeys
        )
        cachedTypeStr = [byTags, byIcon, byRaw].compactMap { $0 }.first { !$0.isEmpty }
        
        return cachedTypeStr
    }
}
