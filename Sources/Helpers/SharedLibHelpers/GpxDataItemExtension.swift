//
//  GpxDataItemExtension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 13.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import OsmAndShared

private var gpxTitleKey: UInt8 = 0
private var newGpxKey: UInt8 = 0

extension Array where Element: GpxDataItem {
    func toTrackItems() -> [TrackItem] { compactMap{ TrackItem(file: $0.file) }}
}

@objc(OASGpxDataItem)
extension GpxDataItem {
    
    var gpxFileName: String {
        get {
            getParameter(parameter: .fileName) as? String ?? ""
        }
        set {
            setParameter(parameter: .fileName, value: newValue)
        }
    }
    
    var gpxFolderName: String {
        get {
            getParameter(parameter: .fileDir) as? String ?? ""
        }
        set {
            setParameter(parameter: .fileDir, value: newValue)
        }
    }
    
    var gpxFilePath: String {
        let fileName = getParameter(parameter: .fileName) as? String ?? ""
        let dir = getParameter(parameter: .fileDir) as? String ?? ""
        if !dir.isEmpty {
            return dir + "/" + fileName
        }
        return fileName
    }
    
    var creationDate: Date {
        get {
            let fileCreationTimestamp = getParameter(parameter: .fileCreationTime) as? Double ?? 0.0
            return convertTimestamp(fileCreationTimestamp)
        }
        set {
            setParameter(parameter: .fileCreationTime, value: newValue.timeIntervalSince1970 * 1000)
        }
    }
    
    var lastModifiedTime: Date {
        get {
            let lastModifiedTimestamp = getParameter(parameter: .fileLastModifiedTime) as? Double ?? 0.0
            return convertTimestamp(lastModifiedTimestamp)
        }
        set {
            setParameter(parameter: .fileLastModifiedTime, value: newValue.timeIntervalSince1970 * 1000)
        }
    }
    
    var fileLastUploadedTime: Date {
        get {
            let lastUploadedTimestamp = getParameter(parameter: .fileLastUploadedTime) as? Double ?? 0.0
            return convertTimestamp(lastUploadedTimestamp)
        }
        set {
            setParameter(parameter: .fileLastUploadedTime, value: newValue.timeIntervalSince1970 * 1000)
        }
    }
    
    var nearestCity: String? {
        get {
            getParameter(parameter: .nearestCityName) as? String
        }
        set {
            setParameter(parameter: .nearestCityName, value: newValue)
        }
    }
    
    var totalDistance: Float {
        get {
            getParameter(parameter: .totalDistance) as? Float ?? 0.0
        }
        set {
            setParameter(parameter: .totalDistance, value: newValue)
        }
    }
    
    var totalTracks: Int {
        get {
            getParameter(parameter: .totalTracks) as? Int ?? 0
        }
        set {
            setParameter(parameter: .totalTracks, value: KotlinInt(integerLiteral: newValue))
        }
    }
    
    var timeSpan: Int {
        get {
            getParameter(parameter: .timeSpan) as? Int ?? 0
        }
        set {
            setParameter(parameter: .timeSpan, value: KotlinInt(integerLiteral: newValue))
        }
    }
    
    var wptPoints: Int32 {
        get {
            getParameter(parameter: .wptPoints) as? Int32 ?? 0
        }
        set {
            setParameter(parameter: .wptPoints, value: newValue)
        }
    }
    
    var diffElevationUp: Double {
        get {
            getParameter(parameter: .diffElevationUp) as? Double ?? 0.0
        }
        set {
            setParameter(parameter: .diffElevationUp, value: newValue)
        }
    }
    
    var diffElevationDown: Double {
        get {
            getParameter(parameter: .diffElevationDown) as? Double ?? 0.0
        }
        set {
            setParameter(parameter: .diffElevationDown, value: newValue)
        }
    }
    
    var startLat: Double {
        get {
            getParameter(parameter: .startLat) as? Double ?? 0.0
        }
        set {
            setParameter(parameter: .startLat, value: newValue)
        }
    }
    
    var startLon: Double {
        get {
            getParameter(parameter: .startLon) as? Double ?? 0.0
        }
        set {
            setParameter(parameter: .startLon, value: newValue)
        }
    }
    
    var showArrows: Bool {
        get {
            getParameter(parameter: .showArrows) as? Bool ?? false
        }
        set {
            setParameter(parameter: .showArrows, value: newValue)
        }
    }
    
    var showStartFinish: Bool {
        get {
            getParameter(parameter: .showStartFinish) as? Bool ?? false
        }
        set {
            setParameter(parameter: .showStartFinish, value: newValue)
        }
    }
    
