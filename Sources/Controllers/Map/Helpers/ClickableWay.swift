//
//  ClickableWay.swift
//  OsmAnd
//
//  Created by Max Kojin on 07/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation
import CoreLocation

@objcMembers
final class ClickableWay: NSObject {
    
    private let osmId: UInt64
    private let name: String?
    private let bbox: KQuadRect
    private let gpxFile: GpxFile
    private let selectedGpxPoint: SelectedGpxPoint
    
    init(gpxFile: GpxFile, osmId: UInt64, name: String?, selectedLatLon: CLLocation, bbox: KQuadRect) {
        self.gpxFile = gpxFile
        self.osmId = osmId
        self.name = name
        self.bbox = bbox
        
        let wpt = WptPt()
        wpt.lat = selectedLatLon.coordinate.latitude
        wpt.lon = selectedLatLon.coordinate.longitude
        self.selectedGpxPoint = SelectedGpxPoint(selectedGpxFile: nil, selectedPoint: wpt)
        
        super.init()
    }
    
    func getOsmId() -> UInt64 {
        osmId
    }
    
    func getBbox() -> KQuadRect {
        bbox
    }
    
    func getGpxFile() -> GpxFile {
        gpxFile
    }
    
    func getSelectedGpxPoint() -> SelectedGpxPoint {
        selectedGpxPoint
    }
    
    func getGpxFileName() -> String {
        getWayName().sanitizeFileName()
    }
    
    func getWayName() -> String {
        if let name, !name.isEmpty {
            return name
        } else {
            let altName = gpxFile.getExtensionsToRead()["ref"]
            return altName ?? String(osmId)
        }
    }
    
    func toString() -> String {
        getWayName()
    }
} 
