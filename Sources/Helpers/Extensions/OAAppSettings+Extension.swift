//
//  OAAppSettings+Extension.swift
//  OsmAnd Maps
//
//  Created by Skalii on 15.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

extension OACommonInteger {
    @objc func getValueFromString(_ value: String) -> Int32 {
        if key.hasPrefix("simple_widget_size") {
            return Int32(WidgetSizeStyle.getValueFromString(value))
        }
        return Int32(value) ?? 0
    }

    @objc func getStringFromValue(_ mode: OAApplicationMode) -> String {
        let value = get(mode)
        if key.hasPrefix("simple_widget_size") {
            return WidgetSizeStyle.getStringFromValue(Int(value))
        }
        return String(value)
    }
}
