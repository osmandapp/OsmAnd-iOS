//
//  CollectTracksTask.swift
//  OsmAnd
//
//  Created by Vitaliy Sova on 09.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

protocol CollectTracksListener: AnyObject {
    func tracksCollectionStarted()
    func tracksCollectionFinished(_ items: [ImportTrackItem])
}

final class CollectTracksTask: OAAsyncTask {
    private let gpxFile: GpxFile
    private let fileName: String
    private weak var listener: CollectTracksListener?

    init(gpxFile: GpxFile, fileName: String, listener: CollectTracksListener?) {
        self.gpxFile = gpxFile
        self.fileName = fileName
        self.listener = listener
        super.init()
    }

    override func onPreExecute() {
        listener?.tracksCollectionStarted()
    }

    override func doInBackground() -> Any? {
        var items: [ImportTrackItem] = []
        let baseName = fileName.deletingPathExtension()
        let tracks = gpxFile.tracks as? [Track] ?? []

        let author = gpxAuthor()
        
        for (index, track) in tracks.enumerated() {
            if isCancelled() { return items }

            guard !track.isGeneralTrack() else { continue }

            let trackFile = GpxFile(author: author)
            trackFile.tracks.add(track)

            copyAppearance(from: gpxFile, track: track, to: trackFile)
            let metadata = OsmAndShared.Metadata(source: gpxFile.metadata)
            metadata.name = nil
            trackFile.metadata = metadata

            var trackName = track.name ?? ""
            if trackName.isEmpty {
                trackName = String(format: localizedString("ltr_or_rtl_combine_via_dash"), baseName, "\(index + 1)")
            }
            
            let analysis = trackFile.getAnalysis(
                fileTimestamp: 0,
                fromDistance: nil,
                toDistance: nil,
                pointsAnalyzer: PlatformUtil.shared.getTrackPointsAnalyser()
            )
            
            let item = ImportTrackItem(
                index: index,
                name: trackName,
                gpxFile: trackFile,
                selectedPoints: [],
                suggestedPoints: []
            )
            item.analysis = analysis

            items.append(item)
        }

        for point in gpxFile.getPointsList() {
            if isCancelled() { return items }
            guard let item = findNearestTrack(for: point, items: items) else { continue }
            item.selectedPoints.append(point)
            item.suggestedPoints.append(point)
        }

        return items
    }

    override func onPostExecute(result: Any?) {
        let items = result as? [ImportTrackItem] ?? []
        listener?.tracksCollectionFinished(items)
    }

    // MARK: - Private

    private func gpxAuthor() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return "OsmAnd Maps \(version) (\(build))"
    }

    private func copyAppearance(from source: GpxFile, track: Track, to target: GpxFile) {
        target.setColor(color: track.getColor(defColor: source.getColor(defColor: 0)))
        if let width = source.getWidth(defaultWidth: nil) {
            target.setWidth(width: width)
        }
        target.setShowArrows(showArrows: source.isShowArrows())
        target.setShowStartFinish(showStartFinish: source.isShowStartFinish())
        target.setSplitInterval(splitInterval: source.getSplitInterval())
        if let splitType = source.getSplitType() {
            target.setSplitType(gpxSplitType: splitType)
        }
        if let coloringType = source.getColoringType() {
            target.setColoringType(coloringType: coloringType)
        }
        if let palette = source.getGradientColorPalette() {
            target.setGradientColorPalette(gradientColorPaletteName: palette)
        }
        if let type3d = source.get3DVisualizationType() {
            target.set3DVisualizationType(visualizationType: type3d)
        }
        if let wallColor = source.get3DWallColoringType() {
            target.set3DWallColoringType(trackWallColoringType: wallColor)
        }
        if let linePos = source.get3DLinePositionType() {
            target.set3DLinePositionType(trackLinePositionType: linePos)
        }
        target.setAdditionalExaggeration(additionalExaggeration: source.getAdditionalExaggeration())
        target.setElevationMeters(elevation: source.getElevationMeters())
    }

    private func findNearestTrack(for point: WptPt, items: [ImportTrackItem]) -> ImportTrackItem? {
        var nearest: ImportTrackItem?
        var minDistance = Double.greatestFiniteMagnitude
        let mapUtils = KMapUtils.shared

        for item in items {
            if isCancelled() { return nil }
            
            for wpt in item.gpxFile.getAllSegmentsPoints() {
                if isCancelled() { return nil }
                
                let distance = mapUtils.getDistance(
                    lat1: point.getLatitude(),
                    lon1: point.getLongitude(),
                    lat2: wpt.getLatitude(),
                    lon2: wpt.getLongitude()
                )
                if distance < minDistance {
                    minDistance = distance
                    nearest = item
                }
            }
        }
        return nearest
    }
}
