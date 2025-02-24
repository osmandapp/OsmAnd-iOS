//
//  SaveRecordedTripAndContinueAction.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 22.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class SaveRecordedTripAndContinueAction: BaseMonitoringAction {
    static let type: QuickActionType = {
        return QuickActionType(id: QuickActionIds.saveRecordedTripAndContinueAction.rawValue, stringId: "save.trip.and.continue", cl: SaveRecordedTripAndContinueAction.self)
            .name(localizedString("quick_action_save_recorded_trip_and_continue"))
            .nameAction(localizedString("shared_string_save"))
            .iconName("ic_custom_trip_rec_save")
            .category(QuickActionTypeCategory.myPlaces.rawValue)
            .nonEditable()
    }()
    
    override class func getQuickActionType() -> QuickActionType {
        SaveRecordedTripAndContinueAction.type
    }
    
    override func execute() {
        guard let plugin = getPlugin() else { return }
        if isRecordingTrack() {
            plugin.saveTrack(false)
        }
    }
}
