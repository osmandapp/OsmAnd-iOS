//
//  ChartHelper.swift
//  OsmAnd
//
//  Created by Skalii on 22.11.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation
import CoreLocation
import DGCharts

@objc protocol ChartHelperDelegate: AnyObject {
    func centerMapOnBBox(_ rect: KQuadRect)
    func adjustViewPort(_ landscape: Bool)
    func showCurrentHighlitedLocation(_ trackChartPoints: TrackChartPoints)
    func showCurrentStatisticsLocation(_ trackChartPoints: TrackChartPoints)
}

@objcMembers
final class TrackChartPoints: NSObject {
    var xAxisPoints = [CLLocation]()
    var highlightedPoint = kCLLocationCoordinate2DInvalid
    var segmentColor = 0
    var gpx: GpxFile?
    var start = kCLLocationCoordinate2DInvalid
    var end = kCLLocationCoordinate2DInvalid
}

@objcMembers
final class TrackChartHelper: NSObject {

    var isLandscape: Bool = false
    var screenBBox: CGRect = .zero

    weak var delegate: ChartHelperDelegate?

    private var gpxDoc: GpxFile?
    private var trackChartPoints: TrackChartPoints?
    private var chartHighlightPos: Double = -1
    private var xAxisPoints = [CLLocation]()

    init(gpxDoc: GpxFile) {
        self.gpxDoc = gpxDoc
    }

    static func getTrackSegment(_ analysis: GpxTrackAnalysis,
                                gpxItem: GpxFile) -> TrkSegment? {
        guard let locStart = analysis.locationStart,
              let locEnd = analysis.locationEnd else {
            return nil
        }

        for t in gpxItem.tracks {
            guard let track = t as? Track else { continue }
            for s in track.segments {
                guard let segment = s as? TrkSegment, segment.points.count > 0 else { continue }
                if let firstPoint = segment.points.firstObject as? WptPt,
                   let lastPoint = segment.points.lastObject as? WptPt,
                   firstPoint.lat == locStart.lat,
                   firstPoint.lon == locStart.lon,
                   lastPoint.lat == locEnd.lat,
                   lastPoint.lon == locEnd.lon {
                    return segment
                }
            }
        }
        return nil
    }

    static func getAnalysisFor(_ segment: TrkSegment) -> GpxTrackAnalysis {
        let analysis = GpxTrackAnalysis()
        let splitSegments = ArraySplitSegmentConverter.toKotlinArray(from: [SplitSegment(segment: segment)])
        analysis.prepareInformation(fileTimeStamp: 0,
                                    pointsAnalyser: nil,
                                    splitSegments: splitSegments)
        return analysis
    }

    func changeChartTypes(_ types: [Int],
                          chart: ElevationChart,
                          analysis: GpxTrackAnalysis,
                          statsModeCell: OARouteStatisticsModeCell?) {
        var secondType: GPXDataSetType = .none
        if types.count == 2 {
            if types.last == GPXDataSetType.speed.rawValue && !analysis.isSpeedSpecified() {
                changeChartTypes([GPXDataSetType.altitude.rawValue],
                                 chart: chart,
                                 analysis: analysis,
                                 statsModeCell: statsModeCell)
            } else {
                if let statsModeCell {
                    statsModeCell.modeButton.setTitle(
                        String(format: localizedString("ltr_or_rtl_combine_via_slash"),
                               OAGPXDataSetType.getTitle(types.first!),
                               OAGPXDataSetType.getTitle(types.last!)),
                        for: .normal)
                }
                secondType = GPXDataSetType(rawValue: types.last!)!
            }
        } else if types.count == 1 {
            statsModeCell?.modeButton.setTitle(OAGPXDataSetType.getTitle(types.first ?? GPXDataSetType.none.rawValue),
                                               for: .normal)
        }

        let gpx = OAGPXDatabase.sharedDb().getGPXItem(OAUtilities.getGpxShortPath(gpxDoc?.path ?? ""))
        GpxUIHelper.refreshLineChart(
            chartView: chart,
            analysis: analysis,
            firstType: GPXDataSetType(rawValue: types.first!)!,
            secondType: secondType,
            axisType: .distance,
            calcWithoutGaps: GpxUtils.calcWithoutGaps(gpxDoc, gpxDataItem: gpx)
        )
    }

