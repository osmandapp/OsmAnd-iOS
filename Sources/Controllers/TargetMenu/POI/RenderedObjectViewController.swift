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
    
    private static func getSyntheticAmenity(renderedObject: OARenderedObject) -> OAPOI {
        let poi = OAPOI()
        poi.type = OAPOIHelper.sharedInstance().getDefaultOtherCategoryType()
        poi.subType = ""
        
        var pt: OAPOIType?
        var otherPt: OAPOIType?
        var subtype: String?
        var additionalInfo = [String: String]()
        var localizedNames = [String: String]()
        
        for e in renderedObject.tags {
            let tag = e.key
            let value = e.value
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
        
        return poi
    }
    
    override func getTypeStr() -> String? {
        if renderedObject.isPolygon {
            return Self.getTranslatedType(renderedObject: renderedObject)
        }
        return super.getTypeStr()
    }
    
    // TODO: rewrite from objc from OAPOIHelper
    public static func getTranslatedType(renderedObject: OARenderedObject) -> String? {
        var pt: OAPOIType?
        var otherPt: OAPOIType?
        var translated: String?
        var firstTag: String?
        var separate: String?
        var single: String?
        
        for item in renderedObject.tags {
            if item.key.hasPrefix("name") {
                continue
            }
            if item.value.isEmpty && otherPt == nil {
                otherPt = OAPOIHelper.sharedInstance().getPoiType(byKey: item.key)
            }
            pt = OAPOIHelper.sharedInstance().getPoiType(byKey: item.key + "_" + item.value)
            if let pt {
                break
            }
            firstTag = (firstTag == nil || firstTag!.isEmpty) ? item.key + ": " + item.value : firstTag
            if !item.value.isEmpty {
                let t = OAPOIHelper.sharedInstance().getTranslation(item.key + "_" + item.value)
                if let t, translated == nil && !t.isEmpty {
                    translated = t
                }
                let t1 = OAPOIHelper.sharedInstance().getTranslation(item.key)
                let t2 = OAPOIHelper.sharedInstance().getTranslation(item.value)
                if let t1, let t2, separate == nil {
                    separate = t1 + ": " + t2.lowercased()
                }
                if let t2, single == nil && item.value != "yes" && item.value != "no" {
                    single = t2
                }
                if item.key == "amenity" {
                    translated = t2
                }
            }
        }
        if let pt {
            //TODO: implement
            //return pt.getTranslation();
        }
        if let translated {
            return translated
        }
        if let otherPt {
            //TODO: implement
            //return otherPt.getTranslation();
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
        if let iconRes = getIconRes() {
            if let icon = UIImage(named: iconRes) {
                return icon
            } else {
                return UIImage.mapSvgImageNamed("mx_" + iconRes)
            }
        } else {
            return UIImage.templateImageNamed("ic_action_street_name")
        }
    }
    
    private func getIconRes() -> String? {
        if renderedObject.isPolygon {
            for e in renderedObject.tags {
                if let pt = OAPOIHelper.sharedInstance().getPoiType(byKey: e.value) {
                    return pt.iconName()
                }
            }
        }
        return getActualContent()
    }
    
    private func getActualContent() -> String? {
        let content = renderedObject.iconRes
        if content == "osmand_steps" {
            return "highway_steps"
        }
        return content
    }
}
