//
//  TextInfoWidget+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 29.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

extension OATextInfoWidget {
    @objc var widgetSizeStyle: WidgetSizeStyle {
        guard sizeStylePref != nil, let style = WidgetSizeStyle(rawValue: NSInteger(sizeStylePref.get(OAAppSettings.sharedManager().applicationMode.get()!))) else {
            return .medium
        }
        return style
    }
    
    func updateWith(style: WidgetSizeStyle, appMode: OAApplicationMode) {
        guard widgetSizeStyle != style else { 
            return
        }
        sizeStylePref.set(Int32(style.rawValue), mode: appMode)
    }
}

extension Array where Element == OATextInfoWidget {
    func updateWithMostFrequentStyle(with appMode: OAApplicationMode) {
        var styleCounts: [WidgetSizeStyle: Int] = [:]
        
        for widget in self {
            let style = widget.widgetSizeStyle
            styleCounts[style] = (styleCounts[style] ?? 0) + 1
        }
        guard let mostFrequentStyle = styleCounts.max(by: { $0.value < $1.value })?.key else {
            return
        }
        forEach { $0.updateWith(style: mostFrequentStyle, appMode: appMode) }
    }
}
