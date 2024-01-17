//
//  DistanceToIntermediateDestinationWidget.swift
//  OsmAnd Maps
//
//  Created by Paul on 11.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import CoreLocation

@objc(OADistanceToIntermediateDestinationWidget)
@objcMembers
class DistanceToIntermediateDestinationWidget: OADistanceToPointWidget {
    
    init(customId: String?, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        super.init(icon: "widget_intermediate", widgetType: .intermediateDestination)
        configurePrefs(withId: customId, appMode: appMode)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = frame
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func click() {
        if let intermediatePoints = OATargetPointsHelper.sharedInstance().getIntermediatePoints(), intermediatePoints.count > 1 {
            // TODO: map.getMapActions().openIntermediatePointsDialog()
        } else {
            super.click()
        }
    }
    
    override func getPointToNavigate() -> CLLocation? {
        let p = OATargetPointsHelper.sharedInstance().getFirstIntermediatePoint()
        return p?.point
    }
    
    override func getDistance() -> CLLocationDistance {
        let routingHelper = OARoutingHelper.sharedInstance()!
        if let pointToNavigate = getPointToNavigate(), routingHelper.isRouteCalculated() {
            return CLLocationDistance(routingHelper.getLeftDistanceNextIntermediate())
        }
        return super.getDistance()
    }
}
