//
//  Buildings3DColorType.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 17.03.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objc enum Buildings3DColorType: Int {
    case mapStyle = 1
    case custom = 2
    
    var labelId: String {
        switch self {
        case .mapStyle:
            return "quick_action_map_style"
        case .custom:
            return "shared_string_custom"
        }
    }
    
    static func getById(_ id: Int) -> Buildings3DColorType {
        guard let type = Buildings3DColorType(rawValue: id) else {
            fatalError("Unknown Buildings3DColorType id=\(id)")
        }
        
        return type
    }
}
