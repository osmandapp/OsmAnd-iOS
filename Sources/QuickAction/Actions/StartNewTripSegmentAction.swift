//
//  StartNewTripSegmentAction.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 21.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class StartNewTripSegmentAction: BaseMonitoringAction {
    static let type: QuickActionType = {
        return QuickActionType(id: QuickActionIds.startNewTripSegmentAction.rawValue, stringId: "start.new.trip.segment", cl: StartNewTripSegmentAction.self)
            .name(localizedString("new_trip_segment"))
            .nameAction(localizedString("shared_string_control_start"))
            .iconName("ic_custom_trip_rec_new_segment")
            .category(QuickActionTypeCategory.myPlaces.rawValue)
            .nonEditable()
    }()
    
    override class func getQuickActionType() -> QuickActionType {
        StartNewTripSegmentAction.type
    }
    
    override func execute() {
        if isRecordingTrack() {
            OASavingTrackHelper.sharedInstance().startNewSegment()
        }
    }
}
