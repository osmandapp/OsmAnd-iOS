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
private var hiddenGroupsKey: UInt8 = 0

extension Array where Element: GpxDataItem {
    func toTrackItems() -> [TrackItem] { compactMap { TrackItem(file: $0.file) }}
}

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
        dataItem?.gpxFilePath ?? ""
    }

    var creationDate: Date {
        get {
            dataItem?.creationDate ?? Date()
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

    var elevationMeters: Bool {
        get {
            dataItem?.elevationMeters ?? false
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
            let fileCreationTime = getParameter(parameter: .fileCreationTime) as? Double ?? 0.0
            return Date(timeIntervalSince1970: fileCreationTime)
        }
        set {
            setParameter(parameter: .fileCreationTime, value: newValue.timeIntervalSince1970)
        }
    }
    
    var lastModifiedTime: Date {
        get {
            let lastModifiedTimeInMilliseconds = getParameter(parameter: .fileLastModifiedTime) as? Double ?? 0.0
            return Date(timeIntervalSince1970: lastModifiedTimeInMilliseconds / 1000)
        }
        set {
            let milliseconds = newValue.timeIntervalSince1970 * 1000
            setParameter(parameter: .fileLastModifiedTime, value: milliseconds)
        }
    }
    
    var fileLastUploadedTime: Date {
        get {
            let lastUploadedTime = getParameter(parameter: .fileLastUploadedTime) as? Double ?? 0.0
            return Date(timeIntervalSince1970: lastUploadedTime)
        }
        set {
            setParameter(parameter: .fileLastUploadedTime, value: newValue.timeIntervalSince1970)
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
            setParameter(parameter: .totalTracks, value: newValue)
        }
    }
    
    var timeSpan: Int {
        get {
            getParameter(parameter: .timeSpan) as? Int ?? 0
        }
        set {
            setParameter(parameter: .timeSpan, value: newValue)
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
    
    var elevationMeters: Bool {
        get {
            getParameter(parameter: .elevationMeters) as? Bool ?? false
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
            return Self.lineVisualizationByType(forName: name)
        }
        set {
            let value = Self.lineVisualizationByTypeName(for: newValue)
            setParameter(parameter: .trackVisualizationType, value: value)
        }
    }
    
    var visualization3dWallColorType: EOAGPX3DLineVisualizationWallColorType {
        get {
            let name = getParameter(parameter: .track3dWallColoringType) as? String ?? ""
            return Self.lineVisualizationWallColorType(forName: name)
        }
        set {
            let value = Self.lineVisualizationWallColorTypeName(for: newValue)
            setParameter(parameter: .track3dWallColoringType, value: value)
        }
    }
    
    var visualization3dPositionType: EOAGPX3DLineVisualizationPositionType {
        get {
            let name = getParameter(parameter: .track3dLinePositionType) as? String ?? ""
            return Self.lineVisualizationPositionType(for: name)
        }
        set {
            let value = Self.lineVisualizationPositionTypeName(for: newValue)
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
            getParameter(parameter: .color) as? Int ?? 0
        }
        set {
            setParameter(parameter: .color, value: newValue)
        }
    }
    
    var splitType: EOAGpxSplitType {
        get {
            let value = getParameter(parameter: .splitType) as? Int ?? 0
            return EOAGpxSplitType(rawValue: value) ?? .none
        }
        set {
            setParameter(parameter: .splitType, value: newValue)
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
            setParameter(parameter: .joinSegments, value: newValue)
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
    
    var hiddenGroups: Set<String>? {
        get {
            objc_getAssociatedObject(self, &hiddenGroupsKey) as? Set<String>
        }
        set {
            objc_setAssociatedObject(self, &hiddenGroupsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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
    
    func removeHiddenGroups(_ groupName: String) {
        guard var groups = hiddenGroups else {
            hiddenGroups = []
            return
        }
        
        groups.remove(groupName)
        hiddenGroups = groups
    }
    
    func addHiddenGroups(_ groupName: String) {
        if hiddenGroups == nil {
            hiddenGroups = [groupName]
        } else {
            hiddenGroups?.insert(groupName)
        }
    }
    
    func updateFolderName(newFilePath: String) {
      //  gpxFilePath = newFilePath
        // FIXME: save to db
        gpxFileName = (newFilePath as NSString).lastPathComponent
        gpxTitle = (gpxFileName as NSString).deletingPathExtension
        gpxFolderName = (newFilePath as NSString).deletingLastPathComponent
    }
    
//    static func splitTypeByName(_ splitName: String) -> EOAGpxSplitType {
//        switch splitName {
//        case "":
//            fallthrough
//        case "no_split":
//            return .none
//        case "distance":
//            return .distance
//        case "time":
//            return .time
//        default:
//            return .none
//        }
//    }
//
//    static func splitTypeNameByValue(_ splitType: EOAGpxSplitType) -> String {
//        switch splitType {
//        case .distance:
//            return "distance"
//        case .time:
//            return "time"
//        case .none:
//            return "no_split"
//        default:
//            return "no_split"
//        }
//    }
    
    static func lineVisualizationByTypeName(for type: EOAGPX3DLineVisualizationByType) -> String {
        switch type {
        case .altitude:
            return "altitude"
        case .speed:
            return "speed"
        case .heartRate:
            return "hr"
        case .bicycleCadence:
            return "cad"
        case .bicyclePower:
            return "power"
            // FIXME: .temperatureW
        case .temperatureA: /*, .temperatureW*/
            return "temp_sensor"
        case .speedSensor:
            return "speed_sensor"
        case .fixedHeight:
            return "fixed_height"
        case .none:
            return "none"
        default:
            return "none"
        }
    }
    
    static func lineVisualizationByType(forName name: String) -> EOAGPX3DLineVisualizationByType {
        switch name {
        case "altitude":
            return .altitude
        case "speed":
            return .speed
        case "hr":
            return .heartRate
        case "cad":
            return .bicycleCadence
        case "power":
            return .bicyclePower
        case "temp_sensor":
            return .temperatureA
        case "speed_sensor":
            return .speedSensor
        case "fixed_height":
            return .fixedHeight
        default:
            return .none
        }
    }
    
    static func lineVisualizationWallColorTypeName(for type: EOAGPX3DLineVisualizationWallColorType) -> String {
        switch type {
        case .solid:
            return "solid"
        case .downwardGradient:
            return "downward_gradient"
        case .upwardGradient:
            return "upward_gradient"
        case .altitude:
            return "altitude"
        case .slope:
            return "slope"
        case .speed:
            return "speed"
        case .none:
            return "none"
        default:
            return "none"
        }
    }
    
    static func lineVisualizationWallColorType(forName name: String) -> EOAGPX3DLineVisualizationWallColorType {
        switch name {
        case "none":
            return .none
        case "solid":
            return .solid
        case "downward_gradient":
            return .downwardGradient
        case "upward_gradient":
            return .upwardGradient
        case "altitude":
            return .altitude
        case "slope":
            return .slope
        case "speed":
            return .speed
        default:
            return .upwardGradient
        }
    }
    
    static func lineVisualizationPositionTypeName(for type: EOAGPX3DLineVisualizationPositionType) -> String {
        switch type {
        case .bottom:
            return "bottom"
        case .topBottom:
            return "top_bottom"
        case .top:
            return "top"
        default:
            return "top"
        }
    }
    
    static func lineVisualizationPositionType(for name: String) -> EOAGPX3DLineVisualizationPositionType {
        switch name {
        case "bottom":
            return .bottom
        case "top_bottom":
            return .topBottom
        default:
            return .top
        }
    }
}
