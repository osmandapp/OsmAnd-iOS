//
//  OAMapSelectionResult.swift
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

@objcMembers
class OAMapSelectionResult: NSObject {
    
    private var lang: String
    private var point: CGPoint
    var pointLatLon: CLLocation?
    var objectLatLon: CLLocation?
    
    private var poiProvider: OAContextMenuProvider
    
    private var allObjects: Array<OASelectedMapObject>
    private var processedObjects: Array<OASelectedMapObject>
    
    init(point: CGPoint) {
        self.point = point
        self.allObjects = Array()
        self.processedObjects = Array()
        
        let mapVc = OARootViewController.instance().mapPanel.mapViewController
        let loc = mapVc.getLatLon(fromElevatedPixel: point.x, y: point.y)
        self.pointLatLon = loc
        self.poiProvider = mapVc.getMapPoiLayer()
        self.lang = LocaleHelper.getPreferredPlacesLanguage()
        
        super.init()
    }
    
    func getPoint() -> CGPoint {
        return point
    }
    
    func getAllObjects() -> Array<OASelectedMapObject> {
        return allObjects
    }
    
    func getProcessedObjects() -> Array<OASelectedMapObject> {
        return processedObjects
    }
    
    func collect(_ object: Any, provider: Any) {
        allObjects.append(OASelectedMapObject(mapObject: object, provider: provider as? OAContextMenuProvider))
    }
    
    func groupByOsmIdAndWikidataId() {
        if allObjects.count == 1 {
            processedObjects.append(contentsOf: allObjects)
            return
        }
        
        var other = Array<OASelectedMapObject>()
        var detailsObjects = processObjects(allObjects, other: &other)
        
        for object in detailsObjects {
            if object.getObjects().count > 1 {
                let selectedObject = OASelectedMapObject(mapObject: object, provider: poiProvider)
                processedObjects.append(selectedObject)
            } else {
                let selectedObject = OASelectedMapObject(mapObject: object.getObjects()[0], provider: poiProvider)
                processedObjects.append(selectedObject)
            }
        }
        processedObjects.append(contentsOf: other)
    }
    
    private func processObjects(_ selectedObjects: Array<OASelectedMapObject>, other: inout Array<OASelectedMapObject>) -> Array<OABaseDetailsObject> {
        var detailsObjects = Array<OABaseDetailsObject>()
        for selectedObject in selectedObjects {
            let object = selectedObject.getObject()
            var overlapped = collectOverlappedObjects(object, detailsObjects: detailsObjects)
            
            let detailsObject: OABaseDetailsObject
            if overlapped.count == 0 {
                detailsObject = OABaseDetailsObject(lang: lang)
            } else {
                detailsObject = overlapped[0]
                for i in 1..<overlapped.count {
                    detailsObject.merge(overlapped[i])
                }

                detailsObjects.removeAll { overlapped.contains($0) }
            }
            
            if detailsObject.addObject(object) {
                detailsObjects.append(detailsObject)
            } else {
                other.append(selectedObject)
            }
        }
        return detailsObjects
    }
    
    private func collectOverlappedObjects(_ object: Any, detailsObjects: Array<OABaseDetailsObject>) -> Array<OABaseDetailsObject> {
        var overlapped = Array<OABaseDetailsObject>()
        for detailsObject in detailsObjects {
            if detailsObject.overlapsWith(object) {
                overlapped.append(detailsObject)
            }
        }
        return overlapped
    }
    
    func isEmpty() -> Bool {
        return allObjects.count == 0
    }
} 
