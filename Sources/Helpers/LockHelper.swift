//
//  LockHelper.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.11.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
final class LockHelper: NSObject {
    static let shared = LockHelper()
    
    private(set) var isScreenLocked = false
    
    override private init() { }
    
    func toggleLockScreen() {
        isScreenLocked.toggle()
    }
}
