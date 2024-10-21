//
//  GpxFileExtension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 03.10.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import OsmAndShared
private var gpxProcessedPointsToDisplaKey: UInt8 = 0

@objc(OASGpxFile)
extension GpxFile {
    
    var processedPointsToDisplay: [TrkSegment]? {
        get {
            objc_getAssociatedObject(self, &gpxProcessedPointsToDisplaKey) as? [TrkSegment]
        }
        set {
            objc_setAssociatedObject(self, &gpxProcessedPointsToDisplaKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func hasTrkPt(withElevation: Bool) -> Bool {
        for track in tracks {
            for segment in (track as! Track).segments {
                if withElevation {
                    for point in (segment as! TrkSegment).points {
                        if !(point as! WptPt).ele.isNaN {
                            return true
                        }
                    }
                } else if (segment as! TrkSegment).points.count > 0 {
                    return true
                }
            }
        }
        return false
    }
    
    func recalculateProcessPoint() {
        processedPointsToDisplay = processPoints()
        guard let processedPoints = processedPointsToDisplay, processedPoints.isEmpty else {
            return
        }
        processedPointsToDisplay = processRoutePoints()
    }
    
    func getPointsToDisplay(isJoinSegments: Bool) -> [TrkSegment] {
        if isJoinSegments {
            if let getGeneralTrack = getGeneralTrack() {
                return getGeneralTrack.segments as! [TrkSegment]
            }
            return []
        } else {
            return processedPointsToDisplay ?? []
        }
    }
}