    func refreshChart(_ chart: LineChartView,
                      fitTrack: Bool,
                      forceFit: Bool,
                      recalculateXAxis: Bool,
                      analysis: GpxTrackAnalysis,
                      segment: TrkSegment?) {
        guard let gpxDoc else { return }

        let highlights = chart.highlighted
        var location: CLLocation?

        if trackChartPoints == nil {
            trackChartPoints = TrackChartPoints()
            trackChartPoints?.segmentColor = segment?.getColor(defColor: 0)?.intValue ?? 0
            trackChartPoints?.gpx = gpxDoc
            trackChartPoints?.start = analysis.locationStart?.position ?? kCLLocationCoordinate2DInvalid
            trackChartPoints?.end = analysis.locationEnd?.position ?? kCLLocationCoordinate2DInvalid
        }

        let minimumVisibleXValue = chart.lowestVisibleX
        let maximumVisibleXValue = chart.highestVisibleX

        if !highlights.isEmpty {
            if minimumVisibleXValue != 0 && maximumVisibleXValue != 0 {
                if highlights[0].x < minimumVisibleXValue {
                    let difference = (maximumVisibleXValue - minimumVisibleXValue) * 0.1
                    chartHighlightPos = minimumVisibleXValue + difference
                    chart.highlightValue(x: minimumVisibleXValue + difference, dataSetIndex: 0)
                } else if highlights[0].x > maximumVisibleXValue {
                    let difference = (maximumVisibleXValue - minimumVisibleXValue) * 0.1
                    chartHighlightPos = maximumVisibleXValue - difference
                    chart.highlightValue(x: maximumVisibleXValue - difference, dataSetIndex: 0)
                } else {
                    chartHighlightPos = highlights[0].x
                }
            } else {
                chartHighlightPos = highlights[0].x
            }

            location = getLocationAtPos(chart,
                                        pos: chartHighlightPos,
                                        analysis: analysis,
                                        segment: segment)
            if let location {
                trackChartPoints?.highlightedPoint = location.coordinate
            }
            if let trackChartPoints {
                delegate?.showCurrentHighlitedLocation(trackChartPoints)
            }
        } else {
            chartHighlightPos = -1
        }

        if let start = (segment?.isGeneralSegment() ?? false)
            ? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            : analysis.locationStart?.position,
        let end = (segment?.isGeneralSegment() ?? false)
            ? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            : analysis.locationEnd?.position,
           let trackChartPoints {
            if recalculateXAxis
                || !OAMapUtils.areLatLonEqual(trackChartPoints.start, l2: start)
                || !OAMapUtils.areLatLonEqual(trackChartPoints.end, l2: end) {
                trackChartPoints.start = start
                trackChartPoints.end = end
                trackChartPoints.xAxisPoints = getXAxisPoints(chart,
                                                              analysis: analysis,
                                                              segment: segment)
                delegate?.showCurrentStatisticsLocation(trackChartPoints)
                if let location {
                    OARootViewController.instance().mapPanel.refreshMap()
                }
            }
        }

        if let location, fitTrack {
            let mapViewController = OARootViewController.instance().mapPanel.mapViewController
            mapViewController.fitTrack(onMap: chart,
                                       startPos: chart.lowestVisibleX,
                                       endPos: chart.highestVisibleX,
                                       location: location.coordinate,
                                       forceFit: forceFit,
                                       analysis: analysis,
                                       segment: segment,
                                       trackChartHelper: self)
        }
    }

