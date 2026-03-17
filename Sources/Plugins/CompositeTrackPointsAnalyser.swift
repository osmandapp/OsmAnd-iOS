//
//  CompositeTrackPointsAnalyser.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 08.03.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class CompositeTrackPointsAnalyser: NSObject, GpxTrackAnalysisTrackPointsAnalyser {
    private let analysers: [AnyObject]
    
    init(analysers: [AnyObject]) {
        self.analysers = analysers
        super.init()
    }
    
    func onAnalysePoint(analysis: GpxTrackAnalysis, point: WptPt, attribute: PointAttributes) {
        for analyser in analysers {
            callAnalyser(analyser, analysis: analysis, point: point, attribute: attribute)
        }
    }
    
    private func callAnalyser(_ analyser: AnyObject, analysis: GpxTrackAnalysis, point: WptPt, attribute: PointAttributes) {
        switch analyser {
        case let analyser as GpxTrackAnalysisTrackPointsAnalyser:
            analyser.onAnalysePoint(analysis: analysis, point: point, attribute: attribute)
        case let analyser as SensorPointAnalyser:
            analyser.onAnalysePoint(analysis: analysis, point: point, attribute: attribute)
        default:
            break
        }
    }
}
