//
//  BLEInitHeader.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 16.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import SwiftyBluetooth

@objcMembers
final class BLEInitHeader: NSObject {
    static func configure() {
        SwiftyBluetooth.setSharedCentralInstanceWith(restoreIdentifier: Bundle.main.bundleIdentifier ?? "restoreIdentifier")
        let _ = BLEManager.shared
    }
}
