//
//  GPXDataItemGPXFileWrapper.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 16.10.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import OsmAndShared

@objcMembers
final class GPXDataItemGPXFileWrapper: NSObject {
    var gpxDataItem: GpxDataItem?
    var gpxFile: GpxFile?
    
    var elevationMeters: Double {
        if let gpxDataItem {
            return gpxDataItem.elevationMeters
        }
        if let gpxFile {
            return Double(gpxFile.getElevationMeters())
        }
        return 0.0
    }

    var visualization3dByType: EOAGPX3DLineVisualizationByType {
        if let gpxDataItem {
            return gpxDataItem.visualization3dByType
        }
        if let gpxFile {
            let value = gpxFile.get3DVisualizationType() ?? ""
            return GpxDataItem.lineVisualizationByType(forName: value)
        }
        return .none
    }

    var visualization3dWallColorType: EOAGPX3DLineVisualizationWallColorType {
        if let gpxDataItem {
            return gpxDataItem.visualization3dWallColorType
        }
        if let gpxFile {
            guard let value = gpxFile.get3DWallColoringType() else { return .upwardGradient }
            return GpxDataItem.lineVisualizationWallColorType(forName: value)
        }
        return .upwardGradient
    }

    var coloringType: String {
        if let gpxDataItem {
            return gpxDataItem.coloringType
        }
        if let gpxFile {
            return gpxFile.getColoringType() ?? ""
        }
        return ""
    }

    var color: Int {
        if let gpxDataItem {
            return gpxDataItem.color
        }
        if let gpxFile {
            return gpxFile.getColor(defColor: 0)?.intValue ?? 0
        }
        return 0
    }

    var splitType: EOAGpxSplitType {
        if let gpxDataItem {
            return gpxDataItem.splitType
        }
        if let gpxFile {
            OAGPXDatabase.splitType(byName: gpxFile.getSplitType())
        }
        return .none
    }

    var joinSegments: Bool {
        if let gpxDataItem {
            return gpxDataItem.joinSegments
        }
        if let gpxFile {
            return OAAppSettings.sharedManager().currentTrackIsJoinSegments.get()
        }
        return false
    }

    var gradientPaletteName: String? {
        if let gpxDataItem = gpxDataItem {
            return gpxDataItem.gradientPaletteName
        }
        if let gpxFile = gpxFile {
            return gpxFile.getGradientColorPalette()
        }
        return nil
    }
    
    init(gpxDataItem: GpxDataItem?, gpxFile: GpxFile?) {
         self.gpxDataItem = gpxDataItem
         self.gpxFile = gpxFile
     }
}
