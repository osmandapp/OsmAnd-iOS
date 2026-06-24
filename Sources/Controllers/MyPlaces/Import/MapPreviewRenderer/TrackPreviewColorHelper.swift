//
//  TrackPreviewColorHelper.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 12.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

@objcMembers
final class TrackPreviewColorHelper: NSObject {

    static func appDefaultTrackColor() -> Int32 {
        let settingsColor = Int32(OAAppSettings.sharedManager().currentTrackColor.get())
        if settingsColor != 0 { return settingsColor }
        return Int32(bitPattern: UInt32(truncatingIfNeeded: kDefaultTrackColor))
    }

    static func resolvedColor(gpxFile: GpxFile, segment: TrkSegment?, defaultColor: Int32) -> Int32 {
        let fallbackColor = defaultColor != 0 ? defaultColor : appDefaultTrackColor()

        if let segment, let segmentColor = segment.getColor(defColor: 0)?.intValue, segmentColor != 0 {
            return Int32(segmentColor)
        }

        if let track = (gpxFile.tracks as? [Track])?.first,
           let trackColor = track.getColor(defColor: 0)?.intValue, trackColor != 0 {
            return Int32(trackColor)
        }

        if let fileColor = gpxFile.getColor(defColor: 0)?.intValue, fileColor != 0 {
            return Int32(fileColor)
        }

        return fallbackColor
    }

    static func previewSegments(for gpxFile: GpxFile) -> [TrkSegment] {
        if let processed = gpxFile.processedPointsToDisplay, !processed.isEmpty {
            return processed
        }
        guard let track = (gpxFile.tracks as? [Track])?.first else { return [] }
        return (track.segments as? [TrkSegment]) ?? []
    }
}
