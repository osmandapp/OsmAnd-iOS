//
//  FinishTripRecordingAction.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 22.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class FinishTripRecordingAction: BaseMonitoringAction {
    static let type: QuickActionType = {
        return QuickActionType(id: QuickActionIds.finishTripRecordingAction.rawValue, stringId: "finish.trip.recording", cl: FinishTripRecordingAction.self)
            .name(localizedString("record_plugin_name"))
            .nameAction(localizedString("shared_string_finish"))
            .iconName("ic_custom_trip_rec_finish")
            .category(QuickActionTypeCategory.myPlaces.rawValue)
            .nonEditable()
    }()
    
    override class func getQuickActionType() -> QuickActionType {
        FinishTripRecordingAction.type
    }
    
    override func execute() {
        guard let plugin = getPlugin() else { return }
        if !isRecordingTrack() {
        } else if !hasDataToSave() {
        } else {
            plugin.finishRecording()
        }
    }
}
