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
    
    func onAnalysePoint(analysis: GpxTrackAnalysis, point: WptPt, attribute: PointAttributes) {
        // Skip analyser entirely if the point has no OBD extensions
        guard !(point.getDeferredExtensionsToRead().isEmpty && point.getExtensionsToRead().isEmpty) else { return }
        for command in OBDCommand.entries {
            guard let tag = command.gpxTag else { continue }
            let value = getPointAttribute(wptPt: point, key: tag)
            attribute.setAttributeValue(tag: tag, value: value)
            if !analysis.hasData(tag: tag) && attribute.hasValidValue(tag: tag) {
                analysis.setHasData(tag: tag, hasData: true)
            }
        }
    }
    
    private func getPointAttribute(wptPt: WptPt, key: String) -> Float {
        var value = wptPt.getDeferredExtensionsToRead()[key]
        if value?.isEmpty ?? true {
            value = wptPt.getExtensionsToRead()[key]
        }
        
        return Float(value ?? "") ?? 0
    }
}
