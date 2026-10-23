// Copyright © 2026 OsmAnd. All rights reserved.

import OsmAndShared
import UIKit

struct TurnPaths {
    let arrow: CGPath
    let roundabout: CGPath
    let roundaboutCenter: CGPoint
}

extension TurnType {
    func makePaths() -> TurnPaths {
        let arrow = UIBezierPath()
        let roundabout = UIBezierPath()
        var roundaboutCenter = CGPoint.zero
        OATurnPathHelper.calcTurn(arrow, outlay: roundabout, turnType: self,
                                 transform: .identity, center: &roundaboutCenter, mini: false,
                                 shortArrow: false, noOverlap: true, smallArrow: false)
        return TurnPaths(arrow: arrow.cgPath, roundabout: roundabout.cgPath, roundaboutCenter: roundaboutCenter)
    }
}
