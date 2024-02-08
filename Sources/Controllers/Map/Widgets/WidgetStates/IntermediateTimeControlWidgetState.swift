//
//  IntermediateTimeControlWidgetState.swift
//  OsmAnd Maps
//
//  Created by Paul on 11.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class IntermediateTimeControlWidgetState: OAWidgetState {
    
    private static let INTERMEDIATE_TIME_CONTROL_WIDGET_STATE_ARRIVAL_TIME = "intermediate_time_control_widget_state_arrival_time"
    private static let INTERMEDIATE_TIME_CONTROL_WIDGET_STATE_TIME_TO_GO  = "intermediate_time_control_widget_state_time_to_go"
    
    private let showArrival: OACommonBoolean = OAAppSettings.sharedManager().showIntermediateArrivalTime
    
    override func getMenuTitle() -> String {
        return showArrival.get() ? localizedString("access_intermediate_arrival_time") : localizedString("map_widget_intermediate_time")
    }
    
    override func getWidgetTitle() -> String? {
        return showArrival.get() ? localizedString("access_intermediate_arrival_time") : localizedString("map_widget_intermediate_time")
    }
    
    override func getMenuIconId() -> String {
        return "ic_action_intermediate_destination_time"
    }
    
    override func getMenuItemId() -> String {
        return showArrival.get() ? Self.INTERMEDIATE_TIME_CONTROL_WIDGET_STATE_ARRIVAL_TIME : Self.INTERMEDIATE_TIME_CONTROL_WIDGET_STATE_TIME_TO_GO
    }
    
    override func getMenuTitles() -> [String] {
        return ["access_intermediate_arrival_time", "map_widget_intermediate_time"]
    }
    
    override func getMenuIconIds() -> [String] {
        return ["ic_action_intermediate_destination_time", "ic_action_intermediate_destination_time"]
    }
    
    override func getMenuItemIds() -> [String] {
        return [Self.INTERMEDIATE_TIME_CONTROL_WIDGET_STATE_ARRIVAL_TIME, Self.INTERMEDIATE_TIME_CONTROL_WIDGET_STATE_TIME_TO_GO]
    }
    
    override func change(_ stateId: String) {
        showArrival.set(stateId == Self.INTERMEDIATE_TIME_CONTROL_WIDGET_STATE_ARRIVAL_TIME)
    }
}

