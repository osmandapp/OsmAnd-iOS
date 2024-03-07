//
//  GlideBaseWidget.swift
//  OsmAnd Maps
//
//  Created by Skalii on 04.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAGlideBaseWidget)
@objcMembers
class GlideBaseWidget: OASimpleWidget {

    static let longUpdateIntervalMillis = 10000
    private static var updateIntervalMillis = 1000

    private var lastUpdateTime = 0

    init(_ widgetType: WidgetType, customId: String?, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        super.init(type: widgetType)
        setText("-", subtext: "")
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func markUpdated() {
        lastUpdateTime = Int(Date.now.timeIntervalSince1970)
    }

    func isTimeToUpdate() -> Bool {
        return isTimeToUpdate(Self.updateIntervalMillis)
    }

    func isTimeToUpdate(_ interval: Int) -> Bool {
        return Int(Date.now.timeIntervalSince1970) - lastUpdateTime > interval
    }
}