    func getXAxisPoints(_ chart: LineChartView,
                        analysis: GpxTrackAnalysis,
                        segment: TrkSegment?) -> [CLLocation] {
        let entries = chart.xAxis.entries
        let lineData = chart.lineData
        let maxXValue = lineData?.xMax ?? -1
        if entries.count >= 2, let lineData {
            let interval = entries[1] - entries[0]
            if interval > 0 {
                var xAxisPoints = [CLLocation]()
                var currentPointEntry = interval
                while currentPointEntry < maxXValue {
                    if let location = getLocationAtPos(chart,
                                                       pos: currentPointEntry,
                                                       analysis: analysis,
                                                       segment: segment) {
                        xAxisPoints.append(location)
                    }
                    currentPointEntry += interval
                }
                self.xAxisPoints = xAxisPoints
            }
        }
        return xAxisPoints
    }

    func getRect(_ chart: LineChartView,
                 startPos: Float,
                 endPos: Float,
                 analysis: GpxTrackAnalysis,
                 segment: TrkSegment?) -> KQuadRect {
        var left: Double = 0, right: Double = 0
        var top: Double = 0, bottom: Double = 0

        guard let segment,
              let lineData = chart.lineData,
              !lineData.dataSets.isEmpty,
              let dataSet = lineData.dataSets.first else {
            return KQuadRect(left: left, top: top, right: right, bottom: bottom)
        }

        let axisType = GpxUIHelper.getDataSetAxisType(dataSet: dataSet)
        if axisType == .time || axisType == .timeOfDay {
            let startTime = startPos * 1000
            let endTime = endPos * 1000
            for point in segment.points {
                if let p = point as? WptPt {
                    if Float(p.time - analysis.startTime) >= startTime,
                       Float(p.time - analysis.startTime) <= endTime {
                        if left == 0 && right == 0 {
                            left = p.getLongitude()
                            right = p.getLongitude()
                            top = p.getLatitude()
                            bottom = p.getLatitude()
                        } else {
                            left = min(left, p.getLongitude())
                            right = max(right, p.getLongitude())
                            top = max(top, p.getLatitude())
                            bottom = min(bottom, p.getLatitude())
                        }
                    }
                }
            }
        } else {
            let startDistance = Double(startPos) * dataSet.getDivX()
            let endDistance = Double(endPos) * dataSet.getDivX()
            var previousSplitDistance: Double = 0
            for i in 0..<segment.points.count {
                if let currentPoint = segment.points[i] as? WptPt {
                    if i != 0,
                       let previousPoint = segment.points[i - 1] as? WptPt {
                        if currentPoint.distance < previousPoint.distance {
                            previousSplitDistance += previousPoint.distance
                        }
                    }
                    let totalDistance = previousSplitDistance + currentPoint.distance
                    if totalDistance >= startDistance && totalDistance <= endDistance {
                        if left == 0 && right == 0 {
                            left = currentPoint.getLongitude()
                            right = currentPoint.getLongitude()
                            top = currentPoint.getLatitude()
                            bottom = currentPoint.getLatitude()
                        } else {
                            left = min(left, currentPoint.getLongitude())
                            right = max(right, currentPoint.getLongitude())
                            top = max(top, currentPoint.getLatitude())
                            bottom = min(bottom, currentPoint.getLatitude())
                        }
                    }
                }
            }
        }
        return KQuadRect(left: left, top: top, right: right, bottom: bottom)
    }

    private func getLocationAtPos(_ chart: LineChartView,
                                  pos: Double,
                                  analysis: GpxTrackAnalysis,
                                  segment: TrkSegment?) -> CLLocation? {
        guard let gpxDoc = gpxDoc else { return nil }
        let gpx = OAGPXDatabase.sharedDb().getGPXItem(gpxDoc.path)
        return GpxUtils.getLocationAtPos(chart,
                                         gpxFile: gpxDoc,
                                         segment: segment,
                                         pos: Float(pos),
                                         joinSegments: gpx?.joinSegments ?? false)
    }
}
