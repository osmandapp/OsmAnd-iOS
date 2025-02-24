//
//  TripRecordingAction.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 21.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class TripRecordingAction: BaseMonitoringAction {
    static let type: QuickActionType = {
        return QuickActionType(id: QuickActionIds.tripRecordingAction.rawValue, stringId: "trip.recording.startpause", cl: TripRecordingAction.self)
            .name(localizedString("record_plugin_name"))
            .nameAction(localizedString("quick_action_verb_start_pause"))
            .iconName("ic_custom_trip_rec_start")
            .category(QuickActionTypeCategory.myPlaces.rawValue)
            .nonEditable()
    }()
    
    override class func getQuickActionType() -> QuickActionType {
        TripRecordingAction.type
    }
    
    override func execute() {
        guard let plugin = getPlugin() else { return }
        if hasDataToSave() {
            plugin.pauseOrResumeRecording()
        } else {
            plugin.showTripRecordingDialog()
        }
    }
    
    override func getIconResName() -> String? {
        isRecordingTrack() ? "ic_custom_trip_rec_pause" : "ic_custom_trip_rec_start"
    }
    
    override func getText() -> String? {
        isRecordingTrack() ? localizedString("shared_string_pause") : localizedString("shared_string_control_start")
    }
}
