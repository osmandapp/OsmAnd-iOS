//
//  RouteInfoDisplayValue.swift
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 08.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objc
enum RouteInfoDisplayValue: Int32, CaseIterable {
    case arrivalTime
    case timeToGo
    case distance
    
    var title: String {
        switch self {
        case .arrivalTime: localizedString("side_marker_eta")
        case .timeToGo: localizedString("map_widget_time")
        case .distance: localizedString("map_widget_distance")
        }
    }
    
    var iconName: String {
        switch self {
        case .arrivalTime: "ic_action_time"
        case .timeToGo: "ic_custom_timer"
        case .distance: "ic_custom_distance"
        }
    }
    
    var key: String {
        switch self {
        case .arrivalTime: "ARRIVAL_TIME"
        case .timeToGo: "TIME_TO_GO"
        case .distance: "DISTANCE"
        }
    }
    
    static func getValues(with displayValue: RouteInfoDisplayValue) -> [RouteInfoDisplayValue] {
        switch displayValue {
        case .arrivalTime: [.arrivalTime, .distance, .timeToGo]
        case .timeToGo: [.timeToGo, .distance, .arrivalTime]
        case .distance: [.distance, .arrivalTime, .timeToGo]
        }
    }
}
