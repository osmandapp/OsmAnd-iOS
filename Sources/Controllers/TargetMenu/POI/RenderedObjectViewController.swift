//
//  RenderedObjectViewController.swift
//  OsmAnd
//
//  Created by Max Kojin on 20/01/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class RenderedObjectViewController: OAPOIViewController {
    
    private var renderedObject: OARenderedObject!
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "OAPOIViewController", bundle: nibBundleOrNil)
    }
    
    init(renderedObject: OARenderedObject) {
        let poi = Self.getSyntheticAmenity(renderedObject: renderedObject)
        super.init(poi: poi)
        self.renderedObject = renderedObject
    }
    
    override func mapObject() -> OAMapObject! {
        renderedObject
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUIAfterAmenitySearch()
    }
    
    private func updateUIAfterAmenitySearch() {
        Task {
            do {
                if let foundAmenity = try await searchAmenity() {
                    await MainActor.run {
                        setup(foundAmenity)
                        rebuildRows()
                        tableView.reloadData()
                    }
                }
            } catch {
                print("Poi finding error: \(error)")
            }
        }
    }
    
    private func searchAmenity() async throws -> OAPOI? {
        OAPOIHelper.findPOI(byOsmId: ObfConstants.getOsmObjectId(renderedObject), lat: poi.latitude, lon: poi.longitude)
    }
    
    static func getSyntheticAmenity(renderedObject: OARenderedObject) -> OAPOI {
        let poi = OAPOI()
        poi.type = OAPOIHelper.sharedInstance().getDefaultOtherCategoryType()
        poi.subType = ""
        
        var pt: OAPOIType?
        var otherPt: OAPOIType?
        var subtype: String?
        var additionalInfo = [String: String]()
        var localizedNames = [String: String]()
        
        for e in renderedObject.tags {
            guard let tag = e.key as? String, let value = e.value as? String else { continue }
            
            if tag == "name" {
                poi.name = value
                continue
            }
            if tag.hasPrefix("name:") {
                localizedNames[tag.substring(to: "name:".length)] = value
                continue
            }
            if tag == "amenity" {
                if let pt {
                    otherPt = pt
                }
                pt = OAPOIHelper.sharedInstance().getPoiType(byKey: value)
            } else {
                if let poiType = OAPOIHelper.sharedInstance().getPoiType(byKey: tag + "_" + value) {
                    otherPt = pt != nil ? poiType : otherPt
                    subtype = pt == nil ? value : subtype
                    pt = pt == nil ? poiType : pt
                }
            }
            if value.isEmpty && otherPt == nil {
                otherPt = OAPOIHelper.sharedInstance().getPoiType(byKey: tag)
            }
            if otherPt == nil {
                let poiType = OAPOIHelper.sharedInstance().getPoiType(byKey: value)
                if let poiType, poiType.getOsmTag() == tag {
                    otherPt = poiType
                }
            }
            if !value.isEmpty {
                let translate = OAPOIHelper.sharedInstance().getTranslation(tag + "_" + value)
                let translate2 = OAPOIHelper.sharedInstance().getTranslation(value)
                if let translate, let translate2 {
                    additionalInfo[translate] = translate2
                } else {
                    additionalInfo[tag] = value
                }
            }
        }
        
        if let pt {
            poi.type = pt
        } else if let otherPt {
            poi.type = otherPt
        }
        if let subtype {
            poi.subType = subtype
        }
        
        poi.obfId = renderedObject.obfId
        poi.values = additionalInfo
        poi.localizedNames = localizedNames
        poi.latitude = renderedObject.labelLatLon.latitude
        poi.longitude = renderedObject.labelLatLon.longitude
        poi.setXYPoints(renderedObject)
        poi.name = poi.name != nil && poi.name.length > 0 ? poi.name : renderedObject.name;
        
        return poi
    }
    
    override func getTypeStr() -> String? {
        if renderedObject.isPolygon {
            return Self.getTranslatedType(renderedObject: renderedObject)
        }
        return super.getTypeStr()
    }
    
    static func getTranslatedType(renderedObject: OARenderedObject) -> String? {
        var pt: OAPOIType?
        var otherPt: OAPOIType?
        var translated: String?
        var firstTag: String?
        var separate: String?
        var single: String?
        
        for item in renderedObject.tags {
            guard let key = item.key as? String, let value = item.value as? String else { continue }
            
            if key.hasPrefix("name") {
                continue
            }
            if value.isEmpty && otherPt == nil {
                otherPt = OAPOIHelper.sharedInstance().getPoiType(byKey: key)
            }
            pt = OAPOIHelper.sharedInstance().getPoiType(byKey: key + "_" + value)
            if let pt {
                break
            }
            firstTag = (firstTag == nil || firstTag!.isEmpty) ? key + ": " + value : firstTag
            if !value.isEmpty {
                let t = OAPOIHelper.sharedInstance().getTranslation(key + "_" + value)
                if let t, translated == nil && !t.isEmpty {
                    translated = t
                }
                let t1 = OAPOIHelper.sharedInstance().getTranslation(key)
                let t2 = OAPOIHelper.sharedInstance().getTranslation(value)
                if let t1, let t2, separate == nil {
                    separate = t1 + ": " + t2.lowercased()
                }
                if let t2, single == nil && value != "yes" && value != "no" {
                    single = t2
                }
                if key == "amenity" {
                    translated = t2
                }
            }
        }
        if let pt {
            return pt.nameLocalized
        }
        if let translated {
            return translated
        }
        if let otherPt {
            return otherPt.nameLocalized;
        }
        if let separate {
            return separate
        }
        if let single {
            return single
        }
        return firstTag
    }
    
    override func getIcon() -> UIImage? {
        return Self.getIcon(renderedObject: renderedObject)
    }
        
    static func getIcon(renderedObject: OARenderedObject) -> UIImage? {
        if let iconRes = getIconRes(renderedObject) {
            if let icon = UIImage(named: iconRes) {
                return icon
            } else {
                return UIImage.mapSvgImageNamed(iconRes)
            }
        } else {
            return UIImage.templateImageNamed("ic_action_street_name")
        }
    }
    
    private static func getIconRes(_ renderedObject: OARenderedObject) -> String? {
        if renderedObject.isPolygon {
            for e in renderedObject.tags {
                guard let value = e.value as? String else { continue }
                
                if let pt = OAPOIHelper.sharedInstance().getPoiType(byKey: value) {
                    return pt.iconName()
                }
            }
        }
        return getActualContent(renderedObject)
    }
    
    private static func getActualContent(_ renderedObject: OARenderedObject) -> String? {
        let content = renderedObject.iconRes
        if content == "osmand_steps" {
            return "highway_steps"
        }
        return content
    }
}
