//
//  DataSourceType.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 16.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objc enum DataSourceType: Int, CaseIterable {
    case offline
    case online

    var title: String {
        switch self {
        case .offline: localizedString("shared_string_offline_only")
        case .online: localizedString("shared_string_online_only")
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .offline: .icCustomOffline
        case .online: .icCustomOnline
        }
    }
}

@objcMembers
final class DataSourceTypeWrapper: NSObject {
    static func titleFor(type: DataSourceType) -> String {
        type.title
    }

    static func iconFor(type: DataSourceType) -> UIImage? {
        type.icon?.withRenderingMode(.alwaysTemplate)
    }
}

