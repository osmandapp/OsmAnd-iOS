//
//  GpxUtils.swift
//  OsmAnd Maps
//
//  Created by Skalii on 08.11.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation
import DGCharts

@objcMembers
final class GpxUtils: NSObject {

    static func calcWithoutGaps(_ gpxFile: GpxFile?, gpxDataItem: GpxDataItem?) -> Bool {
        guard let gpxFile, let gpxDataItem else { return false }
        let isGeneralTrack = gpxFile.tracks.count > 0
            && (gpxFile.tracks.firstObject as? Track)?.isGeneralTrack() ?? false
        if gpxFile.isShowCurrentTrack() {
            return !OAAppSettings.sharedManager().currentTrackIsJoinSegments.get() && (gpxFile.tracks.count == 0 || isGeneralTrack)
        } else {
            return isGeneralTrack && gpxDataItem.joinSegments
        }
    }

    static func getLocationAtPos(_ chart: LineChartView,
                                 gpxFile: GpxFile,
                                 segment: TrkSegment?,
                                 pos: Float,
                                 joinSegments: Bool) -> CLLocation? {
        var point: WptPt?
        if let ds = chart.lineData?.dataSets,
           let dataSet = ds.first as? GpxUIHelper.OrderedLineDataSet,
           let segment {
            if GpxUIHelper.getDataSetAxisType(dataSet: dataSet) == .time
                || GpxUIHelper.getDataSetAxisType(dataSet: dataSet) == .timeOfDay {
                let time = pos * 1000
                point = getSegmentPointByTime(segment,
                                              gpxFile: gpxFile,
                                              time: time,
                                              preciseLocation: true,
                                              joinSegments: joinSegments)
            } else {
                let distance = pos * Float(dataSet.getDivX())
                point = getSegmentPointByDistance(segment,
                                                  gpxFile: gpxFile,
                                                  distanceToPoint: distance,
                                                  preciseLocation: true,
                                                  joinSegments: joinSegments)
            }
        }
        guard let point else { return nil }
        return CLLocation(latitude: point.getLatitude(), longitude: point.getLongitude())
    }

    static func getSegmentPointByTime(_ segment: TrkSegment,
                                      gpxFile: GpxFile,
                                      time: Float,
                                      preciseLocation: Bool,
                                      joinSegments: Bool) -> WptPt? {
        if !segment.isGeneralSegment() || joinSegments {
            return getSegmentPointByTime(segment,
                                         timeToPoint: time,
                                         passedSegmentsTime: 0,
                                         preciseLocation: preciseLocation)
        }

        var passedSegmentsTime: Int64 = 0
        for t in gpxFile.tracks {
            guard let track = t as? Track, !track.isGeneralTrack() else { continue }
            for s in track.segments {
                guard let seg = s as? TrkSegment else { continue }
                if let point = getSegmentPointByTime(seg,
                                                     timeToPoint: time,
                                                     passedSegmentsTime: passedSegmentsTime,
                                                     preciseLocation: preciseLocation) {
                    return point
                }

                let segmentStartTime = seg.points.count == 0 ? 0 : (seg.points.firstObject as? WptPt)?.time ?? 0
                let segmentEndTime = seg.points.count == 0 ? 0 : (seg.points.lastObject as? WptPt)?.time ?? 0
                passedSegmentsTime += segmentEndTime - segmentStartTime
            }
        }
        return nil
    }

