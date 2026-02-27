//
//  MapSelectionResult.swift
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

// OsmAnd/src/net/osmand/plus/views/layers/MapSelectionResult.java
// git revision 744c6b5831ca13767b936d62be8c78138b8dda08

import CoreLocation

@objcMembers
final class MapSelectionResult: NSObject {
    
    var pointLatLon: CLLocation?
    var objectLatLon: CLLocation?
    
    private(set) var point: CGPoint
    private(set) var allObjects: Array<SelectedMapObject>
    
    private var lang: String
    private var poiProvider: OAContextMenuProvider
    private var processedObjects: Array<SelectedMapObject>
    
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
    
    func getProcessedObjects() -> [SelectedMapObject] {
        processedObjects
    }

    func collect(_ object: Any, provider: Any?, toBegin: Bool = false) {
        if toBegin {
            allObjects.insert(SelectedMapObject(mapObject: object, provider: provider as? OAContextMenuProvider), at: 0)
        } else {
            allObjects.append(SelectedMapObject(mapObject: object, provider: provider as? OAContextMenuProvider))
        }
    }

    func collect(_ object: Any, provider: Any?) {
        collect(object, provider:provider, toBegin:false)
    }

    func groupByOsmIdAndWikidataId() {
        if allObjects.count == 1 {
            processedObjects.append(contentsOf: allObjects)
            return
        }
        
        var other = [SelectedMapObject]()
        let detailsObjects = processObjects(allObjects, other: &other)
        
        for object in detailsObjects {
            if object.objects.count > 1 {
                let selectedObject = SelectedMapObject(mapObject: object, provider: poiProvider)
                processedObjects.append(selectedObject)
            } else {
                let selectedObject = SelectedMapObject(mapObject: object.objects[0], provider: poiProvider)
                processedObjects.append(selectedObject)
            }
        }
        processedObjects.append(contentsOf: other)
    }
    
    func isEmpty() -> Bool {
        allObjects.isEmpty
    }
    
    private func processObjects(_ selectedObjects: Array<SelectedMapObject>, other: inout Array<SelectedMapObject>) -> Array<BaseDetailsObject> {
        var detailsObjects = Array<BaseDetailsObject>()
        for selectedObject in selectedObjects {
            let object = selectedObject.object
            let overlapped = collectOverlappedObjects(object, detailsObjects: detailsObjects)
            
            let detailsObject: BaseDetailsObject
            if overlapped.count == 0 {
                detailsObject = BaseDetailsObject(lang: lang)
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
    
    private func collectOverlappedObjects(_ object: Any, detailsObjects: [BaseDetailsObject]) -> [BaseDetailsObject] {
        detailsObjects.filter { $0.overlapsWith(object) }
    }
} 
