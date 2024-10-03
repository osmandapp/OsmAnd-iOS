//
//  GpxFileExtension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 03.10.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import OsmAndShared

@objc(OASGpxFile)
extension GpxFile {
    func hasTrkPt(withElevation: Bool) -> Bool {
        for track in tracks {
            // FIXME:
//            for segment in track.segments {
//                if withElevation {
//                    for point in segment.points {
//                        if !point.elevation.isNaN {
//                            return true
//                        }
//                    }
//                } else if segment.points.count > 0 {
//                    return true
//                }
//            }
        }
        return false
    }
    
}


