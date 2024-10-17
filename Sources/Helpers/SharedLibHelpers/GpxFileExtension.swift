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
    
}


