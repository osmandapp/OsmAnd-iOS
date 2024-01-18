//
//  CurrentTimeWidget.swift
//  OsmAnd Maps
//
//  Created by Paul on 15.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OACurrentTimeWidget)
@objcMembers
class CurrentTimeWidget: OASimpleWidget {
    
    var cachedTime: TimeInterval = 0
    
    init(customId: String?, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        super.init(type: .currentTime)
        setIconFor(.currentTime)
        setText(nil, subtext: nil)
        configurePrefs(withId: customId, appMode: appMode)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateInfo() -> Bool {
        let timeNow = Date.now.timeIntervalSince1970
        let timeStart = Date.now.startOfDay.timeIntervalSince1970
        let time = timeNow - timeStart
        if (isUpdateNeeded() || time - cachedTime > TimeInterval(UPDATE_INTERVAL_MILLIS)) {
            cachedTime = time
            setTimeText(time)
            return true
        }
        return false
    }
}
