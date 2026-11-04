//
//  VehicleTrackPointsAnalyser.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 06.03.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class VehicleTrackPointsAnalyser: NSObject, GpxTrackAnalysisTrackPointsAnalyser {
    
    private static let gpxTags: [String] = OBDCommand.entries.compactMap { $0.gpxTag }
    private static let gpxTagSet: Set<String> = Set(gpxTags)

    func onAnalysePoint(analysis: GpxTrackAnalysis, point: WptPt, attribute: PointAttributes) {
        let ext = point.extensions as NSDictionary?
        let deferred = point.deferredExtensions as NSDictionary?
        
        guard hasAnyObdKey(ext) || hasAnyObdKey(deferred) else { return }

        let deferredExtensions = point.getDeferredExtensionsToRead()
        let extensions = point.getExtensionsToRead()
        for tag in Self.gpxTags {
            let value = getPointAttribute(deferredExtensions: deferredExtensions, extensions: extensions, key: tag)
            attribute.setAttributeValue(tag: tag, value: value)
            if !analysis.hasData(tag: tag) && attribute.hasValidValue(tag: tag) {
                analysis.setHasData(tag: tag, hasData: true)
            }
        }
    }

    private func hasAnyObdKey(_ dict: NSDictionary?) -> Bool {
        guard let dict, dict.count > 0 else { return false }
        for key in dict {
            if let key = key as? String, Self.gpxTagSet.contains(key) {
                return true
            }
        }
        return false
    }

    private func getPointAttribute(deferredExtensions: [String: String], extensions: [String: String], key: String) -> Float {
        var value = deferredExtensions[key]
        if value?.isEmpty ?? true {
            value = extensions[key]
        }
        
        return Float(value ?? "") ?? 0
    }
}
