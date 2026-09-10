//
//  AppEnvironment.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 02.09.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

@objcMembers
final class AppEnvironment: NSObject {
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }
}