    static func getSegmentPointByDistance(_ segment: TrkSegment,
                                          gpxFile: GpxFile,
                                          distanceToPoint: Float,
                                          preciseLocation: Bool,
                                          joinSegments: Bool) -> WptPt? {
        var passedDistance = 0.0
        if !segment.isGeneralSegment() || joinSegments {
            var prevPoint: WptPt?
            for p in segment.points {
                if let currPoint = p as? WptPt {
                    if let prevPoint {
                        passedDistance += OAMapUtils.getDistance(prevPoint.lat,
                                                                 lon1: prevPoint.lon,
                                                                 lat2: currPoint.lat,
                                                                 lon2: currPoint.lon)
                    }
                    if currPoint.distance >= Double(distanceToPoint)
                        || abs(passedDistance - Double(distanceToPoint)) < 0.1 {
                        guard preciseLocation,
                              let prevPoint,
                              currPoint.distance >= Double(distanceToPoint) else {
                            return currPoint
                        }
                        return getIntermediatePointByDistance(passedDistance,
                                                              distanceToPoint: Double(distanceToPoint),
                                                              currPoint: currPoint,
                                                              prevPoint: prevPoint)
                    }
                    prevPoint = currPoint
                }
            }
        }
        
        passedDistance = 0
        var passedSegmentsPointsDistance = 0.0
        var prevPoint: WptPt?
        for t in gpxFile.tracks {
            guard let track = t as? Track, !track.isGeneralTrack() else { continue }
            for s in track.segments {
                guard let seg = s as? TrkSegment, seg.points.count > 0 else { continue }
                for p in seg.points {
                    if let currPoint = p as? WptPt {
                        if let prevPoint {
                            passedDistance += OAMapUtils.getDistance(prevPoint.lat,
                                                                     lon1: prevPoint.lon,
                                                                     lat2: currPoint.lat,
                                                                     lon2: currPoint.lon)
                        }
                        if passedSegmentsPointsDistance + currPoint.distance >= Double(distanceToPoint)
                            || abs(passedDistance - Double(distanceToPoint)) < 0.1 {
                            guard let prevPoint,
                                  preciseLocation,
                                  currPoint.distance + passedSegmentsPointsDistance >= Double(distanceToPoint) else {
                                return currPoint
                            }
                            return getIntermediatePointByDistance(passedDistance,
                                                                  distanceToPoint: Double(distanceToPoint),
                                                                  currPoint: currPoint,
                                                                  prevPoint: prevPoint)
                        }
                        prevPoint = currPoint
                    }
                }
                prevPoint = nil
                passedSegmentsPointsDistance += (seg.points.lastObject as? WptPt)?.distance ?? 0
            }
        }
        return nil
    }
    
    static func getRect(from bbox: OABBox) -> KQuadRect {
        KQuadRect(left: bbox.left, top: bbox.top, right: bbox.right, bottom: bbox.bottom)
    }

    private static func getSegmentPointByTime(_ segment: TrkSegment,
                                              timeToPoint: Float,
                                              passedSegmentsTime: Int64,
                                              preciseLocation: Bool) -> WptPt? {
        var previousPoint: WptPt?
        let segmentStartTime = (segment.points.firstObject as? WptPt)?.time ?? 0
        for p in segment.points {
            if let currentPoint = p as? WptPt {
                let totalPassedTime = passedSegmentsTime + currentPoint.time - segmentStartTime
                if totalPassedTime >= Int64(timeToPoint) {
                    guard let previousPoint, preciseLocation else { return currentPoint }
                    return getIntermediatePointByTime(Double(totalPassedTime),
                                                      timeToPoint: Double(timeToPoint),
                                                      prevPoint: previousPoint,
                                                      currPoint: currentPoint)
                }
                previousPoint = currentPoint
            }
        }
        return nil
    }

    private static func getIntermediatePointByTime(_ passedTime: Double,
                                                   timeToPoint: Double,
                                                   prevPoint: WptPt,
                                                   currPoint: WptPt) -> WptPt {
        let percent = 1 - (passedTime - timeToPoint) / Double((currPoint.time - prevPoint.time))
        let dLat = (currPoint.lat - prevPoint.lat) * percent
        let dLon = (currPoint.lon - prevPoint.lon) * percent
        let intermediatePoint = WptPt()
        intermediatePoint.lat = prevPoint.lat + dLat
        intermediatePoint.lon = prevPoint.lon + dLon
        return intermediatePoint
    }

    private static func getIntermediatePointByDistance(_ passedDistance: Double,
                                                       distanceToPoint: Double,
                                                       currPoint: WptPt,
                                                       prevPoint: WptPt) -> WptPt {
        let percent = 1 - (passedDistance - distanceToPoint) / (currPoint.distance - prevPoint.distance)
        let dLat = (currPoint.lat - prevPoint.lat) * percent
        let dLon = (currPoint.lon - prevPoint.lon) * percent
        let intermediatePoint = WptPt()
        intermediatePoint.lat = prevPoint.lat + dLat
        intermediatePoint.lon = prevPoint.lon + dLon
        return intermediatePoint
    }
}
