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

    func onAnalysePoint(analysis: GpxTrackAnalysis, point: WptPt, attribute: PointAttributes) {
        let deferredExtensions = point.getDeferredExtensionsToRead()
        let extensions = point.getExtensionsToRead()
        // Skip analyser entirely if the point has no OBD extensions
        guard !(deferredExtensions.isEmpty && extensions.isEmpty) else { return }
        for tag in Self.gpxTags {
            let value = getPointAttribute(deferredExtensions: deferredExtensions, extensions: extensions, key: tag)
            attribute.setAttributeValue(tag: tag, value: value)
            if !analysis.hasData(tag: tag) && attribute.hasValidValue(tag: tag) {
                analysis.setHasData(tag: tag, hasData: true)
            }
        }
    }
    
    private func getPointAttribute(deferredExtensions: [String: String], extensions: [String: String], key: String) -> Float {
        var value = deferredExtensions[key]
        if value?.isEmpty ?? true {
            value = extensions[key]
        }
        
        return Float(value ?? "") ?? 0
    }
}
