//
//  RulerDistanceWidget.swift
//  OsmAnd Maps
//
//  Created by Paul on 20.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OARulerDistanceWidget)
@objcMembers
class RulerDistanceWidget: OATextInfoWidget {
    
    init() {
        super.init(type: .radiusRuler)
        setIcons(.radiusRuler)
        onClickFunction = { [weak self] _ in
            let settings = OAAppSettings.sharedManager()!
            let mode = settings.rulerMode.get()
            if (mode == .RULER_MODE_DARK) {
                settings.rulerMode.set(.RULER_MODE_LIGHT)
            } else if (mode == .RULER_MODE_LIGHT) {
                settings.rulerMode.set(.RULER_MODE_NO_CIRCLES)
            } else if (mode == .RULER_MODE_NO_CIRCLES) {
                settings.rulerMode.set(.RULER_MODE_DARK)
            }
            if (settings.rulerMode.get() == .RULER_MODE_NO_CIRCLES) {
                self?.setIcons("widget_ruler_circle_hide_day", widgetNightIcon: "widget_ruler_circle_hide_night")
            } else {
                self?.setIcons(.radiusRuler)
            }
            OARootViewController.instance().mapPanel.hudViewController.mapInfoController.updateRuler()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateInfo() -> Bool {
        if let currentLocation = OsmAndApp.swiftInstance().locationServices.lastKnownLocation,
           let centerLocation = OARootViewController.instance().mapPanel.mapViewController.getMapLocation() {
            let trackingUtilities = OAMapViewTrackingUtilities.instance()!
            if trackingUtilities.isMapLinkedToLocation() {
                setText(OAOsmAndFormatter.getFormattedDistance(0), subtext: nil)
            } else {
                let distance = OAOsmAndFormatter.getFormattedDistance(Float(currentLocation.distance(from: centerLocation)))!
                if let ls = distance.range(of: " ", options: .backwards)?.lowerBound {
                    setText(String(distance[..<ls]), subtext: String(distance[distance.index(after: ls)...]))
                }
            }
        } else {
            setText("-", subtext: nil)
        }
        return true

    }
    
}
