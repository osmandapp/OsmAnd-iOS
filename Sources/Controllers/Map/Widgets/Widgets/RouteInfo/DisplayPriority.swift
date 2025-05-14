//
//  DisplayPriority.swift
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 08.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objc
enum DisplayPriority: Int32, CaseIterable {
    case intermediateFirst
    case destinationFirst
    
    var title: String {
        switch self {
        case .intermediateFirst: localizedString("intermediate_first")
        case .destinationFirst: localizedString("destination_first")
        }
    }
    
    var iconName: String {
        switch self {
        case .intermediateFirst: "ic_action_intermediate"
        case .destinationFirst: "ic_action_target"
        }
    }
    
    var key: String {
        switch self {
        case .intermediateFirst: "INTERMEDIATE_FIRST"
        case .destinationFirst: "DESTINATION_FIRST"
        }
    }
}
