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
        let baseName = fileName.deletingPathExtension()
        let tracks = gpxFile.tracks as? [Track] ?? []
        let author = gpxAuthor()
        var items: [ImportTrackItem] = []

        for (index, track) in tracks.enumerated() {
            if isCancelled() { return items }
            guard !track.isGeneralTrack() else { continue }
            items.append(makeImportTrackItem(from: track, at: index, baseName: baseName, author: author))
        }

        assignWaypoints(from: gpxFile, to: &items)
        return items
    }

    override func onPostExecute(result: Any?) {
        let items = result as? [ImportTrackItem] ?? []
        listener?.tracksCollectionFinished(items)
    }

    // MARK: - Track building

    private func makeImportTrackItem(
        from track: Track,
        at index: Int,
        baseName: String,
        author: String
    ) -> ImportTrackItem {
        let trackFile = makeSingleTrackGpxFile(from: track, author: author)
        let trackName = resolvedTrackName(for: track, index: index, baseName: baseName)
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
        return item
    }

    private func makeSingleTrackGpxFile(from track: Track, author: String) -> GpxFile {
        let trackFile = GpxFile(author: author)
        trackFile.tracks.add(track)
        copyAppearance(from: gpxFile, track: track, to: trackFile)
        trackFile.recalculateProcessPoint()

        let metadata = OsmAndShared.Metadata(source: gpxFile.metadata)
        metadata.name = nil
        trackFile.metadata = metadata
        return trackFile
    }

    private func resolvedTrackName(for track: Track, index: Int, baseName: String) -> String {
        if let name = track.name, !name.isEmpty {
            return name
        }
        return String(format: localizedString("ltr_or_rtl_combine_via_dash"), baseName, "\(index)")
    }

    private func assignWaypoints(from sourceFile: GpxFile, to items: inout [ImportTrackItem]) {
        for point in sourceFile.getPointsList() {
            if isCancelled() { return }
            guard let nearestItem = findNearestTrack(for: point, in: items) else { continue }
            nearestItem.selectedPoints.append(point)
            nearestItem.suggestedPoints.append(point)
        }
    }

    // MARK: - Helpers

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

    private func findNearestTrack(for point: WptPt, in items: [ImportTrackItem]) -> ImportTrackItem? {
        var nearestItem: ImportTrackItem?
        var minDistance = Double.greatestFiniteMagnitude

        for item in items {
            if isCancelled() { return nil }

            for waypoint in item.gpxFile.getAllSegmentsPoints() {
                if isCancelled() { return nil }

                let distance = KMapUtils.shared.getDistance(
                    lat1: point.getLatitude(),
                    lon1: point.getLongitude(),
                    lat2: waypoint.getLatitude(),
                    lon2: waypoint.getLongitude()
                )
                if distance < minDistance {
                    minDistance = distance
                    nearestItem = item
                }
            }
        }
        return nearestItem
    }
}
