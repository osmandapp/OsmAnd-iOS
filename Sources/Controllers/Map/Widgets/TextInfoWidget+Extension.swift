//
//  TextInfoWidget+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 29.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

extension OATextInfoWidget {
    @objc var widgetSizeStyle: EOAWidgetSizeStyle {
        guard widgetSizePref != nil else {
            return .medium
        }
        return widgetSizePref?.get(OAAppSettings.sharedManager().applicationMode.get()!) ?? .medium
    }
    
    @objc var isSidePanelSimpleLayoutMode: Bool {
        switch widgetSizeStyle {
        case .medium, .large:
            return true
        default:
            return false
        }
    }
    
    func updateWith(style: EOAWidgetSizeStyle, appMode: OAApplicationMode) {
        refreshLayout()
        guard widgetSizeStyle != style else {
            return
        }
        widgetSizePref?.set(style, mode: appMode)
    }
    
    @objc func widgetSizeStyleFor(appMode: OAApplicationMode) -> EOAWidgetSizeStyle {
        guard widgetSizePref != nil else {
            return .medium
        }
        return widgetSizePref?.get(appMode) ?? .medium
    }
}

extension Array where Element == OATextInfoWidget {
    func updateWithMostFrequentStyle(with appMode: OAApplicationMode) {
        var styleCounts: [EOAWidgetSizeStyle: Int] = [:]
        
        for widget in self {
            let style = widget.widgetSizeStyleFor(appMode: appMode)
            styleCounts[style] = (styleCounts[style] ?? 0) + 1
        }
        guard let mostFrequentStyle = styleCounts.max(by: { $0.value < $1.value })?.key else {
            return
        }
        forEach { $0.updateWith(style: mostFrequentStyle, appMode: appMode) }
    }
}
