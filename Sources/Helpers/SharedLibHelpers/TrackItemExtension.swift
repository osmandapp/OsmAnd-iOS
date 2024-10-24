//
//  TrackItem.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 18.10.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objc(OASTrackItem)
extension TrackItem {

    var gpxFileName: String {
        get {
            if isShowCurrentTrack {
                return name
            } else {
                return dataItem?.gpxFileName ?? ""
            }
        }
        set {
            dataItem?.gpxFileName = newValue
        }
    }

    var gpxFolderName: String {
        get {
            dataItem?.gpxFolderName ?? ""
        }
        set {
            dataItem?.gpxFolderName = newValue
        }
    }

    var gpxFilePath: String {
        path ?? ""
    }

    var creationDate: Date {
        get {
            if isShowCurrentTrack {
                let lastModifiedTime = Double(lastModified)
                return Date(timeIntervalSince1970: lastModifiedTime)
            } else {
                return dataItem?.creationDate ?? Date()
            }
        }
        set {
            dataItem?.creationDate = newValue
        }
    }

    var lastModifiedTime: Date {
        get {
            dataItem?.lastModifiedTime ?? Date()
        }
        set {
            dataItem?.lastModifiedTime = newValue
        }
    }

    var fileLastUploadedTime: Date {
        get {
            dataItem?.fileLastUploadedTime ?? Date()
        }
        set {
            dataItem?.fileLastUploadedTime = newValue
        }
    }

    var nearestCity: String? {
        get {
            dataItem?.nearestCity
        }
        set {
            dataItem?.nearestCity = newValue
        }
    }

    var totalDistance: Float {
        get {
            dataItem?.totalDistance ?? 0.0
        }
        set {
            dataItem?.totalDistance = newValue
        }
    }

    var totalTracks: Int {
        get {
            dataItem?.totalTracks ?? 0
        }
        set {
            dataItem?.totalTracks = newValue
        }
    }

    var timeSpan: Int {
        get {
            dataItem?.timeSpan ?? 0
        }
        set {
            dataItem?.timeSpan = newValue
        }
    }

    var wptPoints: Int32 {
        get {
            dataItem?.wptPoints ?? 0
        }
        set {
            dataItem?.wptPoints = newValue
        }
    }

    var diffElevationUp: Double {
        get {
            dataItem?.diffElevationUp ?? 0.0
        }
        set {
            dataItem?.diffElevationUp = newValue
        }
    }

    var diffElevationDown: Double {
        get {
            dataItem?.diffElevationDown ?? 0.0
        }
        set {
            dataItem?.diffElevationDown = newValue
        }
    }

    var startLat: Double {
        get {
            dataItem?.startLat ?? 0.0
        }
        set {
            dataItem?.startLat = newValue
        }
    }

    var startLon: Double {
        get {
            dataItem?.startLon ?? 0.0
        }
        set {
            dataItem?.startLon = newValue
        }
    }

    var showArrows: Bool {
        get {
            dataItem?.showArrows ?? false
        }
        set {
            dataItem?.showArrows = newValue
        }
    }

    var showStartFinish: Bool {
        get {
            dataItem?.showStartFinish ?? false
        }
        set {
            dataItem?.showStartFinish = newValue
        }
    }

    var elevationMeters: Double {
        get {
            dataItem?.elevationMeters ?? 0.0
        }
        set {
            dataItem?.elevationMeters = newValue
        }
    }

    var verticalExaggerationScale: Double {
        get {
            dataItem?.verticalExaggerationScale ?? 0.0
        }
        set {
            dataItem?.verticalExaggerationScale = newValue
        }
    }

    var visualization3dByType: EOAGPX3DLineVisualizationByType {
        get {
            dataItem?.visualization3dByType ?? .none
        }
        set {
            dataItem?.visualization3dByType = newValue
        }
    }

    var visualization3dWallColorType: EOAGPX3DLineVisualizationWallColorType {
        get {
            dataItem?.visualization3dWallColorType ?? .upwardGradient
        }
        set {
            dataItem?.visualization3dWallColorType = newValue
        }
    }

    var visualization3dPositionType: EOAGPX3DLineVisualizationPositionType {
        get {
            dataItem?.visualization3dPositionType ?? .top
        }
        set {
            dataItem?.visualization3dPositionType = newValue
        }
    }

    var coloringType: String {
        get {
            dataItem?.coloringType ?? ""
        }
        set {
            dataItem?.coloringType = newValue
        }
    }

    var width: String {
        get {
            dataItem?.width ?? ""
        }
        set {
            dataItem?.width = newValue
        }
    }

    var color: Int {
        get {
            dataItem?.color ?? 0
        }
        set {
            dataItem?.color = newValue
        }
    }

    var splitType: EOAGpxSplitType {
        get {
            dataItem?.splitType ?? .none
        }
        set {
            dataItem?.splitType = newValue
        }
    }

    var splitInterval: Double {
        get {
            dataItem?.splitInterval ?? 0.0
        }
        set {
            dataItem?.splitInterval = newValue
        }
    }

    var joinSegments: Bool {
        get {
            dataItem?.joinSegments ?? false
        }
        set {
            dataItem?.joinSegments = newValue
        }
    }

    var gradientPaletteName: String? {
        get {
            dataItem?.gradientPaletteName
        }
        set {
            dataItem?.gradientPaletteName = newValue
        }
    }
    
    func getNiceTitle() -> String {
        dataItem?.getNiceTitle() ?? ""
    }
    
    func resetAppearanceToOriginal() {
        var gpx: GpxFile?
        if isShowCurrentTrack {
            gpx = OASavingTrackHelper.sharedInstance().currentTrack
        } else {
            if let file = dataItem?.file {
                gpx = GpxUtilities.shared.loadGpxFile(file: file)
            }
        }
        if let gpx {
            splitType = OAGPXDatabase.splitType(byName: gpx.getSplitType())
            splitInterval = gpx.getSplitInterval()
            color = gpx.getColor(defColor: 0)?.intValue ?? 0
            coloringType = gpx.getColoringType() ?? ""
            gradientPaletteName = gpx.getGradientColorPalette()
            width = gpx.getWidth(defWidth: nil) ?? ""
            showArrows = gpx.isShowArrows()
            showStartFinish = gpx.isShowStartFinish()
            verticalExaggerationScale = Double(gpx.getAdditionalExaggeration())
            elevationMeters = Double(gpx.getElevationMeters())
            visualization3dByType = OAGPXDatabase.lineVisualizationByType(forName: gpx.get3DVisualizationType())
            visualization3dWallColorType = OAGPXDatabase.lineVisualizationWallColorType(forName: gpx.get3DWallColoringType())
            
            visualization3dPositionType = OAGPXDatabase.lineVisualizationPositionType(forName: gpx.get3DLinePositionType())
        } else {
            debugPrint("resetAppearanceToOriginal -> gpx is empty")
        }
    }
}
