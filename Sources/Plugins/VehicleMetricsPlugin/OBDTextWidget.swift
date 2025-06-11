//
//  OBDTextWidget.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 11.06.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class OBDTextWidget: OASimpleWidget {
    private var plugin: VehicleMetricsPlugin?
    
    convenience init(customId: String?, widgetType: WidgetType, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        self.init(frame: .zero)
        self.widgetType = widgetType
        plugin = OAPluginsHelper.getPlugin(VehicleMetricsPlugin.self) as? VehicleMetricsPlugin
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
