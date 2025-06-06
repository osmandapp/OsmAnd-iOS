//
//  BLEInitHeader.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 16.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@objcMembers
final class BLEInitHeader: NSObject {
    static func configure() {
        if UserDefaults.standard.bool(for: .wasAuthorizationRequestBluetooth) {
            SwiftyBluetooth.setSharedCentralInstanceWith(restoreIdentifier: Bundle.main.bundleIdentifier ?? "restoreIdentifier")
            let _ = BLEManager.shared
        }
    }
}
