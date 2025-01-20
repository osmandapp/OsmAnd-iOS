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
    
    override func getTypeStr() -> String {
        if renderedObject.isPolygon {
            return getTranslatedType(renderedObject: renderedObject)
        }
        return super.getTypeStr()
    }
    
    // TODO: rewrite from objc from OAPOIHelper
    private func getTranslatedType(renderedObject: OARenderedObject) -> String {
        return ""
    }
    
    override func getIcon() -> UIImage {
        if let iconRes = getIconRes() {
            return UIImage.templateImageNamed(iconRes)
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