    var elevationMeters: Double {
        get {
            getParameter(parameter: .elevationMeters) as? Double ?? 0.0
        }
        set {
            setParameter(parameter: .elevationMeters, value: newValue)
        }
    }
    
    var verticalExaggerationScale: Double {
        get {
            getParameter(parameter: .additionalExaggeration) as? Double ?? 0.0
        }
        set {
            setParameter(parameter: .additionalExaggeration, value: newValue)
        }
    }
    
    var visualization3dByType: EOAGPX3DLineVisualizationByType {
        get {
            let name = getParameter(parameter: .trackVisualizationType) as? String ?? ""
            return OAGPXDatabase.lineVisualizationByType(forName: name)
        }
        set {
            let value = OAGPXDatabase.lineVisualizationByTypeName(for: newValue)
            setParameter(parameter: .trackVisualizationType, value: value)
        }
    }
    
    var visualization3dWallColorType: EOAGPX3DLineVisualizationWallColorType {
        get {
            let name = getParameter(parameter: .track3dWallColoringType) as? String ?? ""
            return OAGPXDatabase.lineVisualizationWallColorType(forName: name)
        }
        set {
            let value = OAGPXDatabase.lineVisualizationWallColorTypeName(for: newValue)
            setParameter(parameter: .track3dWallColoringType, value: value)
        }
    }
    
    var visualization3dPositionType: EOAGPX3DLineVisualizationPositionType {
        get {
            let name = getParameter(parameter: .track3dLinePositionType) as? String ?? ""
            return OAGPXDatabase.lineVisualizationPositionType(forName: name)
        }
        set {
            let value = OAGPXDatabase.lineVisualizationPositionTypeName(for: newValue)
            setParameter(parameter: .track3dLinePositionType, value: value)
        }
    }
    
    var coloringType: String {
        get {
            getParameter(parameter: .coloringType) as? String ?? ""
        }
        set {
            setParameter(parameter: .coloringType, value: newValue)
        }
    }
    
    var width: String {
        get {
            getParameter(parameter: .width) as? String ?? ""
        }
        set {
            setParameter(parameter: .width, value: newValue)
        }
    }
    
    var color: Int {
        get {
            return getParameter(parameter: .color) as? Int ?? 0
        }
        set {
            setParameter(parameter: .color, value: KotlinInt(integerLiteral: newValue))
        }
    }
    
    var splitType: EOAGpxSplitType {
        get {
            let value = getParameter(parameter: .splitType) as? Int ?? -1
            return EOAGpxSplitType(rawValue: value) ?? .none
        }
        set {
            setParameter(parameter: .splitType, value: KotlinInt(integerLiteral: newValue.rawValue))
        }
    }
    
    var splitInterval: Double {
        get {
            getParameter(parameter: .splitInterval) as? Double ?? 0.0
        }
        set {
            setParameter(parameter: .splitInterval, value: newValue)
        }
    }
    
    var joinSegments: Bool {
        get {
            getParameter(parameter: .joinSegments) as? Bool ?? false
        }
        set {
            setParameter(parameter: .joinSegments, value: KotlinBoolean(bool: newValue))
        }
    }
    
    var gradientPaletteName: String? {
        get {
            getParameter(parameter: .colorPalette) as? String ?? ""
        }
        set {
            setParameter(parameter: .colorPalette, value: newValue)
        }
    }
    
    private func convertTimestamp(_ timestamp: TimeInterval) -> Date {
        // Check if the timestamp is greater than 10 billion
        if timestamp > 10_000_000_000 {
            // The value is in milliseconds, convert to seconds
            return Date(timeIntervalSince1970: timestamp / 1000)
        } else {
            // The value is already in seconds
            return Date(timeIntervalSince1970: timestamp)
        }
    }
}

@objc(OASGpxDataItem)
extension GpxDataItem {
    var gpxTitle: String? {
        get {
            objc_getAssociatedObject(self, &gpxTitleKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &gpxTitleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var newGpx: Bool {
        get {
            objc_getAssociatedObject(self, &newGpxKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &newGpxKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}

@objc(OASGpxDataItem)
extension GpxDataItem {
    
    func getNiceTitle() -> String {
        if newGpx {
            return localizedString("create_new_trip")
        }
        
        if gpxTitle == nil {
            return (gpxFileName as NSString).lastPathComponent.deletingPathExtension()
        }
        
        return gpxTitle ?? ""
    }
    
    func isTempTrack() -> Bool {
        gpxFilePath.hasPrefix("Temp/")
    }
    
    func updateFolderName(newFilePath: String) {
        gpxFileName = (newFilePath as NSString).lastPathComponent
        gpxTitle = (gpxFileName as NSString).deletingPathExtension
        gpxFolderName = (newFilePath as NSString).deletingLastPathComponent
    }
}
