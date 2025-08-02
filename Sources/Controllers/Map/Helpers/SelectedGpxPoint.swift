//
//  SelectedGpxPoint.swift
//  OsmAnd
//
//  Created by Max Kojin on 02/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

// OsmAnd/src/net/osmand/plus/mapcontextmenu/controllers/SelectedGpxMenuController.java
// git revision 3cf155a0312432ffd9f85da619e30ca4fb54e195

import Foundation

@objcMembers
class SelectedGpxPoint: NSObject {
    
    private(set) var selectedGpxFile: GpxFile?
    private(set) var selectedPoint: WptPt?
    private var prevPoint: WptPt?
    private var nextPoint: WptPt?
    private var bearing: Double
    private var showTrackPointMenu: Bool
    
    convenience init(selectedGpxFile: GpxFile?, selectedPoint: WptPt?) {
        self.init(selectedGpxFile: selectedGpxFile, selectedPoint: selectedPoint, prevPoint: nil, nextPoint: nil, bearing: Double.nan, showTrackPointMenu: false)
    }
    
    init(selectedGpxFile: GpxFile?, selectedPoint: WptPt?, prevPoint: WptPt?, nextPoint: WptPt?, bearing: Double, showTrackPointMenu: Bool) {
        self.selectedGpxFile = selectedGpxFile
        self.selectedPoint = selectedPoint
        self.prevPoint = prevPoint
        self.nextPoint = nextPoint
        self.bearing = bearing
        self.showTrackPointMenu = showTrackPointMenu
        super.init()
    }
} 
