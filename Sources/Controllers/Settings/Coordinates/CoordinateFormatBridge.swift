//
//  CoordinateFormatBridge.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 13.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class FormattedCoordinateItem: NSObject {
    let text: String
    let prefix: String?

    init(text: String, prefix: String?) {
        self.text = text
        self.prefix = prefix
        super.init()
    }

    var copyText: String { text }
}

@objcMembers
final class CoordinateFormatBridge: NSObject {

    static func formatPrimary(lat: Double, lon: Double) -> String {
        CoordinateFormatHelper.formatPrimary(lat: lat, lon: lon)
    }

    static func primaryRowPrefix(lat: Double, lon: Double) -> String {
        CoordinateFormatHelper.primaryRowPrefix(lat: lat, lon: lon)
    }

    static func collapsedRows(lat: Double, lon: Double) -> [FormattedCoordinateItem] {
        CoordinateFormatHelper.collapsedLocationData(lat: lat, lon: lon).map { row in
            FormattedCoordinateItem(text: row.text, prefix: row.displayPrefix)
        }
    }
}
