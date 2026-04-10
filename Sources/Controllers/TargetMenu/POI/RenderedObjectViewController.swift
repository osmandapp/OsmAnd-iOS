//
//  RenderedObjectViewController.swift
//  OsmAnd
//
//  Created by Max Kojin on 20/01/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

// analog in android: RenderedObjectMenuBuilder.java

@objcMembers
final class RenderedObjectViewController: OAPOIViewController {
    
    private var renderedObject: OARenderedObject?
    private var detailedObject: BaseDetailsObject?
    
    private var cachedNameStr: String?
    private var cachedTypeStr: String?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(renderedObject: OARenderedObject) {
        let poi = BaseDetailsObject.convertRenderedObjectToAmenity(renderedObject)
        super.init(poi: poi)
        self.renderedObject = renderedObject
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "OAPOIViewController", bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        updateMenuWithDetailedObject()
        super.viewDidLoad()
    }
    
    override func getNameStr() -> String? {
        let name = getNameOnlyStr()
        
        if !name.isEmpty {
            return name
        }
        
        return getTypeStr()
    }
    
    override func getTypeStr() -> String? {
        if let cachedTypeStr, !cachedTypeStr.isEmpty {
            return cachedTypeStr
        }
        
        guard let renderedObject else {
            cachedTypeStr = super.getTypeStr()
            return cachedTypeStr
        }
        
        let amenity: OAPOI? = {
            if let detailedObject {
                return detailedObject.syntheticAmenity
            } else {
                return BaseDetailsObject.convertRenderedObjectToAmenity(renderedObject)
            }
        }()
        
        if let amenity {
            cachedTypeStr = searchObjectTypeByAmenityTags(amenity)
        }
        
        if cachedTypeStr?.isEmpty ?? true {
            let additionalInfoKeys = amenity?.getAdditionalInfoKeys()
            
            cachedTypeStr = searchObjectNameByRawTags(
                tags: renderedObject.tags as? [String: String],
                additionalInfoKeys: additionalInfoKeys
            )
        }
        
        return cachedTypeStr != nil ? cachedTypeStr : super.getTypeStr()
    }
    
    override func getIcon() -> UIImage? {
        guard let renderedObject else { return super.getIcon() }
        guard detailedObject == nil else {
            return detailedObject?.syntheticAmenity.icon()
        }
        return RenderedObjectHelper.getIcon(renderedObject: renderedObject)
    }
    
    override func getOsmUrl() -> String {
        guard let renderedObject else { return super.getOsmUrl() }
        return ObfConstants.getOsmUrlForId(renderedObject)
    }
    
    private func updateMenuWithDetailedObject() {
        guard let renderedObject else { return }
        guard let details = OAAmenitySearcher.sharedInstance().searchDetailedObject(renderedObject) else { return }
        detailedObject = details
        let amenity = details.syntheticAmenity
        setup(amenity)
        updateTargetPoint(with: amenity)
        rebuildRows()
        tableView.reloadData()
    }
    
    private func updateTargetPoint(with amenity: OAPOI) {
        guard let mapPanel = OARootViewController.instance()?.mapPanel,
              let targetPoint = mapPanel.getCurrentTargetPoint() else { return }
        
        targetPoint.title = amenity.nameLocalized ?? amenity.name
        targetPoint.icon = amenity.type?.icon()
        
        mapPanel.update(targetPoint)
    }
    
    private func searchObjectNameByRawTags(tags: [String: String]?,
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
    
    private func getNameOnlyStr() -> String {
        if let cachedNameStr, !cachedNameStr.isEmpty {
            return cachedNameStr
        }
        
        let lang = preferredMapAppLang()
        let transliterate = OAAppSettings.sharedManager().settingMapLanguageTranslit.get()
        
        cachedNameStr = renderedObject?.getName(lang, transliterate: transliterate)
        
        if let name = cachedNameStr, !name.isEmpty, !isStartingWithRTLChar(name) {
            return name
        } else if let renderedObject, renderedObject.tags.count > 0 {
            if !lang.isEmpty {
                cachedNameStr = renderedObject.tags["name:\(lang)"] as? String
            }
            
            if cachedNameStr?.isEmpty ?? true {
                cachedNameStr = renderedObject.tags["name"] as? String
            }
        }
        
        return cachedNameStr ?? ""
    }
    
    private func searchObjectTypeByAmenityTags(_ amenity: OAPOI) -> String? {
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
    
    private func isStartingWithRTLChar(_ s: String) -> Bool {
        guard let firstScalar = s.first?.unicodeScalars.first else { return false }
        
        let firstCharString = String(firstScalar)
        let direction = NSLocale.characterDirection(forLanguage: firstCharString)
        
        return direction == .rightToLeft
    }
    
    private func preferredMapAppLang() -> String {
        let lang = OAAppSettings.sharedManager().settingPrefMapLanguage.get()
        return lang.isEmpty ? "en" : lang
    }
}
